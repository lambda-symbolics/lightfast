#include "cl_fltk_bridge.hpp"

namespace clfl_bridge {

void apply_scrollbar_style(Fl_Scrollbar *scrollbar)
{
    if (!scrollbar) {
        return;
    }
    scrollbar->box(FL_DOWN_BOX);
    scrollbar->slider(FL_UP_BOX);
    scrollbar->color(fl_rgb_color(224, 224, 224));
    scrollbar->selection_color(fl_rgb_color(144, 144, 144));
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
    widget->labelsize(12);
    widget->labelcolor(FL_BLACK);
    apply_scrollbar_styles(widget);
}

void apply_inset_style(Fl_Widget *widget)
{
    widget->box(FL_DOWN_BOX);
    apply_common_style(widget);
}

void apply_button_style(Fl_Button *button)
{
    button->box(FL_UP_BOX);
    button->down_box(FL_DOWN_BOX);
    button->labelsize(12);
    button->labelcolor(FL_BLACK);
}

} // namespace clfl_bridge
