#include "cl_fltk_bridge.hpp"

using namespace clfl_bridge;

namespace {

void configure_file_chooser_backend()
{
    // Use the desktop's own file dialog. FLTK tries zenity, then kdialog
    // under KDE, then in-process GTK, and only falls back to its built-in
    // browser when none of those works. The subprocess dialogs come first
    // deliberately: they are crash-isolated, where a GTK assertion failure
    // aborts the whole Lisp image. The SIGFPE these backends used to raise
    // under SBCL is handled by the Lisp wrappers, which mask floating
    // point traps around every modal dialog.
    Fl::option(Fl::OPTION_FNFC_USES_ZENITY, true);
    Fl::option(Fl::OPTION_FNFC_USES_KDIALOG, true);
    Fl::option(Fl::OPTION_FNFC_USES_GTK, true);
}

} // namespace

extern "C" {

int clfl_popup_menu(const char **items, int count)
{
    if (!items || count <= 0) {
        return -1;
    }
    std::vector<Fl_Menu_Item> entries;
    std::vector<int> original_indexes;
    entries.reserve(count + 1);
    for (int index = 0; index < count; ++index) {
        const char *label = items[index] ? items[index] : "";
        if (std::strcmp(label, "-") == 0) {
            if (!entries.empty()) {
                entries.back().flags |= FL_MENU_DIVIDER;
            }
            continue;
        }
        Fl_Menu_Item entry = {};
        entry.text = label;
        entry.labelsize_ = 12;
        entries.push_back(entry);
        original_indexes.push_back(index);
    }
    if (entries.empty()) {
        return -1;
    }
    Fl_Menu_Item terminator = {};
    entries.push_back(terminator);
    const Fl_Menu_Item *picked =
        entries.data()->popup(Fl::event_x(), Fl::event_y());
    if (!picked) {
        return -1;
    }
    const auto position = picked - entries.data();
    if (position < 0 ||
        position >= static_cast<long>(original_indexes.size())) {
        return -1;
    }
    return original_indexes[position];
}

char *clfl_input_dialog(const char *message, const char *initial)
{
    struct InputState {
        bool accepted;
        Fl_Window *window;
    };
    Fl_Window window(360, 108, "Input");
    Fl_Input input(12, 30, 336, 26,
                   message && *message ? message : "Value:");
    input.align(FL_ALIGN_TOP_LEFT);
    input.labelsize(12);
    input.textsize(12);
    input.value(initial ? initial : "");
    // Select the initial text so typing replaces it outright.
    input.insert_position(input.size(), 0);
    Fl_Return_Button ok(188, 70, 76, 26, "OK");
    Fl_Button cancel(272, 70, 76, 26, "Cancel");
    ok.labelsize(12);
    cancel.labelsize(12);
    window.end();
    InputState state{false, &window};
    ok.callback(
        [](Fl_Widget *, void *data) {
            auto *held = static_cast<InputState *>(data);
            held->accepted = true;
            held->window->hide();
        },
        &state);
    cancel.callback(
        [](Fl_Widget *, void *data) {
            static_cast<InputState *>(data)->window->hide();
        },
        &state);
    // Closing the window (or Escape) cancels.
    window.callback([](Fl_Widget *widget, void *) { widget->hide(); });
    window.set_modal();
    window.hotspot(&window);
    window.show();
    input.take_focus();
    while (window.shown()) {
        Fl::wait();
    }
    return copy_c_string(state.accepted ? input.value() : "");
}

int clfl_color_chooser(const char *title, double *red, double *green, double *blue)
{
    if (!red || !green || !blue) {
        return 0;
    }
    return fl_color_chooser(title && *title ? title : "Choose color",
                            *red,
                            *green,
                            *blue,
                            1);
}

char *clfl_choose_file(const char *title, const char *filter, const char *preset_file)
{
    configure_file_chooser_backend();
    Fl_Native_File_Chooser chooser(Fl_Native_File_Chooser::BROWSE_FILE);
    if (title && *title) {
        chooser.title(title);
    }
    if (filter && *filter) {
        chooser.filter(filter);
    }
    if (preset_file && *preset_file) {
        chooser.preset_file(preset_file);
    }

    const int result = chooser.show();
    if (result == 0 && chooser.filename()) {
        return copy_c_string(chooser.filename());
    }
    return copy_c_string("");
}

char *clfl_choose_files(const char *title, const char *filter, const char *preset_file)
{
    configure_file_chooser_backend();
    Fl_Native_File_Chooser chooser(Fl_Native_File_Chooser::BROWSE_MULTI_FILE);
    if (title && *title) {
        chooser.title(title);
    }
    if (filter && *filter) {
        chooser.filter(filter);
    }
    if (preset_file && *preset_file) {
        chooser.preset_file(preset_file);
    }

    const int result = chooser.show();
    if (result != 0) {
        return copy_c_string("");
    }
    std::string paths;
    for (int index = 0; index < chooser.count(); ++index) {
        const char *filename = chooser.filename(index);
        if (!filename || !*filename) {
            continue;
        }
        if (!paths.empty()) {
            paths.push_back('\n');
        }
        paths.append(filename);
    }
    return copy_c_string(paths.c_str());
}

char *clfl_choose_save_file(const char *title, const char *filter, const char *preset_file)
{
    configure_file_chooser_backend();
    Fl_Native_File_Chooser chooser(Fl_Native_File_Chooser::BROWSE_SAVE_FILE);
    if (title && *title) {
        chooser.title(title);
    }
    if (filter && *filter) {
        chooser.filter(filter);
    }
    if (preset_file && *preset_file) {
        chooser.preset_file(preset_file);
    }

    const int result = chooser.show();
    if (result == 0 && chooser.filename()) {
        return copy_c_string(chooser.filename());
    }
    return copy_c_string("");
}

char *clfl_choose_directory(const char *title, const char *preset_path)
{
    configure_file_chooser_backend();
    Fl_Native_File_Chooser chooser(Fl_Native_File_Chooser::BROWSE_DIRECTORY);
    if (title && *title) {
        chooser.title(title);
    }
    if (preset_path && *preset_path) {
        chooser.preset_file(preset_path);
    }

    const int result = chooser.show();
    if (result == 0 && chooser.filename()) {
        return copy_c_string(chooser.filename());
    }
    return copy_c_string("");
}

namespace {

/// Dresses FLTK's shared dialog icon in a stock picture: the question mark
/// of a choice, the "i" of a message, the "!" of an alert, drawn the way the
/// desktop drew them rather than as one bold character in a white square.
///
/// The stock icon is a fifty-pixel box carrying one character, which FLTK
/// re-labels and re-sizes on every call. The box goes flat and grey so
/// nothing frames the picture, the picture is set as the box's image, which
/// FLTK leaves alone, and the character is blanked for this one dialog —
/// `fl_message_icon_label` applies to the next call only, so it is asked
/// before each.
void dress_message_icon(const char *icon_name)
{
    if (Fl_Widget *icon = fl_message_icon()) {
        icon->box(FL_FLAT_BOX);
        icon->color(FL_BACKGROUND_COLOR);
        icon->align(FL_ALIGN_CENTER | FL_ALIGN_INSIDE);
        icon->image(stock_icon_pixmap(icon_name));
    }
    fl_message_icon_label("");
}

} // namespace

void clfl_message_box(const char *message)
{
    dress_message_icon("information");
    fl_message("%s", message ? message : "");
}

void clfl_alert_box(const char *message)
{
    dress_message_icon("exclamation");
    fl_alert("%s", message ? message : "");
}

int clfl_choice_box(const char *message,
                    const char *button0,
                    const char *button1,
                    const char *button2)
{
    dress_message_icon("question");
    return fl_choice("%s",
                     button0 && *button0 ? button0 : nullptr,
                     button1 && *button1 ? button1 : nullptr,
                     button2 && *button2 ? button2 : nullptr,
                     message ? message : "");
}

}
