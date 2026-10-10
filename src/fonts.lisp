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

;;; Baseline correction.
;;;
;;; FLTK's Cairo driver places a string by its line height minus its descent,
;;; taking the result for the ascent. A font whose hhea or OS/2 table carries a
;;; line gap has a line height of ascent + descent + gap, so FLTK draws it the
;;; gap above the baseline it was asked for: beside other fonts in one text
;;; display, or beside a widget aligned by WIDGET-BASELINE, such a face floats.
;;; Folding the gap into the ascender leaves every metric FLTK reports the
;;; same and puts the glyphs where FLTK thinks they are.

(defun font-files (family)
  "Return the font files of FAMILY as a list of (PATH . STYLE) in the font
system's order."
  (load-library)
  (loop for line in (split-lines (foreign-string (lambda () (%font-files family))))
        for tab = (position #\Tab line)
        when tab
          collect (cons (subseq line 0 tab) (subseq line (1+ tab)))))

(defun %sfnt-tables (octets)
  "Return an alist of (TAG . (INDEX OFFSET LENGTH)) for the sfnt font OCTETS,
or NIL when OCTETS is not a single sfnt font."
  (flet ((u32 (at) (logior (ash (aref octets at) 24) (ash (aref octets (+ at 1)) 16)
                           (ash (aref octets (+ at 2)) 8) (aref octets (+ at 3))))
         (u16 (at) (logior (ash (aref octets at) 8) (aref octets (1+ at)))))
    (when (and (>= (length octets) 12)
               (member (u32 0) '(#x00010000 #x4F54544F #x74727565)))
      (loop for index below (u16 4)
            for record = (+ 12 (* 16 index))
            when (<= (+ record 16) (length octets))
              collect (cons (map 'string #'code-char (subseq octets record (+ record 4)))
                            (list index (u32 (+ record 8)) (u32 (+ record 12))))))))

(defun %s16 (octets at)
  "Read the signed 16-bit integer at AT in OCTETS."
  (let ((value (logior (ash (aref octets at) 8) (aref octets (1+ at)))))
    (if (>= value #x8000) (- value #x10000) value)))

(defun (setf %s16) (value octets at)
  "Write the signed 16-bit integer VALUE at AT in OCTETS."
  (let ((unsigned (ldb (byte 16 0) value)))
    (setf (aref octets at) (ash unsigned -8)
          (aref octets (1+ at)) (logand unsigned #xFF))
    value))

(defun (setf %u32) (value octets at)
  "Write the unsigned 32-bit integer VALUE at AT in OCTETS."
  (loop for shift from 24 downto 0 by 8
        for index from at
        do (setf (aref octets index) (ldb (byte 8 shift) value)))
  value)

(defun %sfnt-checksum (octets start length)
  "Return the sfnt checksum of LENGTH octets at START, padded with zeros."
  (let ((sum 0))
    (loop for at from start below (+ start length) by 4
          do (incf sum (loop for index from at below (+ at 4)
                             for shift from 24 downto 0 by 8
                             sum (ash (if (< index (length octets)) (aref octets index) 0) shift))))
    (ldb (byte 32 0) sum)))

(defun %read-octets (path)
  "Return the contents of the file at PATH as an octet vector."
  (with-open-file (stream path :element-type '(unsigned-byte 8))
    (let ((octets (make-array (file-length stream) :element-type '(unsigned-byte 8))))
      (read-sequence octets stream)
      octets)))

(defun font-line-gaps (path)
  "Return the hhea line gap and the OS/2 typographic line gap of the sfnt
font at PATH in font units, or NIL when the file is not a single sfnt font."
  (let* ((octets (%read-octets path))
         (tables (%sfnt-tables octets))
         (hhea (cdr (assoc "hhea" tables :test #'string=)))
         (os/2 (cdr (assoc "OS/2" tables :test #'string=))))
    (when hhea
      (values (%s16 octets (+ (second hhea) 8))
              (and os/2 (%s16 octets (+ (second os/2) 72)))))))

(defun fold-font-line-gap (source target)
  "Write the sfnt font at SOURCE to TARGET with its line gaps folded into its
ascenders: the hhea ascender grows by the hhea line gap and the OS/2
typographic ascender by the typographic line gap, and both gaps become zero.
Table checksums and the whole-font checksum adjustment are refreshed. Returns
the hhea gap that was folded, or NIL when SOURCE has no gap or is not a single
sfnt font, in which case nothing is written."
  (let* ((octets (%read-octets source))
         (tables (%sfnt-tables octets))
         (hhea (cdr (assoc "hhea" tables :test #'string=)))
         (os/2 (cdr (assoc "OS/2" tables :test #'string=)))
         (head (cdr (assoc "head" tables :test #'string=)))
         (gap (and hhea (%s16 octets (+ (second hhea) 8))))
         (typo-gap (and os/2 (%s16 octets (+ (second os/2) 72)))))
    (when (and hhea (or (/= gap 0) (and typo-gap (/= typo-gap 0))))
      (flet ((fold (table ascender-at gap-at)
               (destructuring-bind (index offset length) table
                 (incf (%s16 octets (+ offset ascender-at)) (%s16 octets (+ offset gap-at)))
                 (setf (%s16 octets (+ offset gap-at)) 0
                       (%u32 octets (+ 12 (* 16 index) 4)) (%sfnt-checksum octets offset length)))))
        (fold hhea 4 8)
        (when os/2
          (fold os/2 68 72))
        (when head
          (let ((adjustment-at (+ (second head) 8)))
            (setf (%u32 octets adjustment-at) 0
                  (%u32 octets adjustment-at)
                  (ldb (byte 32 0) (- #xB1B0AFBA (%sfnt-checksum octets 0 (length octets))))))))
      (ensure-directories-exist target)
      (with-open-file (stream target :element-type '(unsigned-byte 8)
                                     :direction :output :if-exists :supersede)
        (write-sequence octets stream))
      gap)))

(defmacro %with-c-strings ((pointer strings) &body body)
  "Run BODY with POINTER bound to a foreign array of the C strings for STRINGS."
  (let ((list (gensym "STRINGS")) (count (gensym "COUNT")) (index (gensym "INDEX")))
    `(let* ((,list ,strings) (,count (length ,list)))
       (cffi:with-foreign-object (,pointer :pointer ,count)
         (loop for ,index from 0 for string in ,list
               do (setf (cffi:mem-aref ,pointer :pointer ,index) (cffi:foreign-string-alloc string)))
         (unwind-protect (progn ,@body)
           (loop for ,index below ,count
                 do (cffi:foreign-string-free (cffi:mem-aref ,pointer :pointer ,index))))))))

(defun correct-font-baselines (families &key (directory (uiop:xdg-cache-home "lightfast/fonts/")))
  "Make FLTK draw FAMILIES on the baseline it is given. Each font file of each
family that carries a line gap is copied to DIRECTORY with the gap folded into
its ascender by FOLD-FONT-LINE-GAP, and the font system is told to use the
copies in place of the originals for this process. Returns the corrected
files as a list of (ORIGINAL . COPY), NIL when no family needed it.

Call this once, after LOAD-LIBRARY and before any font is loaded or window
shown; faces loaded earlier keep their uncorrected metrics."
  (load-library)
  (let ((corrected nil))
    (dolist (family families)
      (dolist (entry (font-files family))
        (let* ((source (car entry))
               (target (namestring (merge-pathnames (file-namestring source)
                                                    (uiop:ensure-directory-pathname directory)))))
          (when (and (not (assoc source corrected :test #'string=))
                     (fold-font-line-gap source target))
            (push (cons source target) corrected)))))
    (setf corrected (nreverse corrected))
    (when corrected
      (%with-c-strings (copies (mapcar #'cdr corrected))
        (%with-c-strings (originals (mapcar #'car corrected))
          (unless (plusp (%font-substitute copies (length corrected) originals (length corrected)))
            (error "The font system refused the corrected copies of ~{~A~^, ~}." families)))))
    corrected))

(defun split-lines (text)
  "Split TEXT at newlines, dropping the empty tail a final newline leaves."
  (loop with start = 0
        for end = (position #\Newline text :start start)
        collect (subseq text start end) into lines
        while end
        do (setf start (1+ end))
        finally (return (remove "" lines :test #'string=))))
