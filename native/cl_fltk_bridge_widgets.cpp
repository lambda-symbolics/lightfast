#include "cl_fltk_bridge.hpp"

namespace clfl_bridge {

namespace {

struct ChildGeometry {
    Fl_Widget *widget = nullptr;
    int x = 0;
    int y = 0;
    int w = 0;
    int h = 0;
};

std::string ellipsized_label(const char *label, int available_width)
{
    const char *text = label ? label : "";
    if (!*text || available_width <= 0) {
        return "";
    }
    if (fl_width(text) <= available_width) {
        return text;
    }

    constexpr const char *ellipsis = "\xE2\x80\xA6";
    if (fl_width(ellipsis) > available_width) {
        return "";
    }

    std::string prefix(text);
    while (!prefix.empty()) {
        std::size_t start = prefix.size() - 1;
        while (start > 0 &&
               (static_cast<unsigned char>(prefix[start]) & 0xC0) == 0x80) {
            --start;
        }
        prefix.resize(start);
        std::string candidate = prefix + ellipsis;
        if (fl_width(candidate.c_str()) <= available_width) {
            return candidate;
        }
    }
    return ellipsis;
}

} // namespace

Fl_Tile *g_active_tile_drag = nullptr;

class ClflWindow final : public Fl_Double_Window {
public:
    ClflWindow(int x, int y, int w, int h, const char *label)
        : Fl_Double_Window(x, y, w, h, label)
    {
    }

    void resize(int x, int y, int w, int h) override
    {
        const bool changed = (w != this->w()) || (h != this->h());
        Fl_Double_Window::resize(x, y, w, h);
        if (changed && g_programmatic_resize_depth == 0) {
            dispatch_resize_callback(this);
        }
    }

    int handle(int event) override
    {
        if (event == FL_KEYDOWN &&
            dispatch_input_callback(this, EVENT_KEY, key_event_value())) {
            return 1;
        }
        // A key reaches the window only after the focused widget and every
        // group above it declined it. FLTK would next offer it as a shortcut
        // to the widget under the mouse and its groups, each of which asks its
        // children last-added first — so a vertical scrollbar anywhere in the
        // way takes Page Up, Page Down, Home and End whether or not it has
        // focus, and an application's accelerators on those keys never fired.
        // The menu bar is asked here instead, before that pass; what it does
        // not claim goes round as usual, and a focused text field or slider
        // has already had first refusal.
        if (event == FL_KEYDOWN) {
            for (int index = 0; index < children(); ++index) {
                if (auto *bar = dynamic_cast<Fl_Menu_Bar *>(child(index))) {
                    if (bar->takesevents() && bar->handle(FL_SHORTCUT)) {
                        return 1;
                    }
                }
            }
        }
        return Fl_Double_Window::handle(event);
    }
};

class ClassicGroup final : public Fl_Group {
public:
    ClassicGroup(int x, int y, int w, int h, const char *label)
        : Fl_Group(x, y, w, h)
    {
        copy_label(label ? label : "");
        align(FL_ALIGN_LEFT | FL_ALIGN_TOP | FL_ALIGN_INSIDE);
    }

    void resize(int x, int y, int w, int h) override
    {
        const bool changed = (w != this->w()) || (h != this->h());
        Fl_Widget::resize(x, y, w, h);
        if (changed && g_programmatic_resize_depth == 0) {
            dispatch_resize_callback(this);
        }
    }

    void draw() override
    {
        draw_box();
        if (label() && *label()) {
            fl_font(labelfont(), labelsize());
            fl_color(labelcolor());
            fl_draw(label(),
                    x() + 6,
                    y() + 6,
                    w() - 12,
                    16,
                    FL_ALIGN_LEFT | FL_ALIGN_INSIDE);
        }
        fl_push_clip(x(), y(), w(), h());
        for (int i = 0; i < children(); ++i) {
            draw_child(*child(i));
        }
        fl_pop_clip();
    }
};

class ClassicTile final : public Fl_Tile {
public:
    ClassicTile(int x, int y, int w, int h, const char *label)
        : Fl_Tile(x, y, w, h, label)
    {
    }

    int handle(int event) override
    {
        switch (event) {
        case FL_PUSH:
            capture_child_geometry();
            g_active_tile_drag = this;
            return Fl_Tile::handle(event);
        case FL_DRAG: {
            const int handled = Fl_Tile::handle(event);
            // Resize callbacks may reposition children arbitrarily, which can
            // leave stale pixels wherever no child repaints. Repaint the whole
            // tile so a live drag never accumulates debris.
            redraw();
            return handled;
        }
        case FL_RELEASE:
            return handle_release();
        default:
            return Fl_Tile::handle(event);
        }
    }

private:
    std::vector<ChildGeometry> drag_start_geometry_;

    void capture_child_geometry()
    {
        drag_start_geometry_.clear();
        drag_start_geometry_.reserve(children());
        for (int i = 0; i < children(); ++i) {
            Fl_Widget *item = child(i);
            if (item) {
                drag_start_geometry_.push_back({ item,
                                                 item->x(),
                                                 item->y(),
                                                 item->w(),
                                                 item->h() });
            }
        }
    }

    int handle_release()
    {
        const int handled = Fl_Tile::handle(FL_RELEASE);

        init_sizes();
        if (g_active_tile_drag == this) {
            g_active_tile_drag = nullptr;
        }
        dispatch_changed_child_resizes();
        drag_start_geometry_.clear();
        redraw();
        return handled;
    }

    void dispatch_changed_child_resizes()
    {
        std::vector<Fl_Widget *> changed_children;
        changed_children.reserve(drag_start_geometry_.size());

        for (const ChildGeometry &geometry : drag_start_geometry_) {
            Fl_Widget *item = geometry.widget;
            if (item &&
                (item->x() != geometry.x ||
                 item->y() != geometry.y ||
                 item->w() != geometry.w ||
                 item->h() != geometry.h)) {
                changed_children.push_back(item);
            }
        }

        for (Fl_Widget *item : changed_children) {
            dispatch_resize_callback(item);
        }
    }
};

template <typename Base>
class ClassicButtonControl : public Base {
public:
    ClassicButtonControl(int x, int y, int w, int h, const char *label)
        : Base(x, y, w, h, label)
    {
    }

    void draw() override
    {
        const int offset = this->value() ? 1 : 0;
        this->draw_box(this->value() ? this->down_box() : this->box(), this->color());
        fl_font(this->labelfont(), this->labelsize());
        fl_color(this->active_r() ? this->labelcolor() : fl_inactive(this->labelcolor()));
        if (Fl_Image *icon = this->image()) {
            const char *label_text = this->label() ? this->label() : "";
            if (!*label_text) {
                const int icon_x = this->x() + ((this->w() - icon->w()) / 2) + offset;
                const int icon_y = this->y() + ((this->h() - icon->h()) / 2) + offset;

                icon->draw(icon_x, icon_y);
                return;
            }

            const int icon_x = this->x() + 6 + offset;
            const int icon_y = this->y() + ((this->h() - icon->h()) / 2) + offset;
            const int label_x = icon_x + icon->w() + 5;
            const int label_w = std::max(0, this->x() + this->w() - label_x - 4);
            const std::string display_label = ellipsized_label(label_text, label_w);

            icon->draw(icon_x, icon_y);
            fl_draw(display_label.c_str(),
                    label_x,
                    this->y() + 3 + offset,
                    label_w,
                    this->h() - 3,
                    FL_ALIGN_LEFT | FL_ALIGN_INSIDE);
        } else {
            const int label_w = std::max(0, this->w() - 12);
            const std::string display_label = ellipsized_label(this->label(), label_w);
            fl_draw(display_label.c_str(),
                    this->x() + 6 + offset,
                    this->y() + 3 + offset,
                    label_w,
                    this->h() - 3,
                    FL_ALIGN_CENTER | FL_ALIGN_INSIDE);
        }
    }
};

using ClassicButton = ClassicButtonControl<Fl_Button>;
using ClassicReturnButton = ClassicButtonControl<Fl_Return_Button>;
using ClassicRepeatButton = ClassicButtonControl<Fl_Repeat_Button>;

class ClassicMenuButton final : public Fl_Menu_Button {
public:
    ClassicMenuButton(int x, int y, int w, int h, const char *label)
        : Fl_Menu_Button(x, y, w, h, label)
    {
    }

    void draw() override
    {
        constexpr int arrow_width = 14;
        draw_box(box(), color());
        fl_font(labelfont(), labelsize());
        fl_color(active_r() ? labelcolor() : fl_inactive(labelcolor()));

        const int right_edge = x() + w() - arrow_width - 4;
        if (Fl_Image *icon = image()) {
            const int icon_x = x() + 6;
            const int icon_y = y() + ((h() - icon->h()) / 2);
            const int label_x = icon_x + icon->w() + 5;
            const int label_w = std::max(0, right_edge - label_x);
            const std::string display_label = ellipsized_label(label(), label_w);

            icon->draw(icon_x, icon_y);
            fl_draw(display_label.c_str(),
                    label_x,
                    y() + 3,
                    label_w,
                    h() - 3,
                    FL_ALIGN_LEFT | FL_ALIGN_INSIDE);
        } else {
            const int label_w = std::max(0, right_edge - x() - 8);
            const std::string display_label = ellipsized_label(label(), label_w);
            fl_draw(display_label.c_str(),
                    x() + 4,
                    y() + 3,
                    label_w,
                    h() - 3,
                    FL_ALIGN_CENTER | FL_ALIGN_INSIDE);
        }

        const int arrow_x = x() + w() - 9;
        const int arrow_y = y() + (h() / 2);
        fl_polygon(arrow_x - 4,
                   arrow_y - 3,
                   arrow_x + 4,
                   arrow_y - 3,
                   arrow_x,
                   arrow_y + 2);
    }
};

template <typename Base>
class ClassicSingleLineInput : public Base {
public:
    ClassicSingleLineInput(int x, int y, int w, int h, const char *label)
        : Base(x, y, w, h, label)
    {
    }

    void draw() override
    {
        if (this->input_type() == FL_HIDDEN_INPUT) {
            return;
        }

        const Fl_Boxtype box_type = this->box();
        if (this->damage() & FL_DAMAGE_ALL) {
            this->draw_box(box_type, this->color());
        }
        this->drawtext(this->x() + Fl::box_dx(box_type),
                       this->y() + Fl::box_dy(box_type) + kTextYOffset,
                       this->w() - Fl::box_dw(box_type),
                       this->h() - Fl::box_dh(box_type));
    }

private:
    static constexpr int kTextYOffset = 2;
};

class ClassicChoice final : public Fl_Choice {
public:
    ClassicChoice(int x, int y, int w, int h, const char *label)
        : Fl_Choice(x, y, w, h, label)
    {
    }

    void draw() override
    {
        constexpr int arrow_width = 18;
        const Fl_Boxtype box_type = FL_DOWN_BOX;
        const int dx = Fl::box_dx(box_type);
        const int dy = Fl::box_dy(box_type);
        const int arrow_x = x() + w() - arrow_width - dx;
        const int arrow_y = y() + dy;
        const int arrow_h = h() - (2 * dy);
        const int text_x = x() + dx + 4;
        const int text_w = std::max(0, w() - arrow_width - (2 * dx) - 8);

        draw_box(box_type, FL_BACKGROUND2_COLOR);
        draw_box(FL_UP_BOX, arrow_x, arrow_y, arrow_width, arrow_h, color());

        fl_color(active_r() ? labelcolor() : fl_inactive(labelcolor()));
        const int mid_x = arrow_x + (arrow_width / 2);
        const int mid_y = arrow_y + (arrow_h / 2) + 2;
        fl_polygon(mid_x - 4, mid_y - 2, mid_x + 4, mid_y - 2, mid_x, mid_y + 3);

        if (const char *current = text()) {
            fl_push_clip(text_x, y() + dy, text_w, h() - (2 * dy));
            fl_font(textfont(), textsize());
            fl_color(active_r() ? textcolor() : fl_inactive(textcolor()));
            const int baseline =
                y() + ((h() - fl_height()) / 2) + fl_height() - fl_descent() + 2;
            fl_draw(current, text_x, baseline);
            fl_pop_clip();
        }

        draw_label();
    }
};

class ClassicValueInput final : public Fl_Valuator {
public:
    ClassicSingleLineInput<Fl_Input> input;

    ClassicValueInput(int x, int y, int w, int h, const char *label)
        : Fl_Valuator(x, y, w, h, label),
          input(x, y, w, h, nullptr)
    {
        soft_ = 0;
        if (input.parent()) {
            input.parent()->remove(input);
        }
        input.parent(reinterpret_cast<Fl_Group *>(this));
        input.callback(input_callback, this);
        input.when(FL_WHEN_CHANGED);
        box(input.box());
        color(input.color());
        selection_color(input.selection_color());
        align(FL_ALIGN_LEFT);
        value_damage();
        set_flag(SHORTCUT_LABEL);
    }

    ~ClassicValueInput() override
    {
        if (input.parent() == reinterpret_cast<Fl_Group *>(this)) {
            input.parent(nullptr);
        }
    }

    int handle(int event) override
    {
        double new_value;
        int delta;
        const int mouse_x = Fl::event_x_root();
        static int initial_x = 0;
        static int drag_button = 0;

        input.when(when());
        switch (event) {
        case FL_PUSH:
            if (!step()) {
                goto default_handler;
            }
            initial_x = mouse_x;
            drag_button = Fl::event_button();
            handle_push();
            return 1;
        case FL_DRAG:
            if (!step()) {
                goto default_handler;
            }
            delta = mouse_x - initial_x;
            if (delta > 5) {
                delta -= 5;
            } else if (delta < -5) {
                delta += 5;
            } else {
                delta = 0;
            }
            switch (drag_button) {
            case 3:
                new_value = increment(previous_value(), delta * 100);
                break;
            case 2:
                new_value = increment(previous_value(), delta * 10);
                break;
            default:
                new_value = increment(previous_value(), delta);
                break;
            }
            new_value = round(new_value);
            handle_drag(soft() ? softclamp(new_value) : clamp(new_value));
            return 1;
        case FL_RELEASE:
            if (!step()) {
                goto default_handler;
            }
            if (value() != previous_value() || !Fl::event_is_click()) {
                handle_release();
            } else {
                Fl_Widget_Tracker tracker(&input);
                input.handle(FL_PUSH);
                if (tracker.exists()) {
                    input.handle(FL_RELEASE);
                }
            }
            return 1;
        case FL_FOCUS:
            return input.take_focus();
        case FL_SHORTCUT:
            return input.handle(event);
        default:
        default_handler:
            input.type((std::floor(step()) != step() || step() == 0.0) ? FL_FLOAT_INPUT : FL_INT_INPUT);
            return input.handle(event);
        }
    }

    void draw() override
    {
        if (damage() & ~FL_DAMAGE_CHILD) {
            input.clear_damage(FL_DAMAGE_ALL);
        }
        input.box(box());
        input.color(color(), selection_color());
        Fl_Widget *input_widget = &input;
        input_widget->draw();
        input.clear_damage();
    }

    void resize(int x, int y, int w, int h) override
    {
        Fl_Valuator::resize(x, y, w, h);
        input.resize(x, y, w, h);
    }

    void soft(int value)
    {
        soft_ = value;
    }

    int soft() const
    {
        return soft_;
    }

    Fl_Font textfont() const
    {
        return input.textfont();
    }

    void textfont(Fl_Font font)
    {
        input.textfont(font);
    }

    Fl_Fontsize textsize() const
    {
        return input.textsize();
    }

    void textsize(Fl_Fontsize size)
    {
        input.textsize(size);
    }

    Fl_Color textcolor() const
    {
        return input.textcolor();
    }

    void textcolor(Fl_Color color)
    {
        input.textcolor(color);
    }

protected:
    void value_damage() override
    {
        char buffer[128];
        format(buffer);
        input.value(buffer);
        input.mark(input.insert_position());
    }

private:
    int soft_ = 0;

    static void input_callback(Fl_Widget *, void *data)
    {
        auto &value_input = *static_cast<ClassicValueInput *>(data);
        double new_value;
        if (std::floor(value_input.step()) != value_input.step() || value_input.step() == 0.0) {
            new_value = std::strtod(value_input.input.value(), nullptr);
        } else {
            new_value = std::strtol(value_input.input.value(), nullptr, 0);
        }
        if (new_value != value_input.value() || (value_input.when() & FL_WHEN_NOT_CHANGED)) {
            value_input.set_value(new_value);
            value_input.set_changed();
            if (value_input.when()) {
                value_input.do_callback(FL_REASON_CHANGED);
            }
        }
    }
};

class ClassicStatusBox final : public Fl_Box {
public:
    ClassicStatusBox(int x, int y, int w, int h, const char *label)
        : Fl_Box(x, y, w, h, label)
    {
    }

    void draw() override
    {
        draw_box();
        fl_font(labelfont(), labelsize());
        fl_color(labelcolor());
        fl_draw(label() ? label() : "",
                x() + 5,
                y() + 4,
                w() - 10,
                h() - 4,
                FL_ALIGN_LEFT | FL_ALIGN_INSIDE);
    }
};

bool classic_value_input_set_text_size(Fl_Widget *widget, int size)
{
    if (auto *input = dynamic_cast<ClassicValueInput *>(widget)) {
        input->textsize(size);
        return true;
    }
    if (auto *output = dynamic_cast<Fl_Value_Output *>(widget)) {
        output->textsize(size);
        return true;
    }
    if (auto *chart = dynamic_cast<Fl_Chart *>(widget)) {
        chart->textsize(size);
        return true;
    }
    if (auto *terminal = dynamic_cast<Fl_Terminal *>(widget)) {
        terminal->textsize(size);
        return true;
    }
    return false;
}

bool classic_value_input_set_text_font(Fl_Widget *widget, int font)
{
    const auto text_font = static_cast<Fl_Font>(font);
    if (auto *input = dynamic_cast<ClassicValueInput *>(widget)) {
        input->textfont(text_font);
        return true;
    }
    if (auto *output = dynamic_cast<Fl_Value_Output *>(widget)) {
        output->textfont(text_font);
        return true;
    }
    if (auto *choice = dynamic_cast<Fl_Scheme_Choice *>(widget)) {
        choice->textfont(text_font);
        return true;
    }
    if (auto *chart = dynamic_cast<Fl_Chart *>(widget)) {
        chart->textfont(text_font);
        return true;
    }
    if (auto *terminal = dynamic_cast<Fl_Terminal *>(widget)) {
        terminal->textfont(text_font);
        return true;
    }
    return false;
}

class ClassicToggleButton : public Fl_Button {
public:
    enum class Indicator {
        Check,
        Light,
        Radio
    };

    ClassicToggleButton(int x, int y, int w, int h, const char *label, Indicator indicator)
        : Fl_Button(x, y, w, h, label),
          indicator_(indicator)
    {
    }

    void draw() override
    {
        fl_push_clip(x(), y(), w(), h());
        fl_color(color());
        fl_rectf(x(), y(), w(), h());

        const int indicator_size = indicator_ == Indicator::Radio ? 10 : 11;
        const int indicator_x = x() + 2;
        const int indicator_y = y() + ((h() - indicator_size) / 2);

        if (indicator_ == Indicator::Radio) {
            draw_radio(indicator_x, indicator_y, indicator_size);
        } else {
            draw_square(indicator_x, indicator_y, indicator_size);
        }

        fl_font(labelfont(), labelsize());
        fl_color(active_r() ? labelcolor() : fl_inactive(labelcolor()));
        const int label_x = indicator_x + indicator_size + 6;
        const int label_width = std::max(0, x() + w() - label_x - 4);
        const std::string display_label = ellipsized_label(label(), label_width);
        // FLTK centers the font's ascent/descent box, whose visible glyphs sit
        // slightly high beside the geometric center of the indicator.
        fl_draw(display_label.c_str(), label_x, y() + 4, label_width, h(),
                FL_ALIGN_LEFT | FL_ALIGN_INSIDE);
        fl_pop_clip();
    }

private:
    Indicator indicator_;

    void draw_square(int x, int y, int size)
    {
        fl_color(FL_DARK3);
        fl_line(x, y, x + size - 1, y);
        fl_line(x, y, x, y + size - 1);
        fl_color(FL_WHITE);
        fl_line(x + 1, y + size - 1, x + size - 1, y + size - 1);
        fl_line(x + size - 1, y + 1, x + size - 1, y + size - 1);
        fl_color(indicator_ == Indicator::Light && value()
                     ? selection_color()
                     : FL_WHITE);
        fl_rectf(x + 1, y + 1, size - 2, size - 2);

        if (indicator_ == Indicator::Check && value()) {
            fl_color(FL_BLACK);
            fl_line(x + 2, y + 5, x + 4, y + 8);
            fl_line(x + 4, y + 8, x + 8, y + 2);
            fl_line(x + 3, y + 5, x + 4, y + 7);
            fl_line(x + 4, y + 7, x + 8, y + 1);
        }
    }

    void draw_radio(int x, int y, int size)
    {
        fl_color(FL_WHITE);
        fl_pie(x, y, size, size, 0.0, 360.0);
        fl_color(FL_BLACK);
        fl_arc(x, y, size, size, 0.0, 360.0);
        if (value()) {
            fl_color(FL_BLACK);
            fl_pie(x + 3, y + 3, size - 6, size - 6, 0.0, 360.0);
        }
    }
};

class BufferedTextDisplay final : public Fl_Text_Display {
public:
    BufferedTextDisplay(int x, int y, int w, int h, const char *label)
        : Fl_Text_Display(x, y, w, h, label),
          buffer_(std::make_unique<Fl_Text_Buffer>())
    {
        buffer(buffer_.get());
        textfont(FL_COURIER);
        textsize(12);
        wrap_mode(WRAP_AT_BOUNDS, 0);
    }

    ~BufferedTextDisplay() override
    {
        buffer(nullptr);
        buffer_.reset();
    }

private:
    std::unique_ptr<Fl_Text_Buffer> buffer_;
};

class BufferedTextEditor final : public Fl_Text_Editor {
public:
    BufferedTextEditor(int x, int y, int w, int h, const char *label)
        : Fl_Text_Editor(x, y, w, h, label),
          buffer_(std::make_unique<Fl_Text_Buffer>())
    {
        buffer(buffer_.get());
        textfont(FL_COURIER);
        textsize(12);
        wrap_mode(WRAP_AT_BOUNDS, 0);
    }

    ~BufferedTextEditor() override
    {
        buffer(nullptr);
        buffer_.reset();
    }

private:
    std::unique_ptr<Fl_Text_Buffer> buffer_;
};


class ClassicCanvas final : public Fl_Widget {
public:
    ClassicCanvas(int x, int y, int w, int h, const char *label)
        : Fl_Widget(x, y, w, h, label)
    {
        box(FL_DOWN_BOX);
        color(FL_WHITE);
    }

    void draw() override
    {
        draw_box(box(), color());

        const int clip_x = x() + Fl::box_dx(box());
        const int clip_y = y() + Fl::box_dy(box());
        const int clip_w = std::max(0, w() - Fl::box_dw(box()));
        const int clip_h = std::max(0, h() - Fl::box_dh(box()));
        fl_push_clip(clip_x, clip_y, clip_w, clip_h);
        dispatch_draw_callback(this);
        fl_pop_clip();
    }

    int handle(int event) override
    {
        switch (event) {
        case FL_PUSH:
            take_focus();
            return dispatch_input_callback(this, EVENT_PUSH, mouse_event_value(this)) ? 1 : Fl_Widget::handle(event);
        case FL_DRAG:
            return dispatch_input_callback(this, EVENT_DRAG, mouse_event_value(this)) ? 1 : Fl_Widget::handle(event);
        case FL_RELEASE:
            return dispatch_input_callback(this, EVENT_RELEASE, mouse_event_value(this)) ? 1 : Fl_Widget::handle(event);
        case FL_MOUSEWHEEL:
            return dispatch_input_callback(this, EVENT_WHEEL, mouse_event_value(this)) ? 1 : Fl_Widget::handle(event);
        case FL_KEYDOWN:
            return dispatch_input_callback(this, EVENT_KEY, key_event_value()) ? 1 : Fl_Widget::handle(event);
        case FL_FOCUS:
        case FL_UNFOCUS:
            return 1;
        default:
            return Fl_Widget::handle(event);
        }
    }
};

Fl_Widget *create_widget(int kind, int x, int y, int w, int h, const char *label)
{
    const char *text = label ? label : "";
    switch (kind) {
    case WIDGET_WINDOW:
        return new ClflWindow(x, y, w, h, text);
    case WIDGET_GROUP: {
        auto *group = new ClassicGroup(x, y, w, h, text);
        group->box(FL_ENGRAVED_BOX);
        apply_common_style(group);
        return group;
    }
    case WIDGET_TILE: {
        auto *tile = new ClassicTile(x, y, w, h, text);
        tile->box(FL_NO_BOX);
        apply_common_style(tile);
        return tile;
    }
    case WIDGET_FLEX: {
        auto *flex = new Fl_Flex(x, y, w, h, text);
        flex->box(FL_NO_BOX);
        flex->type(Fl_Flex::VERTICAL);
        apply_common_style(flex);
        return flex;
    }
    case WIDGET_BOX: {
        auto *box = new Fl_Box(x, y, w, h, text);
        box->box(FL_UP_BOX);
        apply_common_style(box);
        return box;
    }
    case WIDGET_LABEL: {
        auto *label = new Fl_Box(x, y, w, h, text);
        label->box(FL_NO_BOX);
        label->align(FL_ALIGN_LEFT | FL_ALIGN_INSIDE);
        apply_common_style(label);
        return label;
    }
    case WIDGET_BUTTON: {
        auto *button = new ClassicButton(x, y, w, h, text);
        apply_button_style(button);
        return button;
    }
    case WIDGET_TOGGLE_BUTTON: {
        auto *button = new ClassicButton(x, y, w, h, text);
        button->type(FL_TOGGLE_BUTTON);
        button->when(FL_WHEN_CHANGED);
        apply_button_style(button);
        return button;
    }
    case WIDGET_RETURN_BUTTON: {
        auto *button = new ClassicReturnButton(x, y, w, h, text);
        apply_button_style(button);
        return button;
    }
    case WIDGET_REPEAT_BUTTON: {
        auto *button = new ClassicRepeatButton(x, y, w, h, text);
        apply_button_style(button);
        return button;
    }
    case WIDGET_INPUT: {
        auto *input = new ClassicSingleLineInput<Fl_Input>(x, y, w, h, text);
        input->when(FL_WHEN_CHANGED);
        input->textsize(12);
        apply_inset_style(input);
        return input;
    }
    case WIDGET_SECRET_INPUT: {
        auto *input = new ClassicSingleLineInput<Fl_Secret_Input>(x, y, w, h, text);
        input->when(FL_WHEN_CHANGED);
        input->textsize(12);
        apply_inset_style(input);
        return input;
    }
    case WIDGET_INT_INPUT: {
        auto *input = new ClassicSingleLineInput<Fl_Int_Input>(x, y, w, h, text);
        input->when(FL_WHEN_CHANGED);
        input->textsize(12);
        apply_inset_style(input);
        return input;
    }
    case WIDGET_FLOAT_INPUT: {
        auto *input = new ClassicSingleLineInput<Fl_Float_Input>(x, y, w, h, text);
        input->when(FL_WHEN_CHANGED);
        input->textsize(12);
        apply_inset_style(input);
        return input;
    }
    case WIDGET_MULTILINE_INPUT: {
        auto *input = new Fl_Multiline_Input(x, y, w, h, text);
        input->when(FL_WHEN_CHANGED);
        input->textfont(FL_COURIER);
        input->textsize(12);
        apply_inset_style(input);
        return input;
    }
    case WIDGET_OUTPUT: {
        auto *output = new ClassicSingleLineInput<Fl_Output>(x, y, w, h, text);
        output->textsize(12);
        apply_inset_style(output);
        return output;
    }
    case WIDGET_MULTILINE_OUTPUT: {
        auto *output = new Fl_Multiline_Output(x, y, w, h, text);
        output->textfont(FL_COURIER);
        output->textsize(12);
        apply_inset_style(output);
        return output;
    }
    case WIDGET_TEXT_DISPLAY: {
        auto *display = new BufferedTextDisplay(x, y, w, h, text);
        display->box(FL_DOWN_BOX);
        apply_common_style(display);
        return display;
    }
    case WIDGET_TEXT_EDITOR: {
        auto *editor = new BufferedTextEditor(x, y, w, h, text);
        editor->box(FL_DOWN_BOX);
        editor->when(FL_WHEN_CHANGED);
        apply_common_style(editor);
        return editor;
    }
    case WIDGET_HELP_VIEW: {
        auto *help = new Fl_Help_View(x, y, w, h, text);
        help->box(FL_DOWN_BOX);
        help->textsize(12);
        apply_common_style(help);
        return help;
    }
    case WIDGET_CLOCK: {
        auto *clock = new Fl_Clock(x, y, w, h, text);
        clock->box(FL_DOWN_BOX);
        apply_common_style(clock);
        return clock;
    }
    case WIDGET_CHOICE: {
        auto *choice = new ClassicChoice(x, y, w, h, text);
        choice->when(FL_WHEN_CHANGED);
        choice->textsize(12);
        apply_inset_style(choice);
        return choice;
    }
    case WIDGET_INPUT_CHOICE: {
        auto *choice = new Fl_Input_Choice(x, y, w, h, text);
        choice->when(FL_WHEN_CHANGED);
        choice->textsize(12);
        choice->box(FL_DOWN_BOX);
        apply_common_style(choice);
        return choice;
    }
    case WIDGET_BROWSER: {
        auto *browser = new Fl_Browser(x, y, w, h, text);
        browser->type(FL_HOLD_BROWSER);
        browser->when(FL_WHEN_RELEASE_ALWAYS);
        browser->textfont(FL_COURIER);
        browser->textsize(12);
        apply_inset_style(browser);
        return browser;
    }
    case WIDGET_CHECK_BROWSER: {
        auto *browser = new Fl_Check_Browser(x, y, w, h, text);
        browser->box(FL_DOWN_BOX);
        browser->textfont(FL_HELVETICA);
        browser->textsize(12);
        browser->when(FL_WHEN_CHANGED);
        apply_common_style(browser);
        return browser;
    }
    case WIDGET_FILE_BROWSER: {
        auto *browser = new Fl_File_Browser(x, y, w, h, text);
        browser->box(FL_DOWN_BOX);
        browser->textfont(FL_HELVETICA);
        browser->textsize(12);
        browser->filetype(Fl_File_Browser::FILES);
        apply_common_style(browser);
        return browser;
    }
    case WIDGET_TABLE: {
        return create_classic_table(x, y, w, h, text);
    }
    case WIDGET_CANVAS: {
        auto *canvas = new ClassicCanvas(x, y, w, h, text);
        apply_common_style(canvas);
        return canvas;
    }
    case WIDGET_MENU_BAR: {
        auto *menu = new Fl_Menu_Bar(x, y, w, h, text);
        menu->box(FL_UP_BOX);
        menu->textsize(12);
        return menu;
    }
    case WIDGET_MENU_BUTTON: {
        auto *menu = new ClassicMenuButton(x, y, w, h, text);
        menu->box(FL_UP_BOX);
        menu->down_box(FL_DOWN_BOX);
        menu->textsize(12);
        menu->labelsize(12);
        return menu;
    }
    case WIDGET_CHECK_BUTTON: {
        auto *check = new ClassicToggleButton(x, y, w, h, text, ClassicToggleButton::Indicator::Check);
        check->type(FL_TOGGLE_BUTTON);
        check->when(FL_WHEN_CHANGED);
        check->labelsize(12);
        check->labelcolor(FL_BLACK);
        check->selection_color(FL_BLACK);
        check->color(FL_BACKGROUND_COLOR);
        return check;
    }
    case WIDGET_VALUE_INPUT: {
        auto *input = new ClassicValueInput(x, y, w, h, text);
        input->when(FL_WHEN_CHANGED);
        input->textsize(12);
        apply_inset_style(input);
        return input;
    }
    case WIDGET_VALUE_SLIDER: {
        auto *slider = new Fl_Hor_Value_Slider(x, y, w, h, text);
        slider->box(FL_DOWN_BOX);
        slider->bounds(0.0, 100.0);
        slider->step(1.0);
        slider->value(50.0);
        slider->when(FL_WHEN_CHANGED);
        slider->textsize(12);
        apply_common_style(slider);
        return slider;
    }
    case WIDGET_SCROLLBAR: {
        auto *scrollbar = new Fl_Scrollbar(x, y, w, h, text);
        scrollbar->type(FL_HORIZONTAL);
        scrollbar->bounds(0.0, 100.0);
        scrollbar->step(1.0);
        scrollbar->value(25);
        scrollbar->when(FL_WHEN_CHANGED);
        apply_common_style(scrollbar);
        return scrollbar;
    }
    case WIDGET_ADJUSTER: {
        auto *adjuster = new Fl_Adjuster(x, y, w, h, text);
        adjuster->bounds(0.0, 100.0);
        adjuster->step(1.0);
        adjuster->value(10.0);
        adjuster->when(FL_WHEN_CHANGED);
        apply_common_style(adjuster);
        return adjuster;
    }
    case WIDGET_SCROLL: {
        auto *scroll = new Fl_Scroll(x, y, w, h, text);
        scroll->box(FL_FLAT_BOX);
        scroll->type(Fl_Scroll::VERTICAL);
        apply_common_style(scroll);
        return scroll;
    }
    case WIDGET_TABS: {
        auto *tabs = new Fl_Tabs(x, y, w, h, text);
        tabs->box(FL_THIN_UP_BOX);
        tabs->labelsize(12);
        return tabs;
    }
    case WIDGET_TAB_PAGE: {
        auto *page = new Fl_Group(x, y, w, h, text);
        page->box(FL_NO_BOX);
        apply_common_style(page);
        return page;
    }
    case WIDGET_PROGRESS: {
        auto *progress = new Fl_Progress(x, y, w, h, text);
        progress->box(FL_DOWN_BOX);
        progress->minimum(0.0);
        progress->maximum(100.0);
        progress->value(0.0);
        progress->color(FL_WHITE);
        progress->selection_color(fl_rgb_color(0, 0, 128));
        apply_common_style(progress);
        return progress;
    }
    case WIDGET_SLIDER: {
        auto *slider = new Fl_Hor_Slider(x, y, w, h, text);
        slider->box(FL_DOWN_BOX);
        slider->bounds(0.0, 100.0);
        slider->step(1.0);
        slider->value(50.0);
        slider->when(FL_WHEN_CHANGED);
        apply_common_style(slider);
        return slider;
    }
    case WIDGET_VERTICAL_SLIDER: {
        auto *slider = new Fl_Slider(x, y, w, h, text);
        slider->type(FL_VERT_NICE_SLIDER);
        slider->box(FL_DOWN_BOX);
        slider->bounds(100.0, 0.0);
        slider->step(1.0);
        slider->value(50.0);
        slider->when(FL_WHEN_CHANGED);
        apply_common_style(slider);
        return slider;
    }
    case WIDGET_STATUS_BAR: {
        auto *status = new ClassicStatusBox(x, y, w, h, text);
        status->box(FL_DOWN_BOX);
        apply_common_style(status);
        return status;
    }
    case WIDGET_LIGHT_BUTTON: {
        auto *button = new ClassicToggleButton(x, y, w, h, text, ClassicToggleButton::Indicator::Light);
        button->type(FL_TOGGLE_BUTTON);
        button->when(FL_WHEN_CHANGED);
        button->labelsize(12);
        button->labelcolor(FL_BLACK);
        button->selection_color(fl_rgb_color(0, 0, 128));
        button->color(FL_BACKGROUND_COLOR);
        return button;
    }
    case WIDGET_RADIO_BUTTON: {
        auto *button = new ClassicToggleButton(x, y, w, h, text, ClassicToggleButton::Indicator::Radio);
        button->type(FL_RADIO_BUTTON);
        button->when(FL_WHEN_CHANGED);
        button->labelsize(12);
        button->labelcolor(FL_BLACK);
        button->selection_color(FL_BLACK);
        button->color(FL_BACKGROUND_COLOR);
        return button;
    }
    case WIDGET_COUNTER: {
        auto *counter = new Fl_Counter(x, y, w, h, text);
        counter->type(FL_SIMPLE_COUNTER);
        counter->bounds(0.0, 100.0);
        counter->step(1.0);
        counter->value(1.0);
        counter->when(FL_WHEN_CHANGED);
        counter->textsize(12);
        apply_common_style(counter);
        return counter;
    }
    case WIDGET_SPINNER: {
        auto *spinner = new Fl_Spinner(x, y, w, h, text);
        spinner->range(0.0, 100.0);
        spinner->step(1.0);
        spinner->value(1.0);
        spinner->textsize(12);
        spinner->when(FL_WHEN_CHANGED);
        apply_common_style(spinner);
        return spinner;
    }
    case WIDGET_DIAL: {
        auto *dial = new Fl_Dial(x, y, w, h, text);
        dial->type(FL_LINE_DIAL);
        dial->bounds(0.0, 100.0);
        dial->step(1.0);
        dial->value(50.0);
        dial->when(FL_WHEN_CHANGED);
        apply_common_style(dial);
        return dial;
    }
    case WIDGET_ROLLER: {
        auto *roller = new Fl_Roller(x, y, w, h, text);
        roller->bounds(0.0, 100.0);
        roller->step(1.0);
        roller->value(50.0);
        roller->when(FL_WHEN_CHANGED);
        apply_common_style(roller);
        return roller;
    }
    case WIDGET_TREE: {
        auto *tree = new Fl_Tree(x, y, w, h, text);
        tree->box(FL_DOWN_BOX);
        tree->showroot(0);
        tree->connectorstyle(FL_TREE_CONNECTOR_DOTTED);
        tree->selectmode(FL_TREE_SELECT_SINGLE);
        tree->item_labelsize(12);
        tree->when(FL_WHEN_CHANGED);
        apply_common_style(tree);
        return tree;
    }
    case WIDGET_FILE_INPUT: {
        auto *input = new Fl_File_Input(x, y, w, h, text);
        input->when(FL_WHEN_CHANGED);
        input->textsize(12);
        apply_inset_style(input);
        return input;
    }
    case WIDGET_VALUE_OUTPUT: {
        auto *output = new Fl_Value_Output(x, y, w, h, text);
        output->when(FL_WHEN_CHANGED);
        output->textsize(12);
        apply_inset_style(output);
        return output;
    }
    case WIDGET_PACK: {
        auto *pack = new Fl_Pack(x, y, w, h, text);
        pack->type(Fl_Pack::VERTICAL);
        pack->spacing(0);
        apply_common_style(pack);
        return pack;
    }
    case WIDGET_GRID: {
        auto *grid = new Fl_Grid(x, y, w, h, text);
        apply_common_style(grid);
        return grid;
    }
    case WIDGET_POSITIONER: {
        auto *positioner = new Fl_Positioner(x, y, w, h, text);
        positioner->xbounds(0.0, 1.0);
        positioner->ybounds(0.0, 1.0);
        positioner->value(0.5, 0.5);
        positioner->when(FL_WHEN_CHANGED);
        apply_inset_style(positioner);
        return positioner;
    }
    case WIDGET_WIZARD: {
        auto *wizard = new Fl_Wizard(x, y, w, h, text);
        apply_common_style(wizard);
        return wizard;
    }
    case WIDGET_CHART: {
        auto *chart = new Fl_Chart(x, y, w, h, text);
        chart->type(FL_BAR_CHART);
        chart->textsize(12);
        apply_inset_style(chart);
        return chart;
    }
    case WIDGET_SCHEME_CHOICE: {
        auto *choice = new Fl_Scheme_Choice(x, y, w, h, text);
        choice->when(FL_WHEN_CHANGED);
        choice->textsize(12);
        apply_inset_style(choice);
        return choice;
    }
    case WIDGET_TERMINAL: {
        auto *terminal = new Fl_Terminal(x, y, w, h, text);
        terminal->textsize(12);
        apply_inset_style(terminal);
        return terminal;
    }
    case WIDGET_COLOR_CHOOSER: {
        auto *chooser = new Fl_Color_Chooser(x, y, w, h, text);
        chooser->when(FL_WHEN_CHANGED);
        apply_common_style(chooser);
        return chooser;
    }
    case WIDGET_SHORTCUT_BUTTON: {
        auto *button = new Fl_Shortcut_Button(x, y, w, h, text);
        button->when(FL_WHEN_CHANGED);
        apply_button_style(button);
        return button;
    }
    default:
        return nullptr;
    }
}


} // namespace clfl_bridge
