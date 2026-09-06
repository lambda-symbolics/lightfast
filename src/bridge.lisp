(in-package #:lightfast)

(defvar *library-loaded-p* nil)
(defvar *callback-token-counter* 0)
(defvar *callback-registry* (make-hash-table))

(defun bridge-library-path ()
  (merge-pathnames "build/liblightfast.so"
                   (asdf:system-source-directory :lightfast)))

(defun bridge-stale-source (path)
  "Return a native source newer than the bridge built at PATH, or NIL.

A pull brings new C and new pixmaps; it does not bring a new shared library.
Nothing then fails loudly — the old bridge loads, and whatever the new sources
added is simply absent, which looks like a bug in the caller rather than a build
that never happened. Asking the filesystem is cheap and answers it exactly."
  (let ((built (ignore-errors (file-write-date path))))
    (when built
      (find-if (lambda (source)
                 (let ((changed (ignore-errors (file-write-date source))))
                   (and changed (> changed built))))
               (directory (merge-pathnames
                           "native/*.*"
                           (asdf:system-source-directory :lightfast)))))))

(defun load-library ()
  (unless *library-loaded-p*
    (let ((path (bridge-library-path)))
      (unless (probe-file path)
        (error "Native Lightfast bridge is missing at ~A. Run `make native` first."
               path))
      (let ((stale (bridge-stale-source path)))
        (when stale
          ;; A warning rather than an error: a build deliberately kept behind
          ;; its sources is somebody's business, and refusing to start would
          ;; take the application down over it. Naming the file that is newer
          ;; and the library that is not is enough to act on.
          (warn "Lightfast's native bridge at ~A is older than ~A. ~
                 Run `make` in ~A, or anything those sources added — new stock ~
                 icons, new entry points — will be missing without saying so."
                path (file-namestring stale)
                (asdf:system-source-directory :lightfast))))
      (cffi:load-foreign-library path)
      (setf *library-loaded-p* t))))

(defun next-callback-token (callback)
  (let ((token (incf *callback-token-counter*)))
    (setf (gethash token *callback-registry*) callback)
    token))

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
      (funcall callback
               widget-id
               event
               (if (cffi:null-pointer-p value)
                   ""
                   (cffi:foreign-string-to-lisp value))))))

(cffi:defcfun ("clfl_apply_classic_theme" %apply-classic-theme) :void)

(cffi:defcfun ("clfl_widget_create" %widget-create) :long-long
  (kind      :int)
  (parent-id :long-long)
  (x         :int)
  (y         :int)
  (width     :int)
  (height    :int)
  (label     :string))

(cffi:defcfun ("clfl_widget_destroy" %widget-destroy) :int
  (id :long-long))

(cffi:defcfun ("clfl_window_show" %window-show) :void
  (id :long-long))

(cffi:defcfun ("clfl_window_hide" %window-hide) :void
  (id :long-long))

(cffi:defcfun ("clfl_window_cancel_close" %window-cancel-close) :void
  (id :long-long))

(cffi:defcfun ("clfl_window_set_modal" %window-set-modal) :void
  (id :long-long)
  (enabled :int))

(cffi:defcfun ("clfl_event_clicks" %event-clicks) :int)

(cffi:defcfun ("clfl_event_key" %event-key) :int)

(cffi:defcfun ("clfl_widget_take_focus" %widget-take-focus) :void
  (id :long-long))

(cffi:defcfun ("clfl_widget_set_when" %widget-set-when) :void
  (id :long-long)
  (when :int))

(cffi:defcfun ("clfl_window_set_escape_closes" %window-set-escape-closes) :void
  (id      :long-long)
  (enabled :int))

(cffi:defcfun ("clfl_window_set_size_range" %window-set-size-range) :void
  (id         :long-long)
  (min-width  :int)
  (min-height :int)
  (max-width  :int)
  (max-height :int))

(cffi:defcfun ("clfl_window_set_app_id" %window-set-app-id) :void
  (id     :long-long)
  (app-id :string))

(cffi:defcfun ("clfl_window_get_app_id" %window-get-app-id) :pointer
  (id :long-long))

(cffi:defcfun ("clfl_widget_redraw" %widget-redraw) :void
  (id :long-long))

(cffi:defcfun ("clfl_widget_set_label" %widget-set-label) :void
  (id    :long-long)
  (label :string))

(cffi:defcfun ("clfl_widget_get_label" %widget-get-label) :pointer
  (id :long-long))

(cffi:defcfun ("clfl_widget_set_value" %widget-set-value) :void
  (id    :long-long)
  (value :string))

(cffi:defcfun ("clfl_widget_get_value" %widget-get-value) :pointer
  (id :long-long))

(cffi:defcfun ("clfl_widget_set_stock_icon" %widget-set-stock-icon) :void
  (id   :long-long)
  (name :string))

(cffi:defcfun ("clfl_string_free" %string-free) :void
  (value :pointer))

(cffi:defcfun ("clfl_widget_set_callback" %widget-set-callback) :int
  (id       :long-long)
  (callback :pointer)
  (token    :long-long)
  (event    :int))

(cffi:defcfun ("clfl_widget_resize" %widget-resize) :void
  (id     :long-long)
  (x      :int)
  (y      :int)
  (width  :int)
  (height :int))

(cffi:defcfun ("clfl_widget_x" %widget-native-x) :int
  (id :long-long))

(cffi:defcfun ("clfl_widget_y" %widget-native-y) :int
  (id :long-long))

(cffi:defcfun ("clfl_widget_width" %widget-native-width) :int
  (id :long-long))

(cffi:defcfun ("clfl_widget_height" %widget-native-height) :int
  (id :long-long))

(cffi:defcfun ("clfl_menu_add" %menu-add) :int
  (id       :long-long)
  (path     :string)
  (shortcut :int)
  (callback :pointer)
  (token    :long-long)
  (flags    :int))

(cffi:defcfun ("clfl_menu_set_item_checked" %menu-set-item-checked) :int
  (id      :long-long)
  (path    :string)
  (checked :int))

(cffi:defcfun ("clfl_menu_set_item_mode" %menu-set-item-mode) :int
  (id   :long-long)
  (path :string)
  (mode :int))

(cffi:defcfun ("clfl_widget_set_box" %widget-set-box) :void
  (id  :long-long)
  (box :int))

(cffi:defcfun ("clfl_widget_set_label_size" %widget-set-label-size) :void
  (id   :long-long)
  (size :int))

(cffi:defcfun ("clfl_widget_set_label_font" %widget-set-label-font) :void
  (id   :long-long)
  (font :int))

(cffi:defcfun ("clfl_widget_set_tooltip" %widget-set-tooltip) :void
  (id      :long-long)
  (tooltip :string))

(cffi:defcfun ("clfl_widget_set_text_size" %widget-set-text-size) :void
  (id   :long-long)
  (size :int))

(cffi:defcfun ("clfl_widget_set_text_font" %widget-set-text-font) :void
  (id   :long-long)
  (font :int))

(cffi:defcfun ("clfl_widget_set_color_rgb" %widget-set-color-rgb) :void
  (id    :long-long)
  (red   :int)
  (green :int)
  (blue  :int))

(cffi:defcfun ("clfl_widget_set_cursor" %widget-set-cursor) :void
  (id     :long-long)
  (cursor :int))

(cffi:defcfun ("clfl_draw_set_color_rgb" %draw-set-color-rgb) :void
  (red   :int)
  (green :int)
  (blue  :int))

(cffi:defcfun ("clfl_draw_set_font" %draw-set-font) :void
  (font :int)
  (size :int))

(cffi:defcfun ("clfl_draw_line" %draw-line) :void
  (x1 :int)
  (y1 :int)
  (x2 :int)
  (y2 :int))

(cffi:defcfun ("clfl_draw_rect" %draw-rect) :void
  (x      :int)
  (y      :int)
  (width  :int)
  (height :int))

(cffi:defcfun ("clfl_draw_filled_rect" %draw-filled-rect) :void
  (x      :int)
  (y      :int)
  (width  :int)
  (height :int))

(cffi:defcfun ("clfl_draw_circle" %draw-circle) :void
  (x      :int)
  (y      :int)
  (radius :int))

(cffi:defcfun ("clfl_draw_filled_circle" %draw-filled-circle) :void
  (x      :int)
  (y      :int)
  (radius :int))

(cffi:defcfun ("clfl_draw_stock_icon" %draw-stock-icon) :void
  (name :string)
  (x    :int)
  (y    :int))

(cffi:defcfun ("clfl_window_set_icon" %window-set-icon) :void
  (id   :long-long)
  (name :string))

(cffi:defcfun ("clfl_draw_text" %draw-text) :void
  (text   :string)
  (x      :int)
  (y      :int)
  (width  :int)
  (height :int)
  (align  :int))

(cffi:defcfun ("clfl_draw_push_clip" %draw-push-clip) :void
  (x      :int)
  (y      :int)
  (width  :int)
  (height :int))

(cffi:defcfun ("clfl_draw_pop_clip" %draw-pop-clip) :void)

(cffi:defcfun ("clfl_widget_set_range" %widget-set-range) :void
  (id      :long-long)
  (minimum :double)
  (maximum :double))

(cffi:defcfun ("clfl_widget_set_step" %widget-set-step) :void
  (id   :long-long)
  (step :double))

(cffi:defcfun ("clfl_choice_add" %choice-add) :void
  (id    :long-long)
  (label :string))

(cffi:defcfun ("clfl_browser_add" %browser-add) :void
  (id    :long-long)
  (label :string))

(cffi:defcfun ("clfl_browser_set_column_widths" %browser-set-column-widths) :void
  (id     :long-long)
  (widths :pointer)
  (count  :int))

(cffi:defcfun ("clfl_tree_add" %tree-add) :void
  (id   :long-long)
  (path :string))

(cffi:defcfun ("clfl_browser_select" %browser-select) :void
  (id    :long-long)
  (index :int))

(cffi:defcfun ("clfl_check_browser_add" %check-browser-add) :void
  (id      :long-long)
  (label   :string)
  (checked :int))

(cffi:defcfun ("clfl_check_browser_count" %check-browser-count) :int
  (id :long-long))

(cffi:defcfun ("clfl_check_browser_checked_count" %check-browser-checked-count) :int
  (id :long-long))

(cffi:defcfun ("clfl_check_browser_checked" %check-browser-checked) :int
  (id    :long-long)
  (index :int))

(cffi:defcfun ("clfl_check_browser_set_checked" %check-browser-set-checked) :void
  (id      :long-long)
  (index   :int)
  (checked :int))

(cffi:defcfun ("clfl_check_browser_check_all" %check-browser-check-all) :void
  (id :long-long))

(cffi:defcfun ("clfl_check_browser_check_none" %check-browser-check-none) :void
  (id :long-long))

(cffi:defcfun ("clfl_check_browser_text" %check-browser-text) :pointer
  (id    :long-long)
  (index :int))

(cffi:defcfun ("clfl_file_browser_load" %file-browser-load) :int
  (id        :long-long)
  (directory :string))

(cffi:defcfun ("clfl_file_browser_set_filter" %file-browser-set-filter) :void
  (id      :long-long)
  (pattern :string))

(cffi:defcfun ("clfl_file_browser_set_filetype" %file-browser-set-filetype) :void
  (id       :long-long)
  (filetype :int))

(cffi:defcfun ("clfl_menu_button_set_popup" %menu-button-set-popup) :void
  (id      :long-long)
  (buttons :int))

(cffi:defcfun ("clfl_tile_size_range" %tile-size-range) :void
  (id         :long-long)
  (child-id   :long-long)
  (min-width  :int)
  (min-height :int)
  (max-width  :int)
  (max-height :int))

(cffi:defcfun ("clfl_group_init_sizes" %group-init-sizes) :void
  (id :long-long))

(cffi:defcfun ("clfl_scrollbar_set_vertical" %scrollbar-set-vertical) :void
  (id       :long-long)
  (vertical :int))

(cffi:defcfun ("clfl_flex_set_type" %flex-set-type) :void
  (id         :long-long)
  (horizontal :int))

(cffi:defcfun ("clfl_flex_set_gap" %flex-set-gap) :void
  (id  :long-long)
  (gap :int))

(cffi:defcfun ("clfl_flex_set_margin" %flex-set-margin) :void
  (id     :long-long)
  (left   :int)
  (top    :int)
  (right  :int)
  (bottom :int))

(cffi:defcfun ("clfl_flex_fixed" %flex-fixed) :void
  (id       :long-long)
  (child-id :long-long)
  (size     :int))

(cffi:defcfun ("clfl_flex_layout" %flex-layout) :void
  (id :long-long))

(cffi:defcfun ("clfl_table_set_size" %table-set-size) :void
  (id      :long-long)
  (rows    :int)
  (columns :int))

(cffi:defcfun ("clfl_table_set_column_label" %table-set-column-label) :void
  (id     :long-long)
  (column :int)
  (label  :string))

(cffi:defcfun ("clfl_table_set_column_width" %table-set-column-width) :void
  (id     :long-long)
  (column :int)
  (width  :int))

(cffi:defcfun ("clfl_table_set_cell" %table-set-cell) :void
  (id     :long-long)
  (row    :int)
  (column :int)
  (value  :string))

(cffi:defcfun ("clfl_table_get_cell" %table-get-cell) :pointer
  (id     :long-long)
  (row    :int)
  (column :int))

(cffi:defcfun ("clfl_table_selected_row" %table-selected-row) :int
  (id :long-long))

(cffi:defcfun ("clfl_table_selected_rows" %table-selected-rows) :pointer
  (id :long-long))

(cffi:defcfun ("clfl_table_select_row" %table-select-row) :void
  (id  :long-long)
  (row :int))

(cffi:defcfun ("clfl_table_column_width" %table-column-width) :int
  (id     :long-long)
  (column :int))

(cffi:defcfun ("clfl_widget_clear" %widget-clear) :void
  (id :long-long))

(cffi:defcfun ("clfl_pack_set_orientation" %pack-set-orientation) :int
  (id         :long-long)
  (horizontal :int))

(cffi:defcfun ("clfl_pack_set_spacing" %pack-set-spacing) :int
  (id      :long-long)
  (spacing :int))

(cffi:defcfun ("clfl_grid_layout" %grid-layout) :int
  (id         :long-long)
  (rows       :int)
  (columns    :int)
  (margin     :int)
  (row-gap    :int)
  (column-gap :int))

(cffi:defcfun ("clfl_grid_place" %grid-place) :int
  (id          :long-long)
  (child-id    :long-long)
  (row         :int)
  (column      :int)
  (row-span    :int)
  (column-span :int)
  (alignment   :int))

(cffi:defcfun ("clfl_grid_set_row_height" %grid-set-row-height) :int
  (id     :long-long)
  (row    :int)
  (height :int))

(cffi:defcfun ("clfl_grid_set_row_weight" %grid-set-row-weight) :int
  (id     :long-long)
  (row    :int)
  (weight :int))

(cffi:defcfun ("clfl_grid_set_column_width" %grid-set-column-width) :int
  (id     :long-long)
  (column :int)
  (width  :int))

(cffi:defcfun ("clfl_grid_set_column_weight" %grid-set-column-weight) :int
  (id     :long-long)
  (column :int)
  (weight :int))

(cffi:defcfun ("clfl_positioner_set_value" %positioner-set-value) :int
  (id :long-long)
  (x  :double)
  (y  :double))

(cffi:defcfun ("clfl_positioner_get_value" %positioner-get-value) :int
  (id :long-long)
  (x  :pointer)
  (y  :pointer))

(cffi:defcfun ("clfl_positioner_set_bounds" %positioner-set-bounds) :int
  (id        :long-long)
  (x-minimum :double)
  (x-maximum :double)
  (y-minimum :double)
  (y-maximum :double))

(cffi:defcfun ("clfl_positioner_set_steps" %positioner-set-steps) :int
  (id     :long-long)
  (x-step :double)
  (y-step :double))

(cffi:defcfun ("clfl_wizard_next" %wizard-next) :int
  (id :long-long))

(cffi:defcfun ("clfl_wizard_previous" %wizard-previous) :int
  (id :long-long))

(cffi:defcfun ("clfl_wizard_current" %wizard-current) :long-long
  (id :long-long))

(cffi:defcfun ("clfl_wizard_set_current" %wizard-set-current) :int
  (id       :long-long)
  (child-id :long-long))

(cffi:defcfun ("clfl_chart_add" %chart-add) :int
  (id    :long-long)
  (value :double)
  (label :string)
  (color :unsigned-int))

(cffi:defcfun ("clfl_chart_insert" %chart-insert) :int
  (id    :long-long)
  (index :int)
  (value :double)
  (label :string)
  (color :unsigned-int))

(cffi:defcfun ("clfl_chart_replace" %chart-replace) :int
  (id    :long-long)
  (index :int)
  (value :double)
  (label :string)
  (color :unsigned-int))

(cffi:defcfun ("clfl_chart_clear" %chart-clear) :int
  (id :long-long))

(cffi:defcfun ("clfl_chart_set_bounds" %chart-set-bounds) :int
  (id      :long-long)
  (minimum :double)
  (maximum :double))

(cffi:defcfun ("clfl_chart_set_type" %chart-set-type) :int
  (id   :long-long)
  (type :int))

(cffi:defcfun ("clfl_terminal_append" %terminal-append) :int
  (id   :long-long)
  (text :string))

(cffi:defcfun ("clfl_terminal_clear" %terminal-clear) :int
  (id :long-long))

(cffi:defcfun ("clfl_terminal_text" %terminal-text) :pointer
  (id :long-long))

(cffi:defcfun ("clfl_color_chooser_set_rgb" %color-chooser-set-rgb) :int
  (id    :long-long)
  (red   :double)
  (green :double)
  (blue  :double))

(cffi:defcfun ("clfl_color_chooser_get_rgb" %color-chooser-get-rgb) :int
  (id    :long-long)
  (red   :pointer)
  (green :pointer)
  (blue  :pointer))

(cffi:defcfun ("clfl_shortcut_button_set_shortcut" %shortcut-button-set-shortcut) :int
  (id       :long-long)
  (shortcut :unsigned-int))

(cffi:defcfun ("clfl_shortcut_button_get_shortcut" %shortcut-button-get-shortcut) :unsigned-int
  (id :long-long))

(cffi:defcfun ("clfl_browser_set_selection_mode" %browser-set-selection-mode) :int
  (id   :long-long)
  (mode :int))

(cffi:defcfun ("clfl_browser_set_selected" %browser-set-selected) :int
  (id       :long-long)
  (index    :int)
  (selected :int))

(cffi:defcfun ("clfl_browser_selected_indices" %browser-selected-indices) :pointer
  (id :long-long))

(cffi:defcfun ("clfl_copy_text" %copy-text) :void
  (value :string))

(cffi:defcfun ("clfl_popup_menu" %popup-menu) :int
  (items :pointer)
  (count :int))

(cffi:defcfun ("clfl_input_dialog" %input-dialog) :pointer
  (message :string)
  (initial :string))

(cffi:defcfun ("clfl_color_chooser" %color-chooser) :int
  (title :string)
  (red :pointer)
  (green :pointer)
  (blue :pointer))

(cffi:defcfun ("clfl_choose_file" %choose-file) :pointer
  (title       :string)
  (filter      :string)
  (preset-file :string))

(cffi:defcfun ("clfl_choose_files" %choose-files) :pointer
  (title       :string)
  (filter      :string)
  (preset-file :string))

(cffi:defcfun ("clfl_choose_save_file" %choose-save-file) :pointer
  (title       :string)
  (filter      :string)
  (preset-file :string))

(cffi:defcfun ("clfl_choose_directory" %choose-directory) :pointer
  (title       :string)
  (preset-path :string))

(cffi:defcfun ("clfl_message_box" %message-box) :void
  (message :string))

(cffi:defcfun ("clfl_alert_box" %alert-box) :void
  (message :string))

(cffi:defcfun ("clfl_choice_box" %choice-box) :int
  (message :string)
  (button0 :string)
  (button1 :string)
  (button2 :string))

(cffi:defcfun ("clfl_add_timeout" %add-timeout) :long-long
  (seconds  :double)
  (repeat   :int)
  (callback :pointer)
  (token    :long-long))

(cffi:defcfun ("clfl_remove_timeout" %remove-timeout) :int
  (id :long-long))

(cffi:defcfun ("clfl_quit" %quit) :void)

(cffi:defcfun ("clfl_run" %run) :int)
(cffi:defcfun ("clfl_check" %check) :int)

(cffi:defcfun ("clfl_wait" %wait) :int
  (seconds :double))

(defun foreign-string (reader)
  (let ((pointer (funcall reader)))
    (unwind-protect
         (if (cffi:null-pointer-p pointer)
             ""
             (cffi:foreign-string-to-lisp pointer))
      (unless (cffi:null-pointer-p pointer)
        (%string-free pointer)))))
