#include "cl_fltk_bridge.hpp"

namespace clfl_bridge {

std::string widget_value_string(Fl_Widget *widget)
{
    if (!widget) {
        return "";
    }

    if (auto *input = dynamic_cast<Fl_Input *>(widget)) {
        return input->value() ? input->value() : "";
    }
    if (auto *text = dynamic_cast<Fl_Text_Display *>(widget)) {
        Fl_Text_Buffer *buffer = text->buffer();
        if (!buffer) {
            return "";
        }
        char *copy = buffer->text();
        std::string result(copy ? copy : "");
        std::free(copy);
        return result;
    }
    if (auto *help = dynamic_cast<Fl_Help_View *>(widget)) {
        return help->value() ? help->value() : "";
    }
    if (auto *clock = dynamic_cast<Fl_Clock_Output *>(widget)) {
        char buffer[64];
        std::snprintf(buffer, sizeof(buffer), "%lu", clock->value());
        return buffer;
    }
    if (auto *output = dynamic_cast<Fl_Output *>(widget)) {
        return output->value() ? output->value() : "";
    }
    if (auto *input_choice = dynamic_cast<Fl_Input_Choice *>(widget)) {
        return input_choice->value() ? input_choice->value() : "";
    }
    if (auto *choice = dynamic_cast<Fl_Choice *>(widget)) {
        const char *text = choice->text();
        return text ? text : "";
    }
    if (auto *browser = dynamic_cast<Fl_Browser *>(widget)) {
        const int index = browser->value();
        const char *text = index > 0 ? browser->text(index) : nullptr;
        return text ? text : "";
    }
    if (auto *check_browser = dynamic_cast<Fl_Check_Browser *>(widget)) {
        const int index = check_browser->value();
        char *text = index > 0 ? check_browser->text(index) : nullptr;
        return text ? text : "";
    }
    std::string table_value;
    if (classic_table_value_string(widget, &table_value)) {
        return table_value;
    }
    if (auto *tree = dynamic_cast<Fl_Tree *>(widget)) {
        Fl_Tree_Item *item = tree->first_selected_item();
        if (!item) {
            return "";
        }
        char path[512] = {0};
        return tree->item_pathname(path, sizeof(path), item) == 0 ? path : "";
    }
    if (auto *tabs = dynamic_cast<Fl_Tabs *>(widget)) {
        Fl_Widget *page = tabs->value();
        return page && page->label() ? page->label() : "";
    }
    if (auto *menu = dynamic_cast<Fl_Menu_ *>(widget)) {
        if (menu->mvalue()) {
            char path[512] = {0};
            if (menu->item_pathname(path, sizeof(path), menu->mvalue()) == 0) {
                return path;
            }
        }
        const char *text = menu->text();
        return text ? text : "";
    }
    if (auto *check = dynamic_cast<Fl_Check_Button *>(widget)) {
        return check->value() ? "1" : "0";
    }
    if (auto *spinner = dynamic_cast<Fl_Spinner *>(widget)) {
        char buffer[64];
        std::snprintf(buffer, sizeof(buffer), "%.17g", spinner->value());
        return buffer;
    }
    if (auto *value_input = dynamic_cast<Fl_Value_Input *>(widget)) {
        char buffer[64];
        std::snprintf(buffer, sizeof(buffer), "%.17g", value_input->value());
        return buffer;
    }
    if (auto *valuator = dynamic_cast<Fl_Valuator *>(widget)) {
        char buffer[64];
        std::snprintf(buffer, sizeof(buffer), "%.17g", valuator->value());
        return buffer;
    }
    if (auto *progress = dynamic_cast<Fl_Progress *>(widget)) {
        char buffer[64];
        std::snprintf(buffer, sizeof(buffer), "%.17g", progress->value());
        return buffer;
    }
    if (auto *button = dynamic_cast<Fl_Button *>(widget)) {
        return button->value() ? "1" : "0";
    }
    if (auto *box = dynamic_cast<Fl_Box *>(widget)) {
        return box->label() ? box->label() : "";
    }

    return "";
}

std::string widget_callback_value_string(Fl_Widget *widget)
{
    std::string table_value;
    if (classic_table_callback_value_string(widget, &table_value)) {
        return table_value;
    }
    return widget_value_string(widget);
}

void set_choice_value(Fl_Choice *choice, const char *value)
{
    const std::string wanted = value ? value : "";
    for (int i = 0; i < choice->size(); ++i) {
        const Fl_Menu_Item *item = &choice->menu()[i];
        if (item && item->label() && wanted == item->label()) {
            choice->value(i);
            return;
        }
    }
}

void set_widget_value(Fl_Widget *widget, const char *value)
{
    const char *text = value ? value : "";
    if (auto *input = dynamic_cast<Fl_Input *>(widget)) {
        input->value(text);
    } else if (auto *text_display = dynamic_cast<Fl_Text_Display *>(widget)) {
        if (Fl_Text_Buffer *buffer = text_display->buffer()) {
            buffer->text(text);
        }
    } else if (auto *help = dynamic_cast<Fl_Help_View *>(widget)) {
        help->value(text);
    } else if (auto *clock = dynamic_cast<Fl_Clock_Output *>(widget)) {
        char *end = nullptr;
        const unsigned long seconds = std::strtoul(text, &end, 10);
        if (end && end != text) {
            clock->value(seconds);
        }
    } else if (auto *output = dynamic_cast<Fl_Output *>(widget)) {
        output->value(text);
    } else if (auto *input_choice = dynamic_cast<Fl_Input_Choice *>(widget)) {
        input_choice->value(text);
    } else if (auto *choice = dynamic_cast<Fl_Choice *>(widget)) {
        set_choice_value(choice, text);
    } else if (classic_table_set_value(widget, text)) {
    } else if (auto *tree = dynamic_cast<Fl_Tree *>(widget)) {
        if (Fl_Tree_Item *item = tree->find_item(text)) {
            tree->select_only(item, 0);
            tree->show_item(item);
        }
    } else if (auto *tabs = dynamic_cast<Fl_Tabs *>(widget)) {
        for (int i = 0; i < tabs->children(); ++i) {
            Fl_Widget *page = tabs->child(i);
            if (page && page->label() && std::strcmp(page->label(), text) == 0) {
                tabs->value(page);
                break;
            }
        }
    } else if (auto *check = dynamic_cast<Fl_Check_Button *>(widget)) {
        check->value(std::strcmp(text, "0") != 0 && std::strcmp(text, "") != 0);
    } else if (auto *spinner = dynamic_cast<Fl_Spinner *>(widget)) {
        spinner->value(std::atof(text));
    } else if (auto *value_input = dynamic_cast<Fl_Value_Input *>(widget)) {
        value_input->value(std::atof(text));
    } else if (auto *valuator = dynamic_cast<Fl_Valuator *>(widget)) {
        valuator->value(std::atof(text));
    } else if (auto *progress = dynamic_cast<Fl_Progress *>(widget)) {
        progress->value(std::atof(text));
    } else if (auto *button = dynamic_cast<Fl_Button *>(widget)) {
        button->value(std::strcmp(text, "0") != 0 && std::strcmp(text, "") != 0);
    } else if (auto *box = dynamic_cast<Fl_Box *>(widget)) {
        box->copy_label(text);
    }
}

void set_widget_text_size(widget_id id, int size)
{
    if (auto *input = dynamic_cast<Fl_Input *>(find_widget(id))) {
        input->textsize(size);
    } else if (auto *output = dynamic_cast<Fl_Output *>(find_widget(id))) {
        output->textsize(size);
    } else if (auto *choice = dynamic_cast<Fl_Choice *>(find_widget(id))) {
        choice->textsize(size);
    } else if (auto *browser = dynamic_cast<Fl_Browser *>(find_widget(id))) {
        browser->textsize(size);
    } else if (classic_value_input_set_text_size(find_widget(id), size)) {
    } else if (auto *value_input = dynamic_cast<Fl_Value_Input *>(find_widget(id))) {
        value_input->textsize(size);
    } else if (auto *value_slider = dynamic_cast<Fl_Value_Slider *>(find_widget(id))) {
        value_slider->textsize(size);
    }
}


void set_widget_text_font(widget_id id, int font)
{
    if (auto *input = dynamic_cast<Fl_Input *>(find_widget(id))) {
        input->textfont(font);
    } else if (auto *output = dynamic_cast<Fl_Output *>(find_widget(id))) {
        output->textfont(font);
    } else if (auto *browser = dynamic_cast<Fl_Browser *>(find_widget(id))) {
        browser->textfont(font);
    } else if (classic_value_input_set_text_font(find_widget(id), font)) {
    } else if (auto *value_slider = dynamic_cast<Fl_Value_Slider *>(find_widget(id))) {
        value_slider->textfont(font);
    }
}

void clear_widget_contents(widget_id id)
{
    if (auto *choice = dynamic_cast<Fl_Choice *>(find_widget(id))) {
        choice->clear();
    } else if (auto *input_choice = dynamic_cast<Fl_Input_Choice *>(find_widget(id))) {
        input_choice->clear();
        input_choice->value("");
    } else if (auto *browser = dynamic_cast<Fl_Browser *>(find_widget(id))) {
        browser->clear();
    } else if (auto *check_browser = dynamic_cast<Fl_Check_Browser *>(find_widget(id))) {
        check_browser->clear();
    } else if (auto *tree = dynamic_cast<Fl_Tree *>(find_widget(id))) {
        tree->clear();
    } else if (classic_table_clear(find_widget(id))) {
    }
}

} // namespace clfl_bridge
