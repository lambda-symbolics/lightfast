(in-package #:lightfast)

;;; Widget constructor functions built on top of the core allocator and runtime helpers.

(defun make-window
    (&key (x 100) (y 100) (width 640) (height 480) (label "") app-id)
  (let ((window (make-widget +widget-window+
                             :x      x
                             :y      y
                             :width  width
                             :height height
                             :label  label)))
    (when app-id
      (set-window-app-id window app-id))
    window))

(defun make-group (&key (parent *default-parent*) (x 0) (y 0) (width 120) (height 80) (label ""))
  (make-widget +widget-group+ :parent parent :x x :y y :width width :height height :label label))

(defun make-tile (&key (parent *default-parent*) (x 0) (y 0) (width 240) (height 160) (label ""))
  (make-widget +widget-tile+ :parent parent :x x :y y :width width :height height :label label))

(defun make-flex
    (&key (parent *default-parent*) (x 0) (y 0) (width 240) (height 160) (label "")
          (orientation :vertical) (gap 0) margin)
  (let ((widget (make-widget +widget-flex+
                             :parent parent
                             :x      x
                             :y      y
                             :width  width
                             :height height
                             :label  label)))
    (flex-set-orientation widget orientation)
    (flex-set-gap widget gap)
    (when margin
      (etypecase margin
        (integer
         (flex-set-margin widget margin margin margin margin))
        (cons
         (destructuring-bind (left top right bottom) margin
           (flex-set-margin widget left top right bottom)))))
    widget))

(defun make-box (&key (parent *default-parent*) (x 0) (y 0) (width 80) (height 24) (label ""))
  (make-widget +widget-box+ :parent parent :x x :y y :width width :height height :label label))

(defun make-label (&key (parent *default-parent*) (x 0) (y 0) (width 80) (height 24) (label ""))
  (make-widget +widget-label+ :parent parent :x x :y y :width width :height height :label label))

(defun make-canvas (&key (parent *default-parent*) (x 0) (y 0) (width 160) (height 120) (label "") callback)
  (let ((widget (make-widget +widget-canvas+
                             :parent parent
                             :x      x
                             :y      y
                             :width  width
                             :height height
                             :label  label)))
    (when callback
      (on widget callback :event +event-draw+))
    widget))
