(require :asdf)
(asdf:load-system :lightfast)
(lightfast:load-library)
(lightfast:enable-thread-wakeups)
(let* ((window (lightfast:make-window :width 200 :height 100 :label "awake"))
       (woken nil))
  (lightfast:show window)
  (sb-thread:make-thread (lambda () (sleep 0.3) (setf woken t) (lightfast:awake)))
  ;; Without AWAKE this wait would run the full five seconds.
  (let ((start (get-internal-real-time)))
    (lightfast:wait 5.0)
    (loop until woken do (lightfast:wait 5.0))
    (let ((elapsed (/ (- (get-internal-real-time) start) internal-time-units-per-second)))
      (assert (< elapsed 2.0) () "wait was not woken early: ~,2F s" elapsed)
      (format t "~&awake smoke passed in ~,2F s~%" elapsed)))
  (lightfast:destroy window))

;;; A callback from inside the event loop runs with the floating point traps
;;; Lisp had outside it, although the loop itself runs with them masked.
;;; The quotient is stored where the compiler can see no end of it: a division
;;; whose result is dropped is one an older SBCL deletes, trap and all.
(defparameter *zero* 0.0)
(defparameter *quotient* nil)
(let* ((window (lightfast:make-window :width 200 :height 100 :label "float traps"))
       (outside (getf (sb-int:get-floating-point-modes) :traps))
       (inside :never-ran)
       (signalled nil))
  (lightfast:show window)
  (lightfast:add-timeout 0.05
                         (lambda ()
                           (setf inside (getf (sb-int:get-floating-point-modes) :traps)
                                 signalled (handler-case
                                               (progn (setf *quotient* (/ 1.0 *zero*)) nil)
                                             (division-by-zero () t)))))
  (loop repeat 40
        while (eq inside :never-ran)
        do (lightfast:wait 0.05))
  (assert (equal inside outside) () "a timer callback ran with traps ~S, not ~S" inside outside)
  (assert signalled () "division by zero did not signal inside a timer callback")
  (assert (equal outside (getf (sb-int:get-floating-point-modes) :traps)) ()
          "the event loop left the traps changed")
  (lightfast:destroy window)
  (format t "~&float trap smoke passed with traps ~S~%" outside))

;;; RUN-WITH-IDLE: a worker wakes the loop twice, then closes the window;
;;; the idle function must run before the first wait and after each wakeup.
(let* ((window (lightfast:make-window :width 200 :height 100 :label "run-with-idle"))
       (idle-calls 0)
       (worker (sb-thread:make-thread
                (lambda ()
                  (sleep 0.2) (lightfast:awake)
                  (sleep 0.2) (lightfast:awake)
                  (sleep 0.2) (lightfast:quit)))))
  (lightfast:show window)
  (lightfast:run-with-idle (lambda () (incf idle-calls)))
  (sb-thread:join-thread worker)
  (assert (>= idle-calls 3) () "idle ran only ~D times" idle-calls)
  (format t "~&run-with-idle smoke passed with ~D idle calls~%" idle-calls))
