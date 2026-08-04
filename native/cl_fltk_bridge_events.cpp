#include "cl_fltk_bridge.hpp"

namespace clfl_bridge {

void dispatch_callback(Fl_Widget *widget, void *)
{
    const auto found = g_widget_ids.find(widget);
    if (found == g_widget_ids.end()) {
        return;
    }

    Entry *entry = find_entry(found->second);
    if (!entry) {
        return;
    }

    auto callback = entry->callbacks.find(entry->default_event);
    if (callback == entry->callbacks.end()) {
        callback = entry->callbacks.find(EVENT_ACTIVATE);
    }
    if (callback == entry->callbacks.end()) {
        callback = entry->callbacks.find(EVENT_CHANGE);
    }
    if (callback == entry->callbacks.end() || !callback->second.callback) {
        return;
    }
    const std::string value = widget_callback_value_string(widget);
    callback->second.callback(found->second,
                              callback->first,
                              value.c_str(),
                              callback->second.token);
}

void menu_dispatch_callback(Fl_Widget *, void *data)
{
    auto *menu_callback = static_cast<MenuCallback *>(data);
    if (!menu_callback || !menu_callback->callback) {
        return;
    }
    menu_callback->callback(menu_callback->widget,
                            EVENT_MENU,
                            menu_callback->path.c_str(),
                            menu_callback->token);
}

void timer_dispatch_callback(void *data)
{
    auto *timer = static_cast<TimerEntry *>(data);
    if (!timer) {
        return;
    }

    const widget_id id = timer->id;
    if (timer->callback) {
        timer->callback(0, EVENT_TIMER, "", timer->token);
    }

    const auto found = g_timers.find(id);
    if (found == g_timers.end()) {
        return;
    }

    if (found->second->repeat) {
        Fl::repeat_timeout(found->second->interval, timer_dispatch_callback, found->second.get());
    } else {
        g_timers.erase(found);
    }
}

void dispatch_resize_callback(Fl_Widget *widget)
{
    const auto found = g_widget_ids.find(widget);
    if (found == g_widget_ids.end()) {
        return;
    }

    Entry *entry = find_entry(found->second);
    if (entry) {
        auto callback = entry->callbacks.find(EVENT_RESIZE);
        if (callback != entry->callbacks.end() && callback->second.callback) {
            char value[64];
            std::snprintf(value, sizeof(value), "%d %d", widget->w(), widget->h());
            callback->second.callback(found->second,
                                      EVENT_RESIZE,
                                      value,
                                      callback->second.token);
        }
    }
}

void dispatch_draw_callback(Fl_Widget *widget)
{
    const auto found = g_widget_ids.find(widget);
    if (found == g_widget_ids.end()) {
        return;
    }

    Entry *entry = find_entry(found->second);
    if (!entry) {
        return;
    }

    auto callback = entry->callbacks.find(EVENT_DRAW);
    if (callback != entry->callbacks.end() && callback->second.callback) {
        callback->second.callback(found->second,
                                  EVENT_DRAW,
                                  "",
                                  callback->second.token);
    }
}

std::string mouse_event_value(Fl_Widget *widget)
{
    char value[128];
    std::snprintf(value,
                  sizeof(value),
                  "%d %d %d %d %d %d",
                  Fl::event_x() - widget->x(),
                  Fl::event_y() - widget->y(),
                  Fl::event_button(),
                  Fl::event_dx(),
                  Fl::event_dy(),
                  Fl::event_state());
    return value;
}

std::string key_event_value()
{
    char value[160];
    const char *text = Fl::event_text();
    std::snprintf(value,
                  sizeof(value),
                  "%d %d %s",
                  Fl::event_key(),
                  Fl::event_state(),
                  text ? text : "");
    return value;
}

bool dispatch_input_callback(Fl_Widget *widget, int event, const std::string &value)
{
    const auto found = g_widget_ids.find(widget);
    if (found == g_widget_ids.end()) {
        return false;
    }

    Entry *entry = find_entry(found->second);
    if (!entry) {
        return false;
    }

    auto callback = entry->callbacks.find(event);
    if (callback == entry->callbacks.end() || !callback->second.callback) {
        return false;
    }

    callback->second.callback(found->second,
                              event,
                              value.c_str(),
                              callback->second.token);
    return true;
}

void window_event_callback(Fl_Widget *widget, void *)
{
    const auto found = g_widget_ids.find(widget);
    if (found == g_widget_ids.end()) {
        finish_window_close(widget);
        return;
    }

    Entry *entry = find_entry(found->second);
    if (entry) {
        auto callback = entry->callbacks.find(EVENT_CLOSE);
        if (callback != entry->callbacks.end() && callback->second.callback) {
            const std::string value = widget_value_string(widget);
            ++g_window_close_callback_depth;
            callback->second.callback(found->second,
                                      EVENT_CLOSE,
                                      value.c_str(),
                                      callback->second.token);
            --g_window_close_callback_depth;
            finish_window_close(widget);
            return;
        }
    }
    finish_window_close(widget);
}

bool any_visible_windows()
{
    for (Fl_Window *window = Fl::first_window(); window; window = Fl::next_window(window)) {
        if (window->shown() && window->visible()) {
            return true;
        }
    }
    return false;
}

void finish_window_close(Fl_Widget *widget)
{
    if (widget && widget->visible()) {
        widget->hide();
    }
    if (g_quit_requested || !any_visible_windows()) {
        clear_timers();
        Fl::program_should_quit(1);
        Fl::awake();
    }
}

void clear_timers()
{
    for (auto &timer : g_timers) {
        Fl::remove_timeout(timer_dispatch_callback, timer.second.get());
    }
    g_timers.clear();
}

void request_quit()
{
    g_quit_requested = true;
    clear_timers();
    if (g_window_close_callback_depth == 0) {
        Fl::hide_all_windows();
    }
    Fl::program_should_quit(1);
    Fl::awake();
}

} // namespace clfl_bridge
