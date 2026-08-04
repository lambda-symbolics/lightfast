(require :asdf)
(asdf:load-system :lightfast)

(lightfast:apply-classic-theme)

(let ((window (lightfast:make-window :width 520 :height 300
                                   :label "Lightfast button ellipsis visual smoke"
                                   :app-id "lightfast-button-ellipsis-smoke")))
  (lightfast:make-label :parent window :x 16 :y 12 :width 488 :height 24
                      :label "Every narrow button should end in an ellipsis, never clip its label.")
  (lightfast:make-button :parent window :x 16 :y 48 :width 220 :height 28
                       :label "Apply adjustments to 123 photographs")
  (lightfast:make-button :parent window :x 252 :y 48 :width 120 :height 28
                       :label "Apply adjustments to 123 photographs")
  (lightfast:make-button :parent window :x 388 :y 48 :width 68 :height 28
                       :label "Apply adjustments to 123 photographs")
  (lightfast:make-toggle-button :parent window :x 16 :y 92 :width 150 :height 28
                              :label "Show all comparison controls")
  (lightfast:make-return-button :parent window :x 182 :y 92 :width 150 :height 28
                              :label "Export selected photographs")
  (lightfast:make-repeat-button :parent window :x 348 :y 92 :width 108 :height 28
                              :label "Repeat long operation")
  (lightfast:make-check-button :parent window :x 16 :y 136 :width 150 :height 28
                             :label "Preserve all original metadata")
  (lightfast:make-light-button :parent window :x 182 :y 136 :width 150 :height 28
                             :label "Enable automatic correction")
  (lightfast:make-radio-button :parent window :x 348 :y 136 :width 108 :height 28
                             :label "Very long radio choice")
  (let ((button (lightfast:make-button
                 :parent window :x 16 :y 196 :width 440 :height 30
                 :label "Resize this window narrower and wider: the complete label remains intact")))
    (lightfast:set-tooltip button
                         "The native button computes its display label at draw time; the full label is preserved."))
  (lightfast:show window)
  (unwind-protect
       (lightfast:run)
    (ignore-errors (lightfast:destroy window))))

(uiop:quit 0)
