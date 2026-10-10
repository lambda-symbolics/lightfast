#include "cl_fltk_bridge.hpp"

using namespace clfl_bridge;

namespace {

BufferedTextDisplay *styled_display(widget_id id)
{
    return dynamic_cast<BufferedTextDisplay *>(find_widget(id));
}

Fl_Text_Display *any_display(widget_id id)
{
    return dynamic_cast<Fl_Text_Display *>(find_widget(id));
}

} // namespace

extern "C" {

int clfl_text_set_styles(widget_id id, int count, const int *fonts, const int *sizes,
                         const unsigned *colors, const unsigned *attributes, const unsigned *backgrounds)
{
    BufferedTextDisplay *display = styled_display(id);
    if (!display || count < 0 || count > 26 || (count > 0 && (!fonts || !sizes || !colors || !attributes || !backgrounds))) {
        return 0;
    }
    display->set_styles(count, fonts, sizes, colors, attributes, backgrounds);
    return 1;
}

int clfl_text_append_styled(widget_id id, const char *text, const char *styles)
{
    BufferedTextDisplay *display = styled_display(id);
    return display && display->append_styled(text, styles) ? 1 : 0;
}

int clfl_text_replace_styled(widget_id id, int start, int end, const char *text, const char *styles)
{
    BufferedTextDisplay *display = styled_display(id);
    return display && display->replace_styled(start, end, text, styles) ? 1 : 0;
}

int clfl_text_length(widget_id id)
{
    Fl_Text_Display *display = any_display(id);
    return display && display->buffer() ? display->buffer()->length() : -1;
}

char *clfl_text_range(widget_id id, int start, int end)
{
    Fl_Text_Display *display = any_display(id);
    if (!display || !display->buffer() || start < 0 || end < start || end > display->buffer()->length()) {
        return copy_c_string("");
    }
    char *range = display->buffer()->text_range(start, end);
    char *copy = copy_c_string(range ? range : "");
    std::free(range);
    return copy;
}

char *clfl_text_selection(widget_id id)
{
    Fl_Text_Display *display = any_display(id);
    if (!display || !display->buffer() || !display->buffer()->selected()) {
        return copy_c_string("");
    }
    char *text = display->buffer()->selection_text();
    char *copy = copy_c_string(text ? text : "");
    std::free(text);
    return copy;
}

int clfl_text_scroll_to_end(widget_id id)
{
    Fl_Text_Display *display = any_display(id);
    if (!display || !display->buffer()) {
        return 0;
    }
    display->insert_position(display->buffer()->length());
    display->show_insert_position();
    return 1;
}

int clfl_text_set_scrollbars(widget_id id, int mode)
{
    Fl_Text_Display *display = any_display(id);
    if (!display) {
        return 0;
    }
    // MODE: 0 none, 1 horizontal, 2 vertical, 3 both, as for browsers. The
    // display shows a scrollbar only on the sides its alignment names.
    int align = 0;
    if (mode & 1) {
        align |= FL_ALIGN_BOTTOM;
    }
    if (mode & 2) {
        align |= FL_ALIGN_RIGHT;
    }
    display->scrollbar_align(static_cast<Fl_Align>(align));
    display->resize(display->x(), display->y(), display->w(), display->h());
    display->redraw();
    return 1;
}

int clfl_text_at_end(widget_id id)
{
    Fl_Text_Display *display = any_display(id);
    if (!display || !display->buffer()) {
        return -1;
    }
    // The last line is in view when the display can place it: its position
    // maps to a line at or above the bottom of the visible rows.
    int x = 0;
    int y = 0;
    const int last = display->buffer()->length();
    if (!display->position_to_xy(last, &x, &y)) {
        return 0;
    }
    return y < display->y() + display->h() ? 1 : 0;
}

int clfl_text_top_line(widget_id id)
{
    Fl_Text_Display *display = any_display(id);
    return display ? display->scroll_row() : 0;
}

int clfl_text_scroll_to_line(widget_id id, int line)
{
    Fl_Text_Display *display = any_display(id);
    if (!display || line < 1) {
        return 0;
    }
    display->scroll(line, 0);
    return 1;
}

int clfl_text_line_of_position(widget_id id, int position)
{
    Fl_Text_Display *display = any_display(id);
    if (!display || !display->buffer() || position < 0 || position > display->buffer()->length()) {
        return 0;
    }
    return display->buffer()->count_lines(0, position) + 1;
}

int clfl_text_position_at(widget_id id, int x, int y)
{
    BufferedTextDisplay *display = styled_display(id);
    return display ? display->position_at(x, y) : -1;
}

int clfl_text_insert_position(widget_id id)
{
    Fl_Text_Display *display = any_display(id);
    return display ? display->insert_position() : -1;
}

int clfl_text_set_insert_position(widget_id id, int position)
{
    Fl_Text_Display *display = any_display(id);
    if (!display || !display->buffer() || position < 0 || position > display->buffer()->length()) {
        return 0;
    }
    display->insert_position(position);
    display->show_insert_position();
    return 1;
}

int clfl_text_replace(widget_id id, int start, int end, const char *text)
{
    Fl_Text_Display *display = any_display(id);
    if (!display || !display->buffer() || !text || start < 0 || end < start || end > display->buffer()->length()) {
        return 0;
    }
    if (auto *styled = dynamic_cast<BufferedTextDisplay *>(display)) {
        return styled->replace_styled(start, end, text, nullptr) ? 1 : 0;
    }
    display->buffer()->replace(start, end, text);
    return 1;
}

int clfl_text_set_wrap(widget_id id, int mode, int margin)
{
    Fl_Text_Display *display = any_display(id);
    if (!display || mode < 0 || mode > 3) {
        return 0;
    }
    display->wrap_mode(mode, margin);
    display->redraw();
    return 1;
}

}
