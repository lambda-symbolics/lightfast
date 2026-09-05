#include "cl_fltk_bridge.hpp"

using namespace clfl_bridge;

extern "C" {

void clfl_apply_classic_theme()
{
    Fl::scheme("none");
    Fl::background(192, 192, 192);
    Fl::background2(255, 255, 255);
    Fl::foreground(0, 0, 0);
    Fl::set_color(FL_SELECTION_COLOR, 0, 0, 128);
    Fl::visible_focus(0);
}

widget_id clfl_widget_create(int kind,
                             widget_id parent_id,
                             int x,
                             int y,
                             int width,
                             int height,
                             const char *label)
{
    Fl_Group *saved_group = Fl_Group::current();
    Fl_Group::current(nullptr);

    Fl_Widget *widget = create_widget(kind, x, y, width, height, label);
    Fl_Group::current(saved_group);

    if (!widget) {
        return 0;
    }

    if (parent_id > 0) {
        if (Fl_Group *parent = find_group(parent_id)) {
            parent->add(widget);
        } else {
            delete widget;
            return 0;
        }
    }

    return register_widget(kind, widget);
}

int clfl_widget_destroy(widget_id id)
{
    Fl_Widget *widget = find_widget(id);
    if (!widget) {
        return 0;
    }

    if (Fl_Group *parent = widget->parent()) {
        parent->remove(widget);
    }
    unregister_widget_tree(widget);
    delete widget;
    return 1;
}

void clfl_window_show(widget_id id)
{
    if (Fl_Widget *widget = find_widget(id)) {
        widget->show();
    }
}

void clfl_window_hide(widget_id id)
{
    if (Fl_Widget *widget = find_widget(id)) {
        widget->hide();
    }
}

/// Keeps the window open. Meaningful only while its close callback runs: the
/// close that triggered the callback is then abandoned instead of finished.
void clfl_window_cancel_close(widget_id id)
{
    if (g_window_close_callback_depth > 0 && find_widget(id)) {
        g_window_close_cancelled = true;
    }
}

/// Gives the window the stock icon NAME as its icon, which is what a window
/// manager shows in a task bar and a title bar. Kept for the life of the
/// program: FLTK reads the pixels again when the window is shown.
void clfl_window_set_icon(widget_id id, const char *name)
{
    auto *window = dynamic_cast<Fl_Window *>(find_widget(id));
    Fl_Pixmap *pixmap = stock_icon_pixmap(name);
    if (!window || !pixmap) {
        return;
    }
    static std::unordered_map<std::string, std::unique_ptr<Fl_RGB_Image>> icons;
    auto &image = icons[name];
    if (!image) {
        image = std::make_unique<Fl_RGB_Image>(pixmap);
    }
    window->icon(image.get());
}

/// Whether Escape closes the window; on by default, as in FLTK.
void clfl_window_set_escape_closes(widget_id id, int enabled)
{
    set_window_escape_closes(find_widget(id), enabled != 0);
}

void clfl_window_set_size_range(widget_id id,
                                int min_width,
                                int min_height,
                                int max_width,
                                int max_height)
{
    if (auto *window = dynamic_cast<Fl_Window *>(find_widget(id))) {
        window->size_range(min_width,
                           min_height,
                           max_width,
                           max_height);
    }
}

void clfl_window_set_app_id(widget_id id, const char *app_id)
{
    if (auto *window = dynamic_cast<Fl_Window *>(find_widget(id))) {
        window->xclass(app_id ? app_id : "");
    }
}

char *clfl_window_get_app_id(widget_id id)
{
    auto *window = dynamic_cast<Fl_Window *>(find_widget(id));
    return copy_c_string(window && window->xclass() ? window->xclass() : "");
}

void clfl_widget_redraw(widget_id id)
{
    if (Fl_Widget *widget = find_widget(id)) {
        widget->redraw();
    }
}

void clfl_widget_set_label(widget_id id, const char *label)
{
    if (Fl_Widget *widget = find_widget(id)) {
        if (auto *window = dynamic_cast<Fl_Window *>(widget)) {
            // A window's label is its title bar, and only Fl_Window::label()
            // tells the window manager; copy_label() changes the text FLTK
            // holds and nothing the user can see. FLTK keeps the pointer, so
            // the text lives here for as long as the window does.
            std::string &title = g_window_titles[widget];
            title = label ? label : "";
            window->label(title.c_str());
            return;
        }
        widget->copy_label(label ? label : "");
        widget->redraw_label();
    }
}

char *clfl_widget_get_label(widget_id id)
{
    Fl_Widget *widget = find_widget(id);
    return copy_c_string(widget ? widget->label() : "");
}

void clfl_widget_set_value(widget_id id, const char *value)
{
    if (Fl_Widget *widget = find_widget(id)) {
        set_widget_value(widget, value);
        widget->redraw();
    }
}

char *clfl_widget_get_value(widget_id id)
{
    return copy_c_string(widget_value_string(find_widget(id)).c_str());
}

void clfl_widget_set_stock_icon(widget_id id, const char *name)
{
    set_widget_stock_icon(id, name);
}

void clfl_string_free(char *value)
{
    std::free(value);
}

int clfl_widget_set_callback(widget_id id,
                             clfl_callback callback,
                             widget_id token,
                             int event)
{
    Entry *entry = find_entry(id);
    if (!entry || !entry->widget) {
        return 0;
    }

    entry->callbacks[event] = CallbackSlot{callback, token};
    entry->default_event = event;
    if (entry->kind == WIDGET_WINDOW) {
        entry->widget->callback(window_event_callback);
    } else {
        entry->widget->callback(dispatch_callback);
    }
    return 1;
}

int clfl_menu_add(widget_id id,
                  const char *path,
                  int shortcut,
                  clfl_callback callback,
                  widget_id token)
{
    auto *menu = dynamic_cast<Fl_Menu_ *>(find_widget(id));
    if (!menu || !path || !*path) {
        return 0;
    }

    auto menu_callback = std::make_unique<MenuCallback>();
    menu_callback->widget = id;
    menu_callback->callback = callback;
    menu_callback->token = token;
    menu_callback->path = path;
    MenuCallback *raw_callback = menu_callback.get();
    g_menu_callbacks.push_back(std::move(menu_callback));

    menu->add(path, shortcut, menu_dispatch_callback, raw_callback);
    return 1;
}

int clfl_menu_set_item_mode(widget_id id, const char *path, int mode)
{
    auto *menu = dynamic_cast<Fl_Menu_ *>(find_widget(id));
    if (!menu || !path || !*path) {
        return 0;
    }

    const int index = menu->find_index(path);
    if (index < 0) {
        return 0;
    }

    menu->mode(index, mode);
    menu->redraw();
    return 1;
}

}
