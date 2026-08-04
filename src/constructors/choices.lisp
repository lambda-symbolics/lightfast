(in-package #:lightfast)

(defun make-choice (&key (parent *default-parent*) (x 0) (y 0) (width 120) (height 24) (label "") items callback)
  (let ((widget (make-widget +widget-choice+
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

(defun make-input-choice
    (&key (parent *default-parent*) (x 0) (y 0) (width 160) (height 24) (label "") items (value "") callback)
  (let ((widget (make-widget +widget-input-choice+
                             :parent parent
                             :x      x
                             :y      y
                             :width  width
                             :height height
                             :label  label)))
    (dolist (item items)
      (add-item widget item))
    (when value
      (setf (value widget) value))
    (when callback
      (on widget callback :event +event-change+))
    widget))

(defun make-browser
    (&key (parent *default-parent*) (x 0) (y 0) (width 220) (height 120)
          (label "") items column-widths callback)
  (let ((widget (make-widget +widget-browser+
                             :parent parent
                             :x      x
                             :y      y
                             :width  width
                             :height height
                             :label  label)))
    (when column-widths
      (browser-set-column-widths widget column-widths))
    (dolist (item items)
      (add-item widget item))
    (when callback
      (on widget callback :event +event-change+))
    widget))

(defun make-check-browser
    (&key (parent *default-parent*) (x 0) (y 0) (width 220) (height 120) (label "") items callback)
  (let ((widget (make-widget +widget-check-browser+
                             :parent parent
                             :x      x
                             :y      y
                             :width  width
                             :height height
                             :label  label)))
    (dolist (item items)
      (add-check-item widget
                      (checked-item-label item)
                      :checked (checked-item-state item)))
    (when callback
      (on widget callback :event +event-change+))
    widget))

(defun make-file-browser
    (&key (parent *default-parent*) (x 0) (y 0) (width 220) (height 120) (label "")
          directory filter (filetype :files) callback)
  (let ((widget (make-widget +widget-file-browser+
                             :parent parent
                             :x      x
                             :y      y
                             :width  width
                             :height height
                             :label  label)))
    (when filter
      (file-browser-set-filter widget filter))
    (file-browser-set-filetype widget filetype)
    (when directory
      (file-browser-load widget directory))
    (when callback
      (on widget callback :event +event-change+))
    widget))

(defun make-menu-bar (&key (parent *default-parent*) (x 0) (y 0) (width 320) (height 24) (label ""))
  (make-widget +widget-menu-bar+ :parent parent :x x :y y :width width :height height :label label))
