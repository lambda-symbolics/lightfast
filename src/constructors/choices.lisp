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

(defun %create-system-menu-bar (kind &rest arguments)
  "The bridge constructor MAKE-WIDGET calls for a system menu bar."
  (declare (ignore kind))
  (apply #'%system-menu-bar-create arguments))

(defun make-menu-bar (&key (parent *default-parent*) (x 0) (y 0) (width 320) (height 24) (label "")
                           system)
  "Create a menu bar in PARENT for ADD-MENU-ITEM and ADD-MENU-TREE to fill.

With SYSTEM true the bar is the system's own where the system has one: on
macOS its items appear in the menu bar at the top of the screen and nothing
is drawn in the window, and everywhere else it is the ordinary bar it would
have been. MENU-BAR-SYSTEM-P tells which it is, so that a window can give the
bar no height when it has gone to the system. A process has one system menu
bar: while it exists, asking for another gives an ordinary bar. On macOS make
it before the first window is shown, or FLTK's own Window menu is lost."
  (make-widget +widget-menu-bar+ :parent parent :x x :y y :width width :height height :label label
                                 :create (if system #'%create-system-menu-bar #'%widget-create)))

(defun menu-bar-system-p (menu)
  "True when MENU is the system menu bar, as on macOS a bar made with
MAKE-MENU-BAR :SYSTEM T is. Such a bar shows nothing in its window: lay the
window out as though the bar had no height."
  (plusp (%menu-bar-is-system (widget-id menu))))
