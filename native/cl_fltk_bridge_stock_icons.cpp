#include "cl_fltk_bridge.hpp"

namespace clfl_bridge {

namespace {

#include "stock_icons.hpp"

Fl_Pixmap *stock_icon(const char *name)
{
    static Fl_Pixmap photo_icon(kPhotoIcon);
    static Fl_Pixmap folder_icon(kFolderIcon);
    static Fl_Pixmap contrast_icon(kContrastIcon);
    static Fl_Pixmap sharpen_icon(kSharpenIcon);
    static Fl_Pixmap focus_icon(kFocusIcon);
    static Fl_Pixmap crop_icon(kCropIcon);
    static Fl_Pixmap zoom_in_icon(kZoomInIcon);
    static Fl_Pixmap zoom_out_icon(kZoomOutIcon);
    static Fl_Pixmap archive_icon(kArchiveIcon);
    static Fl_Pixmap calendar_icon(kCalendarIcon);
    static Fl_Pixmap contact_icon(kContactIcon);
    static Fl_Pixmap copy_icon(kCopyIcon);
    static Fl_Pixmap country_icon(kCountryIcon);
    static Fl_Pixmap delete_icon(kDeleteIcon);
    static Fl_Pixmap draft_icon(kDraftIcon);
    static Fl_Pixmap due_icon(kDueIcon);
    static Fl_Pixmap export_icon(kExportIcon);
    static Fl_Pixmap filter_icon(kFilterIcon);
    static Fl_Pixmap flag_icon(kFlagIcon);
    static Fl_Pixmap history_icon(kHistoryIcon);
    static Fl_Pixmap hot_icon(kHotIcon);
    static Fl_Pixmap import_icon(kImportIcon);
    static Fl_Pixmap log_icon(kLogIcon);
    static Fl_Pixmap mail_icon(kMailIcon);
    static Fl_Pixmap marker_icon(kMarkerIcon);
    static Fl_Pixmap marker_hot_icon(kMarkerHotIcon);
    static Fl_Pixmap marker_won_icon(kMarkerWonIcon);
    static Fl_Pixmap new_icon(kNewIcon);
    static Fl_Pixmap next_icon(kNextIcon);
    static Fl_Pixmap note_icon(kNoteIcon);
    static Fl_Pixmap open_icon(kOpenIcon);
    static Fl_Pixmap phone_icon(kPhoneIcon);
    static Fl_Pixmap pipeline_icon(kPipelineIcon);
    static Fl_Pixmap previous_icon(kPreviousIcon);
    static Fl_Pixmap reload_icon(kReloadIcon);
    static Fl_Pixmap reminder_icon(kReminderIcon);
    static Fl_Pixmap save_icon(kSaveIcon);
    static Fl_Pixmap school_icon(kSchoolIcon);
    static Fl_Pixmap search_icon(kSearchIcon);
    static Fl_Pixmap send_icon(kSendIcon);
    static Fl_Pixmap stale_icon(kStaleIcon);
    static Fl_Pixmap star_icon(kStarIcon);
    static Fl_Pixmap success_icon(kSuccessIcon);
    static Fl_Pixmap task_icon(kTaskIcon);
    static Fl_Pixmap touch_icon(kTouchIcon);
    static Fl_Pixmap warning_icon(kWarningIcon);
    static Fl_Pixmap web_icon(kWebIcon);
    static Fl_Pixmap won_icon(kWonIcon);
    static Fl_Pixmap white_balance_icon(kWhiteBalanceIcon);
    static Fl_Pixmap exposure_icon(kExposureIcon);
    static Fl_Pixmap noise_icon(kNoiseIcon);
    static Fl_Pixmap tone_icon(kToneIcon);
    static Fl_Pixmap optics_icon(kOpticsIcon);
    static Fl_Pixmap film_icon(kFilmIcon);
    static Fl_Pixmap blend_icon(kBlendIcon);
    static Fl_Pixmap color_subtract_icon(kColorSubtractIcon);
    static Fl_Pixmap negative_icon(kNegativeIcon);
    static Fl_Pixmap rotate_icon(kRotateIcon);
    static Fl_Pixmap flip_icon(kFlipIcon);
    static Fl_Pixmap curves_icon(kCurvesIcon);
    static Fl_Pixmap fit_icon(kFitIcon);
    static Fl_Pixmap actual_pixels_icon(kActualPixelsIcon);
    static Fl_Pixmap compare_icon(kCompareIcon);
    static Fl_Pixmap camera_icon(kCameraIcon);
    static Fl_Pixmap question_icon(kQuestionIcon);
    static Fl_Pixmap information_icon(kInformationIcon);
    static Fl_Pixmap exclamation_icon(kExclamationIcon);
    static Fl_Pixmap home_icon(kHomeIcon);
    static Fl_Pixmap paste_icon(kPasteIcon);
    static Fl_Pixmap dropper_icon(kDropperIcon);
    static Fl_Pixmap film_border_icon(kFilmBorderIcon);
    static Fl_Pixmap orfeus_icon(kOrfeusIcon);
    static Fl_Pixmap orfeus_32_icon(kOrfeus32Icon);

    struct StockIconEntry {
        const char *name;
        Fl_Pixmap *icon;
    };

    static StockIconEntry stock_icons[] = {
        {"photo", &photo_icon},
        {"folder", &folder_icon},
        {"contrast", &contrast_icon},
        {"sharpen", &sharpen_icon},
        {"focus", &focus_icon},
        {"crop", &crop_icon},
        {"zoom-in", &zoom_in_icon},
        {"zoom-out", &zoom_out_icon},
        {"archive", &archive_icon},
        {"calendar", &calendar_icon},
        {"contact", &contact_icon},
        {"copy", &copy_icon},
        {"country", &country_icon},
        {"delete", &delete_icon},
        {"draft", &draft_icon},
        {"due", &due_icon},
        {"export", &export_icon},
        {"filter", &filter_icon},
        {"flag", &flag_icon},
        {"history", &history_icon},
        {"hot", &hot_icon},
        {"import", &import_icon},
        {"log", &log_icon},
        {"mail", &mail_icon},
        {"marker", &marker_icon},
        {"marker-hot", &marker_hot_icon},
        {"marker-won", &marker_won_icon},
        {"new", &new_icon},
        {"next", &next_icon},
        {"note", &note_icon},
        {"open", &open_icon},
        {"phone", &phone_icon},
        {"pipeline", &pipeline_icon},
        {"previous", &previous_icon},
        {"reload", &reload_icon},
        {"reminder", &reminder_icon},
        {"save", &save_icon},
        {"school", &school_icon},
        {"search", &search_icon},
        {"send", &send_icon},
        {"stale", &stale_icon},
        {"star", &star_icon},
        {"success", &success_icon},
        {"task", &task_icon},
        {"touch", &touch_icon},
        {"warning", &warning_icon},
        {"web", &web_icon},
        {"won", &won_icon},
        {"email", &mail_icon},
        {"back", &previous_icon},
        {"forward", &next_icon},
        {"ok", &success_icon},
        {"warn", &warning_icon},
        {"folder-open", &folder_icon},
        {"white-balance", &white_balance_icon},
        {"exposure", &exposure_icon},
        {"noise", &noise_icon},
        {"tone", &tone_icon},
        {"optics", &optics_icon},
        {"film", &film_icon},
        {"blend", &blend_icon},
        {"color-subtract", &color_subtract_icon},
        {"negative", &negative_icon},
        {"rotate", &rotate_icon},
        {"flip", &flip_icon},
        {"curves", &curves_icon},
        {"fit", &fit_icon},
        {"actual-pixels", &actual_pixels_icon},
        {"compare", &compare_icon},
        {"camera", &camera_icon},
        {"question", &question_icon},
        {"information", &information_icon},
        {"exclamation", &exclamation_icon},
        {"home", &home_icon},
        {"paste", &paste_icon},
        {"dropper", &dropper_icon},
        {"film-border", &film_border_icon},
        {"orfeus", &orfeus_icon},
        {"orfeus-32", &orfeus_32_icon},
    };

    if (!name || !*name) {
        return nullptr;
    }
    for (const auto &entry : stock_icons) {
        if (std::strcmp(name, entry.name) == 0) {
            return entry.icon;
        }
    }
    return nullptr;
}

} // namespace

Fl_Pixmap *stock_icon_pixmap(const char *name)
{
    return stock_icon(name);
}

void set_widget_stock_icon(widget_id id, const char *name)
{
    if (Fl_Widget *widget = find_widget(id)) {
        widget->image(stock_icon(name));
        // A captioned button keeps its caption and seats the icon beside it;
        // left to itself FLTK stacks the picture over the text, and in a
        // button one row tall the two land on each other.
        if (widget->label() && *widget->label()) {
            widget->align(FL_ALIGN_CENTER | FL_ALIGN_INSIDE | FL_ALIGN_IMAGE_NEXT_TO_TEXT);
        }
        widget->redraw();
    }
}

} // namespace clfl_bridge
