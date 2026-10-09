(require :asdf)
(asdf:load-system :lightfast)
(lightfast:load-library)

;;; A gallery of ordinary widgets under the flat theme, for inspection by eye.
;;; Pass --classic to see the same gallery under the classic theme.

(let* ((classic-p (member "--classic" sb-ext:*posix-argv* :test #'string=))
       (serif (lightfast:load-font "Times New Roman MT Std"))
       (serif-bold (lightfast:load-font "Times New Roman MT Std Bold"))
       (mono (lightfast:load-font "CMU Typewriter Text")))
  (if classic-p
      (lightfast:apply-classic-theme)
      (lightfast:apply-flat-theme :background '(255 254 250)
                                  :foreground '(0 0 0)
                                  :label-font serif
                                  :label-size 16
                                  :text-font serif
                                  :text-size 16
                                  :mono-font mono))
  (let* ((window (lightfast:make-window :width 760 :height 520
                                        :label (if classic-p "Classic theme" "Flat theme")
                                        :app-id "lightfast-flat-theme"))
         (menu (lightfast:make-menu-bar :parent window :x 0 :y 0 :width 760 :height 30))
         (title (lightfast:make-label :parent window :x 24 :y 44 :width 500 :height 32
                                      :label "Autolith workbench gallery"))
         (name (lightfast:make-input :parent window :x 120 :y 90 :width 280 :height 32
                                     :label "Folder:" :value "/root/common-lisp/aui"))
         (model (lightfast:make-choice :parent window :x 120 :y 134 :width 280 :height 32
                                       :label "Model:" :items '("gpt-5.6-luna" "claude-haiku-4-5")))
         (send (lightfast:make-button :parent window :x 420 :y 90 :width 120 :height 32
                                      :label "Send"))
         (stop (lightfast:make-button :parent window :x 420 :y 134 :width 120 :height 32
                                      :label "Stop"))
         (check (lightfast:make-check-button :parent window :x 560 :y 90 :width 170 :height 32
                                             :label "Visible reasoning"))
         (radio (lightfast:make-radio-button :parent window :x 560 :y 134 :width 170 :height 32
                                             :label "Ask before running"))
         (list (lightfast:make-browser :parent window :x 24 :y 190 :width 300 :height 150))
         (text (lightfast:make-text-display :parent window :x 340 :y 190 :width 396 :height 150))
         (progress (lightfast:make-progress :parent window :x 24 :y 356 :width 300 :height 24
                                            :value "35"))
         (slider (lightfast:make-slider :parent window :x 340 :y 356 :width 396 :height 24
                                        :value "50"))
         (tabs (lightfast:make-tabs :parent window :x 24 :y 396 :width 712 :height 100))
         (page (lightfast:make-tab-page :parent tabs :x 0 :y 30 :width 712 :height 70
                                        :label "Transcript"))
         (page2 (lightfast:make-tab-page :parent tabs :x 0 :y 30 :width 712 :height 70
                                         :label "Jobs")))
    (declare (ignore model send stop radio progress slider page2))
    (setf (lightfast:value check) "1")
    (lightfast:add-menu-item menu "Session/New" (lambda (w e v) (declare (ignore w e v))))
    (lightfast:add-menu-item menu "Session/Resume" (lambda (w e v) (declare (ignore w e v))))
    (lightfast:add-menu-item menu "View/Inspector" (lambda (w e v) (declare (ignore w e v))))
    (lightfast:set-label-font title serif-bold)
    (lightfast:set-label-size title 24)
    (lightfast:set-text-font name serif)
    (dolist (item '("Howdy    2026-10-09 21:09" "Optimize Autolith    2026-07-23 09:50"
                    "Design review    2026-07-20 14:02"))
      (lightfast:add-item list item))
    (lightfast:browser-select list 1)
    (setf (lightfast:value text)
          (format nil "(defun greet (name)~%  \"Say hello.\"~%  (format t \"hello ~~a\" name))~%~%; A code block in CMU Typewriter.~%"))
    (lightfast:make-label :parent page :x 16 :y 20 :width 400 :height 30
                          :label "Body text in Times New Roman, 16 px, on paper.")
    (lightfast:show window)
    (if (member "--shot" sb-ext:*posix-argv* :test #'string=)
        (progn (loop repeat 40 do (lightfast:wait 0.05))
               (uiop:run-program (list "grim" (if classic-p "/tmp/lightfast-classic.png" "/tmp/lightfast-flat.png"))
                                 :ignore-error-status t)
               (lightfast:destroy window))
        (lightfast:run))))
(uiop:quit 0)
