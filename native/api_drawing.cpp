#include "cl_fltk_bridge.hpp"

using namespace clfl_bridge;

extern "C" {

void clfl_draw_set_color_rgb(int red, int green, int blue)
{
    fl_color(fl_rgb_color(std::clamp(red, 0, 255),
                          std::clamp(green, 0, 255),
                          std::clamp(blue, 0, 255)));
}

void clfl_draw_set_font(int font, int size)
{
    fl_font(static_cast<Fl_Font>(font), std::max(1, size));
}

void clfl_draw_line(int x1, int y1, int x2, int y2)
{
    fl_line(x1, y1, x2, y2);
}

void clfl_draw_rect(int x, int y, int width, int height)
{
    fl_rect(x, y, std::max(0, width), std::max(0, height));
}

void clfl_draw_filled_rect(int x, int y, int width, int height)
{
    fl_rectf(x, y, std::max(0, width), std::max(0, height));
}

void clfl_draw_circle(int x, int y, int radius)
{
    const int diameter = std::max(0, radius * 2);
    fl_arc(x - radius, y - radius, diameter, diameter, 0.0, 360.0);
}

void clfl_draw_filled_circle(int x, int y, int radius)
{
    const int diameter = std::max(0, radius * 2);
    fl_pie(x - radius, y - radius, diameter, diameter, 0.0, 360.0);
}

void clfl_draw_text(const char *text, int x, int y, int width, int height, int align)
{
    const char *safe_text = text ? text : "";
    if (width > 0 && height > 0) {
        fl_draw(safe_text, x, y, width, height, static_cast<Fl_Align>(align));
    } else {
        fl_draw(safe_text, x, y);
    }
}

void clfl_draw_push_clip(int x, int y, int width, int height)
{
    fl_push_clip(x, y, std::max(0, width), std::max(0, height));
}

void clfl_draw_pop_clip()
{
    fl_pop_clip();
}

}
