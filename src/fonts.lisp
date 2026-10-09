(in-package #:lightfast)

;;; Named fonts: loading faces by family and style, listing what the system
;;; offers, and measuring text in a face.

(defun load-font (name)
  "Load the face NAME and return its font number for SET-TEXT-FONT and friends.

NAME is the face as the font system knows it: the family followed by its style
words, for example \"Times New Roman Bold Italic\" or \"IBM Plex Mono\". The
family alone names the regular face. Loading the same name twice returns the
same number. FLTK gives no error for an unknown name: it draws a fallback face,
so check SYSTEM-FONT-NAMES when a face looks wrong."
  (load-library)
  (let ((font (%font-load name)))
    (when (minusp font)
      (error "A font name must be a non-empty string, not ~S." name))
    font))

(defun font-name (font)
  "Return the name FLTK holds for font number FONT."
  (load-library)
  (foreign-string (lambda () (%font-name font))))

(defun system-font-names ()
  "Return the faces installed on this system as a list of (NAME . ATTRIBUTES).

ATTRIBUTES is FLTK's bit set: 1 for bold, 2 for italic, 3 for both. Every NAME
is accepted by LOAD-FONT as it is."
  (load-library)
  (let ((text (foreign-string #'%font-system-names)))
    (loop for line in (split-lines text)
          for tab = (position #\Tab line)
          when tab
            collect (cons (subseq line 0 tab)
                          (parse-integer line :start (1+ tab) :junk-allowed t)))))

(defun measure-text (text &key (font 0) (size 12))
  "Measure TEXT drawn in FONT at SIZE.

Returns three values: the advance width in pixels, the line height, and the
descent below the baseline. The height and descent depend only on the face and
size, so a layout can take them once and reuse them for every row."
  (load-library)
  (cffi:with-foreign-objects ((width :int) (height :int) (descent :int))
    (unless (plusp (%font-measure font size text width height descent))
      (error "Cannot measure text in font ~D at size ~D." font size))
    (values (cffi:mem-ref width :int)
            (cffi:mem-ref height :int)
            (cffi:mem-ref descent :int))))

(defun split-lines (text)
  "Split TEXT at newlines, dropping the empty tail a final newline leaves."
  (loop with start = 0
        for end = (position #\Newline text :start start)
        collect (subseq text start end) into lines
        while end
        do (setf start (1+ end))
        finally (return (remove "" lines :test #'string=))))
