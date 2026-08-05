(in-package #:lightfast)

;;; A small, deterministic, single-line flex layout engine.  It deliberately
;;; covers the common application layouts without attempting to reproduce CSS.

(define-condition layout-error (error)
  ((message :initarg :message :reader layout-error-message))
  (:report (lambda (condition stream)
             (write-string (layout-error-message condition) stream)))
  (:documentation "Signaled when an automatic layout specification is invalid."))

(defstruct (layout-node (:constructor %make-layout-node))
  "A leaf, row, or column in an automatic layout tree."
  kind
  target
  (children nil :type list)
  (grow 0 :type real)
  (shrink 1 :type real)
  (basis :auto)
  (min-width 0 :type integer)
  (min-height 0 :type integer)
  max-width
  max-height
  preferred-width
  preferred-height
  (gap 0 :type integer)
  (padding '(0 0 0 0) :type list)
  (justify :start)
  (align :stretch)
  align-self)

(defstruct (layout-placement
             (:constructor make-layout-placement (target rect &optional parent)))
  "A target and parent-relative rectangle produced by COMPUTE-LAYOUT."
  target
  (rect (make-rect) :type rect)
  parent)

(defun %layout-error (control &rest arguments)
  (let ((*print-circle* t)
        (*print-length* 16)
        (*print-level* 6))
    (error 'layout-error :message (apply #'format nil control arguments))))

(defun %proper-list-p (value)
  (and (listp value)
       (handler-case
           (integerp (list-length value))
         (type-error () nil))))

(defun %nonnegative-integer (value name &key allow-nil)
  (cond
    ((and allow-nil (null value)) nil)
    ((and (integerp value) (not (minusp value))) value)
    (t (%layout-error "~A must be a non-negative integer~@[ or NIL~], got ~S."
                      name allow-nil value))))

(defun %nonnegative-real (value name)
  (if (and (realp value) (not (minusp value)))
      value
      (%layout-error "~A must be a non-negative real number, got ~S." name value)))

(defun %layout-padding (padding)
  (cond
    ((and (integerp padding) (not (minusp padding)))
     (list padding padding padding padding))
    ((and (%proper-list-p padding)
          (= (length padding) 4)
          (every (lambda (value)
                   (and (integerp value) (not (minusp value))))
                 padding))
     (copy-list padding))
    (t
     (%layout-error
      "Layout padding must be a non-negative integer or (LEFT TOP RIGHT BOTTOM), got ~S."
      padding))))

(defun %layout-enum (value choices name &key allow-nil)
  (if (or (and allow-nil (null value)) (member value choices))
      value
      (%layout-error "~A must be one of ~{~S~^, ~}~@[ or NIL~], got ~S."
                     name choices allow-nil value)))

(defun %validate-layout-dimensions
    (min-width min-height max-width max-height preferred-width preferred-height)
  (let ((min-width (%nonnegative-integer min-width "MIN-WIDTH"))
        (min-height (%nonnegative-integer min-height "MIN-HEIGHT"))
        (max-width (%nonnegative-integer max-width "MAX-WIDTH" :allow-nil t))
        (max-height (%nonnegative-integer max-height "MAX-HEIGHT" :allow-nil t))
        (preferred-width
          (%nonnegative-integer preferred-width "PREFERRED-WIDTH" :allow-nil t))
        (preferred-height
          (%nonnegative-integer preferred-height "PREFERRED-HEIGHT" :allow-nil t)))
    (when (and max-width (< max-width min-width))
      (%layout-error "MAX-WIDTH ~D is smaller than MIN-WIDTH ~D."
                     max-width min-width))
    (when (and max-height (< max-height min-height))
      (%layout-error "MAX-HEIGHT ~D is smaller than MIN-HEIGHT ~D."
                     max-height min-height))
    (values min-width min-height max-width max-height
            preferred-width preferred-height)))

(defun %make-validated-layout-node
    (kind &key target children (grow 0) (shrink 1) (basis :auto)
       (min-width 0) (min-height 0) max-width max-height
       preferred-width preferred-height (gap 0) (padding 0)
       (justify :start) (align :stretch) align-self)
  (unless (or (eq basis :auto)
              (and (integerp basis) (not (minusp basis))))
    (%layout-error "BASIS must be :AUTO or a non-negative integer, got ~S." basis))
  (unless (and (%proper-list-p children) (every #'layout-node-p children))
    (%layout-error "CHILDREN must be a proper list of layout nodes, got ~S." children))
  (multiple-value-bind
        (min-width min-height max-width max-height preferred-width preferred-height)
      (%validate-layout-dimensions min-width min-height max-width max-height
                                   preferred-width preferred-height)
    (%make-layout-node
     :kind kind
     :target target
     :children children
     :grow (%nonnegative-real grow "GROW")
     :shrink (%nonnegative-real shrink "SHRINK")
     :basis basis
     :min-width min-width
     :min-height min-height
     :max-width max-width
     :max-height max-height
     :preferred-width preferred-width
     :preferred-height preferred-height
     :gap (%nonnegative-integer gap "GAP")
     :padding (%layout-padding padding)
     :justify (%layout-enum justify
                            '(:start :center :end :space-between)
                            "JUSTIFY")
     :align (%layout-enum align '(:stretch :start :center :end) "ALIGN")
     :align-self (%layout-enum align-self
                               '(:stretch :start :center :end)
                               "ALIGN-SELF"
                               :allow-nil t))))

(defun make-layout-item
    (target &key (grow 0) (shrink 1) (basis :auto)
       (min-width 0) (min-height 0) max-width max-height
       preferred-width preferred-height align-self)
  "Create a leaf layout node for TARGET.

BASIS controls its initial size on its parent's main axis.  :AUTO uses the
preferred size, or the current widget size when TARGET is a widget."
  (%make-validated-layout-node
   :item
   :target target
   :grow grow
   :shrink shrink
   :basis basis
   :min-width min-width
   :min-height min-height
   :max-width max-width
   :max-height max-height
   :preferred-width preferred-width
   :preferred-height preferred-height
   :align-self align-self))

(defun %make-layout-container
    (kind &key target children (grow 0) (shrink 1) (basis :auto)
       (min-width 0) (min-height 0) max-width max-height
       preferred-width preferred-height (gap 0) (padding 0)
       (justify :start) (align :stretch) align-self)
  (%make-validated-layout-node
   kind
   :target target
   :children children
   :grow grow
   :shrink shrink
   :basis basis
   :min-width min-width
   :min-height min-height
   :max-width max-width
   :max-height max-height
   :preferred-width preferred-width
   :preferred-height preferred-height
   :gap gap
   :padding padding
   :justify justify
   :align align
   :align-self align-self))

(defun make-layout-row
    (&key target children (grow 0) (shrink 1) (basis :auto)
       (min-width 0) (min-height 0) max-width max-height
       preferred-width preferred-height (gap 0) (padding 0)
       (justify :start) (align :stretch) align-self)
  "Create a horizontal, single-line flex layout node.

CHILDREN are layout nodes.  GAP and PADDING control spacing, JUSTIFY controls
unused main-axis space, and ALIGN controls child placement across the row."
  (%make-layout-container
   :row
   :target target :children children :grow grow :shrink shrink :basis basis
   :min-width min-width :min-height min-height
   :max-width max-width :max-height max-height
   :preferred-width preferred-width :preferred-height preferred-height
   :gap gap :padding padding :justify justify :align align
   :align-self align-self))

(defun make-layout-column
    (&key target children (grow 0) (shrink 1) (basis :auto)
       (min-width 0) (min-height 0) max-width max-height
       preferred-width preferred-height (gap 0) (padding 0)
       (justify :start) (align :stretch) align-self)
  "Create a vertical, single-line flex layout node.

CHILDREN are layout nodes.  GAP and PADDING control spacing, JUSTIFY controls
unused main-axis space, and ALIGN controls child placement across the column."
  (%make-layout-container
   :column
   :target target :children children :grow grow :shrink shrink :basis basis
   :min-width min-width :min-height min-height
   :max-width max-width :max-height max-height
   :preferred-width preferred-width :preferred-height preferred-height
   :gap gap :padding padding :justify justify :align align
   :align-self align-self))

(defun %clamp-layout-size (size minimum maximum)
  (min (or maximum most-positive-fixnum) (max minimum size)))

(defun %node-dimension-limits (node axis)
  (ecase axis
    (:width
     (values (layout-node-min-width node) (layout-node-max-width node)))
    (:height
     (values (layout-node-min-height node) (layout-node-max-height node)))))

(defun %node-natural-dimension (node axis)
  (let ((explicit (ecase axis
                    (:width (layout-node-preferred-width node))
                    (:height (layout-node-preferred-height node)))))
    (multiple-value-bind (minimum maximum) (%node-dimension-limits node axis)
      (%clamp-layout-size
       (or explicit
           (when (member (layout-node-kind node) '(:row :column))
             (destructuring-bind (left top right bottom)
                 (layout-node-padding node)
               (let* ((children (layout-node-children node))
                      (count (length children))
                      (gap-total (* (layout-node-gap node) (max 0 (1- count))))
                      (main-axis (if (eq (layout-node-kind node) :row)
                                     :width
                                     :height))
                      (main-p (eq axis main-axis)))
                 (+ (if (eq axis :width) left top)
                    (if main-p
                        (+ gap-total
                           (loop for child in children
                                 sum (%node-main-basis child main-axis)))
                        (loop for child in children
                              maximize (%node-natural-dimension child axis)
                                into maximum-child
                              finally (return (or maximum-child 0))))
                    (if (eq axis :width) right bottom)))))
           (and (widget-p (layout-node-target node))
                (ecase axis
                  (:width (widget-width (layout-node-target node)))
                  (:height (widget-height (layout-node-target node)))))
           0)
       minimum maximum))))

(defun %node-main-basis (node main-axis)
  (multiple-value-bind (minimum maximum) (%node-dimension-limits node main-axis)
    (%clamp-layout-size
     (if (eq (layout-node-basis node) :auto)
         (%node-natural-dimension node main-axis)
         (layout-node-basis node))
     minimum maximum)))

(defun %weighted-allocation (amount weights capacities)
  (let* ((count (length weights))
         (allocation (make-array count :initial-element 0))
         (remaining amount)
         (remaining-capacities (coerce capacities 'vector)))
    (loop while (plusp remaining) do
      (let* ((active
               (loop for weight in weights
                     for index from 0
                     for capacity = (aref remaining-capacities index)
                     when (and (plusp weight)
                               (or (null capacity) (plusp capacity)))
                       collect index))
             (total-weight
               (loop for index in active sum (nth index weights))))
        (unless active
          (return))
        (let ((distributed 0)
              (round-remaining remaining))
          (dolist (index active)
            (let* ((capacity (aref remaining-capacities index))
                   (share (floor (* round-remaining (nth index weights))
                                 total-weight))
                   (share (min share (or capacity round-remaining))))
              (when (plusp share)
                (incf (aref allocation index) share)
                (incf distributed share)
                (when capacity
                  (decf (aref remaining-capacities index) share)))))
          (decf remaining distributed)
          (when (zerop distributed)
            (dolist (index active)
              (when (plusp remaining)
                (let ((capacity (aref remaining-capacities index)))
                  (when (or (null capacity) (plusp capacity))
                    (incf (aref allocation index))
                    (decf remaining)
                    (when capacity
                      (decf (aref remaining-capacities index)))))))))))
    (values (coerce allocation 'list) remaining)))

(defun %layout-main-sizes (children available main-axis gap)
  (let* ((bases (mapcar (lambda (child)
                          (%node-main-basis child main-axis))
                        children))
         (gap-total (* gap (max 0 (1- (length children)))))
         (free (- available gap-total (reduce #'+ bases :initial-value 0))))
    (cond
      ((plusp free)
       (let ((capacities
               (mapcar (lambda (child base)
                         (multiple-value-bind (minimum maximum)
                             (%node-dimension-limits child main-axis)
                           (declare (ignore minimum))
                           (and maximum (max 0 (- maximum base)))))
                       children bases)))
         (multiple-value-bind (growth remaining)
             (%weighted-allocation free
                                   (mapcar #'layout-node-grow children)
                                   capacities)
           (values (mapcar #'+ bases growth) remaining))))
      ((minusp free)
       (let ((capacities
               (mapcar (lambda (child base)
                         (multiple-value-bind (minimum maximum)
                             (%node-dimension-limits child main-axis)
                           (declare (ignore maximum))
                           (max 0 (- base minimum))))
                       children bases))
             (weights
               (mapcar (lambda (child base)
                         (* (layout-node-shrink child) (max 1 base)))
                       children bases)))
         (multiple-value-bind (shrink remaining)
             (%weighted-allocation (- free) weights capacities)
           (values (mapcar #'- bases shrink) (- remaining)))))
      (t
       (values bases 0)))))

(defun %layout-cross-size (node cross-axis available align)
  (multiple-value-bind (minimum maximum) (%node-dimension-limits node cross-axis)
    (%clamp-layout-size
     (if (eq align :stretch)
         available
         (%node-natural-dimension node cross-axis))
     minimum maximum)))

(defun %layout-children (node rect parent)
  (destructuring-bind (left top right bottom) (layout-node-padding node)
    (let* ((content (rect-inset rect
                               :left left :top top :right right :bottom bottom))
           (row-p (eq (layout-node-kind node) :row))
           (main-axis (if row-p :width :height))
           (cross-axis (if row-p :height :width))
           (main-start (if row-p (rect-x content) (rect-y content)))
           (cross-start (if row-p (rect-y content) (rect-x content)))
           (main-available (if row-p (rect-width content) (rect-height content)))
           (cross-available (if row-p (rect-height content) (rect-width content)))
           (children (layout-node-children node))
           (count (length children))
           (gap (layout-node-gap node)))
      (multiple-value-bind (sizes leftover)
          (%layout-main-sizes children main-available main-axis gap)
        (let ((offset 0)
              (gaps (make-list (max 0 (1- count)) :initial-element gap)))
          (when (plusp leftover)
            (ecase (layout-node-justify node)
              (:start)
              (:center (setf offset (floor leftover 2)))
              (:end (setf offset leftover))
              (:space-between
               (if (> count 1)
                   (multiple-value-bind (extra remainder)
                       (floor leftover (1- count))
                     (setf gaps
                           (loop for index below (1- count)
                                 collect (+ gap extra
                                            (if (< index remainder) 1 0)))))
                   (setf offset (floor leftover 2))))))
          (loop with cursor = (+ main-start offset)
                for child in children
                for main-size in sizes
                for index from 0
                append
                (let* ((align (or (layout-node-align-self child)
                                  (layout-node-align node)))
                       (cross-size
                         (%layout-cross-size child cross-axis cross-available align))
                       (cross-offset
                         (ecase align
                           ((:stretch :start) 0)
                           (:center (max 0 (floor (- cross-available cross-size) 2)))
                           (:end (max 0 (- cross-available cross-size)))))
                       (child-rect
                         (if row-p
                             (make-rect :x cursor
                                        :y (+ cross-start cross-offset)
                                        :width main-size
                                        :height cross-size)
                             (make-rect :x (+ cross-start cross-offset)
                                        :y cursor
                                        :width cross-size
                                        :height main-size))))
                  (prog1 (%compute-layout child child-rect parent)
                    (incf cursor (+ main-size (or (nth index gaps) 0)))))))))))

(defun %compute-layout (node rect parent)
  (let* ((target (layout-node-target node))
         (placement
           (and target (list (make-layout-placement target rect parent))))
         (children (layout-node-children node)))
    (if (or (null children) (eq (layout-node-kind node) :item))
        placement
        (let ((child-rect (if target
                              (make-rect :width (rect-width rect)
                                         :height (rect-height rect))
                              rect)))
          (nconc placement
                 (%layout-children node child-rect (or target parent)))))))

(defun compute-layout (layout rect &key parent)
  "Compute target rectangles for LAYOUT inside RECT without changing widgets.

The result is a list of LAYOUT-PLACEMENT objects.  Rectangles are relative to
each target's direct parent, which makes nested target groups compose correctly.
PARENT records the coordinate frame for root placements when one is known."
  (unless (layout-node-p layout)
    (%layout-error "LAYOUT must be a layout node, got ~S." layout))
  (unless (rect-p rect)
    (%layout-error "RECT must be a rectangle, got ~S." rect))
  (when (or (minusp (rect-width rect))
            (minusp (rect-height rect)))
    (%layout-error "RECT dimensions must be non-negative, got ~S." rect))
  (%compute-layout layout rect parent))

(defun %validate-layout-placements (placements)
  (dolist (placement placements)
    (let ((target (layout-placement-target placement))
          (parent (layout-placement-parent placement)))
      (unless (widget-p target)
        (%layout-error "Cannot apply a layout to non-widget target ~S." target))
      (when (and parent
                 (not (widget-p parent)))
        (%layout-error "Layout parent ~S is not a widget." parent))
      (when (and parent
                 (not (eq (widget-parent target) parent)))
        (%layout-error "Layout target ~S is not a direct child of ~S."
                       target parent))))
  placements)

(defun apply-layout (layout rect &key parent)
  "Compute LAYOUT inside RECT and resize every target widget.

PARENT, when supplied, is the direct widget parent of root layout targets.
Every placement is validated before any widget is resized.  Container targets
are then resized before their descendants.  Returns the computed placements."
  (let ((placements (compute-layout layout rect :parent parent)))
    (%validate-layout-placements placements)
    (dolist (placement placements)
      (resize-widget-to-rect (layout-placement-target placement)
                             (layout-placement-rect placement)))
    placements))

(defun layout-on-resize (widget layout)
  "Apply LAYOUT to WIDGET's content area now and whenever WIDGET is resized.

LAYOUT normally has no target of its own and contains children whose FLTK parent
is WIDGET.  Returns WIDGET so it composes with other constructor calls."
  (labels ((relayout (root)
             (refresh-geometry root)
             (apply-layout layout
                           (make-rect :width (widget-width root)
                                      :height (widget-height root))
                           :parent root)))
    (relayout widget)
    (on-resize widget #'relayout))
  widget)
