# Lightfast

Small, direct Common Lisp bindings for FLTK 1.4.

Requires SBCL with ASDF and CFFI, FLTK 1.4 with `fltk-config`, and a C++17 compiler.

```sh
make
make check        # every smoke test below
make smoke
make layout-smoke
make widget-smoke
make awake-smoke
make font-smoke
make text-smoke
make demo
```

```lisp
(asdf:load-system :lightfast)
```

The `cl-fltk` ASDF system and package nickname are aliases for Lightfast.

Windows are resizable by default, so tiling compositors tile them; use
`set-size-range` with equal minimum and maximum sizes for a fixed window.

## Themes and fonts

Widgets take their box, colors and fonts from the active theme at creation.
`apply-classic-theme` is the gray bevelled desktop look; `apply-flat-theme`
draws one substrate, hairline boxes and inverted selection:

```lisp
(lightfast:apply-flat-theme :background '(255 254 250)
                            :foreground '(0 0 0)
                            :label-font (lightfast:load-font "Times New Roman")
                            :label-size 16
                            :mono-font  (lightfast:load-font "CMU Typewriter Text"))
```

`load-font` takes a face by its family and style words, `system-font-names`
lists what is installed, and `measure-text` returns the width, height and
descent of a string in a face. `make flat-theme-visual` shows a gallery.

FLTK's Cairo driver draws a face with a line gap in its metrics above the
baseline it was asked for, by the gap. `correct-font-baselines` folds the gap
into the ascender in a cached copy of each affected file and makes this
process use the copies, so the face lands on the baseline beside other faces
in a text display and beside widgets aligned with `align-baselines`. Call it
once after `load-library`, before loading fonts:

```lisp
(lightfast:correct-font-baselines '("Times New Roman MT Std" "CMU Typewriter Text"))
```

`browser-set-scrollbars` chooses which scrollbars a browser may show and
`browser-set-line-spacing` gives its rows room above and below the text.

`font-files` lists a family's files, `font-line-gaps` reads a file's gaps and
`fold-font-line-gap` writes one corrected copy.

## Styled text

A text display takes a style table and text whose every character carries a
style index; positions at this boundary are UTF-8 bytes:

```lisp
(lightfast:text-set-styles display
  (list (list :font serif :size 16 :color '(0 0 0))
        (list :font mono  :size 15 :color '(0 0 0))))
(lightfast:text-append-styled display '(("Prose, then " . 0) ("(code)" . 1)))
(lightfast:text-replace-styled display 0 (lightfast:string-byte-length "Prose") '(("Text" . 0)))
```

`text-position-at` maps a click to a byte position, `text-line-of-position`
and `text-top-line` support scrolling, and `text-selection` reads what the
user selected; Ctrl+C copies it. Text editors and displays offer every key to
an `+event-key+` callback first, which may call `consume-event` to keep it
from the widget.

## Threads and the event loop

Call `enable-thread-wakeups` once on the GUI thread, then let other threads
hand over work and call `awake`. `run-with-idle` runs the loop and calls an
idle function before the first wait and after every wakeup, which is where
the GUI thread drains that work:

```lisp
(lightfast:enable-thread-wakeups)
(lightfast:run-with-idle (lambda () (drain-queue)))
```

## Automatic layout

Lightfast includes a deterministic, single-line flex layout engine for ordinary
nested rows and columns. It supports:

- padding and gaps
- natural or fixed bases
- weighted growth and shrinking
- minimum and maximum dimensions
- justification
- cross-axis alignment

Layout calculation is pure. Applying it to FLTK widgets is a separate operation.

```lisp
(let ((layout
        (lightfast:make-layout-column
         :padding 12
         :gap 8
         :children
         (list
          (lightfast:make-layout-item toolbar :basis 32 :shrink 0)
          (lightfast:make-layout-row
           :grow 1
           :gap 8
           :children
           (list
            (lightfast:make-layout-item sidebar :basis 220)
            (lightfast:make-layout-item preview :basis 0 :grow 1)
            (lightfast:make-layout-item inspector :basis 280)))
          (lightfast:make-layout-item status :basis 24 :shrink 0)))))
  (lightfast:layout-on-resize window layout))
```

Use `compute-layout` for display-independent rectangle calculation and
`apply-layout` for explicit widget resizing. Container nodes may have a target
group; their descendants are then calculated in that group's local coordinate
space.
