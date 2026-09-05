(in-package #:lightfast)

;;; Runtime widget operations, callbacks, collection helpers, drawing, and loop control.

(defun add-check-item (widget label &key checked)
  (%check-browser-add (widget-id widget) (cell-string label) (if checked 1 0))
  widget)

(defun apply-classic-theme ()
  (load-library)
  (%apply-classic-theme))

(defun show (widget)
  (%window-show (widget-id widget))
  widget)

(defun hide (widget)
  (%window-hide (widget-id widget))
  widget)

(defun window-cancel-close (widget)
  "Keep WIDGET, a window, open despite the close its callback is handling.

Only meaningful from inside a callback installed with :EVENT +EVENT-CLOSE+: the
close that fired it is abandoned rather than finished, which is how an
application asks about unsaved work before the window goes."
  (%window-cancel-close (widget-id widget))
  widget)

(defun set-size-range (widget &key min-width min-height max-width max-height)
  (%window-set-size-range (widget-id widget)
                          (or min-width 0)
                          (or min-height 0)
                          (or max-width 0)
                          (or max-height 0))
  widget)

(defun set-window-app-id (widget app-id)
  (%window-set-app-id (widget-id widget) (or app-id ""))
  widget)

(defun window-app-id (widget)
  (foreign-string (lambda ()
                    (%window-get-app-id (widget-id widget)))))

(defun resize-widget (widget &key x y width height)
  (refresh-geometry widget)
  (let* ((new-x      (if x
                         (+ (parent-origin-x (widget-parent widget)) x)
                         (widget-x widget)))
         (new-y      (if y
                         (+ (parent-origin-y (widget-parent widget)) y)
                         (widget-y widget)))
         (new-width  (or width (widget-width widget)))
         (new-height (or height (widget-height widget))))
    (unless (and (= new-x (widget-x widget))
                 (= new-y (widget-y widget))
                 (= new-width (widget-width widget))
                 (= new-height (widget-height widget)))
      (%widget-resize (widget-id widget)
                      new-x
                      new-y
                      new-width
                      new-height)
      (setf (widget-x widget)      new-x
            (widget-y widget)      new-y
            (widget-width widget)  new-width
            (widget-height widget) new-height))
    widget))

(defun redraw (widget)
  (%widget-redraw (widget-id widget))
  widget)

(defun destroy (widget)
  (plusp (%widget-destroy (widget-id widget))))

(defun label (widget)
  (foreign-string (lambda ()
                    (%widget-get-label (widget-id widget)))))

(defun (setf label) (label widget)
  (%widget-set-label (widget-id widget) (or label ""))
  label)

(defun value (widget)
  (foreign-string (lambda ()
                    (%widget-get-value (widget-id widget)))))

(defun (setf value) (value widget)
  (%widget-set-value (widget-id widget) (or value ""))
  value)

(defun set-stock-icon (widget icon-name)
  (%widget-set-stock-icon (widget-id widget)
                          (etypecase icon-name
                            (null "")
                            (string icon-name)
                            (symbol (string-downcase (symbol-name icon-name)))))
  widget)

(defun on (widget callback &key (event +event-activate+))
  (let ((token (next-callback-token
                (lambda (widget-id event value)
                  (declare (ignore widget-id))
                  (refresh-geometry widget)
                  (funcall callback
                           widget
                           event
                           value)))))
    (unless (plusp (%widget-set-callback (widget-id widget)
                                         (cffi:callback callback-dispatch)
                                         token
                                         event))
      (remhash token *callback-registry*)
      (error "Unable to install FLTK callback for widget ~D." (widget-id widget)))
    widget))

(defun on-resize (widget callback)
  (on widget
      (lambda (event-widget event value)
        (declare (ignore event value))
        (funcall callback event-widget))
      :event +event-resize+))

(defun on-action (widget callback &key (event +event-activate+))
  (on widget
      (lambda (event-widget event value)
        (declare (ignore event value))
        (funcall callback event-widget))
      :event event))

(defun add-menu-item (menu path callback &key (shortcut 0))
  (let ((token (next-callback-token
                (lambda (widget-id event value)
                  (declare (ignore event))
                  (funcall callback
                           (%make-widget widget-id (widget-kind menu))
                           value)))))
    (unless (plusp (%menu-add (widget-id menu)
                              path
                              shortcut
                              (cffi:callback callback-dispatch)
                              token))
      (remhash token *callback-registry*)
      (error "Unable to add FLTK menu item ~S." path))
    menu))

(defun menu-set-item-mode (menu path mode)
  (plusp (%menu-set-item-mode (widget-id menu) path mode)))

(defun add-item (widget label)
  (ecase (widget-kind widget)
    (#.+widget-choice+
     (%choice-add (widget-id widget) label))
    (#.+widget-input-choice+
     (%choice-add (widget-id widget) label))
    (#.+widget-scheme-choice+
     (%choice-add (widget-id widget) label))
    (#.+widget-browser+
     (%browser-add (widget-id widget) label))
    (#.+widget-file-browser+
     (%browser-add (widget-id widget) label))
    (#.+widget-check-browser+
     (%check-browser-add (widget-id widget) label 0))
    (#.+widget-tree+
     (%tree-add (widget-id widget) label)))
  widget)

(defun browser-select (widget index)
  (%browser-select (widget-id widget) index)
  widget)

(defun browser-set-column-widths (widget widths)
  (let ((count (length widths)))
    (if (plusp count)
        (cffi:with-foreign-object (array :int count)
          (loop for width in widths
                for index below count do
                  (setf (cffi:mem-aref array :int index)
                        (max 1 (truncate width))))
          (%browser-set-column-widths (widget-id widget) array count))
        (%browser-set-column-widths (widget-id widget) (cffi:null-pointer) 0)))
  widget)

(defun check-browser-count (widget)
  (%check-browser-count (widget-id widget)))

(defun check-browser-checked-count (widget)
  (%check-browser-checked-count (widget-id widget)))

(defun check-browser-checked-p (widget index)
  (plusp (%check-browser-checked (widget-id widget) index)))

(defun (setf check-browser-checked-p) (checked widget index)
  (%check-browser-set-checked (widget-id widget)
                              index
                              (if checked 1 0))
  checked)

(defun check-browser-check-all (widget)
  (%check-browser-check-all (widget-id widget))
  widget)

(defun check-browser-check-none (widget)
  (%check-browser-check-none (widget-id widget))
  widget)

(defun check-browser-text (widget index)
  (foreign-string (lambda ()
                    (%check-browser-text (widget-id widget) index))))

(defun check-browser-checked-items (widget)
  (loop for index below (check-browser-count widget)
        when (check-browser-checked-p widget index)
          collect (check-browser-text widget index)))

(defun file-browser-load (widget directory)
  (plusp (%file-browser-load (widget-id widget) (or directory "."))))

(defun file-browser-set-filter (widget pattern)
  (%file-browser-set-filter (widget-id widget) (or pattern ""))
  widget)

(defun file-browser-set-filetype (widget filetype)
  (%file-browser-set-filetype (widget-id widget)
                              (ecase filetype
                                (:files 0)
                                (:directories 1)))
  widget)

(defun popup-button-mask (buttons)
  (ecase buttons
    ((nil :none) 0)
    ((:left :button1) 1)
    ((:middle :button2) 2)
    ((:left-middle :button12) 3)
    ((:right :button3) 4)
    ((:left-right :button13) 5)
    ((:middle-right :button23) 6)
    ((:any :all :button123) 7)))

(defun menu-button-set-popup (widget buttons)
  (%menu-button-set-popup (widget-id widget) (popup-button-mask buttons))
  widget)

(defun tile-size-range
    (tile child &key (min-width 0) (min-height 0) max-width max-height)
  (%tile-size-range (widget-id tile)
                    (widget-id child)
                    min-width
                    min-height
                    (or max-width 0)
                    (or max-height 0))
  tile)

(defun init-sizes (widget)
  (%group-init-sizes (widget-id widget))
  widget)

(defun scrollbar-set-orientation (widget orientation)
  (%scrollbar-set-vertical (widget-id widget)
                           (ecase orientation
                             (:vertical 1)
                             (:horizontal 0)))
  widget)

(defun flex-set-orientation (widget orientation)
  (%flex-set-type (widget-id widget)
                  (ecase orientation
                    (:vertical 0)
                    (:column 0)
                    (:horizontal 1)
                    (:row 1)))
  widget)

(defun flex-set-gap (widget gap)
  (%flex-set-gap (widget-id widget) gap)
  widget)

(defun flex-set-margin (widget left top right bottom)
  (%flex-set-margin (widget-id widget) left top right bottom)
  widget)

(defun flex-fixed (widget child size)
  (%flex-fixed (widget-id widget) (widget-id child) size)
  widget)

(defun flex-layout (widget)
  (%flex-layout (widget-id widget))
  widget)

(defun clear (widget)
  (%widget-clear (widget-id widget))
  widget)

(defun copy-text (value)
  (load-library)
  (%copy-text (or value "")))

(defun add-timeout (seconds callback &key repeat)
  (load-library)
  (let ((token (next-callback-token
                (lambda (widget-id event value)
                  (declare (ignore widget-id event value))
                  (funcall callback)))))
    (let ((id (%add-timeout (coerce seconds 'double-float)
                            (if repeat 1 0)
                            (cffi:callback callback-dispatch)
                            token)))
      (when (zerop id)
        (remhash token *callback-registry*)
        (error "Unable to add FLTK timeout."))
      id)))

(defun remove-timeout (id)
  (plusp (%remove-timeout id)))

(defun set-box (widget box)
  (%widget-set-box (widget-id widget) box)
  widget)

(defun set-label-size (widget size)
  (%widget-set-label-size (widget-id widget) size)
  widget)

(defun set-label-font (widget font)
  (%widget-set-label-font (widget-id widget) font)
  widget)

(defun set-tooltip (widget tooltip)
  (%widget-set-tooltip (widget-id widget) (or tooltip ""))
  widget)

(defun set-text-size (widget size)
  (%widget-set-text-size (widget-id widget) size)
  widget)

(defun set-text-font (widget font)
  (%widget-set-text-font (widget-id widget) font)
  widget)

(defun set-color-rgb (widget &key red green blue)
  (%widget-set-color-rgb (widget-id widget) red green blue)
  widget)

(defparameter *cursor-shapes*
  '((:default . 0) (:arrow . 35) (:cross . 66) (:wait . 76) (:insert . 77)
    (:hand . 31) (:help . 47) (:move . 27) (:none . 255)
    ;; Resize cursors, named for the edge or corner they pull.
    (:north-south . 78) (:west-east . 79)
    (:northwest-southeast . 80) (:northeast-southwest . 81)
    (:north . 70) (:north-east . 69) (:east . 49) (:south-east . 8)
    (:south . 9) (:south-west . 7) (:west . 36) (:north-west . 68))
  "Mouse cursor shapes, keyed by name, holding FLTK's own Fl_Cursor values.")

(defun cursor-shapes ()
  "Return every cursor shape name SET-CURSOR accepts."
  (mapcar #'first *cursor-shapes*))

(defun set-cursor (widget shape)
  "Show cursor SHAPE while the pointer is over WIDGET's window.

SHAPE is a name from CURSOR-SHAPES. FLTK scopes a cursor to a window rather
than to a widget, so this changes the cursor for everything in the same window,
and :DEFAULT puts it back. Signals an error for an unknown shape rather than
silently leaving the pointer as it was."
  (let ((code (rest (assoc shape *cursor-shapes*))))
    (unless code
      (error "Unknown cursor shape ~S; expected one of ~S."
             shape (cursor-shapes)))
    (%widget-set-cursor (widget-id widget) code)
    widget))

(defun draw-color-rgb (&key red green blue)
  (%draw-set-color-rgb red green blue))

(defun draw-font (&key (font 0) (size 12))
  (%draw-set-font font size))

(defun draw-line (x1 y1 x2 y2)
  (%draw-line x1 y1 x2 y2))

(defun draw-rect (x y width height)
  (%draw-rect x y width height))

(defun draw-filled-rect (x y width height)
  (%draw-filled-rect x y width height))

(defun draw-circle (x y radius)
  (%draw-circle x y radius))

(defun draw-filled-circle (x y radius)
  (%draw-filled-circle x y radius))

(defun draw-text (text x y &key (width 0) (height 0) (align 0))
  (%draw-text (or text "") x y width height align))

(defun draw-push-clip (x y width height)
  (%draw-push-clip x y width height))

(defun draw-pop-clip ()
  (%draw-pop-clip))

(defmacro with-clip ((x y width height) &body body)
  `(progn
     (draw-push-clip ,x ,y ,width ,height)
     (unwind-protect
          (progn ,@body)
       (draw-pop-clip))))

(defun set-range (widget minimum maximum)
  (%widget-set-range (widget-id widget)
                     (coerce minimum 'double-float)
                     (coerce maximum 'double-float))
  widget)

(defun set-step (widget step)
  (%widget-set-step (widget-id widget) (coerce step 'double-float))
  widget)

(defun quit ()
  (load-library)
  (%quit))

(defun run ()
  (%run))

(defun check ()
  (%check))

(defun wait (&optional (seconds 0.0d0))
  (%wait (coerce seconds 'double-float)))
