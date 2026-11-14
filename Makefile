FLTK_CONFIG ?= fltk-config
CXX ?= c++
RUN_DISPLAY ?= :0

# The host decides the library's name, how it is linked and which font system
# the bridge talks to: fontconfig and Pango on Linux, CoreText on macOS.
HOST := $(shell uname -s)
ifeq ($(HOST),Darwin)
BRIDGE := build/liblightfast.dylib
HOST_CXXFLAGS :=
HOST_LDFLAGS := -dynamiclib
HOST_LIBS := -framework CoreText -framework CoreFoundation
# Cocoa needs no display variable.
GUI_ENV :=
else
BRIDGE := build/liblightfast.so
HOST_CXXFLAGS := $(shell pkg-config --cflags pangoft2 fontconfig)
HOST_LDFLAGS := -shared
HOST_LIBS := $(shell pkg-config --libs pangoft2 fontconfig)
GUI_ENV := DISPLAY=$(RUN_DISPLAY)
endif

SOURCES := native/api_core.cpp \
           native/api_geometry.cpp \
           native/api_metrics.cpp \
           native/api_drawing.cpp \
           native/api_images.cpp \
           native/api_capture.cpp \
           native/api_controls.cpp \
           native/api_dialogs.cpp \
           native/api_fonts.cpp \
           native/api_runtime.cpp \
           native/api_text.cpp \
           native/api_widgets.cpp \
           native/cl_fltk_bridge_state.cpp \
           native/cl_fltk_bridge_events.cpp \
           native/cl_fltk_bridge_style.cpp \
           native/cl_fltk_bridge_tables.cpp \
           native/cl_fltk_bridge_text.cpp \
           native/cl_fltk_bridge_stock_icons.cpp \
           native/cl_fltk_bridge_values.cpp \
           native/cl_fltk_bridge_widgets.cpp
STOCK_ICONS := $(wildcard native/*.xpm)
CXXFLAGS += -std=c++17 -fPIC -O2 -Wall -Wextra $(shell $(FLTK_CONFIG) --use-images --cxxflags) $(HOST_CXXFLAGS)
LDFLAGS += $(HOST_LDFLAGS) $(shell $(FLTK_CONFIG) --use-images --ldflags) $(HOST_LIBS)
# The checks load the system from this tree, wherever it is checked out, ahead
# of any other copy ASDF knows about, and keep their FASLs under build/.
LISP_ENV := CL_SOURCE_REGISTRY=$(CURDIR)/:$(CL_SOURCE_REGISTRY) ASDF_OUTPUT_TRANSLATIONS=$(CURDIR)/:$(CURDIR)/build/common-lisp-cache/

.PHONY: all native check smoke layout-smoke widget-smoke awake-smoke font-smoke text-smoke canvas-smoke demo layout-visual flat-theme-visual scrollbar-visual button-ellipsis-visual modern-widgets-visual clean

all: native

native: $(BRIDGE)

$(BRIDGE): $(SOURCES) native/cl_fltk_bridge.hpp native/stock_icons.hpp $(STOCK_ICONS)
	mkdir -p build
	$(CXX) $(CXXFLAGS) $(SOURCES) -o $@ $(LDFLAGS)

check: smoke layout-smoke widget-smoke awake-smoke font-smoke text-smoke canvas-smoke

smoke: native
	$(LISP_ENV) sbcl --noinform --non-interactive --load scripts/smoke-load.lisp

layout-smoke:
	$(LISP_ENV) sbcl --noinform --non-interactive --load scripts/smoke-layout.lisp

widget-smoke: native
	$(LISP_ENV) $(GUI_ENV) sbcl --noinform --non-interactive --load scripts/smoke-widgets.lisp

awake-smoke: native
	$(LISP_ENV) $(GUI_ENV) sbcl --noinform --non-interactive --load scripts/smoke-awake.lisp

font-smoke: native
	$(LISP_ENV) $(GUI_ENV) sbcl --noinform --non-interactive --load scripts/smoke-fonts.lisp

text-smoke: native
	$(LISP_ENV) $(GUI_ENV) sbcl --noinform --non-interactive --load scripts/smoke-text.lisp

canvas-smoke: native
	$(LISP_ENV) $(GUI_ENV) sbcl --noinform --non-interactive --load scripts/smoke-canvas.lisp

demo: native
	$(LISP_ENV) $(GUI_ENV) sbcl --load examples/demo.lisp --eval '(lightfast-demo:main)'

layout-visual: native
	$(LISP_ENV) $(GUI_ENV) sbcl --load scripts/visual-layout.lisp

scrollbar-visual: native
	$(LISP_ENV) $(GUI_ENV) sbcl --load scripts/visual-scrollbars.lisp

button-ellipsis-visual: native
	$(LISP_ENV) $(GUI_ENV) sbcl --load scripts/visual-button-ellipsis.lisp

flat-theme-visual: native
	$(LISP_ENV) $(GUI_ENV) sbcl --load scripts/visual-flat-theme.lisp

modern-widgets-visual: native
	$(LISP_ENV) $(GUI_ENV) sbcl --load scripts/visual-modern-widgets.lisp

clean:
	rm -rf build
