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

/// Draws the stock icon NAME with its top-left corner at X, Y; nothing for a
/// name there is no icon for.
void clfl_draw_stock_icon(const char *name, int x, int y)
{
    if (Fl_Pixmap *icon = stock_icon_pixmap(name)) {
        icon->draw(x, y);
    }
}

/// Sets the width of the lines drawn next, in FLTK units, and whether they
/// are dashed. Zero restores FLTK's default hairline.
void clfl_draw_set_line_style(int width, int dashed)
{
    fl_line_style(dashed ? FL_DASH : FL_SOLID, std::max(0, width));
}

/// Draws the closed outline through COUNT points, given as X0 Y0 X1 Y1 and so
/// on, or fills it when FILLED. Three and four points go to FLTK's convex
/// primitives; more are drawn as a general complex polygon.
void clfl_draw_polygon(const int *points, int count, int filled)
{
    if (!points || count < 2) {
        return;
    }
    if (filled) {
        fl_begin_complex_polygon();
    } else {
        fl_begin_loop();
    }
    for (int index = 0; index < count; ++index) {
        fl_vertex(points[index * 2], points[index * 2 + 1]);
    }
    if (filled) {
        fl_end_complex_polygon();
    } else {
        fl_end_loop();
    }
}

/// Draws TEXT rotated ANGLE degrees counterclockwise about its baseline start.
void clfl_draw_text_rotated(const char *text, int angle, int x, int y)
{
    fl_draw(angle, text ? text : "", x, y);
}

/// Reports the box FLTK is drawing into: the part of X, Y, WIDTH, HEIGHT that
/// the current clip leaves. Returns 1 when anything of it is left.
int clfl_draw_clip_box(int x, int y, int width, int height, int *clip_x, int *clip_y, int *clip_w, int *clip_h)
{
    int cx = x;
    int cy = y;
    int cw = width;
    int ch = height;
    fl_clip_box(x, y, width, height, cx, cy, cw, ch);
    if (clip_x) {
        *clip_x = cx;
    }
    if (clip_y) {
        *clip_y = cy;
    }
    if (clip_w) {
        *clip_w = cw;
    }
    if (clip_h) {
        *clip_h = ch;
    }
    return (cw > 0 && ch > 0) ? 1 : 0;
}

} // extern "C"

namespace {

struct DitherTile {
    std::vector<unsigned char> pixels;
    std::unique_ptr<Fl_RGB_Image> image;
    int span = 0;
};

std::unordered_map<unsigned long long, DitherTile> g_dither_tiles;

/// How many device pixels one FLTK unit covers in the window being drawn,
/// rounded up, so a dot stays a crisp square on a scaled display. FLTK does
/// not report a Retina backing store, which every current Mac display has,
/// so macOS doubles the factor; a plain display there averages the dots down.
int drawing_pixel_factor()
{
    Fl_Window *window = Fl_Window::current();
    const float scale = window ? Fl::screen_scale(window->screen_num()) : 1.0f;
    int factor = std::clamp(static_cast<int>(std::ceil(scale - 0.01f)), 1, 4);
#ifdef __APPLE__
    factor *= 2;
#endif
    return factor;
}

DitherTile &dither_tile(int step, int factor, unsigned char red, unsigned char green, unsigned char blue)
{
    const unsigned long long key = (static_cast<unsigned long long>(step) << 40) |
                                   (static_cast<unsigned long long>(factor) << 32) |
                                   (static_cast<unsigned long long>(red) << 16) |
                                   (static_cast<unsigned long long>(green) << 8) |
                                   static_cast<unsigned long long>(blue);
    auto found = g_dither_tiles.find(key);
    if (found != g_dither_tiles.end()) {
        return found->second;
    }
    DitherTile tile;
    const int cells = std::max(1, 96 / step);
    tile.span = cells * step;
    const int side = tile.span * factor;
    tile.pixels.assign(static_cast<size_t>(side) * side * 4, 0);
    for (int row = 0; row < cells; ++row) {
        for (int column = 0; column < cells; ++column) {
            for (int dy = 0; dy < factor; ++dy) {
                for (int dx = 0; dx < factor; ++dx) {
                    const size_t offset =
                        (static_cast<size_t>(row * step * factor + dy) * side + (column * step * factor + dx)) * 4;
                    tile.pixels[offset] = red;
                    tile.pixels[offset + 1] = green;
                    tile.pixels[offset + 2] = blue;
                    tile.pixels[offset + 3] = 255;
                }
            }
        }
    }
    tile.image = std::make_unique<Fl_RGB_Image>(tile.pixels.data(), side, side, 4);
    tile.image->scale(tile.span, tile.span, 0, 1);
    return g_dither_tiles.emplace(key, std::move(tile)).first->second;
}

} // namespace

extern "C" {

/// Fills X, Y, WIDTH, HEIGHT with a one-bit dither in the current color: one
/// unit dot every STEP units, on a grid fixed to the window so neighbouring
/// fills line up. The dots are opaque and the ground shows between them.
void clfl_draw_dither(int x, int y, int width, int height, int step, int red, int green, int blue)
{
    if (width <= 0 || height <= 0) {
        return;
    }
    step = std::clamp(step, 2, 16);
    DitherTile &tile = dither_tile(step,
                                   drawing_pixel_factor(),
                                   static_cast<unsigned char>(std::clamp(red, 0, 255)),
                                   static_cast<unsigned char>(std::clamp(green, 0, 255)),
                                   static_cast<unsigned char>(std::clamp(blue, 0, 255)));
    fl_push_clip(x, y, width, height);
    const int first_x = x - (((x % step) + step) % step);
    const int first_y = y - (((y % step) + step) % step);
    for (int tile_y = first_y; tile_y < y + height; tile_y += tile.span) {
        for (int tile_x = first_x; tile_x < x + width; tile_x += tile.span) {
            if (fl_not_clipped(tile_x, tile_y, tile.span, tile.span)) {
                tile.image->draw(tile_x, tile_y);
            }
        }
    }
    fl_pop_clip();
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
