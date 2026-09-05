#pragma once

#include <FL/Fl.H>
#include <FL/Fl_Adjuster.H>
#include <FL/Fl_Box.H>
#include <FL/Fl_Browser.H>
#include <FL/Fl_Check_Browser.H>
#include <FL/Fl_Button.H>
#include <FL/Fl_Check_Button.H>
#include <FL/Fl_Choice.H>
#include <FL/Fl_Clock.H>
#include <FL/Fl_Color_Chooser.H>
#include <FL/Fl_Counter.H>
#include <FL/Fl_Dial.H>
#include <FL/Fl_Double_Window.H>
#include <FL/Fl_File_Browser.H>
#include <FL/Fl_File_Input.H>
#include <FL/Fl_Flex.H>
#include <FL/Fl_Grid.H>
#include <FL/Fl_Float_Input.H>
#include <FL/Fl_Group.H>
#include <FL/Fl_Help_View.H>
#include <FL/Fl_Hor_Value_Slider.H>
#include <FL/Fl_Hor_Slider.H>
#include <FL/Fl_Slider.H>
#include <FL/Fl_Input.H>
#include <FL/Fl_Input_Choice.H>
#include <FL/Fl_Int_Input.H>
#include <FL/Fl_Light_Button.H>
#include <FL/Fl_Menu_Bar.H>
#include <FL/Fl_Menu_Button.H>
#include <FL/Fl_Multiline_Input.H>
#include <FL/Fl_Multiline_Output.H>
#include <FL/Fl_Native_File_Chooser.H>
#include <FL/Fl_Output.H>
#include <FL/Fl_Pack.H>
#include <FL/Fl_Pixmap.H>
#include <FL/Fl_RGB_Image.H>
#include <FL/Fl_Positioner.H>
#include <FL/Fl_Radio_Round_Button.H>
#include <FL/Fl_Progress.H>
#include <FL/Fl_Repeat_Button.H>
#include <FL/Fl_Return_Button.H>
#include <FL/Fl_Roller.H>
#include <FL/Fl_Scroll.H>
#include <FL/Fl_Scrollbar.H>
#include <FL/Fl_Scheme_Choice.H>
#include <FL/Fl_Secret_Input.H>
#include <FL/Fl_Shortcut_Button.H>
#include <FL/Fl_Spinner.H>
#include <FL/Fl_Table_Row.H>
#include <FL/Fl_Tabs.H>
#include <FL/Fl_Terminal.H>
#include <FL/Fl_Text_Buffer.H>
#include <FL/Fl_Text_Display.H>
#include <FL/Fl_Text_Editor.H>
#include <FL/Fl_Tile.H>
#include <FL/Fl_Tree.H>
#include <FL/Fl_Valuator.H>
#include <FL/Fl_Value_Input.H>
#include <FL/Fl_Value_Output.H>
#include <FL/Fl_Wizard.H>
#include <FL/Fl_Chart.H>
#include <FL/fl_ask.H>
#include <FL/fl_draw.H>

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

namespace clfl_bridge {

using widget_id = long long;
using clfl_callback = void (*)(widget_id widget, int event, const char *value, widget_id token);

enum WidgetKind {
    WIDGET_WINDOW = 1,
    WIDGET_GROUP,
    WIDGET_BOX,
    WIDGET_BUTTON,
    WIDGET_INPUT,
    WIDGET_MULTILINE_INPUT,
    WIDGET_OUTPUT,
    WIDGET_MULTILINE_OUTPUT,
    WIDGET_CHOICE,
    WIDGET_BROWSER,
    WIDGET_MENU_BAR,
    WIDGET_CHECK_BUTTON,
    WIDGET_VALUE_INPUT,
    WIDGET_SCROLL,
    WIDGET_LABEL,
    WIDGET_TABS,
    WIDGET_TAB_PAGE,
    WIDGET_PROGRESS,
    WIDGET_SLIDER,
    WIDGET_STATUS_BAR,
    WIDGET_LIGHT_BUTTON,
    WIDGET_RADIO_BUTTON,
    WIDGET_COUNTER,
    WIDGET_SPINNER,
    WIDGET_DIAL,
    WIDGET_ROLLER,
    WIDGET_TREE,
    WIDGET_SECRET_INPUT,
    WIDGET_INT_INPUT,
    WIDGET_FLOAT_INPUT,
    WIDGET_TEXT_DISPLAY,
    WIDGET_TEXT_EDITOR,
    WIDGET_HELP_VIEW,
    WIDGET_CLOCK,
    WIDGET_TOGGLE_BUTTON,
    WIDGET_RETURN_BUTTON,
    WIDGET_REPEAT_BUTTON,
    WIDGET_VALUE_SLIDER,
    WIDGET_SCROLLBAR,
    WIDGET_ADJUSTER,
    WIDGET_TABLE,
    WIDGET_CANVAS,
    WIDGET_INPUT_CHOICE,
    WIDGET_CHECK_BROWSER,
    WIDGET_FILE_BROWSER,
    WIDGET_MENU_BUTTON,
    WIDGET_TILE,
    WIDGET_FLEX,
    WIDGET_VERTICAL_SLIDER,
    WIDGET_FILE_INPUT = 50,
    WIDGET_VALUE_OUTPUT,
    WIDGET_PACK,
    WIDGET_GRID,
    WIDGET_POSITIONER,
    WIDGET_WIZARD,
    WIDGET_CHART,
    WIDGET_SCHEME_CHOICE,
    WIDGET_TERMINAL,
    WIDGET_COLOR_CHOOSER,
    WIDGET_SHORTCUT_BUTTON
};

enum EventKind {
    EVENT_ACTIVATE = 1,
    EVENT_CHANGE,
    EVENT_CLOSE,
    EVENT_TIMER,
    EVENT_MENU,
    EVENT_RESIZE,
    EVENT_DRAW,
    EVENT_PUSH,
    EVENT_DRAG,
    EVENT_RELEASE,
    EVENT_WHEEL,
    EVENT_KEY
};

struct CallbackSlot {
    clfl_callback callback = nullptr;
    widget_id token = 0;
};

struct Entry {
    Fl_Widget *widget = nullptr;
    int kind = 0;
    std::unordered_map<int, CallbackSlot> callbacks;
    std::vector<int> browser_column_widths;
    int default_event = EVENT_ACTIVATE;
};

void dispatch_resize_callback(Fl_Widget *widget);
void dispatch_draw_callback(Fl_Widget *widget);
bool dispatch_input_callback(Fl_Widget *widget, int event, const std::string &value);
std::string key_event_value();
std::string mouse_event_value(Fl_Widget *widget);
void timer_dispatch_callback(void *data);
void clear_timers();
void finish_window_close(Fl_Widget *widget);

struct MenuCallback {
    widget_id widget = 0;
    clfl_callback callback = nullptr;
    widget_id token = 0;
    std::string path;
};

struct TimerEntry {
    widget_id id = 0;
    double interval = 0.0;
    int repeat = 0;
    clfl_callback callback = nullptr;
    widget_id token = 0;
};

extern widget_id g_next_id;
extern widget_id g_next_timer_id;
extern std::unordered_map<widget_id, Entry> g_widgets;
extern std::unordered_map<Fl_Widget *, widget_id> g_widget_ids;
extern std::unordered_map<widget_id, std::unique_ptr<TimerEntry>> g_timers;
extern std::vector<std::unique_ptr<MenuCallback>> g_menu_callbacks;
extern bool g_quit_requested;
/// Set by clfl_window_cancel_close from inside a close callback: the window stays.
extern bool g_window_close_cancelled;
/// Title text owned on behalf of each window: Fl_Window::label() keeps the
/// pointer it is given rather than a copy, and it is that call, not
/// copy_label(), that reaches the window manager.
extern std::unordered_map<Fl_Widget *, std::string> g_window_titles;
extern int g_window_close_callback_depth;
extern int g_programmatic_resize_depth;
extern Fl_Tile *g_active_tile_drag;

char *copy_c_string(const char *value);
/// Whether Escape closes WIDGET, when it is one of our windows; returns false
/// for anything else.
bool set_window_escape_closes(Fl_Widget *widget, bool enabled);
Entry *find_entry(widget_id id);
Fl_Widget *find_widget(widget_id id);
Fl_Group *find_group(widget_id id);
widget_id register_widget(int kind, Fl_Widget *widget);
void unregister_widget_tree(Fl_Widget *widget);

void apply_scrollbar_style(Fl_Scrollbar *scrollbar);
void apply_scrollbar_styles(Fl_Widget *widget);
void apply_common_style(Fl_Widget *widget);
void apply_inset_style(Fl_Widget *widget);
void apply_button_style(Fl_Button *button);
std::string widget_value_string(Fl_Widget *widget);
std::string widget_callback_value_string(Fl_Widget *widget);
void set_choice_value(Fl_Choice *choice, const char *value);
void set_widget_value(Fl_Widget *widget, const char *value);
void set_widget_stock_icon(widget_id id, const char *name);
/// The stock icon NAME, or null when there is none of that name.
Fl_Pixmap *stock_icon_pixmap(const char *name);
void set_widget_text_size(widget_id id, int size);
void set_widget_text_font(widget_id id, int font);
void clear_widget_contents(widget_id id);

Fl_Widget *create_classic_table(int x, int y, int w, int h, const char *label);
bool classic_table_value_string(Fl_Widget *widget, std::string *out);
bool classic_table_callback_value_string(Fl_Widget *widget, std::string *out);
bool classic_table_set_value(Fl_Widget *widget, const char *value);
bool classic_table_clear(Fl_Widget *widget);
bool classic_value_input_set_text_size(Fl_Widget *widget, int size);
bool classic_value_input_set_text_font(Fl_Widget *widget, int font);
void table_resize_data(widget_id id, int rows, int columns);
void table_set_column_label(widget_id id, int column, const char *label);
void table_set_column_width(widget_id id, int column, int width);
void table_set_cell(widget_id id, int row, int column, const char *value);
char *table_get_cell(widget_id id, int row, int column);
int table_selected_row(widget_id id);
char *table_selected_rows(widget_id id);
void table_select_row(widget_id id, int row);
int table_column_width(widget_id id, int column);

void dispatch_callback(Fl_Widget *widget, void *data);
void menu_dispatch_callback(Fl_Widget *widget, void *data);
void timer_dispatch_callback(void *data);
void window_event_callback(Fl_Widget *widget, void *data);
Fl_Widget *create_widget(int kind, int x, int y, int w, int h, const char *label);
void request_quit();

} // namespace clfl_bridge
