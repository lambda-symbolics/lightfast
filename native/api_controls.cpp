#include "cl_fltk_bridge.hpp"

using namespace clfl_bridge;

extern "C" {

void clfl_widget_set_range(widget_id id, double minimum, double maximum)
{
    if (auto *valuator = dynamic_cast<Fl_Valuator *>(find_widget(id))) {
        auto *entry = find_entry(id);
        if (entry && entry->kind == WIDGET_VERTICAL_SLIDER) {
            valuator->bounds(maximum, minimum);
        } else {
            valuator->bounds(minimum, maximum);
        }
    } else if (auto *spinner = dynamic_cast<Fl_Spinner *>(find_widget(id))) {
        spinner->range(minimum, maximum);
    } else if (auto *progress = dynamic_cast<Fl_Progress *>(find_widget(id))) {
        progress->minimum(minimum);
        progress->maximum(maximum);
    }
}

void clfl_widget_set_step(widget_id id, double step)
{
    if (auto *value_input = dynamic_cast<Fl_Value_Input *>(find_widget(id))) {
        value_input->step(step);
    } else if (auto *counter = dynamic_cast<Fl_Counter *>(find_widget(id))) {
        counter->step(step);
    } else if (auto *spinner = dynamic_cast<Fl_Spinner *>(find_widget(id))) {
        spinner->step(step);
    } else if (auto *valuator = dynamic_cast<Fl_Valuator *>(find_widget(id))) {
        valuator->step(step);
    }
}

void clfl_choice_add(widget_id id, const char *label)
{
    if (auto *choice = dynamic_cast<Fl_Choice *>(find_widget(id))) {
        choice->add(label ? label : "");
        if (choice->value() < 0 && choice->size() > 0) {
            choice->value(0);
        }
    } else if (auto *input_choice = dynamic_cast<Fl_Input_Choice *>(find_widget(id))) {
        input_choice->add(label ? label : "");
        if (!input_choice->value() || !*input_choice->value()) {
            input_choice->value(0);
        }
    }
}

void clfl_browser_add(widget_id id, const char *label)
{
    if (auto *browser = dynamic_cast<Fl_Browser *>(find_widget(id))) {
        browser->add(label ? label : "");
    }
}

void clfl_browser_set_column_widths(widget_id id, const int *widths, int count)
{
    Entry *entry = find_entry(id);
    auto *browser = entry ? dynamic_cast<Fl_Browser *>(entry->widget) : nullptr;
    if (!browser) {
        return;
    }

    entry->browser_column_widths.clear();
    for (int index = 0; widths && index < count; ++index) {
        entry->browser_column_widths.push_back(std::max(1, widths[index]));
    }
    entry->browser_column_widths.push_back(0);

    browser->column_char('\t');
    browser->column_widths(entry->browser_column_widths.data());
    browser->redraw();
}

void clfl_tree_add(widget_id id, const char *path)
{
    if (auto *tree = dynamic_cast<Fl_Tree *>(find_widget(id))) {
        if (path && *path) {
            tree->add(path);
            tree->redraw();
        }
    }
}

void clfl_browser_select(widget_id id, int index)
{
    if (auto *browser = dynamic_cast<Fl_Browser *>(find_widget(id))) {
        if (index < 0) {
            browser->deselect();
        } else {
            browser->select(index + 1);
            browser->middleline(index + 1);
        }
    }
}

void clfl_check_browser_add(widget_id id, const char *label, int checked)
{
    if (auto *browser = dynamic_cast<Fl_Check_Browser *>(find_widget(id))) {
        browser->add(label ? label : "", checked ? 1 : 0);
    }
}

int clfl_check_browser_count(widget_id id)
{
    if (auto *browser = dynamic_cast<Fl_Check_Browser *>(find_widget(id))) {
        return browser->nitems();
    }
    return 0;
}

int clfl_check_browser_checked_count(widget_id id)
{
    if (auto *browser = dynamic_cast<Fl_Check_Browser *>(find_widget(id))) {
        return browser->nchecked();
    }
    return 0;
}

int clfl_check_browser_checked(widget_id id, int index)
{
    if (auto *browser = dynamic_cast<Fl_Check_Browser *>(find_widget(id))) {
        return browser->checked(index + 1) ? 1 : 0;
    }
    return 0;
}

void clfl_check_browser_set_checked(widget_id id, int index, int checked)
{
    if (auto *browser = dynamic_cast<Fl_Check_Browser *>(find_widget(id))) {
        browser->checked(index + 1, checked ? 1 : 0);
        browser->redraw();
    }
}

void clfl_check_browser_check_all(widget_id id)
{
    if (auto *browser = dynamic_cast<Fl_Check_Browser *>(find_widget(id))) {
        browser->check_all();
        browser->redraw();
    }
}

void clfl_check_browser_check_none(widget_id id)
{
    if (auto *browser = dynamic_cast<Fl_Check_Browser *>(find_widget(id))) {
        browser->check_none();
        browser->redraw();
    }
}

char *clfl_check_browser_text(widget_id id, int index)
{
    if (auto *browser = dynamic_cast<Fl_Check_Browser *>(find_widget(id))) {
        return copy_c_string(browser->text(index + 1));
    }
    return copy_c_string("");
}

int clfl_file_browser_load(widget_id id, const char *directory)
{
    if (auto *browser = dynamic_cast<Fl_File_Browser *>(find_widget(id))) {
        return browser->load(directory && *directory ? directory : ".");
    }
    return 0;
}

void clfl_file_browser_set_filter(widget_id id, const char *pattern)
{
    if (auto *browser = dynamic_cast<Fl_File_Browser *>(find_widget(id))) {
        browser->filter(pattern && *pattern ? pattern : nullptr);
    }
}

void clfl_file_browser_set_filetype(widget_id id, int filetype)
{
    if (auto *browser = dynamic_cast<Fl_File_Browser *>(find_widget(id))) {
        browser->filetype(filetype ? Fl_File_Browser::DIRECTORIES : Fl_File_Browser::FILES);
        browser->redraw();
    }
}

void clfl_menu_button_set_popup(widget_id id, int buttons)
{
    if (auto *menu = dynamic_cast<Fl_Menu_Button *>(find_widget(id))) {
        menu->type(std::clamp(buttons, 0, static_cast<int>(Fl_Menu_Button::POPUP123)));
    }
}

void clfl_tile_size_range(widget_id id,
                          widget_id child_id,
                          int min_width,
                          int min_height,
                          int max_width,
                          int max_height)
{
    auto *tile = dynamic_cast<Fl_Tile *>(find_widget(id));
    Fl_Widget *child = find_widget(child_id);
    if (tile && child) {
        tile->size_range(child,
                         std::max(0, min_width),
                         std::max(0, min_height),
                         max_width > 0 ? max_width : 0x7fffffff,
                         max_height > 0 ? max_height : 0x7fffffff);
    }
}

void clfl_group_init_sizes(widget_id id)
{
    if (auto *group = dynamic_cast<Fl_Group *>(find_widget(id))) {
        group->init_sizes();
    }
}

void clfl_scrollbar_set_vertical(widget_id id, int vertical)
{
    if (auto *scrollbar = dynamic_cast<Fl_Scrollbar *>(find_widget(id))) {
        scrollbar->type(vertical ? FL_VERTICAL : FL_HORIZONTAL);
        scrollbar->redraw();
    }
}

void clfl_flex_set_type(widget_id id, int horizontal)
{
    if (auto *flex = dynamic_cast<Fl_Flex *>(find_widget(id))) {
        flex->type(horizontal ? Fl_Flex::HORIZONTAL : Fl_Flex::VERTICAL);
        flex->need_layout(1);
        flex->redraw();
    }
}

void clfl_flex_set_gap(widget_id id, int gap)
{
    if (auto *flex = dynamic_cast<Fl_Flex *>(find_widget(id))) {
        flex->gap(gap);
        flex->redraw();
    }
}

void clfl_flex_set_margin(widget_id id, int left, int top, int right, int bottom)
{
    if (auto *flex = dynamic_cast<Fl_Flex *>(find_widget(id))) {
        flex->margin(left, top, right, bottom);
        flex->redraw();
    }
}

void clfl_flex_fixed(widget_id id, widget_id child_id, int size)
{
    auto *flex = dynamic_cast<Fl_Flex *>(find_widget(id));
    Fl_Widget *child = find_widget(child_id);
    if (flex && child) {
        flex->fixed(child, std::max(0, size));
        flex->redraw();
    }
}

void clfl_flex_layout(widget_id id)
{
    if (auto *flex = dynamic_cast<Fl_Flex *>(find_widget(id))) {
        flex->layout();
        flex->redraw();
    }
}

void clfl_table_set_size(widget_id id, int rows, int columns)
{
    table_resize_data(id, rows, columns);
}

void clfl_table_set_column_label(widget_id id, int column, const char *label)
{
    table_set_column_label(id, column, label);
}

void clfl_table_set_column_width(widget_id id, int column, int width)
{
    table_set_column_width(id, column, width);
}

void clfl_table_set_cell(widget_id id, int row, int column, const char *value)
{
    table_set_cell(id, row, column, value);
}

char *clfl_table_get_cell(widget_id id, int row, int column)
{
    return table_get_cell(id, row, column);
}

int clfl_table_selected_row(widget_id id)
{
    return table_selected_row(id);
}

char *clfl_table_selected_rows(widget_id id)
{
    return table_selected_rows(id);
}

void clfl_table_select_row(widget_id id, int row)
{
    table_select_row(id, row);
}

int clfl_table_column_width(widget_id id, int column)
{
    return table_column_width(id, column);
}

void clfl_widget_clear(widget_id id)
{
    clear_widget_contents(id);
}

void clfl_copy_text(const char *value)
{
    const char *text = value ? value : "";
    Fl::copy(text, static_cast<int>(std::strlen(text)), 1);
}

}
