# Repository Guidelines

## Purpose

Lightfast is a small, direct Common Lisp interface to FLTK 1.4. It provides a
focused native bridge, idiomatic Lisp constructors and operations, reusable
widget composition, geometry, and automatic layout facilities.

Keep Lightfast a general-purpose library. Do not add Orfeus, CRM, or other
application-specific behavior. Build the smallest complete, testable API before
broadening it, and avoid speculative abstractions or silent partial features.

## Architecture

- Keep the C++ bridge narrow and expose stable `clfl_*` ABI functions rather
  than FLTK implementation details.
- Keep widget construction and operations in Lisp where native code is not
  required.
- Preserve the `cl-fltk` ASDF compatibility system and package nickname.
- Keep geometry and automatic layout calculation pure and deterministic where
  possible. Applying a calculated layout to widgets is a separate boundary.
- Prefer structural layout APIs over repeated application-level coordinate
  arithmetic. Use native FLTK layout widgets when they improve behavior, but do
  not leak unexplained native constants into application code.
- Keep focused subsystems in focused files. Avoid unrelated refactors while
  adding a widget or layout capability.
- Support Linux x86-64, SBCL, CFFI, C++17, and FLTK 1.4.

## Common Lisp Style

- Define project packages once, `:use` only `#:cl`, and qualify or import
  third-party symbols explicitly.
- Use focused files organized by coherent responsibility. Do not create generic
  `misc`, `helpers`, or growing utility dumping grounds.
- Use kebab-case without unclear abbreviations. Prefix entity operations,
  suffix predicates with `-p`, and use `->` for conversions.
- Use `defparameter` for reloadable policy and `defvar` only for process state
  intended to survive reload.
- Prefer `first` and `rest` over `car` and `cdr` in application code.
- Use keyword arguments when a function has four or more parameters.
- Document exported functions, classes, generic functions, macros, and
  conditions.
- Use typed domain conditions with useful reports. Offer restarts for failures
  that callers can reasonably recover from.
- Add declarations only when they clarify an invariant or improve a measured
  hot path.

## Tests and Verification

- Cover successful and failing paths at native and public Lisp boundaries.
- Keep pure geometry and layout tests deterministic and display-independent.
- Build the native bridge and run load, layout, and widget smoke tests before
  committing behavior changes.
- Add a permanent visual fixture for GUI behavior that cannot be established by
  assertions alone, and inspect it at representative window sizes.
- Verify both the `lightfast` and compatibility `cl-fltk` system/package names.
- Keep small generated test artifacts outside the repository or under ignored
  build directories.

## Dependencies and Generated Files

- Declare Lisp dependencies in ASDF and native build dependencies in the
  Makefile or reproducible environment definitions.
- Do not commit `build/`, FASLs, shared libraries, screenshots, caches, or
  machine-local configuration.
- Keep credentials, personal paths, and application data out of source, tests,
  logs, and fixtures.
- Preserve attribution and licenses for any redistributed third-party assets.

## Commit Policy

Work directly on `master`. Make frequent, small, coherent commits as soon as
their focused checks pass. Commit messages contain only an imperative title
line, normally under 72 characters. Do not add a body, issue footer, or generated
attribution. Stage only files belonging to the commit and preserve unrelated
work. Push `master` immediately after every commit. Never force-push or rewrite
published history unless the user explicitly requests it.
