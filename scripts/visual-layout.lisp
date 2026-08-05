(require :asdf)
(asdf:load-system :lightfast)

(lightfast:apply-classic-theme)

(let* ((window
         (lightfast:make-window :width 960 :height 620
                                :label "Lightfast automatic layout"
                                :app-id "lightfast-layout-gallery"))
       (toolbar (lightfast:make-panel :parent window :label ""))
       (open (lightfast:make-button :parent toolbar :label "Open"))
       (save (lightfast:make-button :parent toolbar :label "Save"))
       (export (lightfast:make-button :parent toolbar :label "Export"))
       (spacer (lightfast:make-box :parent toolbar))
       (fit (lightfast:make-button :parent toolbar :label "Fit"))
       (actual (lightfast:make-button :parent toolbar :label "1:1"))
       (sidebar (lightfast:make-panel :parent window :label "Photos"))
       (photo-a (lightfast:make-button :parent sidebar :label "PEN-F  001.ORF"))
       (photo-b (lightfast:make-button :parent sidebar :label "OM-1   002.ORF"))
       (photo-c (lightfast:make-button :parent sidebar :label "PEN-F  003.ORF"))
       (preview (lightfast:make-box :parent window :label "Resizable image workspace"))
       (inspector (lightfast:make-panel :parent window :label "Inspector"))
       (exposure-label (lightfast:make-label :parent inspector :label "Exposure"))
       (exposure (lightfast:make-value-input :parent inspector :value "0.00"))
       (contrast-label (lightfast:make-label :parent inspector :label "Contrast"))
       (contrast (lightfast:make-value-input :parent inspector :value "0.00"))
       (lut-label (lightfast:make-label :parent inspector :label "Film look"))
       (lut (lightfast:make-choice :parent inspector))
       (reset (lightfast:make-button :parent inspector :label "Reset adjustments"))
       (status (lightfast:make-status-bar :parent window
                                         :value "Automatic row/column layout, resize this window"))
       (layout
         (lightfast:make-layout-column
          :padding 12
          :gap 8
          :children
          (list
           (lightfast:make-layout-row
            :target toolbar
            :basis 38
            :shrink 0
            :padding 4
            :gap 5
            :align :stretch
            :children
            (list (lightfast:make-layout-item open :basis 72 :shrink 0)
                  (lightfast:make-layout-item save :basis 72 :shrink 0)
                  (lightfast:make-layout-item export :basis 82 :shrink 0)
                  (lightfast:make-layout-item spacer :basis 0 :grow 1)
                  (lightfast:make-layout-item fit :basis 56 :shrink 0)
                  (lightfast:make-layout-item actual :basis 56 :shrink 0)))
           (lightfast:make-layout-row
            :grow 1
            :gap 8
            :children
            (list
             (lightfast:make-layout-column
              :target sidebar
              :basis 190
              :min-width 150
              :max-width 240
              :padding '(10 28 10 10)
              :gap 7
              :align :stretch
              :children
              (list (lightfast:make-layout-item photo-a :basis 34 :shrink 0)
                    (lightfast:make-layout-item photo-b :basis 34 :shrink 0)
                    (lightfast:make-layout-item photo-c :basis 34 :shrink 0)))
             (lightfast:make-layout-item preview
                                         :basis 320
                                         :grow 1
                                         :min-width 180)
             (lightfast:make-layout-column
              :target inspector
              :basis 230
              :min-width 190
              :max-width 280
              :padding '(10 28 10 10)
              :gap 6
              :align :stretch
              :children
              (list
               (lightfast:make-layout-item exposure-label
                                           :basis 20 :shrink 0)
               (lightfast:make-layout-item exposure :basis 28 :shrink 0)
               (lightfast:make-layout-item contrast-label
                                           :basis 20 :shrink 0)
               (lightfast:make-layout-item contrast :basis 28 :shrink 0)
               (lightfast:make-layout-item lut-label :basis 20 :shrink 0)
               (lightfast:make-layout-item lut :basis 28 :shrink 0)
               (lightfast:make-layout-item reset
                                           :basis 30
                                           :shrink 0
                                           :align-self :end
                                           :preferred-width 150)))))
           (lightfast:make-layout-item status :basis 25 :shrink 0)))))
  (dolist (name '("Neutral" "Agfa Vista" "Kodachrome"))
    (lightfast:add-item lut name))
  (setf (lightfast:value lut) "Neutral")
  (lightfast:set-box preview lightfast:+box-down-box+)
  (lightfast:set-color-rgb preview :red 42 :green 48 :blue 58)
  (lightfast:set-label-size preview 18)
  (lightfast:set-label-font preview lightfast:+font-helvetica-bold+)
  (lightfast:layout-on-resize window layout)
  (lightfast:show window)
  (when (uiop:getenv "LIGHTFAST_VISUAL_TIMEOUT")
    (lightfast:add-timeout 1.5d0 #'lightfast:quit))
  (unwind-protect
       (lightfast:run)
    (ignore-errors (lightfast:destroy window))))

(uiop:quit 0)
