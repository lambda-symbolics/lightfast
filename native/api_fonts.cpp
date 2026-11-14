#include "cl_fltk_bridge.hpp"

#include <FL/platform.H>

// The font system under FLTK's text: CoreText on macOS, fontconfig and Pango
// everywhere else.
#ifdef __APPLE__
#include <CoreText/CoreText.h>
#include <climits>
#else
#include <fontconfig/fontconfig.h>
#include <pango/pangocairo.h>
#include <pango/pangofc-fontmap.h>
#endif

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

/// Font files registered by clfl_font_register_file, so that registering one
/// twice is harmless and a configuration built later still carries them.
std::vector<std::string> g_registered_font_files;

bool font_file_registered(const char *path)
{
    return std::find(g_registered_font_files.begin(), g_registered_font_files.end(), path)
        != g_registered_font_files.end();
}

#ifdef __APPLE__

std::string utf8_string(CFStringRef string)
{
    if (!string) {
        return "";
    }
    const CFIndex capacity =
        CFStringGetMaximumSizeForEncoding(CFStringGetLength(string), kCFStringEncodingUTF8) + 1;
    std::vector<char> buffer(static_cast<std::size_t>(capacity));
    if (!CFStringGetCString(string, buffer.data(), capacity, kCFStringEncodingUTF8)) {
        return "";
    }
    return buffer.data();
}

#else

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

/// Adds the font file at PATH to CONFIG as an application font; true when the
/// file brought at least one face. fontconfig reports success for a file it
/// could open and found no font in, so the faces are counted.
bool add_application_font(FcConfig *config, const char *path)
{
    const FcFontSet *before_set = FcConfigGetFonts(config, FcSetApplication);
    const int before = before_set ? before_set->nfont : 0;
    if (!FcConfigAppFontAddFile(config, reinterpret_cast<const FcChar8 *>(path))) {
        return false;
    }
    const FcFontSet *after_set = FcConfigGetFonts(config, FcSetApplication);
    return after_set && after_set->nfont > before;
}

#endif

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


#ifdef __APPLE__

/// The font files of FAMILY as lines of path, tab, style name.
char *clfl_font_files(const char *family)
{
    if (!family) {
        return copy_c_string("");
    }
    CFStringRef name = CFStringCreateWithCString(kCFAllocatorDefault, family, kCFStringEncodingUTF8);
    if (!name) {
        return copy_c_string("");
    }
    std::string lines;
    const void *keys[] = {kCTFontFamilyNameAttribute};
    const void *values[] = {name};
    CFDictionaryRef attributes = CFDictionaryCreate(kCFAllocatorDefault, keys, values, 1,
                                                    &kCFTypeDictionaryKeyCallBacks,
                                                    &kCFTypeDictionaryValueCallBacks);
    // The family is mandatory, or CoreText answers an unknown family with
    // whatever it would draw instead.
    CFSetRef mandatory = CFSetCreate(kCFAllocatorDefault, keys, 1, &kCFTypeSetCallBacks);
    CTFontDescriptorRef wanted = CTFontDescriptorCreateWithAttributes(attributes);
    CFArrayRef matches = CTFontDescriptorCreateMatchingFontDescriptors(wanted, mandatory);
    if (matches) {
        const CFIndex count = CFArrayGetCount(matches);
        for (CFIndex index = 0; index < count; ++index) {
            const auto descriptor =
                static_cast<CTFontDescriptorRef>(CFArrayGetValueAtIndex(matches, index));
            const auto url =
                static_cast<CFURLRef>(CTFontDescriptorCopyAttribute(descriptor, kCTFontURLAttribute));
            if (!url) {
                continue;
            }
            char path[PATH_MAX];
            if (CFURLGetFileSystemRepresentation(url, true, reinterpret_cast<UInt8 *>(path),
                                                 sizeof(path))) {
                const auto style = static_cast<CFStringRef>(
                    CTFontDescriptorCopyAttribute(descriptor, kCTFontStyleNameAttribute));
                lines += path;
                lines += '\t';
                lines += utf8_string(style);
                lines += '\n';
                if (style) {
                    CFRelease(style);
                }
            }
            CFRelease(url);
        }
        CFRelease(matches);
    }
    CFRelease(wanted);
    CFRelease(mandatory);
    CFRelease(attributes);
    CFRelease(name);
    return copy_c_string(lines.c_str());
}

/// Substituting corrected copies is the remedy for a fault of FLTK's Cairo
/// text driver. CoreText has no such fault and no such mechanism: always 0.
int clfl_font_substitute(const char *const *, int, const char *const *, int)
{
    return 0;
}

/// Makes the font file at PATH available to this process alone. Returns 1 when
/// CoreText accepted it or already had it from an earlier call, 0 otherwise.
int clfl_font_register_file(const char *path)
{
    if (!path || !*path) {
        return 0;
    }
    if (font_file_registered(path)) {
        return 1;
    }
    CFURLRef url = CFURLCreateFromFileSystemRepresentation(
        kCFAllocatorDefault, reinterpret_cast<const UInt8 *>(path),
        static_cast<CFIndex>(std::strlen(path)), false);
    if (!url) {
        return 0;
    }
    CFErrorRef error = nullptr;
    const bool registered = CTFontManagerRegisterFontsForURL(url, kCTFontManagerScopeProcess, &error);
    if (error) {
        CFRelease(error);
    }
    CFRelease(url);
    if (!registered) {
        return 0;
    }
    g_registered_font_files.emplace_back(path);
    return 1;
}

#else

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
    // The new configuration starts from the system's fonts alone: the files
    // registered so far go into it too, except those a corrected copy stands
    // in for.
    for (const std::string &file : g_registered_font_files) {
        bool replaced = false;
        for (int index = 0; index < rejected_count; ++index) {
            replaced = replaced || file == rejected[index];
        }
        if (!replaced) {
            FcConfigAppFontAddFile(config, reinterpret_cast<const FcChar8 *>(file.c_str()));
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

/// Makes the font file at PATH available to this process alone. Returns 1 when
/// fontconfig found a face in it or already had it from an earlier call, 0
/// otherwise. Pango is told to look again, so a face loaded from now on finds
/// the file; a face FLTK has already resolved keeps what it resolved to.
int clfl_font_register_file(const char *path)
{
    if (!path || !*path) {
        return 0;
    }
    if (font_file_registered(path)) {
        return 1;
    }
    FcConfig *current = FcConfigGetCurrent();
    if (!current || !add_application_font(current, path)) {
        return 0;
    }
    // After clfl_font_substitute Pango draws from that configuration rather
    // than the current one, so the file goes into both.
    if (g_font_config && g_font_config != current) {
        add_application_font(g_font_config, path);
    }
    PangoFontMap *map = pango_cairo_font_map_get_default();
    if (PANGO_IS_FC_FONT_MAP(map)) {
        pango_fc_font_map_config_changed(PANGO_FC_FONT_MAP(map));
    }
    g_registered_font_files.emplace_back(path);
    return 1;
}

#endif

}
