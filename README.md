# Lightfast

Small, direct Common Lisp bindings for FLTK 1.4.

Requires SBCL with ASDF and CFFI, FLTK 1.4 with `fltk-config`, and a C++17
compiler, on Linux x86-64 or macOS arm64. Linux also needs the Pango and
fontconfig development files; see [macOS](#macos) for that platform. The
bridge also builds on NetBSD amd64 with FLTK from pkgsrc; the Makefile is GNU
make's, so run `gmake` there.

```sh
make              # build/liblightfast.so, or build/liblightfast.dylib on macOS
make check        # every smoke test below
make check-headless   # smoke and layout-smoke, which need no display
make check-display    # the rest, which open windows
make smoke
make layout-smoke
make widget-smoke
make awake-smoke
make font-smoke
make text-smoke
make canvas-smoke
make demo
```

```lisp
(asdf:load-system :lightfast)
```

The `cl-fltk` ASDF system and package nickname are aliases for Lightfast.

`load-library` loads the bridge `make` built under the system's directory. An
application that ships a prebuilt bridge names the file in the environment
variable `LIGHTFAST_LIBRARY` instead.

Every call into the bridge runs with floating point traps masked, since FLTK
and the toolkits under it compute with NaN and infinity as a matter of
course, and every callback runs with the traps Lisp had. Declare a new foreign function with
`define-bridge-function`, never `cffi:defcfun`, or it skips the mask.

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

An application carries its own typefaces with `register-font-file`, which
makes a `.ttf` or `.otf` file available to this process without installing
it. Register before the face is first loaded:

```lisp
(lightfast:register-font-file "fonts/cmu-typewriter-regular.ttf")
(lightfast:load-font "CMU Typewriter Text")
```

`register-font-files` takes a list and reports the files that were refused.

## Menus and shortcuts

`make-menu-bar` makes a bar that `add-menu-item` and `add-menu-tree` fill. A
shortcut is a key with modifiers: `+modifier-command+` is Control, and
Command on macOS, so a shortcut written with it follows each platform's
habit. `+modifier-control+`, `+modifier-shift+`, `+modifier-alt+` and
`+modifier-meta+` name the keys themselves, in shortcuts and in the state a
key or mouse callback is handed.

```lisp
(let* ((menu (lightfast:make-menu-bar :parent window :width 640 :height 24 :system t))
       ;; A bar that went to the system takes no room in the window.
       (top (if (lightfast:menu-bar-system-p menu) 0 24)))
  (lightfast:add-menu-item menu "File/Save" #'save
                           :shortcut (logior lightfast:+modifier-command+ (char-code #\s)))
  (lightfast:make-text-editor :parent window :y top :width 640 :height (- 480 top)))
```

With `:system t` the bar is the system menu bar on macOS and an ordinary bar
everywhere else; `menu-bar-system-p` tells which.

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

`text-position-at` maps a click to a byte position, `text-line-of-position`,
`text-top-line` and `text-at-end-p` support scrolling and following,
`text-set-scrollbars` chooses which scrollbars a display may show, and `text-selection` reads what the
user selected; Ctrl+C copies it, Command+C on macOS. Text editors and displays offer every key to
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

## macOS

Lightfast runs on macOS arm64 with FLTK and SBCL from Homebrew:

```sh
brew install fltk sbcl
make
make check
```

The bridge is `build/liblightfast.dylib`. It loads Homebrew's shared FLTK
(`libfltk` and `libfltk_images`), libpng and jpeg from `/opt/homebrew/opt`, so
an application that ships the bridge ships those libraries with it, links a
static FLTK instead, or relies on Homebrew being there.

- FLTK belongs on the process's main thread. `sbcl --script`, `--load` and
  `--eval` run there; a REPL served by SLIME or Sly evaluates on another
  thread and cannot open windows.
- Started from a shell rather than an application bundle, the process still
  becomes a foreground application: its window comes to the front as the key
  window and it gets a Dock icon, the generic one for an executable. The
  system names it after its executable, so the application menu reads `sbcl`
  until the program lives in a bundle.
- `make-menu-bar :system t` puts the menus in the menu bar at the top of the
  screen. FLTK supplies the application menu, with Quit under Command+Q, and
  a Window menu, which it adds when the first window is shown: make the
  system menu bar and fill it before that, and the Window menu follows the
  application's own. Made later, the bar has no Window menu. Quit asks each
  window to close, so `+event-close+` callbacks run and may refuse.
- A process has one system menu bar, which goes when its parent window is
  destroyed. Asking for a second while the first exists gives an ordinary bar
  in the window, so an application with several windows gives the menu to
  the window that lives longest.
- Write shortcuts with `+modifier-command+`. `+modifier-control+` is the
  Control key, which Mac menus show as `^`.
- `load-font` takes a family and style words (`"Times New Roman Bold"`) or a
  PostScript name (`"TimesNewRomanPS-BoldMT"`); `system-font-names` returns
  full names. A name nothing answers to draws in a fallback face.
- `correct-font-baselines` does nothing here and returns `NIL`: the fault it
  corrects belongs to FLTK's Cairo text driver, and CoreText places text by
  the face's own ascent. Call it the same way on every platform.
- `quit` and anything else that touches a window must run on the main
  thread; Cocoa ends the process otherwise. Other threads hand work over
  with `awake` or `wake`; `quit` does so by itself once
  `enable-thread-wakeups` has run.
- `capture-window` renders at one pixel per FLTK unit, on a Retina display
  too.
