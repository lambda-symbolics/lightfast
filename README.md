# Lightfast

Small, direct Common Lisp bindings for FLTK 1.4.

Requires SBCL with ASDF and CFFI, FLTK 1.4 with `fltk-config`, and a C++17 compiler.

```sh
make
make smoke
make layout-smoke
make widget-smoke
make demo
```

```lisp
(asdf:load-system :lightfast)
```

The `cl-fltk` ASDF system and package nickname remain available for compatibility.

## Automatic layout

Lightfast includes a deterministic, single-line flex layout engine for ordinary
nested rows and columns. It supports padding, gaps, natural or fixed bases,
weighted growth and shrinking, minimum and maximum dimensions, justification,
and cross-axis alignment. Layout calculation is pure; applying it to FLTK
widgets is a separate operation.

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
space. The initial engine intentionally does not implement wrapping, CSS
parsing, percentages, or a constraint solver.
