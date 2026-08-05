(require :asdf)
(asdf:load-system :lightfast)

(lightfast:apply-classic-theme)

(let* ((events nil)
       (window (lightfast:make-window :width 320
                                    :height 520
                                    :label "Lightfast smoke"
                                    :app-id "lightfast-smoke"))
       (menu   (lightfast:make-menu-bar :parent window
                                      :x      0
                                      :y      0
                                      :width  320
                                      :height 24))
       (panel  (lightfast:make-panel :parent window
                                   :x      8
                                   :y      28
                                   :width  304
                                   :height 132
                                   :label  "Panel"))
       (inside (lightfast:make-input :parent panel
                                   :x      12
                                   :y      24
                                   :width  120
                                   :height 24
                                   :value  "Inside"))
       (name   (lightfast:make-input :parent window
                                   :x      88
                                   :y      42
                                   :width  204
                                   :height 24
                                   :label  "Name:"
                                   :value  "Lisp"))
       (state  (lightfast:make-choice :parent window
                                    :x      88
                                    :y      74
                                    :width  204
                                    :height 24
                                    :label  "State:"
                                    :items  '("Ready" "Running")))
       (list   (lightfast:make-browser :parent window
                                     :x      88
                                     :y      106
                                     :width  204
                                     :height 44
                                     :label  "Items:"))
       (button (lightfast:make-button :parent window
                                    :x      220
                                    :y      148
                                    :width  72
                                    :height 24
                                    :label  "Save"
                                    :callback
                                    (lambda (widget event value)
                                      (declare (ignore widget value))
                                      (push event events))))
       (output (lightfast:make-output :parent window
                                    :x      88
                                    :y      12
                                    :width  204
                                    :height 22
                                    :label  "Status:"
                                    :value  "Ready"))
       (tabs   (lightfast:make-tabs :parent window
                                  :x      8
                                  :y      166
                                  :width  304
                                  :height 182))
       (tab    (lightfast:make-tab-page :parent tabs
                                      :x      0
                                      :y      24
                                      :width  304
                                      :height 158
                                      :label  "More"))
       (slider (lightfast:make-slider :parent tab
                                    :x      12
                                    :y      8
                                    :width  132
                                    :height 24
                                    :value  "50"))
       (meter  (lightfast:make-progress :parent tab
                                      :x      156
                                      :y      10
                                      :width  132
                                      :height 20
                                      :value  "50"))
       (light  (lightfast:make-light-button :parent tab
                                          :x      12
                                          :y      42
                                          :width  96
                                          :height 24
                                          :label  "Light"))
       (radio  (lightfast:make-radio-button :parent tab
                                          :x      116
                                          :y      42
                                          :width  96
                                          :height 24
                                          :label  "Radio"))
       (count  (lightfast:make-counter :parent tab
                                     :x      12
                                     :y      74
                                     :width  96
                                     :height 24
                                     :value  "2"))
       (spin   (lightfast:make-spinner :parent tab
                                     :x      116
                                     :y      74
                                     :width  96
                                     :height 24
                                     :value  "3"))
       (dial   (lightfast:make-dial :parent tab
                                  :x      224
                                  :y      42
                                  :width  48
                                  :height 48
                                  :value  "25"))
       (roller (lightfast:make-roller :parent tab
                                    :x      12
                                    :y      110
                                    :width  96
                                    :height 24
                                    :value  "40"))
       (tree   (lightfast:make-tree :parent tab
                                  :x      116
                                  :y      104
                                  :width  172
                                  :height 46
                                  :items  '("System/Input"
                                            "System/Output")))
       (secret (lightfast:make-secret-input :parent window
                                          :x      8
                                          :y      252
                                          :width  72
                                          :height 24
                                          :value  "hidden"))
       (int    (lightfast:make-int-input :parent window
                                       :x      84
                                       :y      252
                                       :width  48
                                       :height 24
                                       :value  "12"))
       (float  (lightfast:make-float-input :parent window
                                         :x      136
                                         :y      252
                                         :width  48
                                         :height 24
                                         :value  "3.5"))
       (text   (lightfast:make-text-display :parent window
                                          :x      188
                                          :y      252
                                          :width  124
                                          :height 36
                                          :value  "display"))
       (editor (lightfast:make-text-editor :parent window
                                         :x      8
                                         :y      292
                                         :width  124
                                         :height 36
                                         :value  "edit"))
       (help   (lightfast:make-help-view :parent window
                                       :x      136
                                       :y      292
                                       :width  92
                                       :height 36
                                       :value  "<b>Help</b>"))
       (clock  (lightfast:make-clock :parent window
                                   :x      236
                                   :y      292
                                   :width  44
                                   :height 44
                                   :value  "3600"))
       (toggle (lightfast:make-toggle-button :parent window
                                           :x      8
                                           :y      340
                                           :width  60
                                           :height 24
                                           :label  "Toggle"))
       (return (lightfast:make-return-button :parent window
                                           :x      72
                                           :y      340
                                           :width  60
                                           :height 24
                                           :label  "Return"))
       (repeat (lightfast:make-repeat-button :parent window
                                           :x      136
                                           :y      340
                                           :width  60
                                           :height 24
                                           :label  "Repeat"))
       (vslide (lightfast:make-value-slider :parent window
                                          :x      8
                                          :y      370
                                          :width  132
                                          :height 24
                                          :value  "45"))
       (scroll (lightfast:make-scrollbar :parent window
                                       :x      148
                                       :y      373
                                       :width  132
                                       :height 18
                                       :value  "25"))
       (adjust (lightfast:make-adjuster :parent window
                                      :x      8
                                      :y      400
                                      :width  132
                                      :height 24
                                      :value  "12"))
       (table  (lightfast:make-table :parent window
                                   :x      8
                                   :y      430
                                   :width  272
                                   :height 80
                                   :columns '("Process" "CPU" "Mem")
                                   :column-widths '(110 60 70)
                                   :rows    '(("sbcl" "4%" "180 MB")
                                              ("Xwayland" "1%" "92 MB")))))
  (lightfast:add-menu-item menu "&File/E&xit"
                         (lambda (widget path)
                           (declare (ignore widget))
                           (push path events)))
  (assert (string= "Panel" (lightfast:label panel)))
  (assert (string= "lightfast-smoke" (lightfast:window-app-id window)))
  (assert (string= "Save" (lightfast:label button)))
  (assert (string= "Return" (lightfast:label return)))
  (assert (string= "Repeat" (lightfast:label repeat)))
  (assert (= (+ (lightfast:widget-x panel) 12)
             (lightfast:widget-x inside)))
  (assert (= (+ (lightfast:widget-y panel) 24)
             (lightfast:widget-y inside)))
  (let ((resize-events 0))
    (lightfast:on-resize panel
                       (lambda (widget)
                         (declare (ignore widget))
                         (incf resize-events)))
    (lightfast:resize-widget panel
                           :x      8
                           :y      28
                           :width  300
                           :height 132)
    (assert (zerop resize-events)))
  (assert (string= "Lisp" (lightfast:value name)))
  (setf (lightfast:value name) "FLTK")
  (assert (string= "FLTK" (lightfast:value name)))
  (assert (string= "Ready" (lightfast:value state)))
  (lightfast:add-item list "One")
  (lightfast:add-item list "Two")
  (lightfast:browser-select list 1)
  (assert (string= "Two" (lightfast:value list)))
  (setf (lightfast:value output) "Smoke passed")
  (assert (string= "Smoke passed" (lightfast:value output)))
  (lightfast:set-range slider 0 100)
  (lightfast:set-range meter 0 100)
  (assert (string= "More" (lightfast:value tabs)))
  (setf (lightfast:value slider) "75")
  (setf (lightfast:value meter) "75")
  (assert (string= "75" (lightfast:value slider)))
  (assert (string= "75" (lightfast:value meter)))
  (setf (lightfast:value light) "1")
  (setf (lightfast:value radio) "1")
  (setf (lightfast:value count) "7")
  (setf (lightfast:value spin) "8")
  (setf (lightfast:value dial) "9")
  (setf (lightfast:value roller) "10")
  (setf (lightfast:value tree) "System/Output")
  (setf (lightfast:value secret) "changed")
  (setf (lightfast:value int) "34")
  (setf (lightfast:value float) "6.75")
  (setf (lightfast:value text) "new display")
  (setf (lightfast:value editor) "new edit")
  (setf (lightfast:value help) "<i>New help</i>")
  (setf (lightfast:value clock) "7200")
  (setf (lightfast:value toggle) "1")
  (setf (lightfast:value vslide) "55")
  (setf (lightfast:value scroll) "35")
  (setf (lightfast:value adjust) "18")
  (lightfast:table-set-cell table 1 1 "2%")
  (lightfast:table-select-row table 1)
  (assert (string= "1" (lightfast:value light)))
  (assert (string= "1" (lightfast:value radio)))
  (assert (string= "7" (lightfast:value count)))
  (assert (string= "8" (lightfast:value spin)))
  (assert (string= "9" (lightfast:value dial)))
  (assert (string= "10" (lightfast:value roller)))
  (assert (string= "System/Output" (lightfast:value tree)))
  (assert (string= "changed" (lightfast:value secret)))
  (assert (string= "34" (lightfast:value int)))
  (assert (string= "6.75" (lightfast:value float)))
  (assert (string= "new display" (lightfast:value text)))
  (assert (string= "new edit" (lightfast:value editor)))
  (assert (string= "<i>New help</i>" (lightfast:value help)))
  (assert (parse-integer (lightfast:value clock) :junk-allowed t))
  (assert (string= "1" (lightfast:value toggle)))
  (assert (string= "55" (lightfast:value vslide)))
  (assert (string= "35" (lightfast:value scroll)))
  (assert (string= "18" (lightfast:value adjust)))
  (assert (string= "2%" (lightfast:table-cell table 1 1)))
  (assert (= 1 (lightfast:table-selected-row table)))
  (let ((timer (lightfast:add-timeout 10.0d0
                                    (lambda ()
                                      (push :timer events)))))
    (assert (lightfast:remove-timeout timer)))
  (assert (lightfast:destroy window)))

(let* ((events nil)
       (window (lightfast:make-window :width 260
                                    :height 176
                                    :label "Lightfast ergonomic smoke"))
       (menu   (lightfast:make-menu :parent window
                                  :x      0
                                  :y      0
                                  :width  260
                                  :height 24
                                  :items  (list
                                           (list "&File"
                                                 (list "E&xit"
                                                       (lambda (widget path)
                                                         (declare (ignore widget))
                                                         (push path events)))))))
       (form   (lightfast:make-form :parent window
                                  :x      12
                                  :y      34
                                  :width  230
                                  :rows   '((:name :input "Name:" :value "Lisp")
                                            (:mode :choice "Mode:" :items ("Run" "Stop"))
                                            (:rate :value-input "Rate:" :value "0.25" :step 0.01d0))))
       (radio  (lightfast:make-radio-group :parent window
                                         :x      12
                                         :y      110
                                         :items  '((:email "Email")
                                                   (:phone "Phone"))
                                         :value  :phone))
       (tools  (lightfast:make-toolbar :parent window
                                     :x      12
                                     :y      142
                                     :buttons (list
                                               (list :ok "OK"
                                                     (lambda (widget event value)
                                                       (declare (ignore widget value))
                                                       (push event events)))))))
  (declare (ignore menu))
  (assert (string= "Lisp" (lightfast:form-value form :name)))
  (setf (lightfast:form-value form :name) "FLTK")
  (assert (string= "FLTK" (lightfast:form-value form :name)))
  (assert (equal '((:name . "FLTK") (:mode . "Run") (:rate . "0.25"))
                 (lightfast:form-values form)))
  (assert (eq :phone (lightfast:radio-group-value radio)))
  (setf (lightfast:radio-group-value radio) :email)
  (assert (eq :email (lightfast:radio-group-value radio)))
  (assert (assoc :ok tools))
  (assert (lightfast:destroy window)))

(let* ((events nil)
       (window (lightfast:make-window :width 420
                                    :height 260
                                    :label "Lightfast advanced smoke"))
       (menu-button (lightfast:make-menu-button
                     :parent window
                     :x      12
                     :y      12
                     :width  104
                     :height 26
                     :label  "Actions"
                     :items  (list
                              (list "&Tools"
                                    (list "&Refresh"
                                          (lambda (widget path)
                                            (declare (ignore widget))
                                            (push path events)))))))
       (combo (lightfast:make-input-choice :parent window
                                         :x      130
                                         :y      12
                                         :width  150
                                         :height 24
                                         :items  '("Alpha" "Beta")
                                         :value  "Beta"))
       (checks (lightfast:make-check-browser :parent window
                                           :x      12
                                           :y      48
                                           :width  180
                                           :height 86
                                           :items  '(("CPU" t)
                                                     ("Memory" nil)
                                                     ("Disk" t))))
       (files (lightfast:make-file-browser :parent window
                                         :x      204
                                         :y      48
                                         :width  196
                                         :height 86
                                         :directory "."
                                         :filter "*.lisp"
                                         :filetype :files))
       (tile (lightfast:make-tile :parent window
                                :x      12
                                :y      146
                                :width  180
                                :height 88))
       (left (lightfast:make-box :parent tile
                               :x      0
                               :y      0
                               :width  88
                               :height 88
                               :label  "Left"))
       (right (lightfast:make-box :parent tile
                                :x      92
                                :y      0
                                :width  88
                                :height 88
                                :label  "Right"))
       (flex (lightfast:make-flex :parent window
                                :x      204
                                :y      146
                                :width  196
                                :height 88
                                :orientation :horizontal
                                :gap 4
                                :margin 4))
       (play (lightfast:make-button :parent flex
                                  :width  64
                                  :height 26
                                  :label  "Play"))
       (track (lightfast:make-output :parent flex
                                   :width  104
                                   :height 26
                                   :value  "demo.wav")))
  (declare (ignore menu-button right))
  (lightfast:tile-size-range tile left :min-width 40 :min-height 40)
  (lightfast:flex-fixed flex play 64)
  (lightfast:flex-layout flex)
  (assert (string= "Beta" (lightfast:value combo)))
  (assert (= 3 (lightfast:check-browser-count checks)))
  (assert (= 2 (lightfast:check-browser-checked-count checks)))
  (assert (equal '("CPU" "Disk")
                 (lightfast:check-browser-checked-items checks)))
  (setf (lightfast:check-browser-checked-p checks 1) t)
  (assert (lightfast:check-browser-checked-p checks 1))
  (lightfast:check-browser-check-none checks)
  (assert (= 0 (lightfast:check-browser-checked-count checks)))
  (assert (lightfast:file-browser-load files "."))
  (assert (string= "demo.wav" (lightfast:value track)))
  (assert (lightfast:destroy window)))

(let* ((records (list (list :name "sbcl" :pid 2847 :cpu 4)
                      (list :name "niri" :pid 1010 :cpu 2)))
       (window  (lightfast:make-window :width 320
                                     :height 140
                                     :label "Lightfast record table smoke"))
       (table   (lightfast:make-record-table
                 :parent window
                 :x      8
                 :y      8
                 :width  304
                 :height 110
                 :columns (list (list :name "Image Name" 130)
                                (list :pid "PID" 60)
                                (list :cpu "CPU" 60
                                      (lambda (value record)
                                        (declare (ignore record))
                                        (format nil "~D%" value))))
                 :records records)))
  (assert (string= "sbcl" (lightfast:table-cell table 0 0)))
  (assert (string= "4%" (lightfast:table-cell table 0 2)))
  (lightfast:table-select-row table 1)
  (assert (eq (second records) (lightfast:table-selected-record table)))
  (assert (lightfast:destroy window)))

(let ((ticks 0)
      (draws 0)
      (window (lightfast:make-window :width 180
                                   :height 112
                                   :label "Lightfast quit smoke")))
  (lightfast:make-canvas :parent window
                       :x      8
                       :y      8
                       :width  164
                       :height 72
                       :callback
                       (lambda (widget event value)
                         (declare (ignore event value))
                         (incf draws)
                         (let ((x (lightfast:widget-x widget))
                               (y (lightfast:widget-y widget)))
                           (lightfast:draw-color-rgb :red 255 :green 255 :blue 255)
                           (lightfast:draw-filled-rect (+ x 2) (+ y 2) 160 68)
                           (lightfast:draw-color-rgb :red 0 :green 0 :blue 128)
                           (lightfast:draw-line (+ x 8) (+ y 54) (+ x 152) (+ y 18))
                           (lightfast:draw-filled-circle (+ x 44) (+ y 34) 10)
                           (lightfast:draw-color-rgb :red 0 :green 0 :blue 0)
                           (lightfast:draw-font :font 0 :size 12)
                           (lightfast:draw-text "Canvas" (+ x 74) (+ y 39)))))
  (lightfast:show window)
  (lightfast:add-timeout 0.01d0
                       (lambda ()
                         (incf ticks)
                         (lightfast:quit))
                       :repeat t)
  (lightfast:run)
  (assert (= ticks 1))
  (assert (plusp draws))
  (assert (lightfast:destroy window)))

(let* ((window (lightfast:make-window :width 260
                                    :height 180
                                    :label "Lightfast geometry cache smoke"))
       (panel  (lightfast:make-panel :parent window
                                   :x      10
                                   :y      20
                                   :width  120
                                   :height 70))
       (button (lightfast:make-button :parent panel
                                    :x      8
                                    :y      10
                                    :width  40
                                    :height 22
                                    :label  "Ok")))
  ;; FLTK and the window manager may mutate child geometry without going
  ;; through the Lisp wrapper. Public layout calls must still repair that.
  (lightfast::%widget-resize (lightfast:widget-id button)
                           10
                           20
                           180
                           44)
  (lightfast:resize-widget button
                         :x      8
                         :y      10
                         :width  40
                         :height 22)
  (lightfast:refresh-geometry button)
  (assert (= 18 (lightfast:widget-x button)))
  (assert (= 30 (lightfast:widget-y button)))
  (assert (= 40 (lightfast:widget-width button)))
  (assert (= 22 (lightfast:widget-height button)))
  ;; The same stale-cache failure can happen to the parent origin. Relative
  ;; child layout must compute against the native parent position, not old Lisp
  ;; slots.
  (lightfast::%widget-resize (lightfast:widget-id panel)
                           40
                           50
                           120
                           70)
  (lightfast:resize-widget button
                         :x      8
                         :y      10
                         :width  42
                         :height 23)
  (lightfast:refresh-geometry button)
  (assert (= 48 (lightfast:widget-x button)))
  (assert (= 60 (lightfast:widget-y button)))
  (assert (= 42 (lightfast:widget-width button)))
  (assert (= 23 (lightfast:widget-height button)))
  (assert (lightfast:destroy window)))

(let* ((window (lightfast:make-window :width 300
                                    :height 200
                                    :label "Lightfast group resize smoke"))
       (panel  (lightfast:make-panel :parent window
                                   :x      10
                                   :y      10
                                   :width  100
                                   :height 100))
       (child  (lightfast:make-box :parent panel
                                 :x      20
                                 :y      20
                                 :width  30
                                 :height 30
                                 :label  "Child")))
  ;; Lightfast layouts own child geometry. Resizing a group must not let FLTK
  ;; scale or move descendants behind Lisp's back.
  (lightfast:resize-widget panel
                         :x      10
                         :y      10
                         :width  150
                         :height 80)
  (lightfast:refresh-geometry child)
  (assert (= 30 (lightfast:widget-x child)))
  (assert (= 30 (lightfast:widget-y child)))
  (assert (= 30 (lightfast:widget-width child)))
  (assert (= 30 (lightfast:widget-height child)))
  (assert (lightfast:destroy window)))

(let* ((window (lightfast:make-window :width 640
                                     :height 480
                                     :label "Lightfast modern widget smoke"))
       (file-input (lightfast:make-file-input :parent window
                                             :x 8 :y 8 :width 180
                                             :value "/tmp/example.raw"))
       (value-output (lightfast:make-value-output :parent window
                                                 :x 196 :y 8 :width 80
                                                 :value "2.5"
                                                 :minimum 0 :maximum 10 :step 0.5))
       (pack (lightfast:make-pack :parent window
                                 :x 8 :y 40 :width 180 :height 80
                                 :orientation :horizontal :spacing 3))
       (grid (lightfast:make-grid :parent window
                                 :x 196 :y 40 :width 180 :height 80
                                 :rows 2 :columns 2 :margin 2
                                 :row-gap 3 :column-gap 4))
       (grid-child (lightfast:make-box :parent grid :label "Cell"))
       (positioner (lightfast:make-positioner :parent window
                                             :x 384 :y 8 :width 100 :height 100
                                             :x-value 0.25 :y-value 0.75
                                             :x-step 0.05 :y-step 0.1))
       (wizard (lightfast:make-wizard :parent window
                                     :x 8 :y 128 :width 180 :height 80))
       (page-one (lightfast:make-group :parent wizard :label "One"))
       (page-two (lightfast:make-group :parent wizard :label "Two"))
       (chart (lightfast:make-chart :parent window
                                   :x 196 :y 128 :width 180 :height 80
                                   :type :line :minimum -1 :maximum 4))
       (scheme (lightfast:make-scheme-choice :parent window
                                            :x 384 :y 116 :width 160))
       (terminal (lightfast:make-terminal :parent window
                                         :x 8 :y 216 :width 368 :height 80
                                         :text (format nil "ready~%")))
       (chooser (lightfast:make-color-chooser :parent window
                                             :x 384 :y 148 :width 195 :height 115
                                             :red 0.25 :green 0.5 :blue 0.75))
       (shortcut (lightfast:make-shortcut-button :parent window
                                                :x 8 :y 304 :width 140
                                                :shortcut 65))
       (browser (lightfast:make-browser :parent window
                                       :x 384 :y 272 :width 195 :height 100
                                       :items '("zero" "one" "two"))))
  (declare (ignore value-output pack page-one scheme))
  (assert (string= "/tmp/example.raw" (lightfast:value file-input)))
  (lightfast:grid-place grid grid-child :row 0 :column 1 :alignment :center)
  (lightfast:grid-set-row-height grid 0 20)
  (lightfast:grid-set-row-weight grid 1 2)
  (lightfast:grid-set-column-width grid 0 40)
  (lightfast:grid-set-column-weight grid 1 3)
  (multiple-value-bind (x y) (lightfast:positioner-values positioner)
    (assert (< (abs (- x 0.25d0)) 1.0d-9))
    (assert (< (abs (- y 0.75d0)) 1.0d-9)))
  (lightfast:positioner-set-bounds positioner
                                   :x-minimum -1 :x-maximum 1
                                   :y-minimum -2 :y-maximum 2)
  (lightfast:positioner-set-value positioner :x -0.5 :y 1.5)
  (setf (lightfast:wizard-current-child wizard) page-two)
  (assert (= (lightfast:widget-id page-two)
             (lightfast:wizard-current-child wizard)))
  (lightfast:wizard-previous wizard)
  (lightfast:wizard-next wizard)
  (lightfast:chart-add chart 1.0 :label "one")
  (lightfast:chart-add chart 3.0 :label "three")
  (lightfast:chart-insert chart 1 2.0 :label "two")
  (lightfast:chart-replace chart 0 1.5 :label "one and a half")
  (lightfast:chart-set-type chart :filled)
  (lightfast:chart-clear chart)
  (lightfast:terminal-append terminal (format nil "done~%"))
  (assert (search "ready" (lightfast:terminal-text terminal)))
  (lightfast:terminal-clear terminal)
  (assert (null (search "ready" (lightfast:terminal-text terminal))))
  (multiple-value-bind (red green blue) (lightfast:color-chooser-rgb chooser)
    (assert (< (abs (- red 0.25d0)) 1.0d-9))
    (assert (< (abs (- green 0.5d0)) 1.0d-9))
    (assert (< (abs (- blue 0.75d0)) 1.0d-9)))
  (setf (lightfast:shortcut-button-shortcut shortcut) 66)
  (assert (= 66 (lightfast:shortcut-button-shortcut shortcut)))
  (lightfast:browser-set-selection-mode browser :multiple)
  (lightfast:browser-set-selected-p browser 0 t)
  (lightfast:browser-set-selected-p browser 2 t)
  (assert (equal '(0 2) (lightfast:browser-selected-indices browser)))
  (lightfast:browser-set-selected-p browser 0 nil)
  (assert (equal '(2) (lightfast:browser-selected-indices browser)))
  (assert (handler-case
              (progn
                (lightfast:browser-set-selection-mode browser :legacy)
                nil)
            (error () t)))
  (assert (lightfast:destroy window)))

(format t "~&Lightfast smoke test passed.~%")
