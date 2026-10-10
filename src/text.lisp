(in-package #:lightfast)

;;; Styled text displays: a style table, appends and replacements carrying one
;;; style per character, and the scroll, selection and hit-testing operations
;;; a document view needs. Positions at this boundary are UTF-8 byte offsets,
;;; as FLTK's text buffer counts them; CHARACTER-BYTE-LENGTH and
;;; STRING-BYTE-LENGTH translate from Lisp characters.

(defconstant +text-attribute-background+ #x0001
  "Draw the style's background color behind its text.")

(defconstant +text-attribute-background-to-end+ #x0003
  "Draw the background color to the end of the line.")

(defconstant +text-attribute-underline+ #x0004
  "Underline the text.")

(defconstant +text-attribute-strike-through+ #x0010
  "Draw a line through the text.")

(defun character-byte-length (character)
  "Return how many UTF-8 bytes CHARACTER occupies."
  (let ((code (char-code character)))
    (cond
      ((< code #x80) 1)
      ((< code #x800) 2)
      ((< code #x10000) 3)
      (t 4))))

(defun string-byte-length (string)
  "Return how many UTF-8 bytes STRING occupies."
  (loop for character across string
        sum (character-byte-length character)))

(defun %packed-color (color)
  "Pack a (RED GREEN BLUE) list into one integer."
  (destructuring-bind (red green blue) color
    (logior (ash red 16) (ash green 8) blue)))

(defun text-set-styles (widget styles)
  "Give the text display WIDGET a style table.

STYLES is a list of plists, each with :FONT (a font number), :SIZE, :COLOR as
(RED GREEN BLUE), and optionally :BACKGROUND as (RED GREEN BLUE) and
:ATTRIBUTES, a logical or of the +TEXT-ATTRIBUTE-...+ constants. The position
of a plist in STYLES is its style index for TEXT-APPEND-STYLED. At most 26
styles are accepted. Text already present takes style 0."
  (%require-widget-kind widget +widget-text-display+ 'text-set-styles)
  (let ((count (length styles)))
    (unless (<= count 26)
      (error "A text display takes at most 26 styles, not ~D." count))
    (cffi:with-foreign-objects ((fonts :int count)
                                (sizes :int count)
                                (colors :unsigned-int count)
                                (attributes :unsigned-int count)
                                (backgrounds :unsigned-int count))
      (loop for style in styles
            for index from 0
            do (setf (cffi:mem-aref fonts :int index) (getf style :font 0)
                     (cffi:mem-aref sizes :int index) (getf style :size 12)
                     (cffi:mem-aref colors :unsigned-int index)
                     (%packed-color (getf style :color '(0 0 0)))
                     (cffi:mem-aref attributes :unsigned-int index) (getf style :attributes 0)
                     (cffi:mem-aref backgrounds :unsigned-int index)
                     (%packed-color (getf style :background '(255 255 255)))))
      (%call-widget-operation
       (%text-set-styles (widget-id widget) count fonts sizes colors attributes backgrounds)
       'text-set-styles widget))))

(defun %style-bytes (runs)
  "Return the concatenated text of RUNS and the style letter for each of its
UTF-8 bytes. RUNS is a list of (TEXT . STYLE-INDEX)."
  (let ((text (make-string-output-stream))
        (letters (make-string-output-stream)))
    (dolist (run runs)
      (destructuring-bind (run-text . style) run
        (let ((letter (code-char (+ (char-code #\A) style))))
          (write-string run-text text)
          (loop for character across run-text
                do (loop repeat (character-byte-length character)
                         do (write-char letter letters))))))
    (values (get-output-stream-string text)
            (get-output-stream-string letters))))

(defun %call-with-style-letters (letters function)
  "Call FUNCTION with a foreign copy of the ASCII string LETTERS."
  (cffi:with-foreign-string (foreign letters :encoding :ascii)
    (funcall function foreign)))

(defun text-append-styled (widget runs)
  "Append RUNS, a list of (TEXT . STYLE-INDEX), to the text display WIDGET."
  (%require-widget-kind widget +widget-text-display+ 'text-append-styled)
  (multiple-value-bind (text letters) (%style-bytes runs)
    (%call-with-style-letters
     letters
     (lambda (foreign)
       (%call-widget-operation (%text-append-styled (widget-id widget) text foreign)
                               'text-append-styled widget)))))

(defun text-replace-styled (widget start end runs)
  "Replace bytes START to END of the text display WIDGET with RUNS."
  (%require-widget-kind widget +widget-text-display+ 'text-replace-styled)
  (multiple-value-bind (text letters) (%style-bytes runs)
    (%call-with-style-letters
     letters
     (lambda (foreign)
       (%call-widget-operation (%text-replace-styled (widget-id widget) start end text foreign)
                               'text-replace-styled widget)))))

(defun text-length (widget)
  "Return the length of WIDGET's text in UTF-8 bytes."
  (let ((length (%text-length (widget-id widget))))
    (when (minusp length)
      (error "~S is not a text display or editor." widget))
    length))

(defun text-range (widget start end)
  "Return the text between byte positions START and END of WIDGET."
  (foreign-string (lambda () (%text-range (widget-id widget) start end))))

(defun text-selection (widget)
  "Return the selected text of WIDGET, or an empty string."
  (foreign-string (lambda () (%text-selection (widget-id widget)))))

(defun text-scroll-to-end (widget)
  "Scroll WIDGET so that the end of its text is visible."
  (%call-widget-operation (%text-scroll-to-end (widget-id widget)) 'text-scroll-to-end widget))

(defun text-set-scrollbars (widget mode)
  "Choose which scrollbars WIDGET, a text display or editor, may show: :NONE,
:VERTICAL, :HORIZONTAL or :BOTH. A display sized to its text wants :NONE."
  (%call-widget-operation (%text-set-scrollbars (widget-id widget)
                                                (ecase mode
                                                  (:none 0)
                                                  (:horizontal 1)
                                                  (:vertical 2)
                                                  (:both 3)))
                          'text-set-scrollbars widget))

(defun text-at-end-p (widget)
  "Return T when WIDGET, a text display or editor, shows the end of its text."
  (let ((result (%text-at-end (widget-id widget))))
    (when (minusp result)
      (error "~S is not a text display." widget))
    (plusp result)))

(defun text-top-line (widget)
  "Return the one-based number of the first line WIDGET shows."
  (%text-top-line (widget-id widget)))

(defun (setf text-top-line) (line widget)
  "Scroll WIDGET so that LINE is its first visible line."
  (%call-widget-operation (%text-scroll-to-line (widget-id widget) line) 'text-top-line widget)
  line)

(defun text-line-of-position (widget position)
  "Return the one-based line number containing byte POSITION in WIDGET."
  (%text-line-of-position (widget-id widget) position))

(defun text-position-at (widget x y)
  "Return the byte position under the point X, Y relative to WIDGET, or NIL
when the point is outside the text area."
  (let ((position (%text-position-at (widget-id widget) x y)))
    (if (minusp position)
        nil
        position)))

(defun text-set-wrap (widget mode &optional (margin 0))
  "Set how WIDGET wraps: :NONE, :COLUMN at MARGIN characters, :PIXEL at
MARGIN pixels, or :BOUNDS at the widget's width."
  (%call-widget-operation
   (%text-set-wrap (widget-id widget)
                   (ecase mode
                     (:none 0)
                     (:column 1)
                     (:pixel 2)
                     (:bounds 3))
                   margin)
   'text-set-wrap widget))

(defun text-insert-position (widget)
  "Return the byte position of the caret in the text display or editor WIDGET."
  (let ((position (%text-insert-position (widget-id widget))))
    (when (minusp position)
      (error "~S is not a text display or editor." widget))
    position))

(defun (setf text-insert-position) (position widget)
  "Move the caret of WIDGET to byte POSITION and scroll it into view."
  (%call-widget-operation (%text-set-insert-position (widget-id widget) position)
                          'text-insert-position widget)
  position)

(defun text-replace (widget start end text)
  "Replace the bytes START to END of WIDGET, a text display or editor, with
TEXT. On a styled display the new text takes the first style."
  (%call-widget-operation (%text-replace (widget-id widget) start end text) 'text-replace widget))

(defun text-insert (widget text)
  "Insert TEXT at the caret of WIDGET and leave the caret after it."
  (let ((position (text-insert-position widget)))
    (text-replace widget position position text)
    (setf (text-insert-position widget) (+ position (string-byte-length text)))
    widget))
