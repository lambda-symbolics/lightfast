(require :asdf)
(asdf:load-system :lightfast)

(defpackage #:lightfast-demo
  (:use #:cl)
  (:export #:main))

(in-package #:lightfast-demo)

(defun add-log-line (browser text)
  (lightfast:add-item browser text)
  (lightfast:browser-select browser 0))

(defun widget-int-value (widget)
  (or (parse-integer (lightfast:value widget) :junk-allowed t)
      0))

(defun draw-demo-canvas (widget event value)
  (declare (ignore event value))
  (let* ((x       (lightfast:widget-x widget))
         (y       (lightfast:widget-y widget))
         (width   (lightfast:widget-width widget))
         (height  (lightfast:widget-height widget))
         (left    (+ x 2))
         (top     (+ y 2))
         (right   (- (+ x width) 3))
         (bottom  (- (+ y height) 3))
         (center-x (floor (+ left right) 2))
         (center-y (floor (+ top bottom) 2))
         (radius   (max 18 (min 64 (floor (min (- right left)
                                             (- bottom top))
                                         3)))))
    (lightfast:draw-color-rgb :red 255 :green 255 :blue 255)
    (lightfast:draw-filled-rect left top (max 0 (- right left)) (max 0 (- bottom top)))
    (lightfast:draw-color-rgb :red 224 :green 224 :blue 224)
    (loop for gx from (+ left 12) below right by 24 do
      (lightfast:draw-line gx top gx bottom))
    (loop for gy from (+ top 12) below bottom by 24 do
      (lightfast:draw-line left gy right gy))
    (lightfast:draw-color-rgb :red 0 :green 0 :blue 128)
    (lightfast:draw-circle center-x center-y radius)
    (lightfast:draw-line (- center-x radius) center-y (+ center-x radius) center-y)
    (lightfast:draw-line center-x (- center-y radius) center-x (+ center-y radius))
    (lightfast:draw-color-rgb :red 255 :green 207 :blue 64)
    (lightfast:draw-filled-circle center-x center-y 10)
    (lightfast:draw-color-rgb :red 96 :green 160 :blue 255)
    (lightfast:draw-filled-circle (+ center-x radius) center-y 6)
    (lightfast:draw-color-rgb :red 0 :green 0 :blue 0)
    (lightfast:draw-font :font 0 :size 12)
    (lightfast:draw-text "Lisp draw callback" (+ left 8) (- bottom 8))))

(defun layout-demo (window widgets)
  (let* ((width           (max 480 (lightfast:widget-width window)))
         (height          (max 520 (lightfast:widget-height window)))
         (margin          12)
         (gap             10)
         (panel-gap       18)
         (panel-title-h   24)
         (menu-height     24)
         (status-h        24)
         (status-y        (- height margin status-h))
         (content-w       (max 360 (- width (* 2 margin))))
         (tabs-y          40)
         (tab-head-h      26)
         (min-log-h       110)
         (tabs-h          (min 320
                                (max 280
                                     (- status-y tabs-y panel-gap gap min-log-h))))
         (page-w          content-w)
         (page-h          (max 220 (- tabs-h tab-head-h)))
         (panel-w         (max 160 (- page-w 24)))
         (panel-h         (max 206 (- page-h 24)))
         (button-y        (max 162 (- panel-h 42)))
         (log-y           (+ tabs-y tabs-h panel-gap))
         (log-top         36)
         (log-h           (max min-log-h (- status-y log-y gap)))
         (right-x         (max 250 (floor panel-w 2)))
         (right-w         (max 120 (- panel-w right-x 18)))
         (menu            (getf widgets :menu))
         (tabs            (getf widgets :tabs))
         (record-tab      (getf widgets :record-tab))
         (controls-tab    (getf widgets :controls-tab))
         (catalog-tab     (getf widgets :catalog-tab))
         (text-tab        (getf widgets :text-tab))
         (more-tab        (getf widgets :more-tab))
         (canvas-tab      (getf widgets :canvas-tab))
         (advanced-tab    (getf widgets :advanced-tab))
         (tasks-tab       (getf widgets :tasks-tab))
         (record-panel    (getf widgets :record-panel))
         (controls-panel  (getf widgets :controls-panel))
         (catalog-panel   (getf widgets :catalog-panel))
         (text-panel      (getf widgets :text-panel))
         (more-panel      (getf widgets :more-panel))
         (canvas-panel    (getf widgets :canvas-panel))
         (advanced-panel  (getf widgets :advanced-panel))
         (tasks-panel     (getf widgets :tasks-panel))
         (name            (getf widgets :name))
         (state           (getf widgets :state))
         (interval        (getf widgets :interval))
         (save-button     (getf widgets :save-button))
         (copy-button     (getf widgets :copy-button))
         (enabled         (getf widgets :enabled))
         (light-button    (getf widgets :light-button))
         (radio-email     (getf widgets :radio-email))
         (radio-phone     (getf widgets :radio-phone))
         (slider-label    (getf widgets :slider-label))
         (meter-slider    (getf widgets :meter-slider))
         (progress-label  (getf widgets :progress-label))
         (meter-progress  (getf widgets :meter-progress))
         (counter-label   (getf widgets :counter-label))
         (counter         (getf widgets :counter))
         (spinner-label   (getf widgets :spinner-label))
         (spinner         (getf widgets :spinner))
         (dial-label      (getf widgets :dial-label))
         (dial            (getf widgets :dial))
         (roller-label    (getf widgets :roller-label))
         (roller          (getf widgets :roller))
         (tree-label      (getf widgets :tree-label))
         (tree            (getf widgets :tree))
         (secret-label    (getf widgets :secret-label))
         (secret-input    (getf widgets :secret-input))
         (int-label       (getf widgets :int-label))
         (int-input       (getf widgets :int-input))
         (float-label     (getf widgets :float-label))
         (float-input     (getf widgets :float-input))
         (clock-label     (getf widgets :clock-label))
         (clock           (getf widgets :clock))
         (editor-label    (getf widgets :editor-label))
         (text-editor     (getf widgets :text-editor))
         (help-label      (getf widgets :help-label))
         (help-view       (getf widgets :help-view))
         (toggle-button   (getf widgets :toggle-button))
         (return-button   (getf widgets :return-button))
         (repeat-button   (getf widgets :repeat-button))
         (value-label     (getf widgets :value-label))
         (value-slider    (getf widgets :value-slider))
         (scrollbar-label (getf widgets :scrollbar-label))
         (scrollbar       (getf widgets :scrollbar))
         (adjuster-label  (getf widgets :adjuster-label))
         (adjuster        (getf widgets :adjuster))
         (demo-canvas     (getf widgets :demo-canvas))
         (action-menu     (getf widgets :action-menu))
         (source-field    (getf widgets :source-field))
         (check-list      (getf widgets :check-list))
         (file-list       (getf widgets :file-list))
         (transport-flex  (getf widgets :transport-flex))
         (play-button     (getf widgets :play-button))
         (track-output    (getf widgets :track-output))
         (process-table   (getf widgets :process-table))
         (end-task-button (getf widgets :end-task-button))
         (refresh-button  (getf widgets :refresh-button))
         (log-panel       (getf widgets :log-panel))
         (log-list        (getf widgets :log-list))
         (status          (getf widgets :status)))
    (lightfast:resize-widget menu
                            :x      0
                            :y      0
                            :width  width
                            :height menu-height)
    (lightfast:resize-widget tabs
                            :x      margin
                            :y      tabs-y
                            :width  content-w
                            :height tabs-h)
    (dolist (page (list record-tab controls-tab catalog-tab text-tab more-tab canvas-tab advanced-tab tasks-tab))
      (lightfast:resize-widget page
                              :x      0
                              :y      tab-head-h
                              :width  page-w
                              :height page-h))
    (lightfast:resize-widget record-panel
                            :x      12
                            :y      12
                            :width  panel-w
                            :height panel-h)
    (lightfast:resize-field name
                           :x           18
                           :y           (+ panel-title-h 18)
                           :width       (- panel-w 36)
                           :label-width 92)
    (lightfast:resize-field state
                           :x           18
                           :y           (+ panel-title-h 56)
                           :width       (- panel-w 36)
                           :label-width 92)
    (lightfast:resize-field interval
                           :x           18
                           :y           (+ panel-title-h 94)
                           :width       (min 280 (- panel-w 36))
                           :label-width 92)
    (lightfast:resize-widget save-button
                            :x      (max 18 (- panel-w 190))
                            :y      button-y
                            :width  82
                            :height 28)
    (lightfast:resize-widget copy-button
                            :x      (max 108 (- panel-w 100))
                            :y      button-y
                            :width  82
                            :height 28)
    (lightfast:resize-widget controls-panel
                            :x      12
                            :y      12
                            :width  panel-w
                            :height panel-h)
    (lightfast:resize-widget enabled
                            :x      18
                            :y      (+ panel-title-h 20)
                            :width  112
                            :height 24)
    (lightfast:resize-widget light-button
                            :x      152
                            :y      (+ panel-title-h 20)
                            :width  132
                            :height 24)
    (lightfast:resize-widget radio-email
                            :x      18
                            :y      (+ panel-title-h 58)
                            :width  124
                            :height 24)
    (lightfast:resize-widget radio-phone
                            :x      152
                            :y      (+ panel-title-h 58)
                            :width  124
                            :height 24)
    (lightfast:resize-widget slider-label
                            :x      18
                            :y      (+ panel-title-h 98)
                            :width  92
                            :height 24)
    (lightfast:resize-widget meter-slider
                            :x      118
                            :y      (+ panel-title-h 98)
                            :width  (max 80 (- panel-w 144))
                            :height 24)
    (lightfast:resize-widget progress-label
                            :x      18
                            :y      (+ panel-title-h 136)
                            :width  92
                            :height 24)
    (lightfast:resize-widget meter-progress
                            :x      118
                            :y      (+ panel-title-h 138)
                            :width  (max 80 (- panel-w 144))
                            :height 22)
    (lightfast:resize-widget catalog-panel
                            :x      12
                            :y      12
                            :width  panel-w
                            :height panel-h)
    (lightfast:resize-widget counter-label
                            :x      18
                            :y      (+ panel-title-h 20)
                            :width  86
                            :height 24)
    (lightfast:resize-widget counter
                            :x      112
                            :y      (+ panel-title-h 20)
                            :width  124
                            :height 24)
    (lightfast:resize-widget spinner-label
                            :x      18
                            :y      (+ panel-title-h 58)
                            :width  86
                            :height 24)
    (lightfast:resize-widget spinner
                            :x      112
                            :y      (+ panel-title-h 58)
                            :width  124
                            :height 24)
    (lightfast:resize-widget dial-label
                            :x      18
                            :y      (+ panel-title-h 106)
                            :width  86
                            :height 24)
    (lightfast:resize-widget dial
                            :x      112
                            :y      (+ panel-title-h 94)
                            :width  58
                            :height 58)
    (lightfast:resize-widget roller-label
                            :x      18
                            :y      (+ panel-title-h 170)
                            :width  86
                            :height 24)
    (lightfast:resize-widget roller
                            :x      112
                            :y      (+ panel-title-h 170)
                            :width  124
                            :height 24)
    (lightfast:resize-widget tree-label
                            :x      right-x
                            :y      (+ panel-title-h 20)
                            :width  right-w
                            :height 24)
    (lightfast:resize-widget tree
                            :x      right-x
                            :y      (+ panel-title-h 48)
                            :width  right-w
                            :height (max 88 (- panel-h panel-title-h 66)))
    (lightfast:resize-widget text-panel
                            :x      12
                            :y      12
                            :width  panel-w
                            :height panel-h)
    (lightfast:resize-widget secret-label
                            :x      18
                            :y      (+ panel-title-h 20)
                            :width  86
                            :height 24)
    (lightfast:resize-widget secret-input
                            :x      112
                            :y      (+ panel-title-h 20)
                            :width  124
                            :height 24)
    (lightfast:resize-widget int-label
                            :x      18
                            :y      (+ panel-title-h 58)
                            :width  86
                            :height 24)
    (lightfast:resize-widget int-input
                            :x      112
                            :y      (+ panel-title-h 58)
                            :width  124
                            :height 24)
    (lightfast:resize-widget float-label
                            :x      18
                            :y      (+ panel-title-h 96)
                            :width  86
                            :height 24)
    (lightfast:resize-widget float-input
                            :x      112
                            :y      (+ panel-title-h 96)
                            :width  124
                            :height 24)
    (lightfast:resize-widget clock-label
                            :x      18
                            :y      (+ panel-title-h 150)
                            :width  86
                            :height 24)
    (lightfast:resize-widget clock
                            :x      112
                            :y      (+ panel-title-h 136)
                            :width  58
                            :height 58)
    (lightfast:resize-widget editor-label
                            :x      right-x
                            :y      (+ panel-title-h 20)
                            :width  right-w
                            :height 24)
    (lightfast:resize-widget text-editor
                            :x      right-x
                            :y      (+ panel-title-h 48)
                            :width  right-w
                            :height 68)
    (lightfast:resize-widget help-label
                            :x      right-x
                            :y      (+ panel-title-h 126)
                            :width  right-w
                            :height 24)
    (lightfast:resize-widget help-view
                            :x      right-x
                            :y      (+ panel-title-h 154)
                            :width  right-w
                            :height (max 42 (- panel-h panel-title-h 172)))
    (lightfast:resize-widget more-panel
                            :x      12
                            :y      12
                            :width  panel-w
                            :height panel-h)
    (lightfast:resize-widget toggle-button
                            :x      18
                            :y      (+ panel-title-h 20)
                            :width  90
                            :height 28)
    (lightfast:resize-widget return-button
                            :x      118
                            :y      (+ panel-title-h 20)
                            :width  90
                            :height 28)
    (lightfast:resize-widget repeat-button
                            :x      218
                            :y      (+ panel-title-h 20)
                            :width  90
                            :height 28)
    (lightfast:resize-widget value-label
                            :x      18
                            :y      (+ panel-title-h 68)
                            :width  92
                            :height 24)
    (lightfast:resize-widget value-slider
                            :x      118
                            :y      (+ panel-title-h 68)
                            :width  (max 160 (- panel-w 144))
                            :height 24)
    (lightfast:resize-widget scrollbar-label
                            :x      18
                            :y      (+ panel-title-h 106)
                            :width  92
                            :height 24)
    (lightfast:resize-widget scrollbar
                            :x      118
                            :y      (+ panel-title-h 109)
                            :width  (max 160 (- panel-w 144))
                            :height 18)
    (lightfast:resize-widget adjuster-label
                            :x      18
                            :y      (+ panel-title-h 144)
                            :width  92
                            :height 24)
    (lightfast:resize-widget adjuster
                            :x      118
                            :y      (+ panel-title-h 144)
                            :width  150
                            :height 24)
    (lightfast:resize-widget canvas-panel
                            :x      12
                            :y      12
                            :width  panel-w
                            :height panel-h)
    (lightfast:resize-widget demo-canvas
                            :x      18
                            :y      (+ panel-title-h 20)
                            :width  (max 120 (- panel-w 36))
                            :height (max 120 (- panel-h panel-title-h 40)))
    (lightfast:resize-widget advanced-panel
                            :x      12
                            :y      12
                            :width  panel-w
                            :height panel-h)
    (lightfast:resize-widget action-menu
                            :x      18
                            :y      (+ panel-title-h 20)
                            :width  104
                            :height 26)
    (lightfast:resize-field source-field
                           :x           142
                           :y           (+ panel-title-h 21)
                           :width       (max 180 (- panel-w 160))
                           :label-width 64)
    (lightfast:resize-widget check-list
                            :x      18
                            :y      (+ panel-title-h 62)
                            :width  (max 180 (- (floor panel-w 2) 28))
                            :height (max 90 (- panel-h panel-title-h 112)))
    (lightfast:resize-widget file-list
                            :x      right-x
                            :y      (+ panel-title-h 62)
                            :width  right-w
                            :height (max 90 (- panel-h panel-title-h 112)))
    (lightfast:resize-widget transport-flex
                            :x      18
                            :y      (max (+ panel-title-h 168) (- panel-h 42))
                            :width  (max 240 (- panel-w 36))
                            :height 30)
    (lightfast:flex-fixed transport-flex play-button 76)
    (lightfast:flex-layout transport-flex)
    (lightfast:refresh-geometry track-output)
    (lightfast:resize-widget tasks-panel
                            :x      12
                            :y      12
                            :width  panel-w
                            :height panel-h)
    (lightfast:resize-widget process-table
                            :x      18
                            :y      (+ panel-title-h 20)
                            :width  (- panel-w 36)
                            :height (max 124 (- panel-h panel-title-h 86)))
    (lightfast:resize-widget end-task-button
                            :x      (max 18 (- panel-w 190))
                            :y      (max (+ panel-title-h 156) (- panel-h 42))
                            :width  82
                            :height 28)
    (lightfast:resize-widget refresh-button
                            :x      (max 108 (- panel-w 100))
                            :y      (max (+ panel-title-h 156) (- panel-h 42))
                            :width  82
                            :height 28)
    (lightfast:resize-widget log-panel
                            :x      margin
                            :y      log-y
                            :width  content-w
                            :height log-h)
    (lightfast:resize-widget log-list
                            :x      12
                            :y      log-top
                            :width  (max 80 (- content-w 24))
                            :height (max 24 (- log-h (+ log-top 12))))
    (lightfast:resize-widget status
                            :x      margin
                            :y      status-y
                            :width  content-w
                            :height status-h)
    window))

(defvar *demo-timer-id* nil)

(defun cleanup-demo ()
  (when *demo-timer-id*
    (ignore-errors
      (lightfast:remove-timeout *demo-timer-id*))
    (setf *demo-timer-id* nil)))

(defun main ()
  (let (widgets)
    (lightfast:with-window (window :width 560
                                 :height 560
                                 :label "Lightfast Classic Demo"
                                 :show nil)
      (lightfast:set-size-range window
                              :min-width  480
                              :min-height 520)
      (let* ((menu            (lightfast:make-menu-bar :x      0
                                                     :y      0
                                                     :width  560
                                                     :height 24))
             (tabs            (lightfast:make-tabs :x      12
                                                 :y      40
                                                 :width  536
                                                 :height 320))
             (record-tab      (lightfast:make-tab-page :parent tabs
                                                      :x      0
                                                      :y      26
                                                      :width  536
                                                      :height 294
                                                      :label  "Entry"))
             (controls-tab    (lightfast:make-tab-page :parent tabs
                                                      :x      0
                                                      :y      26
                                                      :width  536
                                                      :height 294
                                                      :label  "Controls"))
             (catalog-tab     (lightfast:make-tab-page :parent tabs
                                                      :x      0
                                                      :y      26
                                                      :width  536
                                                      :height 294
                                                      :label  "Catalog"))
             (text-tab        (lightfast:make-tab-page :parent tabs
                                                      :x      0
                                                      :y      26
                                                      :width  536
                                                      :height 294
                                                      :label  "Text"))
             (more-tab        (lightfast:make-tab-page :parent tabs
                                                      :x      0
                                                      :y      26
                                                      :width  536
                                                      :height 294
                                                      :label  "More"))
             (canvas-tab      (lightfast:make-tab-page :parent tabs
                                                      :x      0
                                                      :y      26
                                                      :width  536
                                                      :height 294
                                                      :label  "Canvas"))
             (advanced-tab    (lightfast:make-tab-page :parent tabs
                                                      :x      0
                                                      :y      26
                                                      :width  536
                                                      :height 294
                                                      :label  "Advanced"))
             (tasks-tab       (lightfast:make-tab-page :parent tabs
                                                      :x      0
                                                      :y      26
                                                      :width  536
                                                      :height 294
                                                      :label  "Tasks"))
             (record-panel    nil)
             (controls-panel  nil)
             (catalog-panel   nil)
             (text-panel      nil)
             (more-panel      nil)
             (canvas-panel    nil)
             (advanced-panel  nil)
             (tasks-panel     nil)
             (name            nil)
             (state           nil)
             (interval        nil)
             (save-button     nil)
             (copy-button     nil)
             (enabled         nil)
             (light-button    nil)
             (radio-email     nil)
             (radio-phone     nil)
             (slider-label    nil)
             (meter-slider    nil)
             (progress-label  nil)
             (meter-progress  nil)
             (counter-label   nil)
             (counter         nil)
             (spinner-label   nil)
             (spinner         nil)
             (dial-label      nil)
             (dial            nil)
             (roller-label    nil)
             (roller          nil)
             (tree-label      nil)
             (tree            nil)
             (secret-label    nil)
             (secret-input    nil)
             (int-label       nil)
             (int-input       nil)
             (float-label     nil)
             (float-input     nil)
             (clock-label     nil)
             (clock           nil)
             (editor-label    nil)
             (text-editor     nil)
             (help-label      nil)
             (help-view       nil)
             (toggle-button   nil)
             (return-button   nil)
             (repeat-button   nil)
             (value-label     nil)
             (value-slider    nil)
             (scrollbar-label nil)
             (scrollbar       nil)
             (adjuster-label  nil)
             (adjuster        nil)
             (demo-canvas     nil)
             (action-menu     nil)
             (source-field    nil)
             (check-list      nil)
             (file-list       nil)
             (transport-flex  nil)
             (play-button     nil)
             (track-output    nil)
             (process-table   nil)
             (end-task-button nil)
             (refresh-button  nil)
             (log-panel       nil)
             (log-list        nil)
             (status          nil))
        (lightfast:with-parent (record-tab)
          (setf record-panel (lightfast:make-panel :x      12
                                                 :y      12
                                                 :width  512
                                                 :height 270
                                                 :label  "Record"))
          (lightfast:with-parent (record-panel)
            (setf name (lightfast:make-labeled-input :x           18
                                                   :y           42
                                                   :width       476
                                                   :label       "Name:"
                                                   :label-width 92
                                                   :value       "Gymnasium"))
            (setf state (lightfast:make-labeled-choice :x           18
                                                     :y           80
                                                     :width       476
                                                     :label       "State:"
                                                     :label-width 92
                                                     :items       '("Research"
                                                                    "Contacted"
                                                                    "Meeting"
                                                                    "Won")))
            (setf interval (lightfast:make-labeled-value-input :x           18
                                                            :y           118
                                                            :width       248
                                                            :label       "Every:"
                                                            :label-width 92
                                                            :value       "1"))
            (setf save-button
                  (lightfast:make-button :x      322
                                       :y      228
                                       :width  82
                                       :height 28
                                       :label  "Save"))
            (setf copy-button
                  (lightfast:make-button :x      412
                                       :y      228
                                       :width  82
                                       :height 28
                                       :label  "Copy"))))
        (lightfast:with-parent (controls-tab)
          (setf controls-panel (lightfast:make-panel :x      12
                                                   :y      12
                                                   :width  512
                                                   :height 270
                                                   :label  "Classic Controls"))
          (lightfast:with-parent (controls-panel)
            (setf enabled (lightfast:make-check-button :x      18
                                                     :y      44
                                                     :width  112
                                                     :height 24
                                                     :label  "Enabled"))
            (setf light-button (lightfast:make-light-button :x      152
                                                          :y      44
                                                          :width  132
                                                          :height 24
                                                          :label  "Notify"))
            (setf radio-email (lightfast:make-radio-button :x      18
                                                         :y      82
                                                         :width  124
                                                         :height 24
                                                         :label  "Email"))
            (setf radio-phone (lightfast:make-radio-button :x      152
                                                         :y      82
                                                         :width  124
                                                         :height 24
                                                         :label  "Phone"))
            (setf (lightfast:value radio-email) "1")
            (setf slider-label (lightfast:make-label :x      18
                                                   :y      122
                                                   :width  92
                                                   :height 24
                                                   :label  "Level:"))
            (setf meter-slider (lightfast:make-slider :x      118
                                                    :y      122
                                                    :width  368
                                                    :height 24
                                                    :value  "50"))
            (lightfast:set-range meter-slider 0 100)
            (setf progress-label (lightfast:make-label :x      18
                                                     :y      160
                                                     :width  92
                                                     :height 24
                                                     :label  "Progress:"))
            (setf meter-progress (lightfast:make-progress :x      118
                                                        :y      162
                                                        :width  368
                                                        :height 22
                                                        :value  "50"))
            (lightfast:set-range meter-progress 0 100)))
        (lightfast:with-parent (catalog-tab)
          (setf catalog-panel (lightfast:make-panel :x      12
                                                  :y      12
                                                  :width  512
                                                  :height 270
                                                  :label  "Widget Catalog"))
          (lightfast:with-parent (catalog-panel)
            (setf counter-label (lightfast:make-label :x      18
                                                    :y      44
                                                    :width  86
                                                    :height 24
                                                    :label  "Counter:"))
            (setf counter (lightfast:make-counter :x      112
                                                :y      44
                                                :width  124
                                                :height 24
                                                :value  "2"))
            (lightfast:set-range counter 0 20)
            (lightfast:set-step counter 1)
            (setf spinner-label (lightfast:make-label :x      18
                                                    :y      82
                                                    :width  86
                                                    :height 24
                                                    :label  "Spinner:"))
            (setf spinner (lightfast:make-spinner :x      112
                                                :y      82
                                                :width  124
                                                :height 24
                                                :value  "3"))
            (lightfast:set-range spinner 0 20)
            (lightfast:set-step spinner 1)
            (setf dial-label (lightfast:make-label :x      18
                                                 :y      130
                                                 :width  86
                                                 :height 24
                                                 :label  "Dial:"))
            (setf dial (lightfast:make-dial :x      112
                                          :y      118
                                          :width  58
                                          :height 58
                                          :value  "40"))
            (lightfast:set-range dial 0 100)
            (setf roller-label (lightfast:make-label :x      18
                                                   :y      194
                                                   :width  86
                                                   :height 24
                                                   :label  "Roller:"))
            (setf roller (lightfast:make-roller :x      112
                                              :y      194
                                              :width  124
                                              :height 24
                                              :value  "60"))
            (lightfast:set-range roller 0 100)
            (setf tree-label (lightfast:make-label :x      256
                                                 :y      44
                                                 :width  238
                                                 :height 24
                                                 :label  "Tree:"))
            (setf tree (lightfast:make-tree :x      256
                                          :y      72
                                          :width  238
                                          :height 180
                                          :items  '("Application/Windows"
                                                    "Application/Menus"
                                                    "Application/Dialogs"
                                                    "Data/Tree Items"
                                                    "Data/Lists"
                                                    "Data/Timers")))
            (setf (lightfast:value tree) "Application/Windows")))
        (lightfast:with-parent (text-tab)
          (setf text-panel (lightfast:make-panel :x      12
                                               :y      12
                                               :width  512
                                               :height 270
                                               :label  "Text Widgets"))
          (lightfast:with-parent (text-panel)
            (setf secret-label (lightfast:make-label :x      18
                                                   :y      44
                                                   :width  86
                                                   :height 24
                                                   :label  "Secret:"))
            (setf secret-input (lightfast:make-secret-input :x      112
                                                          :y      44
                                                          :width  124
                                                          :height 24
                                                          :value  "hidden"))
            (setf int-label (lightfast:make-label :x      18
                                                :y      82
                                                :width  86
                                                :height 24
                                                :label  "Integer:"))
            (setf int-input (lightfast:make-int-input :x      112
                                                    :y      82
                                                    :width  124
                                                    :height 24
                                                    :value  "12"))
            (setf float-label (lightfast:make-label :x      18
                                                  :y      120
                                                  :width  86
                                                  :height 24
                                                  :label  "Float:"))
            (setf float-input (lightfast:make-float-input :x      112
                                                        :y      120
                                                        :width  124
                                                        :height 24
                                                        :value  "3.5"))
            (setf clock-label (lightfast:make-label :x      18
                                                  :y      174
                                                  :width  86
                                                  :height 24
                                                  :label  "Clock:"))
            (setf clock (lightfast:make-clock :x      112
                                            :y      160
                                            :width  58
                                            :height 58))
            (setf editor-label (lightfast:make-label :x      256
                                                   :y      44
                                                   :width  238
                                                   :height 24
                                                   :label  "Editor:"))
            (setf text-editor (lightfast:make-text-editor :x      256
                                                        :y      72
                                                        :width  238
                                                        :height 68
                                                        :value  "Editable text from Lisp."))
            (setf help-label (lightfast:make-label :x      256
                                                 :y      150
                                                 :width  238
                                                 :height 24
                                                 :label  "Help View:"))
            (setf help-view (lightfast:make-help-view :x      256
                                                    :y      178
                                                    :width  238
                                                    :height 74
                                                    :value  "<b>Lightfast</b><br>HTML-ish help text."))))
        (lightfast:with-parent (more-tab)
          (setf more-panel (lightfast:make-panel :x      12
                                               :y      12
                                               :width  512
                                               :height 270
                                               :label  "More Widgets"))
          (lightfast:with-parent (more-panel)
            (setf toggle-button (lightfast:make-toggle-button :x      18
                                                            :y      44
                                                            :width  90
                                                            :height 28
                                                            :label  "Toggle"))
            (setf return-button (lightfast:make-return-button :x      118
                                                            :y      44
                                                            :width  90
                                                            :height 28
                                                            :label  "Return"))
            (setf repeat-button (lightfast:make-repeat-button :x      218
                                                            :y      44
                                                            :width  90
                                                            :height 28
                                                            :label  "Repeat"))
            (setf value-label (lightfast:make-label :x      18
                                                  :y      92
                                                  :width  92
                                                  :height 24
                                                  :label  "Value:"))
            (setf value-slider (lightfast:make-value-slider :x      118
                                                          :y      92
                                                          :width  368
                                                          :height 24
                                                          :value  "45"))
            (lightfast:set-range value-slider 0 100)
            (setf scrollbar-label (lightfast:make-label :x      18
                                                      :y      130
                                                      :width  92
                                                      :height 24
                                                      :label  "Scroll:"))
            (setf scrollbar (lightfast:make-scrollbar :x      118
                                                    :y      133
                                                    :width  368
                                                    :height 18
                                                    :value  "25"))
            (lightfast:set-range scrollbar 0 100)
            (setf adjuster-label (lightfast:make-label :x      18
                                                     :y      168
                                                     :width  92
                                                     :height 24
                                                     :label  "Adjuster:"))
            (setf adjuster (lightfast:make-adjuster :x      118
                                                  :y      168
                                                  :width  150
                                                  :height 24
                                                  :value  "12"))
            (lightfast:set-range adjuster 0 100)
            (lightfast:set-step adjuster 1)))
        (lightfast:with-parent (canvas-tab)
          (setf canvas-panel (lightfast:make-panel :x      12
                                                 :y      12
                                                 :width  512
                                                 :height 270
                                                 :label  "Drawing Surface"))
          (lightfast:with-parent (canvas-panel)
            (setf demo-canvas (lightfast:make-canvas :x        18
                                                   :y        44
                                                   :width    476
                                                   :height   204
                                                   :callback #'draw-demo-canvas))))
        (lightfast:with-parent (advanced-tab)
          (setf advanced-panel (lightfast:make-panel :x      12
                                                   :y      12
                                                   :width  512
                                                   :height 270
                                                   :label  "Advanced Widgets"))
          (lightfast:with-parent (advanced-panel)
            (setf action-menu
                  (lightfast:make-menu-button
                   :x      18
                   :y      44
                   :width  104
                   :height 26
                   :label  "Actions"
                   :items  (list
                            (list "&Files"
                                  (list "&Reload"
                                        (lambda (widget path)
                                          (declare (ignore widget path))
                                          (when file-list
                                            (lightfast:file-browser-load file-list "."))
                                          (setf (lightfast:value status) "File list reloaded.")))
                                  (list "&Clear Checks"
                                        (lambda (widget path)
                                          (declare (ignore widget path))
                                          (when check-list
                                            (lightfast:check-browser-check-none check-list))
                                          (setf (lightfast:value status) "Checklist cleared.")))))))
            (setf source-field
                  (lightfast:make-labeled-control :input-choice
                                                :x           142
                                                :y           45
                                                :width       350
                                                :label       "Source:"
                                                :label-width 64
                                                :items       '("Playlist" "Directory" "Stream")
                                                :value       "Directory"))
            (setf check-list (lightfast:make-check-browser :x      18
                                                         :y      86
                                                         :width  218
                                                         :height 118
                                                         :items  '(("Show user processes" t)
                                                                   ("Show services" t)
                                                                   ("Follow changes" nil))))
            (setf file-list (lightfast:make-file-browser :x         256
                                                       :y         86
                                                       :width     238
                                                       :height    118
                                                       :directory "."
                                                       :filter    "*.lisp"
                                                       :filetype  :files))
            (setf transport-flex (lightfast:make-flex :x           18
                                                    :y           224
                                                    :width       476
                                                    :height      30
                                                    :orientation :horizontal
                                                    :gap         6
                                                    :margin      2))
            (lightfast:with-parent (transport-flex)
              (setf play-button (lightfast:make-button :width 76
                                                     :height 26
                                                     :label "Play"))
              (setf track-output (lightfast:make-output :width 380
                                                      :height 26
                                                      :value "No track loaded")))
            (lightfast:flex-fixed transport-flex play-button 76)
            (lightfast:flex-layout transport-flex)))
        (lightfast:with-parent (tasks-tab)
          (setf tasks-panel (lightfast:make-panel :x      12
                                                :y      12
                                                :width  512
                                                :height 270
                                                :label  "Task Manager"))
          (lightfast:with-parent (tasks-panel)
            (setf process-table (lightfast:make-table :x      18
                                                    :y      44
                                                    :width  476
                                                    :height 166
                                                    :columns '("Image Name"
                                                               "PID"
                                                               "CPU"
                                                               "Memory"
                                                               "Status")
                                                    :column-widths '(150 58 58 82 96)
                                                    :rows    '(("sbcl" "2847" "4%" "180 MB" "Running")
                                                               ("Xwayland" "1722" "1%" "92 MB" "Running")
                                                               ("niri" "1010" "2%" "64 MB" "Running")
                                                               ("demo.exe" "4001" "0%" "12 MB" "Idle"))))
            (lightfast:table-select-row process-table 0)
            (setf end-task-button
                  (lightfast:make-button :x      322
                                       :y      228
                                       :width  82
                                       :height 28
                                       :label  "End Task"))
            (setf refresh-button
                  (lightfast:make-button :x      412
                                       :y      228
                                       :width  82
                                       :height 28
                                       :label  "Refresh"))))
        (setf log-panel (lightfast:make-panel :x      12
                                            :y      378
                                            :width  536
                                            :height 126
                                            :label  "Event Log"))
        (lightfast:with-parent (log-panel)
          (setf log-list (lightfast:make-browser :x      12
                                               :y      36
                                               :width  512
                                               :height 78)))
        (setf status (lightfast:make-status-bar :x     12
                                              :y     524
                                              :width 536
                                              :value "Ready"))
        (setf widgets (list :menu           menu
                            :tabs           tabs
                            :record-tab     record-tab
                            :controls-tab   controls-tab
                            :catalog-tab    catalog-tab
                            :text-tab       text-tab
                            :more-tab       more-tab
                            :canvas-tab     canvas-tab
                            :advanced-tab   advanced-tab
                            :tasks-tab      tasks-tab
                            :record-panel   record-panel
                            :controls-panel controls-panel
                            :catalog-panel  catalog-panel
                            :text-panel     text-panel
                            :more-panel     more-panel
                            :canvas-panel   canvas-panel
                            :advanced-panel advanced-panel
                            :tasks-panel    tasks-panel
                            :name           name
                            :state          state
                            :interval       interval
                            :save-button    save-button
                            :copy-button    copy-button
                            :enabled        enabled
                            :light-button   light-button
                            :radio-email    radio-email
                            :radio-phone    radio-phone
                            :slider-label   slider-label
                            :meter-slider   meter-slider
                            :progress-label progress-label
                            :meter-progress meter-progress
                            :counter-label  counter-label
                            :counter        counter
                            :spinner-label  spinner-label
                            :spinner        spinner
                            :dial-label     dial-label
                            :dial           dial
                            :roller-label   roller-label
                            :roller         roller
                            :tree-label     tree-label
                            :tree           tree
                            :secret-label   secret-label
                            :secret-input   secret-input
                            :int-label      int-label
                            :int-input      int-input
                            :float-label    float-label
                            :float-input    float-input
                            :clock-label    clock-label
                            :clock          clock
                            :editor-label   editor-label
                            :text-editor    text-editor
                            :help-label     help-label
                            :help-view      help-view
                            :toggle-button  toggle-button
                            :return-button  return-button
                            :repeat-button  repeat-button
                            :value-label    value-label
                            :value-slider   value-slider
                            :scrollbar-label scrollbar-label
                            :scrollbar      scrollbar
                            :adjuster-label adjuster-label
                            :adjuster       adjuster
                            :demo-canvas    demo-canvas
                            :action-menu    action-menu
                            :source-field   source-field
                            :check-list     check-list
                            :file-list      file-list
                            :transport-flex transport-flex
                            :play-button    play-button
                            :track-output   track-output
                            :process-table  process-table
                            :end-task-button end-task-button
                            :refresh-button refresh-button
                            :log-panel      log-panel
                            :log-list       log-list
                            :status         status))
        (lightfast:add-menu-item menu "&File/E&xit"
                               (lambda (widget path)
                                 (declare (ignore widget path))
                                 (cleanup-demo)
                                 (lightfast:quit)))
        (lightfast:add-menu-item menu "&View/&Relayout"
                               (lambda (widget path)
                                 (declare (ignore widget path))
                                 (layout-demo window widgets)
                                 (setf (lightfast:value status) "Relayout complete.")))
        (lightfast:on-action window
                           (lambda (widget)
                             (declare (ignore widget))
                             (cleanup-demo)
                             (lightfast:quit))
                           :event lightfast:+event-close+)
        (lightfast:on-action
         save-button
         (lambda (widget)
           (declare (ignore widget))
           (let ((line (format nil "Saved ~A as ~A."
                               (lightfast:field-value name)
                               (lightfast:field-value state))))
             (add-log-line log-list line)
             (setf (lightfast:value status) line))))
        (lightfast:on-action
         copy-button
         (lambda (widget)
           (declare (ignore widget))
           (lightfast:copy-text (lightfast:field-value name))
           (add-log-line log-list "Copied name to clipboard.")
           (setf (lightfast:value status) "Copied name to clipboard.")))
        (lightfast:on-action
         enabled
         (lambda (widget)
           (let ((line (if (string= (lightfast:value widget) "1")
                           "Controls enabled."
                           "Controls disabled.")))
             (add-log-line log-list line)
             (setf (lightfast:value status) line)))
         :event lightfast:+event-change+)
        (lightfast:on-action
         light-button
         (lambda (widget)
           (let ((line (if (string= (lightfast:value widget) "1")
                           "Notification light on."
                           "Notification light off.")))
             (add-log-line log-list line)
             (setf (lightfast:value status) line)))
         :event lightfast:+event-change+)
        (dolist (radio (list radio-email radio-phone))
          (lightfast:on-action
           radio
           (lambda (widget)
             (when (string= (lightfast:value widget) "1")
               (let ((line (format nil "Contact mode: ~A."
                                   (lightfast:label widget))))
                 (add-log-line log-list line)
                 (setf (lightfast:value status) line))))
           :event lightfast:+event-change+))
        (lightfast:on-action
         meter-slider
         (lambda (widget)
           (let* ((level (widget-int-value widget))
                  (line  (format nil "Level set to ~D%." level)))
             (setf (lightfast:value meter-progress) (write-to-string level))
             (setf (lightfast:value status) line)))
         :event lightfast:+event-change+)
        (dolist (widget (list counter spinner dial roller))
          (lightfast:on-action
           widget
           (lambda (changed-widget)
             (let ((line (format nil "~A changed to ~A."
                                 (lightfast:label changed-widget)
                                 (lightfast:value changed-widget))))
               (setf (lightfast:value status) line)))
           :event lightfast:+event-change+))
        (lightfast:on-action
         tree
         (lambda (widget)
           (let ((line (format nil "Selected ~A." (lightfast:value widget))))
             (add-log-line log-list line)
             (setf (lightfast:value status) line)))
         :event lightfast:+event-change+)
        (dolist (widget (list toggle-button value-slider scrollbar adjuster))
          (lightfast:on-action
           widget
           (lambda (changed-widget)
             (let ((line (format nil "~A is ~A."
                                 (lightfast:label changed-widget)
                                 (lightfast:value changed-widget))))
               (setf (lightfast:value status) line)))
           :event lightfast:+event-change+))
        (dolist (widget (list return-button repeat-button))
          (lightfast:on-action
           widget
           (lambda (changed-widget)
             (let ((line (format nil "~A pressed." (lightfast:label changed-widget))))
               (add-log-line log-list line)
               (setf (lightfast:value status) line)))))
        (lightfast:on-action
         (lightfast:field-control source-field)
         (lambda (widget)
           (declare (ignore widget))
           (setf (lightfast:value status)
                 (format nil "Source: ~A." (lightfast:field-value source-field))))
         :event lightfast:+event-change+)
        (lightfast:on-action
         check-list
         (lambda (widget)
           (setf (lightfast:value status)
                 (format nil "~D advanced option(s) checked."
                         (lightfast:check-browser-checked-count widget))))
         :event lightfast:+event-change+)
        (lightfast:on-action
         file-list
         (lambda (widget)
           (let ((selected (lightfast:value widget)))
             (when (plusp (length selected))
               (setf (lightfast:value track-output) selected)
               (setf (lightfast:value status)
                     (format nil "Selected file ~A." selected)))))
         :event lightfast:+event-change+)
        (lightfast:on-action
         play-button
         (lambda (widget)
           (declare (ignore widget))
           (setf (lightfast:value status)
                 (format nil "Play pressed for ~A." (lightfast:value track-output)))))
        (lightfast:on-action
         process-table
         (lambda (widget)
           (let ((row (lightfast:table-selected-row widget)))
             (when (>= row 0)
               (let ((line (format nil "Selected process ~A."
                                   (lightfast:table-cell widget row 0))))
                 (setf (lightfast:value status) line)))))
         :event lightfast:+event-change+)
        (lightfast:on-action
         end-task-button
         (lambda (widget)
           (declare (ignore widget))
           (let ((row (lightfast:table-selected-row process-table)))
             (when (>= row 0)
               (lightfast:table-set-cell process-table row 4 "Ended")
               (setf (lightfast:value status)
                     (format nil "Marked ~A as ended."
                             (lightfast:table-cell process-table row 0)))))))
        (lightfast:on-action
         refresh-button
         (lambda (widget)
           (declare (ignore widget))
           (lightfast:table-set-cell process-table 0 2 "3%")
           (lightfast:table-set-cell process-table 1 2 "1%")
           (lightfast:table-set-cell process-table 2 2 "2%")
           (lightfast:table-set-cell process-table 3 2 "0%")
           (setf (lightfast:value status) "Task list refreshed.")))
        (lightfast:on-resize window
                           (lambda (resized-window)
                             (layout-demo resized-window widgets)))
        (add-log-line log-list "Demo started.")
        (layout-demo window widgets)
        (setf (lightfast:value tabs) "Controls")
        (lightfast:show window)
        (setf *demo-timer-id*
              (lightfast:add-timeout
               1.0d0
               (lambda ()
                 (setf (lightfast:value status)
                       (format nil "Timer tick; interval field is ~A second(s)."
                               (lightfast:field-value interval))))
               :repeat t))
        (unwind-protect
             (lightfast:run)
          (cleanup-demo)
          (ignore-errors
            (lightfast:destroy window)))))))
