#include "cl_fltk_bridge.hpp"

#include <FL/Fl_Shared_Image.H>

using namespace clfl_bridge;

namespace {

struct LoadedImage {
    Fl_Shared_Image *image = nullptr;
    int width = 0;
    int height = 0;
};

std::unordered_map<widget_id, LoadedImage> g_images;
widget_id g_next_image_id = 1;
bool g_image_formats_registered = false;

LoadedImage *find_image(widget_id id)
{
    const auto found = g_images.find(id);
    return found == g_images.end() ? nullptr : &found->second;
}

} // namespace

extern "C" {

/// Loads the image file at PATH (PNG, JPEG, GIF, BMP or SVG, told apart by
/// content) and returns its handle, or 0 when it cannot be read.
widget_id clfl_image_load(const char *path)
{
    if (!path || !*path) {
        return 0;
    }
    if (!g_image_formats_registered) {
        fl_register_images();
        g_image_formats_registered = true;
    }
    Fl_Shared_Image *image = Fl_Shared_Image::get(path);
    if (!image || image->fail() || image->w() <= 0 || image->h() <= 0) {
        if (image) {
            image->release();
        }
        return 0;
    }
    const widget_id id = g_next_image_id++;
    g_images[id] = LoadedImage{image, image->data_w() > 0 ? image->data_w() : image->w(),
                               image->data_h() > 0 ? image->data_h() : image->h()};
    return id;
}

/// The image's own width in pixels, or 0 for an unknown handle.
int clfl_image_width(widget_id id)
{
    const LoadedImage *loaded = find_image(id);
    return loaded ? loaded->width : 0;
}

/// The image's own height in pixels, or 0 for an unknown handle.
int clfl_image_height(widget_id id)
{
    const LoadedImage *loaded = find_image(id);
    return loaded ? loaded->height : 0;
}

/// Draws the image with its top-left corner at X, Y, scaled to WIDTH by
/// HEIGHT units; a zero in either draws that side at the image's own size.
/// The pixels are kept at full resolution, so a scaled display stays sharp.
void clfl_image_draw(widget_id id, int x, int y, int width, int height)
{
    LoadedImage *loaded = find_image(id);
    if (!loaded || !loaded->image) {
        return;
    }
    const int draw_w = width > 0 ? width : loaded->width;
    const int draw_h = height > 0 ? height : loaded->height;
    loaded->image->scale(draw_w, draw_h, 0, 1);
    loaded->image->draw(x, y);
}

/// Releases the image; its handle means nothing afterwards.
void clfl_image_release(widget_id id)
{
    const auto found = g_images.find(id);
    if (found == g_images.end()) {
        return;
    }
    if (found->second.image) {
        found->second.image->release();
    }
    g_images.erase(found);
}

}
