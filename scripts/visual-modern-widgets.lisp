(require :asdf)
(asdf:load-system :lightfast)

(lightfast:apply-classic-theme)

(let* ((window (lightfast:make-window :width 780 :height 590
                                     :label "Lightfast modern widget gallery"
                                     :app-id "lightfast-modern-widget-gallery"))
       (pack (lightfast:make-pack :parent window :x 16 :y 56
                                 :width 250 :height 120 :label "Pack"
                                 :orientation :horizontal :spacing 6))
       (grid (lightfast:make-grid :parent window :x 282 :y 56
                                 :width 270 :height 120 :label "Grid"
                                 :rows 2 :columns 2 :margin 8
                                 :row-gap 6 :column-gap 6))
       (positioner (lightfast:make-positioner :parent window :x 574 :y 56
                                             :width 150 :height 120
                                             :label "Positioner"
                                             :x-value 0.35 :y-value 0.7))
       (chart (lightfast:make-chart :parent window :x 16 :y 204
                                   :width 300 :height 160 :label "Chart"
                                   :type :bar :minimum 0 :maximum 10))
       (terminal (lightfast:make-terminal :parent window :x 332 :y 204
                                         :width 392 :height 160
                                         :label "Terminal"))
       (chooser (lightfast:make-color-chooser :parent window :x 16 :y 396
                                             :width 230 :height 150
                                             :label "Color chooser"
                                             :red 0.18 :green 0.48 :blue 0.82))
       (wizard (lightfast:make-wizard :parent window :x 270 :y 396
                                     :width 220 :height 150
                                     :label "Wizard"))
       (page (lightfast:make-group :parent wizard :x 0 :y 0
                                  :width 220 :height 150 :label "Page one")))
  (declare (ignore positioner chooser))
  (lightfast:make-file-input :parent window :x 16 :y 16
                             :width 250 :height 26 :label "File:"
                             :value "/photos/example.orf")
  (lightfast:make-value-output :parent window :x 282 :y 16
                              :width 92 :height 26 :label "Value:"
                              :value "42.5")
  (lightfast:make-scheme-choice :parent window :x 390 :y 16
                                :width 150 :height 26 :label "Scheme:")
  (lightfast:make-shortcut-button :parent window :x 556 :y 16
                                  :width 168 :height 26
                                  :label "Capture shortcut")
  (dolist (label '("One" "Two" "Three"))
    (lightfast:make-button :parent pack :width 76 :height 30 :label label))
  (loop for label in '("North" "East" "South" "West")
        for row in '(0 0 1 1)
        for column in '(0 1 0 1)
        for child = (lightfast:make-button :parent grid :label label)
        do (lightfast:grid-place grid child :row row :column column))
  (lightfast:grid-set-column-weight grid 0 1)
  (lightfast:grid-set-column-weight grid 1 1)
  (loop for value in '(3.0 7.0 5.0 9.0 4.0)
        for label in '("A" "B" "C" "D" "E")
        do (lightfast:chart-add chart value :label label))
  (lightfast:terminal-append terminal
                             (format nil "~C[32mLightfast terminal~C[0m~%Ready.~%"
                                     #\Escape #\Escape))
  (lightfast:make-label :parent page :x 16 :y 28
                        :width 188 :height 24 :label "Wizard page content")
  (lightfast:make-input :parent page :x 16 :y 64
                        :width 188 :height 26 :value "Editable field")
  (lightfast:make-button :parent page :x 86 :y 106
                         :width 118 :height 28 :label "Continue")
  (setf (lightfast:wizard-current-child wizard) page)
  (lightfast:show window)
  (unwind-protect
       (lightfast:run)
    (ignore-errors (lightfast:destroy window))))

(uiop:quit 0)
