(require :asdf)
(asdf:load-system :lightfast)
(lightfast:load-library)
(let* ((outer   (lightfast:make-rect :x 10 :y 20 :width 101 :height 30))
       (inner   (lightfast:rect-inset outer :horizontal 5 :vertical 2))
       (columns (lightfast:rect-columns outer 2 :gap 1)))
  (assert (= 15 (lightfast:rect-x inner)))
  (assert (= 22 (lightfast:rect-y inner)))
  (assert (= 91 (lightfast:rect-width inner)))
  (assert (= 26 (lightfast:rect-height inner)))
  (assert (= 2 (length columns)))
  (assert (= 50 (lightfast:rect-width (first columns))))
  (assert (= 50 (lightfast:rect-width (second columns))))
  (assert (= 61 (lightfast:rect-x (second columns)))))
;; Every foreign function is declared with DEFINE-BRIDGE-FUNCTION, which masks
;; floating point traps around the call. A plain CFFI:DEFCFUN would skip the
;; mask, pass every check on Linux and end the process on macOS.
(labels ((mentions-defcfun-p (form)
           (cond ((eq form 'cffi:defcfun) t)
                 ((consp form) (or (mentions-defcfun-p (car form))
                                   (mentions-defcfun-p (cdr form)))))))
  (dolist (file (directory (merge-pathnames "src/**/*.lisp"
                                            (asdf:system-source-directory :lightfast))))
    (with-open-file (stream file)
      (let ((*package* (find-package :lightfast)))
        (loop for form = (read stream nil stream)
              until (eq form stream)
              do (assert (not (mentions-defcfun-p form)) ()
                         "~A declares a foreign function with CFFI:DEFCFUN; use DEFINE-BRIDGE-FUNCTION."
                         file))))))

;; Foreign code runs with every floating point trap masked, and Lisp has its
;; own traps back as soon as the call returns and inside a callback meanwhile.
(defparameter *zero* 0.0)
(flet ((traps () (getf (sb-int:get-floating-point-modes) :traps))
       (division-signals-p ()
         (handler-case (progn (/ 1.0 *zero*) nil)
           (division-by-zero () t))))
  (let ((outside (traps)))
    (assert outside () "this Lisp runs with no floating point traps to mask")
    (lightfast::with-native-float-traps
      (assert (null (traps)) () "traps ~S are still enabled inside the bridge" (traps))
      (lightfast::with-lisp-float-traps
        (assert (equal outside (traps)) () "a callback runs with traps ~S, not ~S" (traps) outside)
        (assert (division-signals-p) () "division by zero does not signal inside a callback"))
      (assert (null (traps)) () "traps ~S came back after a callback" (traps)))
    (assert (equal outside (traps)) () "traps are ~S after the bridge, not ~S" (traps) outside)
    (lightfast::%event-key)
    (assert (equal outside (traps)) () "traps are ~S after a bridge call, not ~S" (traps) outside)
    (assert (division-signals-p) () "division by zero does not signal after a bridge call")))

(format t "~&Lightfast load smoke passed.~%")
