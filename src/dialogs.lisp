(in-package #:lightfast)

;;; Modal dialogs. The native file choosers do floating point work that trips
;;; the traps SBCL leaves enabled; like every call into the bridge, these run
;;; with the traps masked by DEFINE-BRIDGE-FUNCTION.

(defun choose-file (&key (title "") (filter "") (preset-file ""))
  (let ((path (foreign-string (lambda ()
                                (%choose-file title filter preset-file)))))
    (and (plusp (length path))
         path)))

(defun choose-files (&key (title "") (filter "") (preset-file ""))
  "Return every path selected in a native multi-file chooser."
  (let ((paths (foreign-string (lambda ()
                                 (%choose-files title filter preset-file)))))
    (unless (zerop (length paths))
      (uiop:split-string paths :separator '(#\Newline)))))

(defun choose-save-file (&key (title "") (filter "") (preset-file ""))
  (let ((path (foreign-string (lambda ()
                                (%choose-save-file title filter preset-file)))))
    (and (plusp (length path))
         path)))

(defun choose-directory (&key (title "") (preset-path ""))
  (let ((path (foreign-string (lambda ()
                                (%choose-directory title preset-path)))))
    (and (plusp (length path))
         path)))

(defun message-box (message)
  (%message-box (or message "")))

(defun popup-menu (items)
  "Show a popup menu of ITEMS at the mouse cursor.

Returns the chosen zero-based index, or NIL when dismissed. An item string
of \"-\" is not selectable; it draws a divider under the previous item. An
item of the form \"section/item\" goes into the submenu \"section\"; the index
returned is the item's position in ITEMS either way. The menu takes the
theme's text face and size."
  (load-library)
  (let* ((count (length items))
         (pointers (mapcar (lambda (item)
                             (cffi:foreign-string-alloc (or item "")))
                           items)))
    (unwind-protect
         (cffi:with-foreign-object (array :pointer count)
           (loop for pointer in pointers
                 for index from 0
                 do (setf (cffi:mem-aref array :pointer index) pointer))
           (let ((chosen (%popup-menu array count)))
             (when (>= chosen 0)
               chosen)))
      (mapc #'cffi:foreign-string-free pointers))))

(defun input-dialog (message &key (initial ""))
  "Prompt for one line of text with FLTK's modal input dialog.

Returns the entered string, or NIL when the dialog is cancelled or the
answer is empty."
  (load-library)
  (let ((answer (foreign-string (lambda ()
                                  (%input-dialog (or message "")
                                                 (or initial ""))))))
    (and (plusp (length answer)) answer)))

(defun choose-color (&key (title "Choose color") (red 1.0d0) (green 1.0d0)
                          (blue 1.0d0))
  "Show FLTK's modal color chooser seeded with the given 0..1 components.

Returns the chosen red, green, and blue as three values, or NIL when the
dialog is cancelled."
  (load-library)
  (cffi:with-foreign-objects ((red-cell :double) (green-cell :double)
                              (blue-cell :double))
    (setf (cffi:mem-ref red-cell :double) (coerce red 'double-float)
          (cffi:mem-ref green-cell :double) (coerce green 'double-float)
          (cffi:mem-ref blue-cell :double) (coerce blue 'double-float))
    (when (plusp (%color-chooser (or title "") red-cell green-cell blue-cell))
      (values (cffi:mem-ref red-cell :double)
              (cffi:mem-ref green-cell :double)
              (cffi:mem-ref blue-cell :double)))))

(defun alert-box (message)
  (%alert-box (or message "")))

(defun choice-box (message &key (button0 "Cancel") button1 button2)
  (%choice-box (or message "")
               (or button0 "")
               (or button1 "")
               (or button2 "")))
