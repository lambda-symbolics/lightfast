(in-package #:lightfast)

(defun make-button (&key (parent *default-parent*) (x 0) (y 0) (width 80) (height 26) (label "") callback)
  (let ((widget (make-widget +widget-button+
                             :parent parent
                             :x      x
                             :y      y
                             :width  width
                             :height height
                             :label  label)))
    (when callback
      (on widget callback :event +event-activate+))
    widget))

(defun make-toggle-button (&key (parent *default-parent*) (x 0) (y 0) (width 90) (height 26) (label "") callback)
  (let ((widget (make-widget +widget-toggle-button+
                             :parent parent
                             :x      x
                             :y      y
                             :width  width
                             :height height
                             :label  label)))
    (when callback
      (on widget callback :event +event-change+))
    widget))

(defun make-return-button (&key (parent *default-parent*) (x 0) (y 0) (width 90) (height 26) (label "") callback)
  (let ((widget (make-widget +widget-return-button+
                             :parent parent
                             :x      x
                             :y      y
                             :width  width
                             :height height
                             :label  label)))
    (when callback
      (on widget callback :event +event-activate+))
    widget))

(defun make-repeat-button (&key (parent *default-parent*) (x 0) (y 0) (width 90) (height 26) (label "") callback)
  (let ((widget (make-widget +widget-repeat-button+
                             :parent parent
                             :x      x
                             :y      y
                             :width  width
                             :height height
                             :label  label)))
    (when callback
      (on widget callback :event +event-activate+))
    widget))

(defun make-check-button (&key (parent *default-parent*) (x 0) (y 0) (width 100) (height 24) (label "") callback)
  (let ((widget (make-widget +widget-check-button+
                             :parent parent
                             :x      x
                             :y      y
                             :width  width
                             :height height
                             :label  label)))
    (when callback
      (on widget callback :event +event-change+))
    widget))

(defun make-light-button (&key (parent *default-parent*) (x 0) (y 0) (width 120) (height 24) (label "") callback)
  (let ((widget (make-widget +widget-light-button+
                             :parent parent
                             :x      x
                             :y      y
                             :width  width
                             :height height
                             :label  label)))
    (when callback
      (on widget callback :event +event-change+))
    widget))

(defun make-radio-button (&key (parent *default-parent*) (x 0) (y 0) (width 120) (height 24) (label "") callback)
  (let ((widget (make-widget +widget-radio-button+
                             :parent parent
                             :x      x
                             :y      y
                             :width  width
                             :height height
                             :label  label)))
    (when callback
      (on widget callback :event +event-change+))
    widget))
