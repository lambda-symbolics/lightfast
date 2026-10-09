# Lightfast

Small, direct Common Lisp bindings for FLTK 1.4.

Requires SBCL with ASDF and CFFI, FLTK 1.4 with `fltk-config`, and a C++17 compiler.

```sh
make
make smoke
make layout-smoke
make widget-smoke
make awake-smoke
make font-smoke
make demo
```

```lisp
(asdf:load-system :lightfast)
```

The `cl-fltk` ASDF system and package nickname are aliases for Lightfast.

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
