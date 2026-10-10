#include "cl_fltk_bridge.hpp"

#include <FL/platform.H>

#include <fontconfig/fontconfig.h>
#include <pango/pangocairo.h>
#include <pango/pangofc-fontmap.h>

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

/// The fontconfig configuration handed to Pango by clfl_font_substitute, kept
/// so a later call can release it.
FcConfig *g_font_config = nullptr;

std::string xml_escaped(const char *text)
{
    std::string out;
    for (const char *p = text; *p; ++p) {
        switch (*p) {
        case '&': out += "&amp;"; break;
        case '<': out += "&lt;"; break;
        case '>': out += "&gt;"; break;
        default: out += *p; break;
        }
    }
    return out;
}

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


char *clfl_font_files(const char *family)
{
    if (!family) {
        return copy_c_string("");
    }
    std::string lines;
    FcPattern *pattern = FcPatternCreate();
    FcPatternAddString(pattern, FC_FAMILY, reinterpret_cast<const FcChar8 *>(family));
    FcObjectSet *wanted = FcObjectSetBuild(FC_FILE, FC_STYLE, nullptr);
    FcFontSet *fonts = FcFontList(nullptr, pattern, wanted);
    if (fonts) {
        for (int index = 0; index < fonts->nfont; ++index) {
            FcChar8 *file = nullptr;
            FcChar8 *style = nullptr;
            if (FcPatternGetString(fonts->fonts[index], FC_FILE, 0, &file) != FcResultMatch) {
                continue;
            }
            FcPatternGetString(fonts->fonts[index], FC_STYLE, 0, &style);
            lines += reinterpret_cast<const char *>(file);
            lines += '\t';
            lines += style ? reinterpret_cast<const char *>(style) : "";
            lines += '\n';
        }
        FcFontSetDestroy(fonts);
    }
    FcObjectSetDestroy(wanted);
    FcPatternDestroy(pattern);
    return copy_c_string(lines.c_str());
}

int clfl_font_substitute(const char *const *files, int count, const char *const *rejected, int rejected_count)
{
    if (count < 0 || rejected_count < 0 || (count > 0 && !files) || (rejected_count > 0 && !rejected)) {
        return 0;
    }
    FcConfig *config = FcInitLoadConfig();
    if (!config) {
        return 0;
    }
    std::string xml = "<?xml version=\"1.0\"?><!DOCTYPE fontconfig SYSTEM \"fonts.dtd\">"
                      "<fontconfig><selectfont><rejectfont>";
    for (int index = 0; index < rejected_count; ++index) {
        xml += "<glob>" + xml_escaped(rejected[index]) + "</glob>";
    }
    xml += "</rejectfont></selectfont></fontconfig>";
    if (!FcConfigParseAndLoadFromMemory(config, reinterpret_cast<const FcChar8 *>(xml.c_str()), FcTrue)
        || !FcConfigBuildFonts(config)) {
        FcConfigDestroy(config);
        return 0;
    }
    for (int index = 0; index < count; ++index) {
        if (!FcConfigAppFontAddFile(config, reinterpret_cast<const FcChar8 *>(files[index]))) {
            FcConfigDestroy(config);
            return 0;
        }
    }
    PangoFontMap *map = pango_cairo_font_map_get_default();
    if (!PANGO_IS_FC_FONT_MAP(map)) {
        FcConfigDestroy(config);
        return 0;
    }
    pango_fc_font_map_set_config(PANGO_FC_FONT_MAP(map), config);
    if (g_font_config) {
        FcConfigDestroy(g_font_config);
    }
    g_font_config = config;
    g_first_free_font = -1;
    return 1;
}

}
