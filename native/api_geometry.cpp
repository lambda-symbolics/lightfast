#include "cl_fltk_bridge.hpp"

using namespace clfl_bridge;

namespace {

struct ProgrammaticResizeScope {
    ProgrammaticResizeScope()
    {
        ++g_programmatic_resize_depth;
    }

    ~ProgrammaticResizeScope()
    {
        --g_programmatic_resize_depth;
    }
};

void refresh_tile_baselines_for(Fl_Widget *widget)
{
    if (auto *tile = dynamic_cast<Fl_Tile *>(widget)) {
        if (tile != g_active_tile_drag) {
            tile->init_sizes();
        }
    }

    Fl_Group *parent = widget->parent();
    if (auto *parent_tile = dynamic_cast<Fl_Tile *>(parent)) {
        if (parent_tile != g_active_tile_drag) {
            parent_tile->init_sizes();
        }
    }
}

} // namespace

extern "C" {

void clfl_widget_set_box(widget_id id, int box)
{
    if (Fl_Widget *widget = find_widget(id)) {
        widget->box(static_cast<Fl_Boxtype>(box));
        widget->redraw();
    }
}

void clfl_widget_resize(widget_id id, int x, int y, int width, int height)
{
    if (Fl_Widget *widget = find_widget(id)) {
        if (widget->x() == x &&
            widget->y() == y &&
            widget->w() == width &&
            widget->h() == height) {
            return;
        }

        const ProgrammaticResizeScope resize_scope;
        widget->resize(x, y, width, height);
        refresh_tile_baselines_for(widget);
        widget->redraw();
    }
}

int clfl_widget_x(widget_id id)
{
    Fl_Widget *widget = find_widget(id);
    return widget ? widget->x() : 0;
}

int clfl_widget_y(widget_id id)
{
    Fl_Widget *widget = find_widget(id);
    return widget ? widget->y() : 0;
}

int clfl_widget_width(widget_id id)
{
    Fl_Widget *widget = find_widget(id);
    return widget ? widget->w() : 0;
}

int clfl_widget_height(widget_id id)
{
    Fl_Widget *widget = find_widget(id);
    return widget ? widget->h() : 0;
}

void clfl_widget_set_label_size(widget_id id, int size)
{
    if (Fl_Widget *widget = find_widget(id)) {
        widget->labelsize(size);
        widget->redraw_label();
    }
}

void clfl_widget_set_label_font(widget_id id, int font)
{
    if (Fl_Widget *widget = find_widget(id)) {
        widget->labelfont(static_cast<Fl_Font>(font));
        widget->redraw_label();
        widget->redraw();
    }
}

void clfl_widget_set_tooltip(widget_id id, const char *tooltip)
{
    if (Fl_Widget *widget = find_widget(id)) {
        widget->copy_tooltip(tooltip ? tooltip : "");
    }
}

void clfl_widget_set_text_size(widget_id id, int size)
{
    set_widget_text_size(id, size);
}

void clfl_widget_set_text_font(widget_id id, int font)
{
    set_widget_text_font(id, font);
}

void clfl_widget_set_color_rgb(widget_id id, int red, int green, int blue)
{
    if (Fl_Widget *widget = find_widget(id)) {
        widget->color(fl_rgb_color(red, green, blue));
        widget->redraw();
    }
}

// Set the mouse cursor shown over a widget.
//
// FLTK scopes a cursor to a window rather than to a widget, so this resolves
// the widget to the window that contains it; a widget that is itself a window
// stands in for its own. CURSOR is an Fl_Cursor value.
void clfl_widget_set_cursor(widget_id id, int cursor)
{
    if (Fl_Widget *widget = find_widget(id)) {
        Fl_Window *window = widget->window();
        if (!window) {
            window = widget->as_window();
        }
        if (window) {
            window->cursor(static_cast<Fl_Cursor>(cursor));
        }
    }
}

}
