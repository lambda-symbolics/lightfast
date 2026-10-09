#include "cl_fltk_bridge.hpp"

namespace clfl_bridge {

BufferedTextDisplay::BufferedTextDisplay(int x, int y, int w, int h, const char *label)
    : Fl_Text_Display(x, y, w, h, label),
      buffer_(std::make_unique<Fl_Text_Buffer>())
{
    buffer(buffer_.get());
    textfont(theme().mono_font);
    textsize(theme().text_size);
    wrap_mode(WRAP_AT_BOUNDS, 0);
}

BufferedTextDisplay::~BufferedTextDisplay()
{
    highlight_data(nullptr, nullptr, 0, 'A', nullptr, nullptr);
    buffer(nullptr);
    style_buffer_.reset();
    buffer_.reset();
}

void BufferedTextDisplay::set_styles(int count, const int *fonts, const int *sizes,
                                     const unsigned *colors, const unsigned *attributes,
                                     const unsigned *backgrounds)
{
    styles_.clear();
    for (int index = 0; index < count; ++index) {
        Style_Table_Entry entry;
        entry.color = fl_rgb_color((colors[index] >> 16) & 0xFF, (colors[index] >> 8) & 0xFF, colors[index] & 0xFF);
        entry.font = static_cast<Fl_Font>(fonts[index]);
        entry.size = sizes[index];
        entry.attr = attributes[index];
        entry.bgcolor = fl_rgb_color((backgrounds[index] >> 16) & 0xFF, (backgrounds[index] >> 8) & 0xFF, backgrounds[index] & 0xFF);
        styles_.push_back(entry);
    }
    if (!style_buffer_) {
        style_buffer_ = std::make_unique<Fl_Text_Buffer>();
        // Text already present is given the first style.
        const std::string fill(static_cast<std::size_t>(buffer_->length()), 'A');
        style_buffer_->text(fill.c_str());
    }
    if (styles_.empty()) {
        highlight_data(nullptr, nullptr, 0, 'A', nullptr, nullptr);
    } else {
        highlight_data(style_buffer_.get(), styles_.data(), static_cast<int>(styles_.size()), 'A', nullptr, nullptr);
    }
    redraw();
}

std::string BufferedTextDisplay::style_fill(const char *text, const char *styles, bool *ok) const
{
    const std::size_t length = std::strlen(text);
    *ok = true;
    if (!styles) {
        return std::string(length, 'A');
    }
    if (std::strlen(styles) != length) {
        *ok = false;
        return std::string();
    }
    const char last = styles_.empty() ? 'A' : static_cast<char>('A' + styles_.size() - 1);
    for (std::size_t index = 0; index < length; ++index) {
        if (styles[index] < 'A' || styles[index] > last) {
            *ok = false;
            return std::string();
        }
    }
    return std::string(styles, length);
}

bool BufferedTextDisplay::append_styled(const char *text, const char *styles)
{
    if (!text) {
        return false;
    }
    bool ok = false;
    const std::string fill = style_fill(text, styles, &ok);
    if (!ok) {
        return false;
    }
    buffer_->append(text);
    if (style_buffer_) {
        style_buffer_->append(fill.c_str());
    }
    return true;
}

bool BufferedTextDisplay::replace_styled(int start, int end, const char *text, const char *styles)
{
    if (!text || start < 0 || end < start || end > buffer_->length()) {
        return false;
    }
    bool ok = false;
    const std::string fill = style_fill(text, styles, &ok);
    if (!ok) {
        return false;
    }
    buffer_->replace(start, end, text);
    if (style_buffer_) {
        style_buffer_->replace(start, end, fill.c_str());
    }
    return true;
}

int BufferedTextDisplay::position_at(int x, int y)
{
    const int absolute_x = this->x() + x;
    const int absolute_y = this->y() + y;
    if (absolute_x < text_area.x || absolute_x >= text_area.x + text_area.w ||
        absolute_y < text_area.y || absolute_y >= text_area.y + text_area.h) {
        return -1;
    }
    return xy_to_position(absolute_x, absolute_y, CHARACTER_POS);
}

void BufferedTextDisplay::copy_selection()
{
    if (!buffer_->selected()) {
        return;
    }
    char *text = buffer_->selection_text();
    if (text) {
        Fl::copy(text, static_cast<int>(std::strlen(text)), 1);
        std::free(text);
    }
}

int BufferedTextDisplay::handle(int event)
{
    switch (event) {
    case FL_PUSH:
        dispatch_input_callback(this, EVENT_PUSH, mouse_event_value(this));
        break;
    case FL_RELEASE:
        dispatch_input_callback(this, EVENT_RELEASE, mouse_event_value(this));
        break;
    case FL_KEYDOWN:
        if ((Fl::event_state() & FL_CTRL) && (Fl::event_key() == 'c' || Fl::event_key() == FL_Insert)) {
            copy_selection();
            return 1;
        }
        if (dispatch_input_callback(this, EVENT_KEY, key_event_value())) {
            return 1;
        }
        break;
    default:
        break;
    }
    return Fl_Text_Display::handle(event);
}

} // namespace clfl_bridge
