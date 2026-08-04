(in-package #:lightfast)

;;; Small rectangle layout helpers.  These keep application layout code about
;;; structure rather than repeated x/y/width arithmetic.

(defconstant +space-none+ 0)
(defconstant +space-tight+ 4)
(defconstant +space-small+ 8)
(defconstant +space-medium+ 12)
(defconstant +space-large+ 16)

(defstruct (rect (:constructor make-rect
                     (&key (x 0) (y 0) (width 0) (height 0))))
  (x      0 :type integer)
  (y      0 :type integer)
  (width  0 :type integer)
  (height 0 :type integer))

(defun rect-right (rect)
  (+ (rect-x rect) (rect-width rect)))

(defun rect-bottom (rect)
  (+ (rect-y rect) (rect-height rect)))

(defun rect-empty-p (rect)
  (or (not (plusp (rect-width rect)))
      (not (plusp (rect-height rect)))))

(defun rect-with (rect &key x y width height)
  (make-rect :x      (or x (rect-x rect))
             :y      (or y (rect-y rect))
             :width  (or width (rect-width rect))
             :height (or height (rect-height rect))))

(defun rect-inset
    (rect &key all horizontal vertical left top right bottom)
  (let* ((base   (or all 0))
         (h      (or horizontal base))
         (v      (or vertical base))
         (left   (or left h))
         (right  (or right h))
         (top    (or top v))
         (bottom (or bottom v)))
    (make-rect :x      (+ (rect-x rect) left)
               :y      (+ (rect-y rect) top)
               :width  (max 0 (- (rect-width rect) left right))
               :height (max 0 (- (rect-height rect) top bottom)))))

(defun rect-split-x (rect width &key (gap 0))
  (let* ((left-w  (min (rect-width rect) (max 0 width)))
         (right-x (+ (rect-x rect) left-w gap))
         (right-w (max 0 (- (rect-right rect) right-x))))
    (values
     (rect-with rect :width left-w)
     (make-rect :x      right-x
                :y      (rect-y rect)
                :width  right-w
                :height (rect-height rect)))))

(defun rect-split-y (rect height &key (gap 0))
  (let* ((top-h    (min (rect-height rect) (max 0 height)))
         (bottom-y (+ (rect-y rect) top-h gap))
         (bottom-h (max 0 (- (rect-bottom rect) bottom-y))))
    (values
     (rect-with rect :height top-h)
     (make-rect :x      (rect-x rect)
                :y      bottom-y
                :width  (rect-width rect)
                :height bottom-h))))

(defun rect-columns (rect count &key (gap 0))
  (unless (plusp count)
    (error "Column count must be positive, got ~S." count))
  (let* ((available (max 0 (- (rect-width rect)
                              (* gap (1- count)))))
         (base      (floor available count))
         (extra     (mod available count)))
    (loop with x = (rect-x rect)
          for index below count
          for width = (+ base (if (< index extra) 1 0))
          collect (make-rect :x      x
                             :y      (rect-y rect)
                             :width  width
                             :height (rect-height rect))
          do (incf x (+ width gap)))))

(defun rect-rows (rect heights &key (gap 0))
  (loop with y = (rect-y rect)
        for height in heights
        for row-height = (max 0 height)
        collect (make-rect :x      (rect-x rect)
                           :y      y
                           :width  (rect-width rect)
                           :height row-height)
        do (incf y (+ row-height gap))))

(defun resize-widget-to-rect (widget rect)
  (resize-widget widget
                 :x      (rect-x rect)
                 :y      (rect-y rect)
                 :width  (rect-width rect)
                 :height (rect-height rect)))

(defun label-width-for-text
    (text &key (minimum 82) (maximum 122) (char-width 7) (padding 14))
  (min maximum
       (max minimum
            (+ padding
               (* char-width
                  (length (if text (princ-to-string text) "")))))))

(defun labeled-control-rects
    (rect &key (label-width 84) (gap 8) height (min-control-width 24))
  (let* ((height        (or height (rect-height rect)))
         (label-width   (min label-width
                             (max 0 (- (rect-width rect)
                                       gap
                                       min-control-width))))
         (label-rect    (rect-with rect :height height :width label-width))
         (control-x     (+ (rect-x label-rect) label-width gap))
         (control-width (max min-control-width
                             (- (rect-right rect) control-x))))
    (values label-rect
            (make-rect :x      control-x
                       :y      (rect-y rect)
                       :width  control-width
                       :height height))))

(defun layout-labeled-widgets
    (label control rect &key (label-width 84) (gap 8) height
       (min-control-width 24))
  (multiple-value-bind (label-rect control-rect)
      (labeled-control-rects rect
                             :label-width       label-width
                             :gap               gap
                             :height            height
                             :min-control-width min-control-width)
    (resize-widget-to-rect label label-rect)
    (resize-widget-to-rect control control-rect))
  rect)
