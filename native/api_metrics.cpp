#include "cl_fltk_bridge.hpp"

using namespace clfl_bridge;

namespace {

/// The font and size a widget draws its principal text with: the text font of
/// inputs, choices and menus, else the label font.
void principal_font(Fl_Widget *widget, Fl_Font *font, int *size)
{
    if (auto *input = dynamic_cast<Fl_Input_ *>(widget)) {
        *font = input->textfont();
        *size = input->textsize();
    } else if (auto *menu = dynamic_cast<Fl_Menu_ *>(widget)) {
        *font = menu->textfont();
        *size = menu->textsize();
    } else {
        *font = widget->labelfont();
        *size = widget->labelsize();
    }
}

} // namespace

extern "C" {

/// The offset from the top of widget ID to the baseline of its single line of
/// text, as FLTK will draw it: centered inside the box with the font's ascent
/// above the baseline. Returns -1 for an unknown widget.
int clfl_widget_baseline(widget_id id)
{
    Fl_Widget *widget = find_widget(id);
    if (!widget) {
        return -1;
    }
    Fl_Font font = FL_HELVETICA;
    int size = 12;
    principal_font(widget, &font, &size);
    fl_font(font, size);
    const int height = fl_height();
    const int descent = fl_descent();
    const int inner_y = Fl::box_dy(widget->box());
    const int inner_h = widget->h() - Fl::box_dh(widget->box());
    return inner_y + (inner_h - height) / 2 + height - descent;
}

}
