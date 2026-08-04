#include "cl_fltk_bridge.hpp"

using namespace clfl_bridge;

extern "C" {

widget_id clfl_add_timeout(double seconds,
                           int repeat,
                           clfl_callback callback,
                           widget_id token)
{
    if (seconds < 0.0 || !callback) {
        return 0;
    }

    const widget_id id = g_next_timer_id++;
    auto timer = std::make_unique<TimerEntry>();
    timer->id = id;
    timer->interval = seconds;
    timer->repeat = repeat ? 1 : 0;
    timer->callback = callback;
    timer->token = token;
    TimerEntry *raw_timer = timer.get();
    g_timers[id] = std::move(timer);
    Fl::add_timeout(seconds, timer_dispatch_callback, raw_timer);
    return id;
}

int clfl_remove_timeout(widget_id id)
{
    const auto found = g_timers.find(id);
    if (found == g_timers.end()) {
        return 0;
    }

    Fl::remove_timeout(timer_dispatch_callback, found->second.get());
    g_timers.erase(found);
    return 1;
}

void clfl_quit()
{
    request_quit();
}

int clfl_run()
{
    g_quit_requested = false;
    Fl::program_should_quit(0);
    return Fl::run();
}

int clfl_check()
{
    return Fl::check();
}

int clfl_wait(double seconds)
{
    return Fl::wait(seconds);
}

}
