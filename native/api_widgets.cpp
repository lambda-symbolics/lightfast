#include "cl_fltk_bridge.hpp"

#include <sstream>

using namespace clfl_bridge;

namespace {

Entry *entry_of_kind(widget_id id, int kind)
{
    Entry *entry = find_entry(id);
    return entry && entry->kind == kind ? entry : nullptr;
}

template <typename T>
T *widget_of_kind(widget_id id, int kind)
{
    Entry *entry = entry_of_kind(id, kind);
    return entry ? dynamic_cast<T *>(entry->widget) : nullptr;
}

Fl_Grid_Align grid_alignment(int alignment)
{
    switch (alignment) {
    case 0: return FL_GRID_FILL;
    case 1: return FL_GRID_CENTER;
    case 2: return FL_GRID_LEFT;
    case 3: return FL_GRID_RIGHT;
    case 4: return FL_GRID_TOP;
    case 5: return FL_GRID_BOTTOM;
    case 6: return FL_GRID_TOP_LEFT;
    case 7: return FL_GRID_TOP_RIGHT;
    case 8: return FL_GRID_BOTTOM_LEFT;
    case 9: return FL_GRID_BOTTOM_RIGHT;
    case 10: return FL_GRID_PROPORTIONAL;
    default: return FL_GRID_FILL;
    }
}

} // namespace

extern "C" {

int clfl_pack_set_orientation(widget_id id, int horizontal)
{
    auto *pack = widget_of_kind<Fl_Pack>(id, WIDGET_PACK);
    if (!pack || (horizontal != 0 && horizontal != 1)) return 0;
    pack->type(horizontal ? Fl_Pack::HORIZONTAL : Fl_Pack::VERTICAL);
    pack->redraw();
    return 1;
}

int clfl_pack_set_spacing(widget_id id, int spacing)
{
    auto *pack = widget_of_kind<Fl_Pack>(id, WIDGET_PACK);
    if (!pack || spacing < 0) return 0;
    pack->spacing(spacing);
    pack->redraw();
    return 1;
}

int clfl_grid_layout(widget_id id, int rows, int columns, int margin,
                     int row_gap, int column_gap)
{
    auto *grid = widget_of_kind<Fl_Grid>(id, WIDGET_GRID);
    if (!grid || rows <= 0 || columns <= 0 || margin < 0 ||
        row_gap < 0 || column_gap < 0) return 0;
    grid->layout(rows, columns, margin, 0);
    grid->gap(row_gap, column_gap);
    grid->layout();
    grid->redraw();
    return 1;
}

int clfl_grid_place(widget_id id, widget_id child_id, int row, int column,
                    int row_span, int column_span, int alignment)
{
    auto *grid = widget_of_kind<Fl_Grid>(id, WIDGET_GRID);
    Fl_Widget *child = find_widget(child_id);
    if (!grid || !child || child->parent() != grid || row < 0 || column < 0 ||
        row_span <= 0 || column_span <= 0 || alignment < 0 || alignment > 10)
        return 0;
    if (!grid->widget(child, row, column, row_span, column_span,
                      grid_alignment(alignment))) return 0;
    grid->layout();
    grid->redraw();
    return 1;
}

int clfl_grid_set_row_height(widget_id id, int row, int height)
{
    auto *grid = widget_of_kind<Fl_Grid>(id, WIDGET_GRID);
    if (!grid || row < 0 || row >= grid->rows() || height < 0) return 0;
    grid->row_height(row, height);
    grid->layout();
    return 1;
}

int clfl_grid_set_row_weight(widget_id id, int row, int weight)
{
    auto *grid = widget_of_kind<Fl_Grid>(id, WIDGET_GRID);
    if (!grid || row < 0 || row >= grid->rows() || weight < 0) return 0;
    grid->row_weight(row, weight);
    grid->layout();
    return 1;
}

int clfl_grid_set_column_width(widget_id id, int column, int width)
{
    auto *grid = widget_of_kind<Fl_Grid>(id, WIDGET_GRID);
    if (!grid || column < 0 || column >= grid->cols() || width < 0) return 0;
    grid->col_width(column, width);
    grid->layout();
    return 1;
}

int clfl_grid_set_column_weight(widget_id id, int column, int weight)
{
    auto *grid = widget_of_kind<Fl_Grid>(id, WIDGET_GRID);
    if (!grid || column < 0 || column >= grid->cols() || weight < 0) return 0;
    grid->col_weight(column, weight);
    grid->layout();
    return 1;
}

int clfl_positioner_set_value(widget_id id, double x, double y)
{
    auto *positioner = widget_of_kind<Fl_Positioner>(id, WIDGET_POSITIONER);
    if (!positioner || !std::isfinite(x) || !std::isfinite(y)) return 0;
    positioner->value(x, y);
    positioner->redraw();
    return 1;
}

int clfl_positioner_get_value(widget_id id, double *x, double *y)
{
    auto *positioner = widget_of_kind<Fl_Positioner>(id, WIDGET_POSITIONER);
    if (!positioner || !x || !y) return 0;
    *x = positioner->xvalue();
    *y = positioner->yvalue();
    return 1;
}

int clfl_positioner_set_bounds(widget_id id, double x_minimum, double x_maximum,
                               double y_minimum, double y_maximum)
{
    auto *positioner = widget_of_kind<Fl_Positioner>(id, WIDGET_POSITIONER);
    if (!positioner || !std::isfinite(x_minimum) || !std::isfinite(x_maximum) ||
        !std::isfinite(y_minimum) || !std::isfinite(y_maximum) ||
        x_minimum > x_maximum || y_minimum > y_maximum) return 0;
    positioner->xbounds(x_minimum, x_maximum);
    positioner->ybounds(y_minimum, y_maximum);
    positioner->redraw();
    return 1;
}

int clfl_positioner_set_steps(widget_id id, double x_step, double y_step)
{
    auto *positioner = widget_of_kind<Fl_Positioner>(id, WIDGET_POSITIONER);
    if (!positioner || !std::isfinite(x_step) || !std::isfinite(y_step) ||
        x_step < 0.0 || y_step < 0.0) return 0;
    positioner->xstep(x_step);
    positioner->ystep(y_step);
    return 1;
}

int clfl_wizard_next(widget_id id)
{
    auto *wizard = widget_of_kind<Fl_Wizard>(id, WIDGET_WIZARD);
    if (!wizard) return 0;
    wizard->next();
    return 1;
}

int clfl_wizard_previous(widget_id id)
{
    auto *wizard = widget_of_kind<Fl_Wizard>(id, WIDGET_WIZARD);
    if (!wizard) return 0;
    wizard->prev();
    return 1;
}

widget_id clfl_wizard_current(widget_id id)
{
    auto *wizard = widget_of_kind<Fl_Wizard>(id, WIDGET_WIZARD);
    Fl_Widget *child = wizard ? wizard->value() : nullptr;
    auto found = child ? g_widget_ids.find(child) : g_widget_ids.end();
    return found == g_widget_ids.end() ? 0 : found->second;
}

int clfl_wizard_set_current(widget_id id, widget_id child_id)
{
    auto *wizard = widget_of_kind<Fl_Wizard>(id, WIDGET_WIZARD);
    Fl_Widget *child = find_widget(child_id);
    if (!wizard || !child || child->parent() != wizard) return 0;
    wizard->value(child);
    return 1;
}

int clfl_chart_add(widget_id id, double value, const char *label, unsigned color)
{
    auto *chart = widget_of_kind<Fl_Chart>(id, WIDGET_CHART);
    if (!chart || !std::isfinite(value)) return 0;
    chart->add(value, label ? label : "", color);
    chart->redraw();
    return 1;
}

int clfl_chart_insert(widget_id id, int index, double value,
                      const char *label, unsigned color)
{
    auto *chart = widget_of_kind<Fl_Chart>(id, WIDGET_CHART);
    if (!chart || index < 0 || index > chart->size() || !std::isfinite(value)) return 0;
    chart->insert(index + 1, value, label ? label : "", color);
    chart->redraw();
    return 1;
}

int clfl_chart_replace(widget_id id, int index, double value,
                       const char *label, unsigned color)
{
    auto *chart = widget_of_kind<Fl_Chart>(id, WIDGET_CHART);
    if (!chart || index < 0 || index >= chart->size() || !std::isfinite(value)) return 0;
    chart->replace(index + 1, value, label ? label : "", color);
    chart->redraw();
    return 1;
}

int clfl_chart_clear(widget_id id)
{
    auto *chart = widget_of_kind<Fl_Chart>(id, WIDGET_CHART);
    if (!chart) return 0;
    chart->clear();
    chart->redraw();
    return 1;
}

int clfl_chart_set_bounds(widget_id id, double minimum, double maximum)
{
    auto *chart = widget_of_kind<Fl_Chart>(id, WIDGET_CHART);
    if (!chart || !std::isfinite(minimum) || !std::isfinite(maximum) ||
        minimum > maximum) return 0;
    chart->bounds(minimum, maximum);
    chart->redraw();
    return 1;
}

int clfl_chart_set_type(widget_id id, int type)
{
    auto *chart = widget_of_kind<Fl_Chart>(id, WIDGET_CHART);
    if (!chart || type < FL_BAR_CHART || type > FL_SPECIALPIE_CHART) return 0;
    chart->type(static_cast<uchar>(type));
    chart->redraw();
    return 1;
}

int clfl_terminal_append(widget_id id, const char *text)
{
    Entry *entry = entry_of_kind(id, WIDGET_TERMINAL);
    auto *terminal = entry ? dynamic_cast<Fl_Terminal *>(entry->widget) : nullptr;
    if (!terminal || !text) return 0;
    terminal->append(text);
    return 1;
}

int clfl_terminal_clear(widget_id id)
{
    Entry *entry = entry_of_kind(id, WIDGET_TERMINAL);
    auto *terminal = entry ? dynamic_cast<Fl_Terminal *>(entry->widget) : nullptr;
    if (!terminal) return 0;
    terminal->reset_terminal();
    terminal->clear_history();
    terminal->clear_screen_home(false);
    return 1;
}

char *clfl_terminal_text(widget_id id)
{
    auto *terminal = widget_of_kind<Fl_Terminal>(id, WIDGET_TERMINAL);
    return copy_c_string(terminal ? terminal->text() : "");
}

int clfl_color_chooser_set_rgb(widget_id id, double red, double green, double blue)
{
    auto *chooser = widget_of_kind<Fl_Color_Chooser>(id, WIDGET_COLOR_CHOOSER);
    if (!chooser || !std::isfinite(red) || !std::isfinite(green) ||
        !std::isfinite(blue) || red < 0.0 || red > 1.0 || green < 0.0 ||
        green > 1.0 || blue < 0.0 || blue > 1.0) return 0;
    chooser->rgb(red, green, blue);
    chooser->redraw();
    return 1;
}

int clfl_color_chooser_get_rgb(widget_id id, double *red, double *green, double *blue)
{
    auto *chooser = widget_of_kind<Fl_Color_Chooser>(id, WIDGET_COLOR_CHOOSER);
    if (!chooser || !red || !green || !blue) return 0;
    *red = chooser->r();
    *green = chooser->g();
    *blue = chooser->b();
    return 1;
}

int clfl_shortcut_button_set_shortcut(widget_id id, unsigned shortcut)
{
    auto *button = widget_of_kind<Fl_Shortcut_Button>(id, WIDGET_SHORTCUT_BUTTON);
    if (!button) return 0;
    button->value(static_cast<Fl_Shortcut>(shortcut));
    button->redraw();
    return 1;
}

unsigned clfl_shortcut_button_get_shortcut(widget_id id)
{
    auto *button = widget_of_kind<Fl_Shortcut_Button>(id, WIDGET_SHORTCUT_BUTTON);
    return button ? static_cast<unsigned>(button->value()) : 0U;
}

int clfl_browser_set_selection_mode(widget_id id, int mode)
{
    auto *browser = widget_of_kind<Fl_Browser>(id, WIDGET_BROWSER);
    if (!browser || mode < 0 || mode > 3) return 0;
    browser->type(static_cast<uchar>(mode));
    browser->redraw();
    return 1;
}

int clfl_browser_set_selected(widget_id id, int index, int selected)
{
    auto *browser = widget_of_kind<Fl_Browser>(id, WIDGET_BROWSER);
    if (!browser || index < 0 || index >= browser->size()) return 0;
    browser->select(index + 1, selected ? 1 : 0);
    return 1;
}

char *clfl_browser_selected_indices(widget_id id)
{
    auto *browser = widget_of_kind<Fl_Browser>(id, WIDGET_BROWSER);
    if (!browser) return copy_c_string("");
    std::ostringstream result;
    bool first = true;
    for (int index = 1; index <= browser->size(); ++index) {
        if (browser->selected(index)) {
            if (!first) result << ',';
            result << (index - 1);
            first = false;
        }
    }
    return copy_c_string(result.str().c_str());
}

} // extern "C"
