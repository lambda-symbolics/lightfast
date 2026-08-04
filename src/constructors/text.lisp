(in-package #:lightfast)

(defun make-input (&key (parent *default-parent*) (x 0) (y 0) (width 160) (height 24) (label "") (value "") callback)
  (let ((widget (make-widget +widget-input+
                             :parent parent
                             :x      x
                             :y      y
                             :width  width
                             :height height
                             :label  label)))
    (setf (value widget) value)
    (when callback
      (on widget callback :event +event-change+))
    widget))

(defun make-secret-input (&key (parent *default-parent*) (x 0) (y 0) (width 160) (height 24) (label "") (value "") callback)
  (let ((widget (make-widget +widget-secret-input+
                             :parent parent
                             :x      x
                             :y      y
                             :width  width
                             :height height
                             :label  label)))
    (setf (value widget) value)
    (when callback
      (on widget callback :event +event-change+))
    widget))

(defun make-int-input (&key (parent *default-parent*) (x 0) (y 0) (width 120) (height 24) (label "") (value "") callback)
  (let ((widget (make-widget +widget-int-input+
                             :parent parent
                             :x      x
                             :y      y
                             :width  width
                             :height height
                             :label  label)))
    (setf (value widget) value)
    (when callback
      (on widget callback :event +event-change+))
    widget))

(defun make-float-input (&key (parent *default-parent*) (x 0) (y 0) (width 120) (height 24) (label "") (value "") callback)
  (let ((widget (make-widget +widget-float-input+
                             :parent parent
                             :x      x
                             :y      y
                             :width  width
                             :height height
                             :label  label)))
    (setf (value widget) value)
    (when callback
      (on widget callback :event +event-change+))
    widget))

(defun make-multiline-input
    (&key (parent *default-parent*) (x 0) (y 0) (width 220) (height 100) (label "") (value "") callback)
  (let ((widget (make-widget +widget-multiline-input+
                             :parent parent
                             :x      x
                             :y      y
                             :width  width
                             :height height
                             :label  label)))
    (setf (value widget) value)
    (when callback
      (on widget callback :event +event-change+))
    widget))

(defun make-output (&key (parent *default-parent*) (x 0) (y 0) (width 160) (height 24) (label "") (value ""))
  (let ((widget (make-widget +widget-output+
                             :parent parent
                             :x      x
                             :y      y
                             :width  width
                             :height height
                             :label  label)))
    (setf (value widget) value)
    widget))

(defun make-multiline-output (&key (parent *default-parent*) (x 0) (y 0) (width 220) (height 100) (label "") (value ""))
  (let ((widget (make-widget +widget-multiline-output+
                             :parent parent
                             :x      x
                             :y      y
                             :width  width
                             :height height
                             :label  label)))
    (setf (value widget) value)
    widget))

(defun make-text-display (&key (parent *default-parent*) (x 0) (y 0) (width 220) (height 100) (label "") (value ""))
  (let ((widget (make-widget +widget-text-display+
                             :parent parent
                             :x      x
                             :y      y
                             :width  width
                             :height height
                             :label  label)))
    (setf (value widget) value)
    widget))

(defun make-text-editor
    (&key (parent *default-parent*) (x 0) (y 0) (width 220) (height 100) (label "") (value "") callback)
  (let ((widget (make-widget +widget-text-editor+
                             :parent parent
                             :x      x
                             :y      y
                             :width  width
                             :height height
                             :label  label)))
    (setf (value widget) value)
    (when callback
      (on widget callback :event +event-change+))
    widget))

(defun make-help-view (&key (parent *default-parent*) (x 0) (y 0) (width 220) (height 100) (label "") (value ""))
  (let ((widget (make-widget +widget-help-view+
                             :parent parent
                             :x      x
                             :y      y
                             :width  width
                             :height height
                             :label  label)))
    (setf (value widget) value)
    widget))

(defun make-clock (&key (parent *default-parent*) (x 0) (y 0) (width 64) (height 64) (label "") value)
  (let ((widget (make-widget +widget-clock+
                             :parent parent
                             :x      x
                             :y      y
                             :width  width
                             :height height
                             :label  label)))
    (when value
      (setf (value widget) value))
    widget))
