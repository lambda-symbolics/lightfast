# Lightfast

Small, direct Common Lisp bindings for FLTK 1.4.

Requires SBCL with ASDF and CFFI, FLTK 1.4 with `fltk-config`, and a C++17 compiler.

```sh
make
make smoke
make widget-smoke
make demo
```

```lisp
(asdf:load-system :lightfast)
```

The `cl-fltk` ASDF system and package nickname remain available for compatibility.
