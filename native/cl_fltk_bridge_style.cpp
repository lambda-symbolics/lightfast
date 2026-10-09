#include "cl_fltk_bridge.hpp"

namespace clfl_bridge {

Theme &theme()
{
    static Theme current;
    return current;
}

void apply_scrollbar_style(Fl_Scrollbar *scrollbar)
{
    if (!scrollbar) {
        return;
    }
    scrollbar->box(theme().sunken_box);
    scrollbar->slider(theme().raised_box);
    scrollbar->color(theme().scrollbar_track_color);
    scrollbar->selection_color(theme().scrollbar_slider_color);
}

void apply_scrollbar_styles(Fl_Widget *widget)
{
    if (!widget) {
        return;
    }
    if (auto *scrollbar = dynamic_cast<Fl_Scrollbar *>(widget)) {
        apply_scrollbar_style(scrollbar);
    }
    if (auto *group = dynamic_cast<Fl_Group *>(widget)) {
        for (int index = 0; index < group->children(); ++index) {
            apply_scrollbar_styles(group->child(index));
        }
    }
}

void apply_common_style(Fl_Widget *widget)
{
    widget->labelfont(theme().label_font);
    widget->labelsize(theme().label_size);
    widget->labelcolor(FL_FOREGROUND_COLOR);
    apply_scrollbar_styles(widget);
}

void apply_inset_style(Fl_Widget *widget)
{
    widget->box(theme().sunken_box);
    apply_common_style(widget);
}

void apply_button_style(Fl_Button *button)
{
    button->box(theme().raised_box);
    button->down_box(theme().pressed_box);
    button->labelfont(theme().label_font);
    button->labelsize(theme().label_size);
    button->labelcolor(FL_FOREGROUND_COLOR);
}

} // namespace clfl_bridge
