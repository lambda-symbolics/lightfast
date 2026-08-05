(in-package #:lightfast)

;;; Constructors for reusable FLTK 1.4 widgets.

(defun make-file-input
    (&key (parent *default-parent*) (x 0) (y 0) (width 180) (height 24)
          (label "") (value "") callback)
  "Create a file-path input using the generic VALUE and text styling APIs."
  (let ((widget (make-widget +widget-file-input+ :parent parent :x x :y y
                             :width width :height height :label label)))
    (setf (value widget) value)
    (when callback
      (on widget callback :event +event-change+))
    widget))

(defun make-value-output
    (&key (parent *default-parent*) (x 0) (y 0) (width 100) (height 24)
          (label "") (value "0") minimum maximum step callback)
  "Create a numeric value output using generic VALUE, SET-RANGE, and SET-STEP."
  (let ((widget (make-widget +widget-value-output+ :parent parent :x x :y y
                             :width width :height height :label label)))
    (when (or minimum maximum)
      (unless (and minimum maximum)
        (error "MINIMUM and MAXIMUM must be supplied together."))
      (set-range widget minimum maximum))
    (when step
      (set-step widget step))
    (setf (value widget) value)
    (when callback
      (on widget callback :event +event-change+))
    widget))

(defun make-pack
    (&key (parent *default-parent*) (x 0) (y 0) (width 240) (height 160)
          (label "") (orientation :vertical) (spacing 0))
  "Create a child-packing group with named ORIENTATION and pixel SPACING."
  (let ((widget (make-widget +widget-pack+ :parent parent :x x :y y
                             :width width :height height :label label)))
    (pack-set-orientation widget orientation)
    (pack-set-spacing widget spacing)
    widget))

(defun make-grid
    (&key (parent *default-parent*) (x 0) (y 0) (width 240) (height 160)
          (label "") rows columns (margin 0) (row-gap 0) (column-gap 0))
  "Create a grid group, optionally configuring its ROWS and COLUMNS."
  (let ((widget (make-widget +widget-grid+ :parent parent :x x :y y
                             :width width :height height :label label)))
    (when (or rows columns)
      (unless (and rows columns)
        (error "ROWS and COLUMNS must be supplied together."))
      (grid-layout widget :rows rows :columns columns :margin margin
                          :row-gap row-gap :column-gap column-gap))
    widget))

(defun make-positioner
    (&key (parent *default-parent*) (x 0) (y 0) (width 120) (height 120)
          (label "") (x-value 0.5d0) (y-value 0.5d0)
          (x-minimum 0.0d0) (x-maximum 1.0d0)
          (y-minimum 0.0d0) (y-maximum 1.0d0)
          (x-step 0.0d0) (y-step 0.0d0) callback)
  "Create a two-dimensional positioner with named values, bounds, and steps."
  (let ((widget (make-widget +widget-positioner+ :parent parent :x x :y y
                             :width width :height height :label label)))
    (positioner-set-bounds widget
                           :x-minimum x-minimum :x-maximum x-maximum
                           :y-minimum y-minimum :y-maximum y-maximum)
    (positioner-set-steps widget :x-step x-step :y-step y-step)
    (positioner-set-value widget :x x-value :y y-value)
    (when callback
      (on widget callback :event +event-change+))
    widget))

(defun make-wizard
    (&key (parent *default-parent*) (x 0) (y 0) (width 320) (height 240)
          (label ""))
  "Create a wizard group whose direct children form its pages."
  (make-widget +widget-wizard+ :parent parent :x x :y y
               :width width :height height :label label))

(defun make-chart
    (&key (parent *default-parent*) (x 0) (y 0) (width 240) (height 140)
          (label "") (type :bar) minimum maximum)
  "Create a chart with named TYPE and optional numeric bounds."
  (let ((widget (make-widget +widget-chart+ :parent parent :x x :y y
                             :width width :height height :label label)))
    (chart-set-type widget type)
    (when (or minimum maximum)
      (unless (and minimum maximum)
        (error "MINIMUM and MAXIMUM must be supplied together."))
      (chart-set-bounds widget :minimum minimum :maximum maximum))
    widget))

(defun make-scheme-choice
    (&key (parent *default-parent*) (x 0) (y 0) (width 160) (height 24)
          (label "") value callback)
  "Create a choice populated with the FLTK schemes available at runtime."
  (let ((widget (make-widget +widget-scheme-choice+ :parent parent :x x :y y
                             :width width :height height :label label)))
    (when value
      (setf (value widget) value))
    (when callback
      (on widget callback :event +event-change+))
    widget))

(defun make-terminal
    (&key (parent *default-parent*) (x 0) (y 0) (width 320) (height 180)
          (label "") text)
  "Create a terminal and optionally append initial TEXT."
  (let ((widget (make-widget +widget-terminal+ :parent parent :x x :y y
                             :width width :height height :label label)))
    (when text
      (terminal-append widget text))
    widget))

(defun make-color-chooser
    (&key (parent *default-parent*) (x 0) (y 0) (width 195) (height 115)
          (label "") (red 0.0d0) (green 0.0d0) (blue 0.0d0) callback)
  "Create an RGB color chooser whose components are normalized to [0,1]."
  (let ((widget (make-widget +widget-color-chooser+ :parent parent :x x :y y
                             :width width :height height :label label)))
    (set-color-chooser-rgb widget :red red :green green :blue blue)
    (when callback
      (on widget callback :event +event-change+))
    widget))

(defun make-shortcut-button
    (&key (parent *default-parent*) (x 0) (y 0) (width 140) (height 24)
          (label "") (shortcut 0) callback)
  "Create a button that captures a portable unsigned FLTK shortcut value."
  (let ((widget (make-widget +widget-shortcut-button+ :parent parent :x x :y y
                             :width width :height height :label label)))
    (setf (shortcut-button-shortcut widget) shortcut)
    (when callback
      (on widget callback :event +event-change+))
    widget))
