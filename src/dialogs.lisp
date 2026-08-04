(in-package #:lightfast)

(defmacro with-dialog-guards (&body body)
  "Run a modal native dialog with floating point traps masked.

The GTK and kdialog chooser backends do floating point work that trips the
traps SBCL leaves unmasked, which used to surface as SIGFPE."
  #+sbcl `(sb-int:with-float-traps-masked
              (:invalid :divide-by-zero :overflow :underflow :inexact)
            ,@body)
  #-sbcl `(progn ,@body))

(defun choose-file (&key (title "") (filter "") (preset-file ""))
  (let ((path (with-dialog-guards
                (foreign-string (lambda ()
                                  (%choose-file title filter preset-file))))))
    (and (plusp (length path))
         path)))

(defun choose-files (&key (title "") (filter "") (preset-file ""))
  "Return every path selected in a native multi-file chooser."
  (let ((paths (with-dialog-guards
                 (foreign-string (lambda ()
                                   (%choose-files title filter
                                                  preset-file))))))
    (unless (zerop (length paths))
      (uiop:split-string paths :separator '(#\Newline)))))

(defun choose-save-file (&key (title "") (filter "") (preset-file ""))
  (let ((path (with-dialog-guards
                (foreign-string (lambda ()
                                  (%choose-save-file title filter
                                                     preset-file))))))
    (and (plusp (length path))
         path)))

(defun choose-directory (&key (title "") (preset-path ""))
  (let ((path (with-dialog-guards
                (foreign-string (lambda ()
                                  (%choose-directory title preset-path))))))
    (and (plusp (length path))
         path)))

(defun message-box (message)
  (%message-box (or message "")))

(defun popup-menu (items)
  "Show a popup menu of ITEMS at the mouse cursor.

Returns the chosen zero-based index, or NIL when dismissed. An item string
of \"-\" is not selectable; it draws a divider under the previous item."
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
  (let ((answer (with-dialog-guards
                  (foreign-string (lambda ()
                                    (%input-dialog (or message "")
                                                   (or initial "")))))))
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
    (when (plusp (with-dialog-guards
                   (%color-chooser (or title "") red-cell green-cell
                                   blue-cell)))
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
