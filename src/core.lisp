(in-package #:lightfast)

;;; Core widget ids, event ids, parent tracking, and base widget allocation.

(defconstant +font-helvetica+ 0)

(defconstant +font-helvetica-bold+ 1)

(defconstant +box-no-box+ 0)

(defconstant +box-flat-box+ 1)

(defconstant +box-up-box+ 2)

(defconstant +box-down-box+ 3)

(defconstant +box-up-frame+ 4)

(defconstant +box-down-frame+ 5)

(defconstant +box-thin-up-box+ 6)

(defconstant +box-thin-down-box+ 7)

(defconstant +box-engraved-box+ 10)

(defconstant +box-embossed-box+ 11)

(defconstant +box-engraved-frame+ 12)

(defconstant +menu-toggle+ 2)

(defconstant +menu-value+ 4)

(defconstant +menu-divider+ #x80)

(defconstant +widget-window+ 1)

(defconstant +widget-group+ 2)

(defconstant +widget-box+ 3)

(defconstant +widget-button+ 4)

(defconstant +widget-input+ 5)

(defconstant +widget-multiline-input+ 6)

(defconstant +widget-output+ 7)

(defconstant +widget-multiline-output+ 8)

(defconstant +widget-choice+ 9)

(defconstant +widget-browser+ 10)

(defconstant +widget-menu-bar+ 11)

(defconstant +widget-check-button+ 12)

(defconstant +widget-value-input+ 13)

(defconstant +widget-scroll+ 14)

(defconstant +widget-label+ 15)

(defconstant +widget-tabs+ 16)

(defconstant +widget-tab-page+ 17)

(defconstant +widget-progress+ 18)

(defconstant +widget-slider+ 19)

(defconstant +widget-status-bar+ 20)

(defconstant +widget-light-button+ 21)

(defconstant +widget-radio-button+ 22)

(defconstant +widget-counter+ 23)

(defconstant +widget-spinner+ 24)

(defconstant +widget-dial+ 25)

(defconstant +widget-roller+ 26)

(defconstant +widget-tree+ 27)

(defconstant +widget-secret-input+ 28)

(defconstant +widget-int-input+ 29)

(defconstant +widget-float-input+ 30)

(defconstant +widget-text-display+ 31)

(defconstant +widget-text-editor+ 32)

(defconstant +widget-help-view+ 33)

(defconstant +widget-clock+ 34)

(defconstant +widget-toggle-button+ 35)

(defconstant +widget-return-button+ 36)

(defconstant +widget-repeat-button+ 37)

(defconstant +widget-value-slider+ 38)

(defconstant +widget-scrollbar+ 39)

(defconstant +widget-adjuster+ 40)

(defconstant +widget-table+ 41)

(defconstant +widget-canvas+ 42)

(defconstant +widget-input-choice+ 43)

(defconstant +widget-check-browser+ 44)

(defconstant +widget-file-browser+ 45)

(defconstant +widget-menu-button+ 46)

(defconstant +widget-tile+ 47)

(defconstant +widget-flex+ 48)

(defconstant +widget-vertical-slider+ 49)

(defconstant +widget-file-input+ 50)

(defconstant +widget-value-output+ 51)

(defconstant +widget-pack+ 52)

(defconstant +widget-grid+ 53)

(defconstant +widget-positioner+ 54)

(defconstant +widget-wizard+ 55)

(defconstant +widget-chart+ 56)

(defconstant +widget-scheme-choice+ 57)

(defconstant +widget-terminal+ 58)

(defconstant +widget-color-chooser+ 59)

(defconstant +widget-shortcut-button+ 60)

(defconstant +event-activate+ 1)

(defconstant +event-change+ 2)

(defconstant +event-close+ 3)

(defconstant +event-timer+ 4)

(defconstant +event-menu+ 5)

(defconstant +event-resize+ 6)

(defconstant +event-draw+ 7)

(defconstant +event-push+ 8)

(defconstant +event-drag+ 9)

(defconstant +event-release+ 10)

(defconstant +event-wheel+ 11)

(defconstant +event-key+ 12)

(defvar *default-parent* nil)

(defstruct (widget (:constructor %make-widget
                       (id kind &optional (x 0) (y 0) (width 0) (height 0) parent)))
  (id     0 :type integer)
  (kind   0 :type integer)
  (x      0 :type integer)
  (y      0 :type integer)
  (width  0 :type integer)
  (height 0 :type integer)
  parent)

(defun refresh-geometry (widget)
  (when widget
    (setf (widget-x widget)      (%widget-native-x (widget-id widget))
          (widget-y widget)      (%widget-native-y (widget-id widget))
          (widget-width widget)  (%widget-native-width (widget-id widget))
          (widget-height widget) (%widget-native-height (widget-id widget))))
  widget)

(defun parent-id (parent)
  (if parent
      (widget-id parent)
      0))

(defun parent-origin-x (parent)
  (if (and parent
           (/= (widget-kind parent) +widget-window+))
      (progn
        (refresh-geometry parent)
        (widget-x parent))
      0))

(defun parent-origin-y (parent)
  (if (and parent
           (/= (widget-kind parent) +widget-window+))
      (progn
        (refresh-geometry parent)
        (widget-y parent))
      0))

(defun make-widget (kind &key (parent *default-parent*) (x 0) (y 0) (width 80) (height 24) (label ""))
  (load-library)
  (let* ((absolute-x (+ (parent-origin-x parent) x))
         (absolute-y (+ (parent-origin-y parent) y))
         (id         (%widget-create kind
                                     (parent-id parent)
                                     absolute-x
                                     absolute-y
                                     width
                                     height
                                     label)))
    (when (zerop id)
      (error "FLTK failed to create widget kind ~D." kind))
    (%make-widget id kind absolute-x absolute-y width height parent)))

(defun cell-string (value)
  (if value
      (princ-to-string value)
      ""))

(defun checked-item-label (item)
  (if (consp item)
      (first item)
      item))

(defun checked-item-state (item)
  (and (consp item)
       (second item)))
