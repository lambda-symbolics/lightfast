(in-package #:lightfast)

(defvar *library-loaded-p* nil)
(defvar *callback-token-counter* 0)
(defvar *callback-registry* (make-hash-table))

(defparameter *bridge-library-name*
  #+darwin "liblightfast.dylib"
  #-darwin "liblightfast.so"
  "File name of the native bridge that `make native` builds on this platform.")

(defun bridge-library-override ()
  "Return the bridge named by the environment variable LIGHTFAST_LIBRARY as a
pathname, or NIL when the variable is unset or empty."
  (let ((name (uiop:getenv "LIGHTFAST_LIBRARY")))
    (when (and name (plusp (length name)))
      (uiop:parse-native-namestring name))))

(defun bridge-library-path ()
  "Return the path of the native bridge LOAD-LIBRARY loads.

The environment variable LIGHTFAST_LIBRARY names the file outright, which is
how an application that ships a prebuilt bridge points at it. Without it the
bridge is the one `make native` builds under the system's source directory:
build/liblightfast.so on Linux, build/liblightfast.dylib on macOS."
  (or (bridge-library-override)
      (merge-pathnames (concatenate 'string "build/" *bridge-library-name*)
                       (asdf:system-source-directory :lightfast))))

(defun bridge-stale-source (path)
  "Return a native source newer than the bridge built at PATH, or NIL.

A pull brings new C and new pixmaps; it does not bring a new shared library.
Nothing then fails loudly: the old bridge loads, and whatever the new sources
added is simply absent, which looks like a bug in the caller rather than a build
that never happened. Asking the filesystem is cheap and answers it exactly. A
bridge shipped without its sources has nothing to be older than."
  (let ((built (ignore-errors (file-write-date path)))
        (source-directory (ignore-errors (asdf:system-source-directory :lightfast))))
    (when (and built source-directory)
      (find-if (lambda (source)
                 (let ((changed (ignore-errors (file-write-date source))))
                   (and changed (> changed built))))
               (directory (merge-pathnames "native/*.*" source-directory))))))

(defun load-library ()
  "Load the native bridge once; later calls do nothing.

The bridge is the file BRIDGE-LIBRARY-PATH returns. Signals an error when it is
missing and warns when it is older than the native sources beside the system."
  (unless *library-loaded-p*
    (let ((path (bridge-library-path)))
      (unless (probe-file path)
        (if (bridge-library-override)
            (error "Native Lightfast bridge is missing at ~A, the file ~
                    LIGHTFAST_LIBRARY names."
                   path)
            (error "Native Lightfast bridge is missing at ~A. Run `make native` first."
                   path)))
      (let ((stale (bridge-stale-source path)))
        (when stale
          ;; A warning rather than an error: a build deliberately kept behind
          ;; its sources is somebody's business, and refusing to start would
          ;; take the application down over it. Naming the file that is newer
          ;; and the library that is not is enough to act on.
          (warn "Lightfast's native bridge at ~A is older than ~A. ~
                 Run `make` in ~A, or anything those sources added, such as ~
                 new stock icons and new entry points, will be missing ~
                 without saying so."
                path (file-namestring stale)
                (asdf:system-source-directory :lightfast))))
      (cffi:load-foreign-library path)
      ;; Every call into the bridge goes through its trap mask, so a bridge
      ;; built before the mask existed would fail at the first call, with an
      ;; error naming a function the caller never mentioned.
      (unless (cffi:foreign-symbol-pointer "clfl_float_traps_mask")
        (error "The native Lightfast bridge at ~A was built from older sources: ~
                it lacks clfl_float_traps_mask, which every call needs. ~
                Rebuild it with `make native`."
               path))
      (setf *library-loaded-p* t))))

(defun next-callback-token (callback)
  (let ((token (incf *callback-token-counter*)))
    (setf (gethash token *callback-registry*) callback)
    token))

;;; Floating point traps.
;;;
;;; SBCL runs Lisp with the invalid, divide-by-zero and overflow traps enabled.
;;; FLTK and what it stands on compute with NaN and infinity as a matter of
;;; course: Cocoa, CoreGraphics and CoreText on macOS, the GTK and KDE file
;;; choosers on Linux. Under those traps that arithmetic ends the process with
;;; SIGFPE. So every call into the bridge runs with every trap masked, and
;;; every callback from the bridge runs with the traps Lisp had when it went
;;; in. The mask covers foreign code alone: an application's own arithmetic
;;; signals what it always did, inside a callback as well as outside one.
;;;
;;; Callbacks get their traps back, rather than staying masked, because it is
;;; cheap enough: the bridge flips the control registers itself
;;; (native/api_floats.cpp) for about 25 ns a call on x86-64, which slows a
;;; canvas drawing two thousand shapes by 5 percent. SBCL's own
;;; WITH-FLOAT-TRAPS-MASKED saves and loads the whole x87 environment there,
;;; takes 200 ns and slowed the same canvas by a third, so it is not used.

(defvar *lisp-float-state* nil
  "The floating point control state Lisp code had when the innermost call into
the bridge on this thread began, or NIL outside any such call.")

(defmacro with-native-float-traps (&body body)
  "Run BODY, a call into the bridge, with every floating point trap masked."
  (let ((state (gensym "STATE")))
    `(let* ((,state (cffi:foreign-funcall "clfl_float_traps_mask" :uint64))
            (*lisp-float-state* ,state))
       (unwind-protect (progn ,@body)
         (cffi:foreign-funcall "clfl_float_traps_restore" :uint64 ,state :void)))))

(defmacro with-lisp-float-traps (&body body)
  "Run BODY, Lisp called back from the bridge, with the floating point traps
Lisp had when it entered the bridge, and mask them again on the way out."
  (let ((state (gensym "STATE")) (run (gensym "RUN")))
    `(let ((,state *lisp-float-state*))
       (flet ((,run () ,@body))
         (declare (dynamic-extent #',run))
         (if ,state
             (progn
               (cffi:foreign-funcall "clfl_float_traps_restore" :uint64 ,state :void)
               (unwind-protect (,run)
                 (cffi:foreign-funcall "clfl_float_traps_mask" :uint64)))
             (,run))))))

(defmacro define-bridge-function ((foreign-name lisp-name) return-type &body arguments)
  "Define LISP-NAME as a call to the bridge's FOREIGN-NAME, written as
CFFI:DEFCFUN is written, that runs with floating point traps masked.

Every foreign function of the bridge is declared with this and none with
CFFI:DEFCFUN: a call that skipped the mask would work on Linux and end the
process on macOS the first time Cocoa computed a NaN under it."
  `(defun ,lisp-name ,(mapcar #'first arguments)
     (with-native-float-traps
       (cffi:foreign-funcall ,foreign-name
                             ,@(loop for (name type) in arguments
                                     collect type
                                     collect name)
                             ,return-type))))

(cffi:defcallback callback-dispatch :void
    ((widget-id :long-long)
     (event     :int)
     (value     :pointer)
     (token     :long-long))
  #+sbcl
  (declare (sb-ext:muffle-conditions sb-ext:compiler-note))
  (let ((callback (the (or null function)
                    (gethash token *callback-registry*))))
    (when callback
      (with-lisp-float-traps
        (funcall callback
                 widget-id
                 event
                 (if (cffi:null-pointer-p value)
                     ""
                     (cffi:foreign-string-to-lisp value)))))))

(define-bridge-function ("clfl_apply_classic_theme" %apply-classic-theme) :void)

(define-bridge-function ("clfl_apply_flat_theme" %apply-flat-theme) :void
  (background-red   :int)
  (background-green :int)
  (background-blue  :int)
  (foreground-red   :int)
  (foreground-green :int)
  (foreground-blue  :int)
  (selection-red    :int)
  (selection-green  :int)
  (selection-blue   :int)
  (label-font       :int)
  (label-size       :int)
  (text-font        :int)
  (text-size        :int)
  (mono-font        :int))

(define-bridge-function ("clfl_widget_create" %widget-create) :long-long
  (kind      :int)
  (parent-id :long-long)
  (x         :int)
  (y         :int)
  (width     :int)
  (height    :int)
  (label     :string))

(define-bridge-function ("clfl_system_menu_bar_create" %system-menu-bar-create) :long-long
  (parent-id :long-long)
  (x         :int)
  (y         :int)
  (width     :int)
  (height    :int)
  (label     :string))

(define-bridge-function ("clfl_menu_bar_is_system" %menu-bar-is-system) :int
  (id :long-long))

(define-bridge-function ("clfl_widget_destroy" %widget-destroy) :int
  (id :long-long))

(define-bridge-function ("clfl_window_show" %window-show) :void
  (id :long-long))

(define-bridge-function ("clfl_window_hide" %window-hide) :void
  (id :long-long))

(define-bridge-function ("clfl_window_cancel_close" %window-cancel-close) :void
  (id :long-long))

(define-bridge-function ("clfl_window_set_modal" %window-set-modal) :void
  (id :long-long)
  (enabled :int))

(define-bridge-function ("clfl_event_consume" %event-consume) :void)

(define-bridge-function ("clfl_event_clicks" %event-clicks) :int)

(define-bridge-function ("clfl_event_key" %event-key) :int)

(define-bridge-function ("clfl_widget_take_focus" %widget-take-focus) :void
  (id :long-long))

(define-bridge-function ("clfl_widget_set_when" %widget-set-when) :void
  (id :long-long)
  (when :int))

(define-bridge-function ("clfl_window_set_escape_closes" %window-set-escape-closes) :void
  (id      :long-long)
  (enabled :int))

(define-bridge-function ("clfl_window_set_size_range" %window-set-size-range) :void
  (id         :long-long)
  (min-width  :int)
  (min-height :int)
  (max-width  :int)
  (max-height :int))

(define-bridge-function ("clfl_window_set_app_id" %window-set-app-id) :void
  (id     :long-long)
  (app-id :string))

(define-bridge-function ("clfl_window_get_app_id" %window-get-app-id) :pointer
  (id :long-long))

(define-bridge-function ("clfl_widget_redraw" %widget-redraw) :void
  (id :long-long))

(define-bridge-function ("clfl_window_capture_ppm" %window-capture-ppm) :int
  (id   :long-long)
  (path :string))

(define-bridge-function ("clfl_widget_set_label" %widget-set-label) :void
  (id    :long-long)
  (label :string))

(define-bridge-function ("clfl_widget_get_label" %widget-get-label) :pointer
  (id :long-long))

(define-bridge-function ("clfl_widget_set_value" %widget-set-value) :void
  (id    :long-long)
  (value :string))

(define-bridge-function ("clfl_widget_get_value" %widget-get-value) :pointer
  (id :long-long))

(define-bridge-function ("clfl_widget_set_stock_icon" %widget-set-stock-icon) :void
  (id   :long-long)
  (name :string))

(define-bridge-function ("clfl_string_free" %string-free) :void
  (value :pointer))

(define-bridge-function ("clfl_widget_set_callback" %widget-set-callback) :int
  (id       :long-long)
  (callback :pointer)
  (token    :long-long)
  (event    :int))

(define-bridge-function ("clfl_widget_resize" %widget-resize) :void
  (id     :long-long)
  (x      :int)
  (y      :int)
  (width  :int)
  (height :int))

(define-bridge-function ("clfl_widget_x" %widget-native-x) :int
  (id :long-long))

(define-bridge-function ("clfl_widget_y" %widget-native-y) :int
  (id :long-long))

(define-bridge-function ("clfl_widget_width" %widget-native-width) :int
  (id :long-long))

(define-bridge-function ("clfl_widget_height" %widget-native-height) :int
  (id :long-long))

(define-bridge-function ("clfl_menu_add" %menu-add) :int
  (id       :long-long)
  (path     :string)
  (shortcut :int)
  (callback :pointer)
  (token    :long-long)
  (flags    :int))

(define-bridge-function ("clfl_menu_set_item_checked" %menu-set-item-checked) :int
  (id      :long-long)
  (path    :string)
  (checked :int))

(define-bridge-function ("clfl_menu_set_item_mode" %menu-set-item-mode) :int
  (id   :long-long)
  (path :string)
  (mode :int))

(define-bridge-function ("clfl_menu_set_item_label" %menu-set-item-label) :int
  (id    :long-long)
  (path  :string)
  (label :string))

(define-bridge-function ("clfl_widget_set_box" %widget-set-box) :void
  (id  :long-long)
  (box :int))

(define-bridge-function ("clfl_widget_set_label_size" %widget-set-label-size) :void
  (id   :long-long)
  (size :int))

(define-bridge-function ("clfl_widget_set_label_font" %widget-set-label-font) :void
  (id   :long-long)
  (font :int))

(define-bridge-function ("clfl_widget_baseline" %widget-baseline) :int
  (id :long-long))

(define-bridge-function ("clfl_widget_set_label_align" %widget-set-label-align) :void
  (id    :long-long)
  (align :int))

(define-bridge-function ("clfl_widget_set_label_color_rgb" %widget-set-label-color-rgb) :void
  (id    :long-long)
  (red   :int)
  (green :int)
  (blue  :int))

(define-bridge-function ("clfl_widget_set_tooltip" %widget-set-tooltip) :void
  (id      :long-long)
  (tooltip :string))

(define-bridge-function ("clfl_widget_set_text_size" %widget-set-text-size) :void
  (id   :long-long)
  (size :int))

(define-bridge-function ("clfl_font_load" %font-load) :int
  (name :string))

(define-bridge-function ("clfl_font_name" %font-name) :pointer
  (font :int))

(define-bridge-function ("clfl_font_system_names" %font-system-names) :pointer)

(define-bridge-function ("clfl_font_files" %font-files) :pointer
  (family :string))

(define-bridge-function ("clfl_font_substitute" %font-substitute) :int
  (files          :pointer)
  (count          :int)
  (rejected       :pointer)
  (rejected-count :int))

(define-bridge-function ("clfl_font_register_file" %font-register-file) :int
  (path :string))

(define-bridge-function ("clfl_font_measure" %font-measure) :int
  (font    :int)
  (size    :int)
  (text    :string)
  (width   :pointer)
  (height  :pointer)
  (descent :pointer))

(define-bridge-function ("clfl_widget_set_text_font" %widget-set-text-font) :void
  (id   :long-long)
  (font :int))

(define-bridge-function ("clfl_widget_set_color_rgb" %widget-set-color-rgb) :void
  (id    :long-long)
  (red   :int)
  (green :int)
  (blue  :int))

(define-bridge-function ("clfl_widget_set_cursor" %widget-set-cursor) :void
  (id     :long-long)
  (cursor :int))

(define-bridge-function ("clfl_draw_set_color_rgb" %draw-set-color-rgb) :void
  (red   :int)
  (green :int)
  (blue  :int))

(define-bridge-function ("clfl_draw_set_font" %draw-set-font) :void
  (font :int)
  (size :int))

(define-bridge-function ("clfl_draw_line" %draw-line) :void
  (x1 :int)
  (y1 :int)
  (x2 :int)
  (y2 :int))

(define-bridge-function ("clfl_draw_rect" %draw-rect) :void
  (x      :int)
  (y      :int)
  (width  :int)
  (height :int))

(define-bridge-function ("clfl_draw_filled_rect" %draw-filled-rect) :void
  (x      :int)
  (y      :int)
  (width  :int)
  (height :int))

(define-bridge-function ("clfl_draw_circle" %draw-circle) :void
  (x      :int)
  (y      :int)
  (radius :int))

(define-bridge-function ("clfl_draw_filled_circle" %draw-filled-circle) :void
  (x      :int)
  (y      :int)
  (radius :int))

(define-bridge-function ("clfl_draw_stock_icon" %draw-stock-icon) :void
  (name :string)
  (x    :int)
  (y    :int))

(define-bridge-function ("clfl_window_set_icon" %window-set-icon) :void
  (id   :long-long)
  (name :string))

(define-bridge-function ("clfl_draw_text" %draw-text) :void
  (text   :string)
  (x      :int)
  (y      :int)
  (width  :int)
  (height :int)
  (align  :int))

(define-bridge-function ("clfl_draw_push_clip" %draw-push-clip) :void
  (x      :int)
  (y      :int)
  (width  :int)
  (height :int))

(define-bridge-function ("clfl_draw_pop_clip" %draw-pop-clip) :void)

(define-bridge-function ("clfl_draw_set_line_style" %draw-set-line-style) :void
  (width  :int)
  (dashed :int))

(define-bridge-function ("clfl_draw_polygon" %draw-polygon) :void
  (points :pointer)
  (count  :int)
  (filled :int))

(define-bridge-function ("clfl_draw_text_rotated" %draw-text-rotated) :void
  (text  :string)
  (angle :int)
  (x     :int)
  (y     :int))

(define-bridge-function ("clfl_draw_clip_box" %draw-clip-box) :int
  (x      :int)
  (y      :int)
  (width  :int)
  (height :int)
  (clip-x :pointer)
  (clip-y :pointer)
  (clip-w :pointer)
  (clip-h :pointer))

(define-bridge-function ("clfl_draw_dither" %draw-dither) :void
  (x      :int)
  (y      :int)
  (width  :int)
  (height :int)
  (step   :int)
  (red    :int)
  (green  :int)
  (blue   :int))

(define-bridge-function ("clfl_image_load" %image-load) :long-long
  (path :string))

(define-bridge-function ("clfl_image_width" %image-width) :int
  (id :long-long))

(define-bridge-function ("clfl_image_height" %image-height) :int
  (id :long-long))

(define-bridge-function ("clfl_image_draw" %image-draw) :void
  (id     :long-long)
  (x      :int)
  (y      :int)
  (width  :int)
  (height :int))

(define-bridge-function ("clfl_image_release" %image-release) :void
  (id :long-long))

(define-bridge-function ("clfl_widget_redraw_region" %widget-redraw-region) :void
  (id     :long-long)
  (x      :int)
  (y      :int)
  (width  :int)
  (height :int))

(define-bridge-function ("clfl_canvas_set_focusable" %canvas-set-focusable) :int
  (id      :long-long)
  (enabled :int))

(define-bridge-function ("clfl_widget_set_placeholder" %widget-set-placeholder) :void
  (id   :long-long)
  (text :string)
  (font :int))

(define-bridge-function ("clfl_widget_set_range" %widget-set-range) :void
  (id      :long-long)
  (minimum :double)
  (maximum :double))

(define-bridge-function ("clfl_widget_set_step" %widget-set-step) :void
  (id   :long-long)
  (step :double))

(define-bridge-function ("clfl_choice_add" %choice-add) :void
  (id    :long-long)
  (label :string))

(define-bridge-function ("clfl_browser_add" %browser-add) :void
  (id    :long-long)
  (label :string))

(define-bridge-function ("clfl_browser_set_column_widths" %browser-set-column-widths) :void
  (id     :long-long)
  (widths :pointer)
  (count  :int))

(define-bridge-function ("clfl_tree_add" %tree-add) :void
  (id   :long-long)
  (path :string))

(define-bridge-function ("clfl_browser_select" %browser-select) :void
  (id    :long-long)
  (index :int))

(define-bridge-function ("clfl_check_browser_add" %check-browser-add) :void
  (id      :long-long)
  (label   :string)
  (checked :int))

(define-bridge-function ("clfl_check_browser_count" %check-browser-count) :int
  (id :long-long))

(define-bridge-function ("clfl_check_browser_checked_count" %check-browser-checked-count) :int
  (id :long-long))

(define-bridge-function ("clfl_check_browser_checked" %check-browser-checked) :int
  (id    :long-long)
  (index :int))

(define-bridge-function ("clfl_check_browser_set_checked" %check-browser-set-checked) :void
  (id      :long-long)
  (index   :int)
  (checked :int))

(define-bridge-function ("clfl_check_browser_check_all" %check-browser-check-all) :void
  (id :long-long))

(define-bridge-function ("clfl_check_browser_check_none" %check-browser-check-none) :void
  (id :long-long))

(define-bridge-function ("clfl_check_browser_text" %check-browser-text) :pointer
  (id    :long-long)
  (index :int))

(define-bridge-function ("clfl_file_browser_load" %file-browser-load) :int
  (id        :long-long)
  (directory :string))

(define-bridge-function ("clfl_file_browser_set_filter" %file-browser-set-filter) :void
  (id      :long-long)
  (pattern :string))

(define-bridge-function ("clfl_file_browser_set_filetype" %file-browser-set-filetype) :void
  (id       :long-long)
  (filetype :int))

(define-bridge-function ("clfl_menu_button_set_popup" %menu-button-set-popup) :void
  (id      :long-long)
  (buttons :int))

(define-bridge-function ("clfl_tile_size_range" %tile-size-range) :void
  (id         :long-long)
  (child-id   :long-long)
  (min-width  :int)
  (min-height :int)
  (max-width  :int)
  (max-height :int))

(define-bridge-function ("clfl_group_init_sizes" %group-init-sizes) :void
  (id :long-long))

(define-bridge-function ("clfl_scrollbar_set_vertical" %scrollbar-set-vertical) :void
  (id       :long-long)
  (vertical :int))

(define-bridge-function ("clfl_flex_set_type" %flex-set-type) :void
  (id         :long-long)
  (horizontal :int))

(define-bridge-function ("clfl_flex_set_gap" %flex-set-gap) :void
  (id  :long-long)
  (gap :int))

(define-bridge-function ("clfl_flex_set_margin" %flex-set-margin) :void
  (id     :long-long)
  (left   :int)
  (top    :int)
  (right  :int)
  (bottom :int))

(define-bridge-function ("clfl_flex_fixed" %flex-fixed) :void
  (id       :long-long)
  (child-id :long-long)
  (size     :int))

(define-bridge-function ("clfl_flex_layout" %flex-layout) :void
  (id :long-long))

(define-bridge-function ("clfl_table_set_size" %table-set-size) :void
  (id      :long-long)
  (rows    :int)
  (columns :int))

(define-bridge-function ("clfl_table_set_column_label" %table-set-column-label) :void
  (id     :long-long)
  (column :int)
  (label  :string))

(define-bridge-function ("clfl_table_set_column_width" %table-set-column-width) :void
  (id     :long-long)
  (column :int)
  (width  :int))

(define-bridge-function ("clfl_table_set_cell" %table-set-cell) :void
  (id     :long-long)
  (row    :int)
  (column :int)
  (value  :string))

(define-bridge-function ("clfl_table_get_cell" %table-get-cell) :pointer
  (id     :long-long)
  (row    :int)
  (column :int))

(define-bridge-function ("clfl_table_selected_row" %table-selected-row) :int
  (id :long-long))

(define-bridge-function ("clfl_table_selected_rows" %table-selected-rows) :pointer
  (id :long-long))

(define-bridge-function ("clfl_table_select_row" %table-select-row) :void
  (id  :long-long)
  (row :int))

(define-bridge-function ("clfl_table_column_width" %table-column-width) :int
  (id     :long-long)
  (column :int))

(define-bridge-function ("clfl_widget_clear" %widget-clear) :void
  (id :long-long))

(define-bridge-function ("clfl_pack_set_orientation" %pack-set-orientation) :int
  (id         :long-long)
  (horizontal :int))

(define-bridge-function ("clfl_pack_set_spacing" %pack-set-spacing) :int
  (id      :long-long)
  (spacing :int))

(define-bridge-function ("clfl_grid_layout" %grid-layout) :int
  (id         :long-long)
  (rows       :int)
  (columns    :int)
  (margin     :int)
  (row-gap    :int)
  (column-gap :int))

(define-bridge-function ("clfl_grid_place" %grid-place) :int
  (id          :long-long)
  (child-id    :long-long)
  (row         :int)
  (column      :int)
  (row-span    :int)
  (column-span :int)
  (alignment   :int))

(define-bridge-function ("clfl_grid_set_row_height" %grid-set-row-height) :int
  (id     :long-long)
  (row    :int)
  (height :int))

(define-bridge-function ("clfl_grid_set_row_weight" %grid-set-row-weight) :int
  (id     :long-long)
  (row    :int)
  (weight :int))

(define-bridge-function ("clfl_grid_set_column_width" %grid-set-column-width) :int
  (id     :long-long)
  (column :int)
  (width  :int))

(define-bridge-function ("clfl_grid_set_column_weight" %grid-set-column-weight) :int
  (id     :long-long)
  (column :int)
  (weight :int))

(define-bridge-function ("clfl_positioner_set_value" %positioner-set-value) :int
  (id :long-long)
  (x  :double)
  (y  :double))

(define-bridge-function ("clfl_positioner_get_value" %positioner-get-value) :int
  (id :long-long)
  (x  :pointer)
  (y  :pointer))

(define-bridge-function ("clfl_positioner_set_bounds" %positioner-set-bounds) :int
  (id        :long-long)
  (x-minimum :double)
  (x-maximum :double)
  (y-minimum :double)
  (y-maximum :double))

(define-bridge-function ("clfl_positioner_set_steps" %positioner-set-steps) :int
  (id     :long-long)
  (x-step :double)
  (y-step :double))

(define-bridge-function ("clfl_wizard_next" %wizard-next) :int
  (id :long-long))

(define-bridge-function ("clfl_wizard_previous" %wizard-previous) :int
  (id :long-long))

(define-bridge-function ("clfl_wizard_current" %wizard-current) :long-long
  (id :long-long))

(define-bridge-function ("clfl_wizard_set_current" %wizard-set-current) :int
  (id       :long-long)
  (child-id :long-long))

(define-bridge-function ("clfl_chart_add" %chart-add) :int
  (id    :long-long)
  (value :double)
  (label :string)
  (color :unsigned-int))

(define-bridge-function ("clfl_chart_insert" %chart-insert) :int
  (id    :long-long)
  (index :int)
  (value :double)
  (label :string)
  (color :unsigned-int))

(define-bridge-function ("clfl_chart_replace" %chart-replace) :int
  (id    :long-long)
  (index :int)
  (value :double)
  (label :string)
  (color :unsigned-int))

(define-bridge-function ("clfl_chart_clear" %chart-clear) :int
  (id :long-long))

(define-bridge-function ("clfl_chart_set_bounds" %chart-set-bounds) :int
  (id      :long-long)
  (minimum :double)
  (maximum :double))

(define-bridge-function ("clfl_chart_set_type" %chart-set-type) :int
  (id   :long-long)
  (type :int))

(define-bridge-function ("clfl_text_set_styles" %text-set-styles) :int
  (id          :long-long)
  (count       :int)
  (fonts       :pointer)
  (sizes       :pointer)
  (colors      :pointer)
  (attributes  :pointer)
  (backgrounds :pointer))

(define-bridge-function ("clfl_text_append_styled" %text-append-styled) :int
  (id     :long-long)
  (text   :string)
  (styles :pointer))

(define-bridge-function ("clfl_text_replace_styled" %text-replace-styled) :int
  (id     :long-long)
  (start  :int)
  (end    :int)
  (text   :string)
  (styles :pointer))

(define-bridge-function ("clfl_text_length" %text-length) :int
  (id :long-long))

(define-bridge-function ("clfl_text_range" %text-range) :pointer
  (id    :long-long)
  (start :int)
  (end   :int))

(define-bridge-function ("clfl_text_selection" %text-selection) :pointer
  (id :long-long))

(define-bridge-function ("clfl_text_scroll_to_end" %text-scroll-to-end) :int
  (id :long-long))

(define-bridge-function ("clfl_text_at_end" %text-at-end) :int
  (id :long-long))

(define-bridge-function ("clfl_text_set_scrollbars" %text-set-scrollbars) :int
  (id   :long-long)
  (mode :int))

(define-bridge-function ("clfl_text_top_line" %text-top-line) :int
  (id :long-long))

(define-bridge-function ("clfl_text_scroll_to_line" %text-scroll-to-line) :int
  (id   :long-long)
  (line :int))

(define-bridge-function ("clfl_text_line_of_position" %text-line-of-position) :int
  (id       :long-long)
  (position :int))

(define-bridge-function ("clfl_text_position_at" %text-position-at) :int
  (id :long-long)
  (x  :int)
  (y  :int))

(define-bridge-function ("clfl_text_insert_position" %text-insert-position) :int
  (id :long-long))

(define-bridge-function ("clfl_text_set_insert_position" %text-set-insert-position) :int
  (id       :long-long)
  (position :int))

(define-bridge-function ("clfl_text_replace" %text-replace) :int
  (id    :long-long)
  (start :int)
  (end   :int)
  (text  :string))

(define-bridge-function ("clfl_browser_set_scrollbars" %browser-set-scrollbars) :void
  (id   :long-long)
  (mode :int))

(define-bridge-function ("clfl_browser_set_line_spacing" %browser-set-line-spacing) :void
  (id     :long-long)
  (pixels :int))

(define-bridge-function ("clfl_text_set_wrap" %text-set-wrap) :int
  (id     :long-long)
  (mode   :int)
  (margin :int))

(define-bridge-function ("clfl_terminal_append" %terminal-append) :int
  (id   :long-long)
  (text :string))

(define-bridge-function ("clfl_terminal_clear" %terminal-clear) :int
  (id :long-long))

(define-bridge-function ("clfl_terminal_text" %terminal-text) :pointer
  (id :long-long))

(define-bridge-function ("clfl_color_chooser_set_rgb" %color-chooser-set-rgb) :int
  (id    :long-long)
  (red   :double)
  (green :double)
  (blue  :double))

(define-bridge-function ("clfl_color_chooser_get_rgb" %color-chooser-get-rgb) :int
  (id    :long-long)
  (red   :pointer)
  (green :pointer)
  (blue  :pointer))

(define-bridge-function ("clfl_shortcut_button_set_shortcut" %shortcut-button-set-shortcut) :int
  (id       :long-long)
  (shortcut :unsigned-int))

(define-bridge-function ("clfl_shortcut_button_get_shortcut" %shortcut-button-get-shortcut) :unsigned-int
  (id :long-long))

(define-bridge-function ("clfl_browser_set_selection_mode" %browser-set-selection-mode) :int
  (id   :long-long)
  (mode :int))

(define-bridge-function ("clfl_browser_set_selected" %browser-set-selected) :int
  (id       :long-long)
  (index    :int)
  (selected :int))

(define-bridge-function ("clfl_browser_selected_indices" %browser-selected-indices) :pointer
  (id :long-long))

(define-bridge-function ("clfl_copy_text" %copy-text) :void
  (value :string))

(define-bridge-function ("clfl_popup_menu" %popup-menu) :int
  (items :pointer)
  (count :int))

(define-bridge-function ("clfl_input_dialog" %input-dialog) :pointer
  (message :string)
  (initial :string))

(define-bridge-function ("clfl_color_chooser" %color-chooser) :int
  (title :string)
  (red :pointer)
  (green :pointer)
  (blue :pointer))

(define-bridge-function ("clfl_choose_file" %choose-file) :pointer
  (title       :string)
  (filter      :string)
  (preset-file :string))

(define-bridge-function ("clfl_choose_files" %choose-files) :pointer
  (title       :string)
  (filter      :string)
  (preset-file :string))

(define-bridge-function ("clfl_choose_save_file" %choose-save-file) :pointer
  (title       :string)
  (filter      :string)
  (preset-file :string))

(define-bridge-function ("clfl_choose_directory" %choose-directory) :pointer
  (title       :string)
  (preset-path :string))

(define-bridge-function ("clfl_message_box" %message-box) :void
  (message :string))

(define-bridge-function ("clfl_alert_box" %alert-box) :void
  (message :string))

(define-bridge-function ("clfl_choice_box" %choice-box) :int
  (message :string)
  (button0 :string)
  (button1 :string)
  (button2 :string))

(define-bridge-function ("clfl_add_timeout" %add-timeout) :long-long
  (seconds  :double)
  (repeat   :int)
  (callback :pointer)
  (token    :long-long))

(define-bridge-function ("clfl_remove_timeout" %remove-timeout) :int
  (id :long-long))

(define-bridge-function ("clfl_add_wakeup" %add-wakeup) :long-long
  (callback :pointer)
  (token    :long-long))

(define-bridge-function ("clfl_wake" %wake) :int
  (id :long-long))

(define-bridge-function ("clfl_remove_wakeup" %remove-wakeup) :int
  (id :long-long))

(define-bridge-function ("clfl_quit" %quit) :void)

(define-bridge-function ("clfl_enable_thread_wakeups" %enable-thread-wakeups) :void)

(define-bridge-function ("clfl_awake" %awake) :void)

(define-bridge-function ("clfl_run" %run) :int)
(define-bridge-function ("clfl_check" %check) :int)

(define-bridge-function ("clfl_wait_for_event" %wait-for-event) :int)

(define-bridge-function ("clfl_wait" %wait) :int
  (seconds :double))

(defun foreign-string (reader)
  (let ((pointer (funcall reader)))
    (unwind-protect
         (if (cffi:null-pointer-p pointer)
             ""
             (cffi:foreign-string-to-lisp pointer))
      (unless (cffi:null-pointer-p pointer)
        (%string-free pointer)))))
