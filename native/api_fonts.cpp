#include "cl_fltk_bridge.hpp"

#include <FL/platform.H>

#include <deque>

using namespace clfl_bridge;

namespace {

/// Names handed to Fl::set_font, which keeps the pointer rather than a copy.
/// A deque never moves its elements, so the pointers stay valid.
std::deque<std::string> g_loaded_font_names;

/// The first font index free for loading: past FLTK's built-in faces and
/// past whatever Fl::set_fonts enumerated, which fills the table from
/// FL_FREE_FONT upward and would otherwise overwrite a loaded face.
int g_first_free_font = -1;

void prepare_font_table()
{
    if (g_first_free_font >= 0) {
        return;
    }
    fl_open_display();
    const int enumerated = Fl::set_fonts("*");
    g_first_free_font = std::max<int>(FL_FREE_FONT, enumerated);
}

} // namespace

extern "C" {

int clfl_font_load(const char *name)
{
    if (!name || !*name) {
        return -1;
    }
    prepare_font_table();
    for (std::size_t index = 0; index < g_loaded_font_names.size(); ++index) {
        if (g_loaded_font_names[index] == name) {
            return g_first_free_font + static_cast<int>(index);
        }
    }
    g_loaded_font_names.emplace_back(name);
    const int font = g_first_free_font + static_cast<int>(g_loaded_font_names.size()) - 1;
    Fl::set_font(static_cast<Fl_Font>(font), g_loaded_font_names.back().c_str());
    return font;
}

char *clfl_font_name(int font)
{
    if (font < 0) {
        return copy_c_string("");
    }
    prepare_font_table();
    const char *name = Fl::get_font(static_cast<Fl_Font>(font));
    return copy_c_string(name ? name : "");
}

char *clfl_font_system_names()
{
    prepare_font_table();
    std::string names;
    for (int font = FL_FREE_FONT; font < g_first_free_font; ++font) {
        int attributes = 0;
        const char *name = Fl::get_font_name(static_cast<Fl_Font>(font), &attributes);
        if (!name || !*name) {
            continue;
        }
        names += name;
        names += '\t';
        names += std::to_string(attributes);
        names += '\n';
    }
    return copy_c_string(names.c_str());
}

int clfl_font_measure(int font, int size, const char *text, int *width, int *height, int *descent)
{
    if (font < 0 || size <= 0 || !text) {
        return 0;
    }
    prepare_font_table();
    fl_font(static_cast<Fl_Font>(font), size);
    if (width) {
        *width = static_cast<int>(std::ceil(fl_width(text)));
    }
    if (height) {
        *height = fl_height();
    }
    if (descent) {
        *descent = fl_descent();
    }
    return 1;
}

}
