(require :asdf)
(asdf:load-system :lightfast)

(defun placement-rect (target placements)
  (let ((placement (find target placements
                         :key #'lightfast:layout-placement-target)))
    (assert placement () "No placement for ~S in ~S." target placements)
    (lightfast:layout-placement-rect placement)))

(defun assert-rect (target placements x y width height)
  (let ((rect (placement-rect target placements)))
    (assert (equal (list x y width height)
                   (list (lightfast:rect-x rect)
                         (lightfast:rect-y rect)
                         (lightfast:rect-width rect)
                         (lightfast:rect-height rect)))
            ()
            "Unexpected rectangle for ~S: ~S."
            target rect)))

;; Equal growth distributes every integer pixel deterministically.
(let* ((layout
         (lightfast:make-layout-row
          :children
          (list (lightfast:make-layout-item :a :basis 0 :grow 1)
                (lightfast:make-layout-item :b :basis 0 :grow 1)
                (lightfast:make-layout-item :c :basis 0 :grow 1))))
       (placements
         (lightfast:compute-layout layout (lightfast:make-rect :width 100 :height 20))))
  (assert-rect :a placements 0 0 34 20)
  (assert-rect :b placements 34 0 33 20)
  (assert-rect :c placements 67 0 33 20))

;; Fixed basis, weighted growth, padding, and gaps compose without hand arithmetic.
(let* ((layout
         (lightfast:make-layout-row
          :padding '(10 4 6 2)
          :gap 5
          :children
          (list (lightfast:make-layout-item :fixed :basis 20 :shrink 0)
                (lightfast:make-layout-item :one :basis 10 :grow 1)
                (lightfast:make-layout-item :two :basis 10 :grow 2))))
       (placements
         (lightfast:compute-layout layout (lightfast:make-rect :width 116 :height 30))))
  (assert-rect :fixed placements 10 4 20 24)
  (assert-rect :one placements 35 4 27 24)
  (assert-rect :two placements 67 4 43 24))

;; Shrinking is proportional and stops at minimum sizes.
(let* ((layout
         (lightfast:make-layout-row
          :children
          (list (lightfast:make-layout-item :wide :basis 80 :min-width 60)
                (lightfast:make-layout-item :narrow :basis 20 :min-width 10))))
       (placements
         (lightfast:compute-layout layout (lightfast:make-rect :width 70 :height 10))))
  (assert-rect :wide placements 0 0 60 10)
  (assert-rect :narrow placements 60 0 10 10))

;; Cross-axis alignment and main-axis justification use preferred dimensions.
(let* ((layout
         (lightfast:make-layout-row
          :justify :space-between
          :align :center
          :children
          (list (lightfast:make-layout-item :left
                                            :basis 10
                                            :preferred-height 8)
                (lightfast:make-layout-item :middle
                                            :basis 10
                                            :preferred-height 6
                                            :align-self :end)
                (lightfast:make-layout-item :right
                                            :basis 10
                                            :preferred-height 10))))
       (placements
         (lightfast:compute-layout layout (lightfast:make-rect :width 100 :height 20))))
  (assert-rect :left placements 0 6 10 8)
  (assert-rect :middle placements 45 14 10 6)
  (assert-rect :right placements 90 5 10 10))

;; Space-between distributes remainder pixels across individual gaps.
(let* ((layout
         (lightfast:make-layout-row
          :justify :space-between
          :children
          (list (lightfast:make-layout-item :a :basis 10)
                (lightfast:make-layout-item :b :basis 10)
                (lightfast:make-layout-item :c :basis 10))))
       (placements
         (lightfast:compute-layout layout (lightfast:make-rect :width 31 :height 5))))
  (assert-rect :a placements 0 0 10 5)
  (assert-rect :b placements 11 0 10 5)
  (assert-rect :c placements 21 0 10 5))

;; A target container establishes local coordinates for its direct children.
(let* ((nested
         (lightfast:make-layout-row
          :target :content
          :grow 1
          :padding 3
          :gap 2
          :children
          (list (lightfast:make-layout-item :sidebar :basis 20)
                (lightfast:make-layout-item :canvas :basis 0 :grow 1))))
       (layout
         (lightfast:make-layout-column
          :padding 5
          :gap 4
          :children
          (list (lightfast:make-layout-item :toolbar :basis 10 :shrink 0)
                nested
                (lightfast:make-layout-item :status :basis 8 :shrink 0))))
       (placements
         (lightfast:compute-layout layout (lightfast:make-rect :width 100 :height 80))))
  (assert-rect :toolbar placements 5 5 90 10)
  (assert-rect :content placements 5 19 90 44)
  (assert-rect :sidebar placements 3 3 20 38)
  (assert-rect :canvas placements 25 3 62 38)
  (assert-rect :status placements 5 67 90 8))

;; Unused space can be centered or placed at the end.
(dolist (case '((:center 40) (:end 80)))
  (destructuring-bind (justify expected-x) case
    (let* ((layout
             (lightfast:make-layout-row
              :justify justify
              :children (list (lightfast:make-layout-item :only :basis 20))))
           (placements
             (lightfast:compute-layout layout
                                       (lightfast:make-rect :width 100 :height 10))))
      (assert-rect :only placements expected-x 0 20 10))))

;; Impossible minimums overflow predictably but never produce negative sizes.
(let* ((layout
         (lightfast:make-layout-row
          :gap 4
          :children
          (list (lightfast:make-layout-item :a :basis 10 :min-width 8)
                (lightfast:make-layout-item :b :basis 10 :min-width 8))))
       (placements
         (lightfast:compute-layout layout (lightfast:make-rect :width 5 :height 0))))
  (assert-rect :a placements 0 0 8 0)
  (assert-rect :b placements 12 0 8 0))

;; Invalid public input is reported as a typed layout condition.
(dolist (thunk
         (list (lambda () (lightfast:make-layout-row :gap -1))
               (lambda () (lightfast:make-layout-row :align :baseline))
               (lambda () (lightfast:make-layout-item :bad :basis -2))
               (lambda ()
                 (lightfast:compute-layout
                  (lightfast:make-layout-item :bad)
                  (lightfast:make-rect :width -1 :height 4)))))
  (handler-case
      (progn (funcall thunk)
             (error "Expected LIGHTFAST:LAYOUT-ERROR."))
    (lightfast:layout-error ())))

(assert (eq (find-package :lightfast) (find-package :cl-fltk)))
(format t "~&Lightfast layout smoke passed.~%")
