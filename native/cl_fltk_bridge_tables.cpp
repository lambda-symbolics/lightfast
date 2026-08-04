#include "cl_fltk_bridge.hpp"

namespace clfl_bridge {

class ClassicTable final : public Fl_Table_Row {
public:
    ClassicTable(int x, int y, int w, int h, const char *label)
        : Fl_Table_Row(x, y, w, h, label)
    {
        box(FL_DOWN_BOX);
        table_box(FL_DOWN_BOX);
        color(FL_WHITE);
        selection_color(fl_rgb_color(0, 0, 128));
        row_header(0);
        col_header(1);
        col_header_height(22);
        col_resize(1);
        row_resize(0);
        row_height_all(20);
        col_width_all(90);
        type(Fl_Table_Row::SELECT_MULTI);
        when(FL_WHEN_RELEASE);
        apply_scrollbar_style(vscrollbar);
        apply_scrollbar_style(hscrollbar);
        end();
    }

    void resize_data(int row_count, int column_count)
    {
        const int safe_rows = std::max(0, row_count);
        const int safe_columns = std::max(0, column_count);

        cells_.resize(safe_rows);
        for (auto &row : cells_) {
            row.resize(safe_columns);
        }

        column_labels_.resize(safe_columns);
        for (int column = 0; column < safe_columns; ++column) {
            if (column_labels_[column].empty()) {
                column_labels_[column] = std::to_string(column + 1);
            }
        }

        rows(safe_rows);
        cols(safe_columns);
        row_height_all(20);
        redraw();
    }

    void set_column_label(int column, const char *label)
    {
        if (column < 0 || column >= static_cast<int>(column_labels_.size())) {
            return;
        }
        column_labels_[column] = label ? label : "";
        redraw();
    }

    void set_cell(int row, int column, const char *value)
    {
        if (row < 0 || row >= static_cast<int>(cells_.size())) {
            return;
        }
        if (column < 0 || column >= static_cast<int>(cells_[row].size())) {
            return;
        }
        cells_[row][column] = value ? value : "";
        redraw();
    }

    const char *cell(int row, int column) const
    {
        if (row < 0 || row >= static_cast<int>(cells_.size())) {
            return "";
        }
        if (column < 0 || column >= static_cast<int>(cells_[row].size())) {
            return "";
        }
        return cells_[row][column].c_str();
    }

    void set_column_width(int column, int width)
    {
        if (column < 0 || column >= cols()) {
            return;
        }
        col_width(column, std::max(24, width));
        redraw();
    }

    int column_width(int column)
    {
        if (column < 0 || column >= cols()) {
            return 0;
        }
        return col_width(column);
    }

    int selected_row()
    {
        for (int row = 0; row < rows(); ++row) {
            if (row_selected(row)) {
                return row;
            }
        }
        return -1;
    }

    std::string selected_rows_string()
    {
        std::string result;
        for (int row = 0; row < rows(); ++row) {
            if (!row_selected(row)) {
                continue;
            }
            if (!result.empty()) {
                result.push_back(' ');
            }
            result.append(std::to_string(row));
        }
        return result;
    }

    void select_single_row(int row)
    {
        select_all_rows(0);
        if (row >= 0 && row < rows()) {
            select_row(row, 1);
            row_position(row);
        }
        redraw();
    }

    std::string callback_value_string()
    {
        char buffer[96];
        const TableContext context = callback_context();
        const int column = callback_col();
        if (context == CONTEXT_COL_HEADER) {
            std::snprintf(buffer,
                          sizeof(buffer),
                          "header %d %s",
                          column,
                          event_phase());
            return buffer;
        }
        if (context == CONTEXT_RC_RESIZE) {
            std::snprintf(buffer,
                          sizeof(buffer),
                          "resize %d %d",
                          column,
                          column_width(column));
            return buffer;
        }
        std::snprintf(buffer, sizeof(buffer), "row %d", selected_row());
        return buffer;
    }

    void draw_cell(TableContext context, int row, int column, int x, int y, int width, int height) override
    {
        switch (context) {
        case CONTEXT_STARTPAGE:
            fl_font(FL_HELVETICA, 12);
            return;
        case CONTEXT_COL_HEADER:
            draw_header_cell(column, x, y, width, height);
            return;
        case CONTEXT_CELL:
            draw_data_cell(row, column, x, y, width, height);
            return;
        default:
            return;
        }
    }

private:
    std::vector<std::string> column_labels_;
    std::vector<std::vector<std::string>> cells_;

    const char *event_phase() const
    {
        switch (Fl::event()) {
        case FL_PUSH:
            return "push";
        case FL_RELEASE:
            return "release";
        case FL_DRAG:
            return "drag";
        default:
            return "event";
        }
    }

    void draw_header_cell(int column, int x, int y, int width, int height)
    {
        fl_push_clip(x, y, width, height);
        fl_draw_box(FL_UP_BOX, x, y, width, height, FL_BACKGROUND_COLOR);
        fl_font(FL_HELVETICA, 12);
        fl_color(FL_BLACK);
        const char *label =
            (column >= 0 && column < static_cast<int>(column_labels_.size()))
                ? column_labels_[column].c_str()
                : "";
        fl_draw(label, x + 5, y + 1, width - 8, height - 2, FL_ALIGN_LEFT | FL_ALIGN_INSIDE);
        fl_pop_clip();
    }

    bool marker_icon_value(const std::string &value)
    {
        return value == "!" || value == "X" || value == "+" || value == "*" || value == "-";
    }

    void draw_marker_icon(const std::string &value, int x, int y, int width, int height, bool selected)
    {
        if (value.empty()) {
            return;
        }

        const int size = std::min(12, std::max(8, std::min(width - 8, height - 6)));
        const int left = x + std::max(3, (width - size) / 2);
        const int top = y + std::max(3, (height - size) / 2);

        if (value == "!") {
            fl_color(selected ? fl_rgb_color(255, 235, 235) : fl_rgb_color(192, 0, 0));
            fl_rectf(left, top, size, size);
            fl_color(selected ? FL_WHITE : fl_rgb_color(96, 0, 0));
            fl_rect(left, top, size, size);
            fl_color(FL_WHITE);
            fl_line(left + size / 2, top + 3, left + size / 2, top + size - 4);
            fl_point(left + size / 2, top + size - 2);
            return;
        }

        if (value == "X") {
            fl_color(selected ? FL_WHITE : fl_rgb_color(128, 128, 128));
            fl_rectf(left, top, size, size);
            fl_color(selected ? fl_rgb_color(64, 64, 64) : FL_BLACK);
            fl_rect(left, top, size, size);
            fl_line(left + 3, top + 3, left + size - 3, top + size - 3);
            fl_line(left + size - 3, top + 3, left + 3, top + size - 3);
            return;
        }

        if (value == "+") {
            fl_color(selected ? FL_WHITE : fl_rgb_color(0, 128, 64));
            fl_rectf(left, top, size, size);
            fl_color(selected ? fl_rgb_color(0, 96, 48) : FL_WHITE);
            fl_line(left + size / 2, top + 3, left + size / 2, top + size - 3);
            fl_line(left + 3, top + size / 2, left + size - 3, top + size / 2);
            return;
        }

        if (value == "*") {
            const int cx = left + size / 2;
            const int cy = top + size / 2;
            fl_color(selected ? FL_WHITE : fl_rgb_color(255, 192, 0));
            fl_polygon(cx, top, left + size, cy, cx, top + size, left, cy);
            fl_color(selected ? fl_rgb_color(128, 96, 0) : fl_rgb_color(96, 64, 0));
            fl_loop(cx, top, left + size, cy, cx, top + size, left, cy);
            return;
        }

        if (value == "-") {
            fl_color(selected ? FL_WHITE : fl_rgb_color(96, 96, 96));
            fl_rectf(left + 2, top + size / 2 - 1, size - 4, 3);
        }
    }

    void draw_data_cell(int row, int column, int x, int y, int width, int height)
    {
        const bool selected = row_selected(row);
        const char *value = cell(row, column);
        fl_push_clip(x, y, width, height);
        fl_color(selected ? selection_color() : FL_WHITE);
        fl_rectf(x, y, width, height);
        if (column == 0 && value && marker_icon_value(value)) {
            draw_marker_icon(value, x, y, width, height, selected);
        } else {
            fl_font(FL_HELVETICA, 12);
            fl_color(selected ? FL_WHITE : FL_BLACK);
            fl_draw(value, x + 5, y + 1, width - 8, height - 2, FL_ALIGN_LEFT | FL_ALIGN_INSIDE);
        }
        fl_color(FL_LIGHT2);
        fl_line(x, y + height - 1, x + width, y + height - 1);
        fl_color(fl_rgb_color(224, 224, 224));
        fl_line(x + width - 1, y, x + width - 1, y + height);
        fl_pop_clip();
    }
};

Fl_Widget *create_classic_table(int x, int y, int w, int h, const char *label)
{
    auto *table = new ClassicTable(x, y, w, h, label ? label : "");
    table->resize_data(0, 0);
    apply_common_style(table);
    return table;
}

bool classic_table_value_string(Fl_Widget *widget, std::string *out)
{
    if (auto *table = dynamic_cast<ClassicTable *>(widget)) {
        char buffer[64];
        std::snprintf(buffer, sizeof(buffer), "%d", table->selected_row());
        if (out) {
            *out = buffer;
        }
        return true;
    }
    return false;
}

bool classic_table_callback_value_string(Fl_Widget *widget, std::string *out)
{
    if (auto *table = dynamic_cast<ClassicTable *>(widget)) {
        if (out) {
            *out = table->callback_value_string();
        }
        return true;
    }
    return false;
}

bool classic_table_set_value(Fl_Widget *widget, const char *value)
{
    if (auto *table = dynamic_cast<ClassicTable *>(widget)) {
        const char *text = value ? value : "";
        char *end = nullptr;
        const long row = std::strtol(text, &end, 10);
        if (end && end != text) {
            table->select_single_row(static_cast<int>(row));
        }
        return true;
    }
    return false;
}

bool classic_table_clear(Fl_Widget *widget)
{
    if (auto *table = dynamic_cast<ClassicTable *>(widget)) {
        table->resize_data(0, 0);
        return true;
    }
    return false;
}

void table_resize_data(widget_id id, int rows, int columns)
{
    if (auto *table = dynamic_cast<ClassicTable *>(find_widget(id))) {
        table->resize_data(rows, columns);
    }
}

void table_set_column_label(widget_id id, int column, const char *label)
{
    if (auto *table = dynamic_cast<ClassicTable *>(find_widget(id))) {
        table->set_column_label(column, label);
    }
}

void table_set_column_width(widget_id id, int column, int width)
{
    if (auto *table = dynamic_cast<ClassicTable *>(find_widget(id))) {
        table->set_column_width(column, width);
    }
}

void table_set_cell(widget_id id, int row, int column, const char *value)
{
    if (auto *table = dynamic_cast<ClassicTable *>(find_widget(id))) {
        table->set_cell(row, column, value);
    }
}

char *table_get_cell(widget_id id, int row, int column)
{
    if (auto *table = dynamic_cast<ClassicTable *>(find_widget(id))) {
        return copy_c_string(table->cell(row, column));
    }
    return copy_c_string("");
}

int table_selected_row(widget_id id)
{
    if (auto *table = dynamic_cast<ClassicTable *>(find_widget(id))) {
        return table->selected_row();
    }
    return -1;
}

char *table_selected_rows(widget_id id)
{
    if (auto *table = dynamic_cast<ClassicTable *>(find_widget(id))) {
        const std::string rows = table->selected_rows_string();
        return copy_c_string(rows.c_str());
    }
    return copy_c_string("");
}

void table_select_row(widget_id id, int row)
{
    if (auto *table = dynamic_cast<ClassicTable *>(find_widget(id))) {
        table->select_single_row(row);
    }
}

int table_column_width(widget_id id, int column)
{
    if (auto *table = dynamic_cast<ClassicTable *>(find_widget(id))) {
        return table->column_width(column);
    }
    return 0;
}


} // namespace clfl_bridge
