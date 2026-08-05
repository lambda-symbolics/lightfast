FLTK_CONFIG ?= fltk-config
CXX ?= c++
RUN_DISPLAY ?= :0

BRIDGE := build/liblightfast.so
SOURCES := native/api_core.cpp \
           native/api_geometry.cpp \
           native/api_drawing.cpp \
           native/api_controls.cpp \
           native/api_dialogs.cpp \
           native/api_runtime.cpp \
           native/api_widgets.cpp \
           native/cl_fltk_bridge_state.cpp \
           native/cl_fltk_bridge_events.cpp \
           native/cl_fltk_bridge_style.cpp \
           native/cl_fltk_bridge_tables.cpp \
           native/cl_fltk_bridge_stock_icons.cpp \
           native/cl_fltk_bridge_values.cpp \
           native/cl_fltk_bridge_widgets.cpp
STOCK_ICONS := $(wildcard native/*.xpm)
CXXFLAGS += -std=c++17 -fPIC -O2 -Wall -Wextra $(shell $(FLTK_CONFIG) --cxxflags)
LDFLAGS += -shared $(shell $(FLTK_CONFIG) --ldflags)
LISP_ENV := ASDF_OUTPUT_TRANSLATIONS=$(CURDIR)/:$(CURDIR)/build/common-lisp-cache/

.PHONY: all native smoke layout-smoke widget-smoke demo layout-visual scrollbar-visual button-ellipsis-visual modern-widgets-visual clean

all: native

native: $(BRIDGE)

$(BRIDGE): $(SOURCES) native/cl_fltk_bridge.hpp native/stock_icons.hpp $(STOCK_ICONS)
	mkdir -p build
	$(CXX) $(CXXFLAGS) $(SOURCES) -o $@ $(LDFLAGS)

smoke: native
	$(LISP_ENV) sbcl --noinform --non-interactive --load scripts/smoke-load.lisp

layout-smoke:
	$(LISP_ENV) sbcl --noinform --non-interactive --load scripts/smoke-layout.lisp

widget-smoke: native
	$(LISP_ENV) DISPLAY=$(RUN_DISPLAY) sbcl --noinform --non-interactive --load scripts/smoke-widgets.lisp

demo: native
	$(LISP_ENV) DISPLAY=$(RUN_DISPLAY) sbcl --load examples/demo.lisp --eval '(lightfast-demo:main)'

layout-visual: native
	$(LISP_ENV) DISPLAY=$(RUN_DISPLAY) sbcl --load scripts/visual-layout.lisp

scrollbar-visual: native
	$(LISP_ENV) DISPLAY=$(RUN_DISPLAY) sbcl --load scripts/visual-scrollbars.lisp

button-ellipsis-visual: native
	$(LISP_ENV) DISPLAY=$(RUN_DISPLAY) sbcl --load scripts/visual-button-ellipsis.lisp

modern-widgets-visual: native
	$(LISP_ENV) DISPLAY=$(RUN_DISPLAY) sbcl --load scripts/visual-modern-widgets.lisp

clean:
	rm -rf build
