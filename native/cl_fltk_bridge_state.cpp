#include "cl_fltk_bridge.hpp"

namespace clfl_bridge {

widget_id g_next_id = 1;
widget_id g_next_timer_id = 1;
std::unordered_map<widget_id, Entry> g_widgets;
std::unordered_map<Fl_Widget *, widget_id> g_widget_ids;
std::unordered_map<widget_id, std::unique_ptr<TimerEntry>> g_timers;
std::vector<std::unique_ptr<MenuCallback>> g_menu_callbacks;
bool g_quit_requested = false;
int g_window_close_callback_depth = 0;
int g_programmatic_resize_depth = 0;

char *copy_c_string(const char *value)
{
    const char *source = value ? value : "";
    const std::size_t length = std::strlen(source);
    auto *copy = static_cast<char *>(std::malloc(length + 1));
    if (!copy) {
        return nullptr;
    }
    std::memcpy(copy, source, length + 1);
    return copy;
}

Entry *find_entry(widget_id id)
{
    const auto found = g_widgets.find(id);
    if (found == g_widgets.end()) {
        return nullptr;
    }
    return &found->second;
}

Fl_Widget *find_widget(widget_id id)
{
    Entry *entry = find_entry(id);
    return entry ? entry->widget : nullptr;
}

Fl_Group *find_group(widget_id id)
{
    return dynamic_cast<Fl_Group *>(find_widget(id));
}

widget_id register_widget(int kind, Fl_Widget *widget)
{
    if (!widget) {
        return 0;
    }

    if (widget->label()) {
        widget->copy_label(widget->label());
    }

    const widget_id id = g_next_id++;
    Entry entry;
    entry.widget = widget;
    entry.kind = kind;
    g_widgets[id] = entry;
    g_widget_ids[widget] = id;
    return id;
}

void unregister_widget_tree(Fl_Widget *widget)
{
    if (!widget) {
        return;
    }

    if (auto *group = dynamic_cast<Fl_Group *>(widget)) {
        std::vector<Fl_Widget *> children;
        children.reserve(group->children());
        for (int i = 0; i < group->children(); ++i) {
            children.push_back(group->child(i));
        }
        for (Fl_Widget *child : children) {
            unregister_widget_tree(child);
        }
    }

    const auto found = g_widget_ids.find(widget);
    if (found != g_widget_ids.end()) {
        const widget_id id = found->second;
        g_menu_callbacks.erase(
            std::remove_if(g_menu_callbacks.begin(),
                           g_menu_callbacks.end(),
                           [id](const std::unique_ptr<MenuCallback> &callback) {
                               return callback->widget == id;
                           }),
            g_menu_callbacks.end());
        g_widgets.erase(found->second);
        g_widget_ids.erase(found);
    }
}

} // namespace clfl_bridge
