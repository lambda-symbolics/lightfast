(in-package #:lightfast)

(defun make-value-input
    (&key (parent *default-parent*) (x 0) (y 0) (width 120) (height 24) (label "")
          (value "0") step callback)
  (let ((widget (make-widget +widget-value-input+
                             :parent parent
                             :x      x
                             :y      y
                             :width  width
                             :height height
                             :label  label)))
    (when step
      (set-step widget step))
    (setf (value widget) value)
    (when callback
      (on widget callback :event +event-change+))
    widget))

(defun make-scroll (&key (parent *default-parent*) (x 0) (y 0) (width 220) (height 120) (label ""))
  (make-widget +widget-scroll+ :parent parent :x x :y y :width width :height height :label label))

(defun make-tabs (&key (parent *default-parent*) (x 0) (y 0) (width 320) (height 180) (label ""))
  (make-widget +widget-tabs+ :parent parent :x x :y y :width width :height height :label label))

(defun make-tab-page (&key (parent *default-parent*) (x 0) (y 0) (width 320) (height 180) (label ""))
  (make-widget +widget-tab-page+ :parent parent :x x :y y :width width :height height :label label))

(defun make-progress (&key (parent *default-parent*) (x 0) (y 0) (width 160) (height 22) (label "") (value "0"))
  (let ((widget (make-widget +widget-progress+
                             :parent parent
                             :x      x
                             :y      y
                             :width  width
                             :height height
                             :label  label)))
    (setf (value widget) value)
    widget))

(defun make-slider
    (&key (parent *default-parent*) (x 0) (y 0) (width 160) (height 24) (label "") (value "50") callback)
  (let ((widget (make-widget +widget-slider+
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

(defun make-vertical-slider
    (&key (parent *default-parent*) (x 0) (y 0) (width 24) (height 160) (label "")
          (value "50") callback)
  "Create a vertical slider valuator."
  (let ((widget (make-widget +widget-vertical-slider+
                             :parent parent
                             :x x
                             :y y
                             :width width
                             :height height
                             :label label)))
    (setf (value widget) value)
    (when callback
      (on widget callback :event +event-change+))
    widget))

(defun make-value-slider
    (&key (parent *default-parent*) (x 0) (y 0) (width 180) (height 24) (label "") (value "50") callback)
  (let ((widget (make-widget +widget-value-slider+
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

(defun make-scrollbar
    (&key (parent *default-parent*) (x 0) (y 0) (width 180) (height 18) (label "") (value "25") callback)
  (let ((widget (make-widget +widget-scrollbar+
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

(defun make-adjuster
    (&key (parent *default-parent*) (x 0) (y 0) (width 120) (height 24) (label "") (value "10") callback)
  (let ((widget (make-widget +widget-adjuster+
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

(defun make-counter
    (&key (parent *default-parent*) (x 0) (y 0) (width 160) (height 24) (label "") (value "1") callback)
  (let ((widget (make-widget +widget-counter+
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

(defun make-spinner
    (&key (parent *default-parent*) (x 0) (y 0) (width 120) (height 24) (label "") (value "1") callback)
  (let ((widget (make-widget +widget-spinner+
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

(defun make-dial
    (&key (parent *default-parent*) (x 0) (y 0) (width 52) (height 52) (label "") (value "50") callback)
  (let ((widget (make-widget +widget-dial+
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

(defun make-roller
    (&key (parent *default-parent*) (x 0) (y 0) (width 120) (height 24) (label "") (value "50") callback)
  (let ((widget (make-widget +widget-roller+
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

(defun make-tree (&key (parent *default-parent*) (x 0) (y 0) (width 220) (height 120) (label "") items callback)
  (let ((widget (make-widget +widget-tree+
                             :parent parent
                             :x      x
                             :y      y
                             :width  width
                             :height height
                             :label  label)))
    (dolist (item items)
      (add-item widget item))
    (when callback
      (on widget callback :event +event-change+))
    widget))
