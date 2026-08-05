(in-package #:lightfast)

;;; Reusable FLTK 1.4 widget operations with Lisp-level names and validation.

(defun %require-widget-kind (widget expected operation)
  (unless (and (widget-p widget) (= (widget-kind widget) expected))
    (error "~A requires widget kind ~D, not ~S." operation expected widget))
  widget)

(defun %require-integer-at-least (value minimum name)
  (unless (and (integerp value) (>= value minimum))
    (error "~A must be an integer greater than or equal to ~D, not ~S."
           name minimum value))
  value)

(defun %require-real (value name)
  (unless (realp value)
    (error "~A must be a real number, not ~S." name value))
  (coerce value 'double-float))

(defun %require-unit-real (value name)
  (let ((number (%require-real value name)))
    (unless (<= 0.0d0 number 1.0d0)
      (error "~A must be between 0 and 1 inclusive, not ~S." name value))
    number))

(defun %call-widget-operation (success operation widget)
  (unless (plusp success)
    (error "FLTK rejected ~A for widget ~D." operation (widget-id widget)))
  widget)

(defun pack-set-orientation (pack orientation)
  "Set PACK's layout ORIENTATION to :HORIZONTAL or :VERTICAL."
  (%require-widget-kind pack +widget-pack+ 'pack-set-orientation)
  (%call-widget-operation
   (%pack-set-orientation (widget-id pack)
                          (ecase orientation
                            (:vertical 0)
                            (:horizontal 1)))
   'pack-set-orientation
   pack))

(defun pack-set-spacing (pack spacing)
  "Set the non-negative pixel SPACING between children of PACK."
  (%require-widget-kind pack +widget-pack+ 'pack-set-spacing)
  (%call-widget-operation
   (%pack-set-spacing (widget-id pack)
                      (%require-integer-at-least spacing 0 'spacing))
   'pack-set-spacing
   pack))

(defun grid-layout (grid &key rows columns (margin 0) (row-gap 0) (column-gap 0))
  "Configure GRID with positive ROWS and COLUMNS and non-negative pixel gaps."
  (%require-widget-kind grid +widget-grid+ 'grid-layout)
  (%call-widget-operation
   (%grid-layout (widget-id grid)
                 (%require-integer-at-least rows 1 'rows)
                 (%require-integer-at-least columns 1 'columns)
                 (%require-integer-at-least margin 0 'margin)
                 (%require-integer-at-least row-gap 0 'row-gap)
                 (%require-integer-at-least column-gap 0 'column-gap))
   'grid-layout
   grid))

(defun grid-place (grid child &key row column (row-span 1) (column-span 1)
                                      (alignment :fill))
  "Place CHILD in GRID using 0-based ROW and COLUMN coordinates.
ALIGNMENT is one of :FILL, :CENTER, :LEFT, :RIGHT, :TOP, :BOTTOM,
:TOP-LEFT, :TOP-RIGHT, :BOTTOM-LEFT, :BOTTOM-RIGHT, or :PROPORTIONAL."
  (%require-widget-kind grid +widget-grid+ 'grid-place)
  (unless (widget-p child)
    (error "CHILD must be a widget, not ~S." child))
  (%call-widget-operation
   (%grid-place (widget-id grid)
                (widget-id child)
                (%require-integer-at-least row 0 'row)
                (%require-integer-at-least column 0 'column)
                (%require-integer-at-least row-span 1 'row-span)
                (%require-integer-at-least column-span 1 'column-span)
                (ecase alignment
                  (:fill 0)
                  (:center 1)
                  (:left 2)
                  (:right 3)
                  (:top 4)
                  (:bottom 5)
                  (:top-left 6)
                  (:top-right 7)
                  (:bottom-left 8)
                  (:bottom-right 9)
                  (:proportional 10)))
   'grid-place
   grid))

(defun grid-set-row-height (grid row height)
  "Set GRID row ROW's minimum HEIGHT in pixels."
  (%require-widget-kind grid +widget-grid+ 'grid-set-row-height)
  (%call-widget-operation
   (%grid-set-row-height (widget-id grid)
                         (%require-integer-at-least row 0 'row)
                         (%require-integer-at-least height 0 'height))
   'grid-set-row-height grid))

(defun grid-set-row-weight (grid row weight)
  "Set GRID row ROW's non-negative expansion WEIGHT."
  (%require-widget-kind grid +widget-grid+ 'grid-set-row-weight)
  (%call-widget-operation
   (%grid-set-row-weight (widget-id grid)
                         (%require-integer-at-least row 0 'row)
                         (%require-integer-at-least weight 0 'weight))
   'grid-set-row-weight grid))

(defun grid-set-column-width (grid column width)
  "Set GRID column COLUMN's minimum WIDTH in pixels."
  (%require-widget-kind grid +widget-grid+ 'grid-set-column-width)
  (%call-widget-operation
   (%grid-set-column-width (widget-id grid)
                           (%require-integer-at-least column 0 'column)
                           (%require-integer-at-least width 0 'width))
   'grid-set-column-width grid))

(defun grid-set-column-weight (grid column weight)
  "Set GRID column COLUMN's non-negative expansion WEIGHT."
  (%require-widget-kind grid +widget-grid+ 'grid-set-column-weight)
  (%call-widget-operation
   (%grid-set-column-weight (widget-id grid)
                            (%require-integer-at-least column 0 'column)
                            (%require-integer-at-least weight 0 'weight))
   'grid-set-column-weight grid))

(defun positioner-values (positioner)
  "Return POSITIONER's X and Y values as two values."
  (%require-widget-kind positioner +widget-positioner+ 'positioner-values)
  (cffi:with-foreign-objects ((x :double) (y :double))
    (unless (plusp (%positioner-get-value (widget-id positioner) x y))
      (error "FLTK could not read positioner widget ~D." (widget-id positioner)))
    (values (cffi:mem-ref x :double)
            (cffi:mem-ref y :double))))

(defun positioner-set-value (positioner &key x y)
  "Set POSITIONER's X and Y values."
  (%require-widget-kind positioner +widget-positioner+ 'positioner-set-value)
  (%call-widget-operation
   (%positioner-set-value (widget-id positioner)
                          (%require-real x 'x)
                          (%require-real y 'y))
   'positioner-set-value
   positioner))

(defun positioner-set-bounds
    (positioner &key x-minimum x-maximum y-minimum y-maximum)
  "Set the inclusive X and Y bounds of POSITIONER."
  (%require-widget-kind positioner +widget-positioner+ 'positioner-set-bounds)
  (let ((x-min (%require-real x-minimum 'x-minimum))
        (x-max (%require-real x-maximum 'x-maximum))
        (y-min (%require-real y-minimum 'y-minimum))
        (y-max (%require-real y-maximum 'y-maximum)))
    (unless (and (<= x-min x-max) (<= y-min y-max))
      (error "Positioner minimum bounds must not exceed maximum bounds."))
    (%call-widget-operation
     (%positioner-set-bounds (widget-id positioner) x-min x-max y-min y-max)
     'positioner-set-bounds
     positioner)))

(defun positioner-set-steps (positioner &key (x-step 0) (y-step 0))
  "Set POSITIONER's non-negative X and Y quantization steps; zero is continuous."
  (%require-widget-kind positioner +widget-positioner+ 'positioner-set-steps)
  (let ((x (%require-real x-step 'x-step))
        (y (%require-real y-step 'y-step)))
    (unless (and (>= x 0.0d0) (>= y 0.0d0))
      (error "Positioner steps must be non-negative."))
    (%call-widget-operation
     (%positioner-set-steps (widget-id positioner) x y)
     'positioner-set-steps
     positioner)))

(defun wizard-next (wizard)
  "Show the child after WIZARD's current child."
  (%require-widget-kind wizard +widget-wizard+ 'wizard-next)
  (%call-widget-operation (%wizard-next (widget-id wizard)) 'wizard-next wizard))

(defun wizard-previous (wizard)
  "Show the child before WIZARD's current child."
  (%require-widget-kind wizard +widget-wizard+ 'wizard-previous)
  (%call-widget-operation
   (%wizard-previous (widget-id wizard)) 'wizard-previous wizard))

(defun wizard-current-child (wizard)
  "Return the native widget id of WIZARD's current child, or NIL if none."
  (%require-widget-kind wizard +widget-wizard+ 'wizard-current-child)
  (let ((id (%wizard-current (widget-id wizard))))
    (unless (zerop id) id)))

(defun (setf wizard-current-child) (child wizard)
  "Select CHILD, which must be a direct child of WIZARD."
  (%require-widget-kind wizard +widget-wizard+ '(setf wizard-current-child))
  (unless (widget-p child)
    (error "CHILD must be a widget, not ~S." child))
  (%call-widget-operation
   (%wizard-set-current (widget-id wizard) (widget-id child))
   '(setf wizard-current-child)
   wizard)
  child)

(defun %chart-color (color)
  (unless (and (integerp color) (<= 0 color #xffffffff))
    (error "Chart COLOR must be an unsigned 32-bit integer, not ~S." color))
  color)

(defun chart-add (chart value &key (label "") (color 0))
  "Append VALUE to CHART with optional LABEL and FLTK COLOR value."
  (%require-widget-kind chart +widget-chart+ 'chart-add)
  (%call-widget-operation
   (%chart-add (widget-id chart) (%require-real value 'value)
               (cell-string label) (%chart-color color))
   'chart-add chart))

(defun chart-insert (chart index value &key (label "") (color 0))
  "Insert VALUE before 0-based INDEX in CHART."
  (%require-widget-kind chart +widget-chart+ 'chart-insert)
  (%call-widget-operation
   (%chart-insert (widget-id chart)
                  (%require-integer-at-least index 0 'index)
                  (%require-real value 'value)
                  (cell-string label)
                  (%chart-color color))
   'chart-insert chart))

(defun chart-replace (chart index value &key (label "") (color 0))
  "Replace the entry at 0-based INDEX in CHART."
  (%require-widget-kind chart +widget-chart+ 'chart-replace)
  (%call-widget-operation
   (%chart-replace (widget-id chart)
                   (%require-integer-at-least index 0 'index)
                   (%require-real value 'value)
                   (cell-string label)
                   (%chart-color color))
   'chart-replace chart))

(defun chart-clear (chart)
  "Remove all entries from CHART."
  (%require-widget-kind chart +widget-chart+ 'chart-clear)
  (%call-widget-operation (%chart-clear (widget-id chart)) 'chart-clear chart))

(defun chart-set-bounds (chart &key minimum maximum)
  "Set CHART's inclusive numeric bounds."
  (%require-widget-kind chart +widget-chart+ 'chart-set-bounds)
  (let ((low (%require-real minimum 'minimum))
        (high (%require-real maximum 'maximum)))
    (unless (<= low high)
      (error "Chart MINIMUM must not exceed MAXIMUM."))
    (%call-widget-operation
     (%chart-set-bounds (widget-id chart) low high)
     'chart-set-bounds chart)))

(defun chart-set-type (chart type)
  "Set CHART's TYPE using a named keyword.
TYPE is :BAR, :HORIZONTAL-BAR, :LINE, :FILLED, :SPIKE, :PIE, or :SPECIAL-PIE."
  (%require-widget-kind chart +widget-chart+ 'chart-set-type)
  (%call-widget-operation
   (%chart-set-type (widget-id chart)
                    (ecase type
                      (:bar 0)
                      (:horizontal-bar 1)
                      (:line 2)
                      (:filled 3)
                      (:spike 4)
                      (:pie 5)
                      (:special-pie 6)))
   'chart-set-type chart))

(defun terminal-append (terminal text)
  "Append TEXT to TERMINAL without adding an implicit newline."
  (%require-widget-kind terminal +widget-terminal+ 'terminal-append)
  (%call-widget-operation
   (%terminal-append (widget-id terminal) (cell-string text))
   'terminal-append terminal))

(defun terminal-clear (terminal)
  "Remove all text from TERMINAL."
  (%require-widget-kind terminal +widget-terminal+ 'terminal-clear)
  (%call-widget-operation
   (%terminal-clear (widget-id terminal)) 'terminal-clear terminal))

(defun terminal-text (terminal)
  "Return TERMINAL's complete text."
  (%require-widget-kind terminal +widget-terminal+ 'terminal-text)
  (foreign-string (lambda () (%terminal-text (widget-id terminal)))))

(defun color-chooser-rgb (chooser)
  "Return CHOOSER's red, green, and blue components as three values in [0,1]."
  (%require-widget-kind chooser +widget-color-chooser+ 'color-chooser-rgb)
  (cffi:with-foreign-objects ((red :double) (green :double) (blue :double))
    (unless (plusp (%color-chooser-get-rgb
                    (widget-id chooser) red green blue))
      (error "FLTK could not read color chooser widget ~D." (widget-id chooser)))
    (values (cffi:mem-ref red :double)
            (cffi:mem-ref green :double)
            (cffi:mem-ref blue :double))))

(defun set-color-chooser-rgb (chooser &key red green blue)
  "Set CHOOSER's RED, GREEN, and BLUE components, each in [0,1]."
  (%require-widget-kind chooser +widget-color-chooser+ 'set-color-chooser-rgb)
  (%call-widget-operation
   (%color-chooser-set-rgb (widget-id chooser)
                           (%require-unit-real red 'red)
                           (%require-unit-real green 'green)
                           (%require-unit-real blue 'blue))
   'set-color-chooser-rgb chooser))

(defun shortcut-button-shortcut (button)
  "Return BUTTON's portable unsigned FLTK shortcut value."
  (%require-widget-kind button +widget-shortcut-button+ 'shortcut-button-shortcut)
  (%shortcut-button-get-shortcut (widget-id button)))

(defun (setf shortcut-button-shortcut) (shortcut button)
  "Set BUTTON's unsigned 32-bit FLTK SHORTCUT value."
  (%require-widget-kind button +widget-shortcut-button+
                        '(setf shortcut-button-shortcut))
  (unless (and (integerp shortcut) (<= 0 shortcut #xffffffff))
    (error "SHORTCUT must be an unsigned 32-bit integer, not ~S." shortcut))
  (%call-widget-operation
   (%shortcut-button-set-shortcut (widget-id button) shortcut)
   '(setf shortcut-button-shortcut) button)
  shortcut)

(defun browser-set-selection-mode (browser mode)
  "Set BROWSER selection MODE to :NORMAL, :SINGLE, :HOLD, or :MULTIPLE."
  (%require-widget-kind browser +widget-browser+ 'browser-set-selection-mode)
  (%call-widget-operation
   (%browser-set-selection-mode (widget-id browser)
                                (ecase mode
                                  (:normal 0)
                                  (:single 1)
                                  (:hold 2)
                                  (:multiple 3)))
   'browser-set-selection-mode browser))

(defun browser-set-selected-p (browser index selected-p)
  "Set whether BROWSER's 0-based INDEX is selected."
  (%require-widget-kind browser +widget-browser+ 'browser-set-selected-p)
  (%call-widget-operation
   (%browser-set-selected (widget-id browser)
                          (%require-integer-at-least index 0 'index)
                          (if selected-p 1 0))
   'browser-set-selected-p browser))

(defun %comma-separated-indices (text)
  (if (zerop (length text))
      nil
      (loop with start = 0
            for comma = (position #\, text :start start)
            collect (parse-integer text :start start :end comma)
            while comma
            do (setf start (1+ comma)))))

(defun browser-selected-indices (browser)
  "Return BROWSER's selected 0-based indices in ascending order."
  (%require-widget-kind browser +widget-browser+ 'browser-selected-indices)
  (%comma-separated-indices
   (foreign-string (lambda ()
                     (%browser-selected-indices (widget-id browser))))))
