#include "cl_fltk_bridge.hpp"

#include <FL/Fl_Image_Surface.H>

using namespace clfl_bridge;

extern "C" {

/// Render the window ID offscreen and write its pixels as a binary PPM file at
/// PATH. Returns 1 on success, 0 when the window is unknown or the file cannot
/// be written. The window must be shown so that FLTK has laid it out.
int clfl_window_capture_ppm(widget_id id, const char *path)
{
    auto *window = dynamic_cast<Fl_Window *>(find_widget(id));
    if (!window || !path || !*path || window->w() <= 0 || window->h() <= 0) {
        return 0;
    }
    Fl_Image_Surface surface(window->w(), window->h());
    surface.set_current();
    surface.draw(window);
    Fl_RGB_Image *image = surface.image();
    Fl_Display_Device::display_device()->set_current();
    if (!image) {
        return 0;
    }
    int result = 0;
    if (FILE *file = std::fopen(path, "wb")) {
        const int width = image->data_w();
        const int height = image->data_h();
        const int depth = image->d();
        const int stride = image->ld() ? image->ld() : width * depth;
        const auto *pixels = reinterpret_cast<const unsigned char *>(image->data()[0]);
        std::fprintf(file, "P6\n%d %d\n255\n", width, height);
        for (int y = 0; y < height; ++y) {
            for (int x = 0; x < width; ++x) {
                std::fwrite(pixels + y * stride + x * depth, 1, 3, file);
            }
        }
        result = std::ferror(file) ? 0 : 1;
        std::fclose(file);
    }
    delete image;
    return result;
}

}
