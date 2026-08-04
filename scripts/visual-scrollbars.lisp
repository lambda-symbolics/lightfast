(require :asdf)
(asdf:load-system :lightfast)

(lightfast:apply-classic-theme)

(let* ((window (lightfast:make-window :width 760 :height 420
                                    :label "Lightfast scrollbar visual smoke"
                                    :app-id "lightfast-scrollbar-smoke"))
       (browser (lightfast:make-browser :parent window :x 12 :y 34
                                      :width 220 :height 350
                                      :label "Browser"))
       (table (lightfast:make-table
               :parent window :x 244 :y 34 :width 270 :height 350
               :label "Table"
               :columns '("Item" "State")
               :column-widths '(170 80)
               :rows (loop for index from 1 to 40
                           collect (list (format nil "Record ~2,'0D" index)
                                         (if (oddp index) "Ready" "Queued")))))
       (scroll (lightfast:make-scroll :parent window :x 526 :y 34
                                    :width 220 :height 350
                                    :label "Scroll")))
  (loop for index from 1 to 40
        do (lightfast:add-item browser (format nil "Browser item ~2,'0D" index)))
  (lightfast:browser-select browser 20)
  (lightfast:table-select-row table 20)
  (loop for index from 0 below 18
        do (lightfast:make-box :parent scroll :x 8 :y (+ 8 (* index 32))
                             :width 180 :height 26
                             :label (format nil "Scrollable child ~2,'0D" (1+ index))))
  (lightfast:show window)
  (unwind-protect
       (lightfast:run)
    (ignore-errors (lightfast:destroy window))))

(uiop:quit 0)
