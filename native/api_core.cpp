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
    theme() = Theme();
}

namespace {

/// A box drawn as one hairline of foreground ink around a flat fill.
void flat_hairline_box(int x, int y, int w, int h, Fl_Color color)
{
    fl_color(color);
    fl_rectf(x + 1, y + 1, w - 2, h - 2);
    fl_color(FL_FOREGROUND_COLOR);
    fl_rect(x, y, w, h);
}

/// The hairline alone, for frames that leave their inside untouched.
void flat_hairline_frame(int x, int y, int w, int h, Fl_Color)
{
    fl_color(FL_FOREGROUND_COLOR);
    fl_rect(x, y, w, h);
}

/// A flat fill with no edge at all.
void flat_plain_box(int x, int y, int w, int h, Fl_Color color)
{
    fl_color(color);
    fl_rectf(x, y, w, h);
}

const Fl_Boxtype FLAT_HAIRLINE_BOX = FL_FREE_BOXTYPE;
const Fl_Boxtype FLAT_HAIRLINE_FRAME = static_cast<Fl_Boxtype>(FL_FREE_BOXTYPE + 1);
const Fl_Boxtype FLAT_PLAIN_BOX = static_cast<Fl_Boxtype>(FL_FREE_BOXTYPE + 2);

} // namespace

void clfl_apply_flat_theme(int background_red, int background_green, int background_blue,
                           int foreground_red, int foreground_green, int foreground_blue,
                           int selection_red, int selection_green, int selection_blue,
                           int label_font, int label_size,
                           int text_font, int text_size,
                           int mono_font)
{
    Fl::scheme("none");
    Fl::background(background_red, background_green, background_blue);
    Fl::background2(background_red, background_green, background_blue);
    Fl::foreground(foreground_red, foreground_green, foreground_blue);
    Fl::set_color(FL_SELECTION_COLOR, selection_red, selection_green, selection_blue);
    Fl::visible_focus(1);
    Fl::scrollbar_size(12);

    Fl::set_boxtype(FLAT_HAIRLINE_BOX, flat_hairline_box, 1, 1, 2, 2);
    Fl::set_boxtype(FLAT_HAIRLINE_FRAME, flat_hairline_frame, 1, 1, 2, 2);
    Fl::set_boxtype(FLAT_PLAIN_BOX, flat_plain_box, 0, 0, 0, 0);
    // Every bevel FLTK or a widget asks for becomes the hairline, so menus,
    // tooltips and widgets created by FLTK itself follow the theme too.
    Fl::set_boxtype(FL_UP_BOX, FLAT_HAIRLINE_BOX);
    Fl::set_boxtype(FL_DOWN_BOX, FLAT_HAIRLINE_BOX);
    Fl::set_boxtype(FL_THIN_UP_BOX, FLAT_HAIRLINE_BOX);
    Fl::set_boxtype(FL_THIN_DOWN_BOX, FLAT_HAIRLINE_BOX);
    Fl::set_boxtype(FL_UP_FRAME, FLAT_HAIRLINE_FRAME);
    Fl::set_boxtype(FL_DOWN_FRAME, FLAT_HAIRLINE_FRAME);
    Fl::set_boxtype(FL_THIN_UP_FRAME, FLAT_HAIRLINE_FRAME);
    Fl::set_boxtype(FL_THIN_DOWN_FRAME, FLAT_HAIRLINE_FRAME);
    Fl::set_boxtype(FL_ENGRAVED_BOX, FLAT_HAIRLINE_BOX);
    Fl::set_boxtype(FL_EMBOSSED_BOX, FLAT_HAIRLINE_BOX);
    Fl::set_boxtype(FL_ENGRAVED_FRAME, FLAT_HAIRLINE_FRAME);
    Fl::set_boxtype(FL_EMBOSSED_FRAME, FLAT_HAIRLINE_FRAME);
    Fl::set_boxtype(FL_ROUND_UP_BOX, FLAT_HAIRLINE_BOX);
    Fl::set_boxtype(FL_ROUND_DOWN_BOX, FLAT_HAIRLINE_BOX);

    Fl_Tooltip::color(FL_BACKGROUND_COLOR);
    Fl_Tooltip::textcolor(FL_FOREGROUND_COLOR);
    Fl_Tooltip::font(static_cast<Fl_Font>(label_font));
    Fl_Tooltip::size(label_size);

    Theme flat;
    flat.label_size = label_size;
    flat.text_size = text_size;
    flat.label_font = static_cast<Fl_Font>(label_font);
    flat.text_font = static_cast<Fl_Font>(text_font);
    flat.mono_font = static_cast<Fl_Font>(mono_font);
    flat.field_color = FL_BACKGROUND_COLOR;
    flat.selection_color = FL_SELECTION_COLOR;
    flat.rule_color = FL_FOREGROUND_COLOR;
    flat.scrollbar_track_color = FL_BACKGROUND_COLOR;
    flat.scrollbar_slider_color = FL_FOREGROUND_COLOR;
    flat.indicator_shadow_color = FL_FOREGROUND_COLOR;
    flat.indicator_highlight_color = FL_FOREGROUND_COLOR;
    flat.raised_box = FLAT_HAIRLINE_BOX;
    flat.sunken_box = FLAT_HAIRLINE_BOX;
    flat.pressed_box = FLAT_HAIRLINE_BOX;
    flat.thin_raised_box = FLAT_HAIRLINE_BOX;
    theme() = flat;
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

/// Makes the window modal: while it is shown, the application's other
/// windows take no input, the way a dialog that asks a question should hold
/// the floor until it is answered.
void clfl_window_set_modal(widget_id id, int enabled)
{
    if (auto *window = dynamic_cast<Fl_Window *>(find_widget(id))) {
        if (enabled) {
            window->set_modal();
        } else {
            window->set_non_modal();
        }
    }
}

/// How many clicks the mouse event being handled is into a series: 0 for a
/// single click, 1 for a double click. Valid only inside a callback.
void clfl_event_consume()
{
    g_event_consumed = true;
}

int clfl_event_clicks()
{
    return Fl::event_clicks();
}

/// The key of the keyboard event being handled, as FLTK numbers keys. Valid
/// only inside a callback; lets a text field's callback tell Enter from a
/// keystroke that changed the text.
int clfl_event_key()
{
    return Fl::event_key();
}

/// Gives the widget the keyboard focus, so its callbacks see the keys.
void clfl_widget_take_focus(widget_id id)
{
    if (Fl_Widget *widget = find_widget(id)) {
        widget->take_focus();
    }
}

/// When the widget runs its callback, as FLTK's FL_WHEN_* bits.
void clfl_widget_set_when(widget_id id, int when)
{
    if (Fl_Widget *widget = find_widget(id)) {
        widget->when(static_cast<uchar>(when));
    }
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
    // Only the widget's own callback events may become the default that
    // FLTK's callback dispatches to; an input callback such as EVENT_KEY is
    // fired by the widget's handle() with its own value format.
    if (event == EVENT_ACTIVATE || event == EVENT_CHANGE) {
        entry->default_event = event;
    }
    if (entry->kind == WIDGET_WINDOW) {
        entry->widget->callback(window_event_callback);
    } else {
        entry->widget->callback(dispatch_callback);
    }
    return 1;
}

/// Adds a menu item; FLAGS are FLTK's menu item flags, of which the one worth
/// naming is FL_MENU_INVISIBLE: an item that never shows but whose shortcut
/// still fires, which is how a command gets a second key without a second line
/// in the menu.
int clfl_menu_add(widget_id id,
                  const char *path,
                  int shortcut,
                  clfl_callback callback,
                  widget_id token,
                  int flags)
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

    menu->add(path, shortcut, menu_dispatch_callback, raw_callback, flags);
    return 1;
}

/// Sets or clears the checked state of the item at PATH — the bullet of a radio
/// item or the tick of a toggle — leaving its other flags as they were.
int clfl_menu_set_item_checked(widget_id id, const char *path, int checked)
{
    auto *menu = dynamic_cast<Fl_Menu_ *>(find_widget(id));
    if (!menu || !path || !*path) {
        return 0;
    }
    const int index = menu->find_index(path);
    if (index < 0) {
        return 0;
    }
    const int flags = menu->menu()[index].flags;
    menu->mode(index, checked ? (flags | FL_MENU_VALUE) : (flags & ~FL_MENU_VALUE));
    menu->redraw();
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

/// Renames the item at PATH to LABEL, keeping its callback, shortcut and flags.
/// The item is found by its current path afterwards, so a caller renaming items
/// keeps track of the labels it gave them. This is what a recent-files list is
/// made of: a fixed set of items relabelled as the list changes.
int clfl_menu_set_item_label(widget_id id, const char *path, const char *label)
{
    auto *menu = dynamic_cast<Fl_Menu_ *>(find_widget(id));
    if (!menu || !path || !*path || !label) {
        return 0;
    }

    const int index = menu->find_index(path);
    if (index < 0) {
        return 0;
    }

    menu->replace(index, label);
    menu->redraw();
    return 1;
}

}
