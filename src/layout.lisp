(in-package #:lightfast)

(defstruct (field (:constructor %make-field (label control)))
  label
  control)

(defstruct (form (:constructor %make-form (fields)))
  fields)

(defstruct (radio-group (:constructor %make-radio-group (buttons)))
  buttons)

(defmacro with-parent ((parent) &body body)
  `(let ((*default-parent* ,parent))
     ,@body))

(defmacro with-window ((window &key
                               ((:x x) 100)
                               ((:y y) 100)
                               ((:width width) 640)
                               ((:height height) 480)
                               ((:label label) "")
                               ((:app-id app-id) nil app-id-supplied-p)
                               (classic-theme t)
                               fixed-size
                               show
                               run)
                       &body body)
  `(progn
     (when ,classic-theme
       (apply-classic-theme))
     (let ((,window (make-window :x      ,x
                                 :y      ,y
                                 :width  ,width
                                 :height ,height
                                 :label  ,label
                                 ,@(when app-id-supplied-p
                                     `(:app-id ,app-id)))))
       (with-parent (,window)
         ,@body)
       (when ,fixed-size
         (set-size-range ,window
                         :min-width  ,width
                         :min-height ,height
                         :max-width  ,width
                         :max-height ,height))
       (when ,show
         (show ,window))
       (when ,run
         (run))
       ,window)))

(defmacro with-group ((group &key
                             ((:parent parent) nil parent-supplied-p)
                             ((:x x) 0)
                             ((:y y) 0)
                             ((:width width) 120)
                             ((:height height) 80)
                             ((:label label) ""))
                      &body body)
  `(let ((,group (make-group ,@(when parent-supplied-p
                                 `(:parent ,parent))
                             :x      ,x
                             :y      ,y
                             :width  ,width
                             :height ,height
                             :label  ,label)))
     (with-parent (,group)
       ,@body)
     ,group))

(defmacro with-tab-page ((page &key
                                ((:parent parent) nil parent-supplied-p)
                                ((:x x) 0)
                                ((:y y) 0)
                                ((:width width) 320)
                                ((:height height) 180)
                                ((:label label) ""))
                         &body body)
  `(let ((,page (make-tab-page ,@(when parent-supplied-p
                                   `(:parent ,parent))
                               :x      ,x
                               :y      ,y
                               :width  ,width
                               :height ,height
                               :label  ,label)))
     (with-parent (,page)
       ,@body)
     ,page))

(defun make-panel (&key (parent *default-parent*) (x 0) (y 0) (width 120) (height 80) (label ""))
  (make-group :parent parent
              :x      x
              :y      y
              :width  width
              :height height
              :label  label))

(defun make-status-bar (&key (parent *default-parent*) (x 0) (y 0) (width 320) (height 24) (value "Ready"))
  (make-widget +widget-status-bar+
               :parent parent
               :x      x
               :y      y
               :width  width
               :height height
               :label  value))

(defun menu-callback-designator-p (value)
  (or (functionp value)
      (and (symbolp value)
           (fboundp value))))

(defun join-menu-path (prefix label)
  (if (and prefix
           (plusp (length prefix)))
      (format nil "~A/~A" prefix label)
      label))

(defun add-menu-tree (menu spec &optional prefix)
  (destructuring-bind (label &rest rest) spec
    (let ((path (join-menu-path prefix label)))
      (cond
        ((and rest
              (menu-callback-designator-p (first rest)))
         (destructuring-bind (callback &key (shortcut 0)) rest
           (add-menu-item menu path callback :shortcut shortcut)))
        (t
         (dolist (child rest)
           (add-menu-tree menu child path))))))
  menu)

(defun make-menu
    (&key (parent *default-parent*) (x 0) (y 0) (width 320) (height 24) items)
  (let ((menu (make-menu-bar :parent parent
                             :x      x
                             :y      y
                             :width  width
                             :height height)))
    (dolist (item items)
      (add-menu-tree menu item))
    menu))

(defun make-menu-button
    (&key (parent *default-parent*) (x 0) (y 0) (width 96) (height 26) (label "")
          items popup-buttons)
  (let ((menu (make-widget +widget-menu-button+
                           :parent parent
                           :x      x
                           :y      y
                           :width  width
                           :height height
                           :label  label)))
    (when popup-buttons
      (menu-button-set-popup menu popup-buttons))
    (dolist (item items)
      (add-menu-tree menu item))
    menu))

(defun make-toolbar
    (&key (parent *default-parent*) (x 0) (y 0) buttons (button-width 78) (button-height 26) (gap 6))
  (loop with current-x = x
        for (name label callback) in buttons
        for button = (make-button :parent parent
                                  :x      current-x
                                  :y      y
                                  :width  button-width
                                  :height button-height
                                  :label  label
                                  :callback callback)
        collect (cons name button) into result
        do (incf current-x (+ button-width gap))
        finally (return result)))

(defun radio-item-value (item)
  (if (consp item)
      (first item)
      item))

(defun radio-item-label (item)
  (if (consp item)
      (second item)
      (princ-to-string item)))

(defun make-radio-group
    (&key (parent *default-parent*) (x 0) (y 0) items value callback
          (orientation :horizontal) (button-width 96) (button-height 24) (gap 10))
  (let ((buttons nil)
        (group   nil))
    (loop for item in items
          for index from 0
          for item-value = (radio-item-value item)
          for item-label = (radio-item-label item)
          for button-x = (if (eq orientation :vertical)
                             x
                             (+ x (* index (+ button-width gap))))
          for button-y = (if (eq orientation :vertical)
                             (+ y (* index (+ button-height gap)))
                             y)
          for button = (make-radio-button :parent parent
                                          :x      button-x
                                          :y      button-y
                                          :width  button-width
                                          :height button-height
                                          :label  item-label
                                          :callback
                                          (lambda (widget event event-value)
                                            (declare (ignore event event-value))
                                            (when (and group
                                                       (string= (value widget) "1")
                                                       callback)
                                              (funcall callback group (radio-group-value group)))))
          do (push (cons item-value button) buttons))
    (setf group (%make-radio-group (nreverse buttons)))
    (when value
      (setf (radio-group-value group) value))
    group))

(defun make-labeled-input
    (&key (parent *default-parent*) (x 0) (y 0) (width 220) (height 24)
          (label "") (label-width 84) (gap 8) (value "") callback)
  (let* ((label-widget (make-label :parent parent
                                   :x      x
                                   :y      y
                                   :width  label-width
                                   :height height
                                   :label  label))
         (control      (make-input :parent parent
                                   :x      (+ x label-width gap)
                                   :y      y
                                   :width  (max 24 (- width label-width gap))
                                   :height height
                                   :value  value
                                   :callback callback)))
    (%make-field label-widget control)))

(defun make-labeled-choice
    (&key (parent *default-parent*) (x 0) (y 0) (width 220) (height 24)
          (label "") (label-width 84) (gap 8) items callback)
  (let* ((label-widget (make-label :parent parent
                                   :x      x
                                   :y      y
                                   :width  label-width
                                   :height height
                                   :label  label))
         (control      (make-choice :parent parent
                                    :x      (+ x label-width gap)
                                    :y      y
                                    :width  (max 24 (- width label-width gap))
                                    :height height
                                    :items  items
                                    :callback callback)))
    (%make-field label-widget control)))

(defun make-labeled-value-input
    (&key (parent *default-parent*) (x 0) (y 0) (width 220) (height 24)
          (label "") (label-width 84) (gap 8) (value "0") step callback)
  (let* ((label-widget (make-label :parent parent
                                   :x      x
                                   :y      y
                                   :width  label-width
                                   :height height
                                   :label  label))
         (control      (make-value-input :parent parent
                                         :x      (+ x label-width gap)
                                         :y      y
                                         :width  (max 24 (- width label-width gap))
                                         :height height
                                         :value  value
                                         :step   step
                                         :callback callback)))
    (%make-field label-widget control)))

(defun make-labeled-control
    (constructor &key (parent *default-parent*) (x 0) (y 0) (width 220) (height 24)
                 (label "") (label-width 84) (gap 8) (value "") step items callback)
  (let* ((label-widget (make-label :parent parent
                                   :x      x
                                   :y      y
                                   :width  label-width
                                   :height height
                                   :label  label))
         (control-x    (+ x label-width gap))
         (control-w    (max 24 (- width label-width gap)))
         (control      (case constructor
                         (:input
                          (make-input :parent parent :x control-x :y y :width control-w :height height
                                      :value value :callback callback))
                         (:secret
                          (make-secret-input :parent parent :x control-x :y y :width control-w :height height
                                             :value value :callback callback))
                         (:int
                          (make-int-input :parent parent :x control-x :y y :width control-w :height height
                                          :value value :callback callback))
                         (:float
                         (make-float-input :parent parent :x control-x :y y :width control-w :height height
                                            :value value :callback callback))
                         (:choice
                          (make-choice :parent parent :x control-x :y y :width control-w :height height
                                       :items items :callback callback))
                         (:input-choice
                          (make-input-choice :parent parent :x control-x :y y :width control-w :height height
                                             :items items :value value :callback callback))
                         (:value-input
                          (make-value-input :parent parent :x control-x :y y :width control-w :height height
                                            :value value :step step :callback callback))
                         (otherwise
                          (error "Unknown labeled control kind ~S." constructor)))))
    (%make-field label-widget control)))

(defun make-form
    (&key (parent *default-parent*) (x 0) (y 0) (width 260) (label-width 84)
          (row-height 24) (row-gap 8) (label-gap 8) rows)
  (let ((fields nil))
    (loop for row-spec in rows
          for row-index from 0
          for row-y = (+ y (* row-index (+ row-height row-gap)))
          do (destructuring-bind (name kind label &rest options) row-spec
               (let ((field (apply #'make-labeled-control
                                   kind
                                   :parent parent
                                   :x x
                                   :y row-y
                                   :width width
                                   :height row-height
                                   :label label
                                   :label-width label-width
                                   :gap label-gap
                                   options)))
                 (push (cons name field) fields))))
    (%make-form (nreverse fields))))

(defun field-value (field)
  (value (field-control field)))

(defun (setf field-value) (value field)
  (setf (value (field-control field)) value))

(defun form-field (form name)
  (cdr (assoc name (form-fields form))))

(defun form-value (form name)
  (let ((field (form-field form name)))
    (when field
      (field-value field))))

(defun (setf form-value) (value form name)
  (let ((field (form-field form name)))
    (unless field
      (error "No field named ~S in form." name))
    (setf (field-value field) value)))

(defun form-values (form)
  (loop for (name . field) in (form-fields form)
        collect (cons name (field-value field))))

(defun radio-group-value (group)
  (loop for (item-value . button) in (radio-group-buttons group)
        when (string= (value button) "1")
          return item-value))

(defun (setf radio-group-value) (value group)
  (loop for (item-value . button) in (radio-group-buttons group)
        do (setf (value button)
                 (if (equal item-value value) "1" "0")))
  value)

(defun resize-field
    (field &key x y width (height 24) (label-width 84) (gap 8))
  (layout-labeled-widgets (field-label field)
                          (field-control field)
                          (make-rect :x      x
                                     :y      y
                                     :width  width
                                     :height height)
                          :label-width label-width
                          :gap         gap
                          :height      height)
  field)
