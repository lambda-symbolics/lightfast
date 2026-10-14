#include "cl_fltk_bridge.hpp"

#include <atomic>
#include <mutex>

using namespace clfl_bridge;

namespace {

// A callback another thread can ask the interface thread to run. Entries are
// never freed: a wake may already be in FLTK's queue when one is removed, and
// FLTK would then call back into freed memory.
struct WakeupEntry {
    clfl_callback callback = nullptr;
    widget_id token = 0;
    // Set by a wake, cleared just before the callback runs, so a burst of
    // wakes costs one callback rather than filling FLTK's awake ring.
    std::atomic<bool> pending{false};
};

std::mutex g_wakeups_lock;
std::unordered_map<widget_id, std::unique_ptr<WakeupEntry>> g_wakeups;
widget_id g_next_wakeup_id = 1;

// Fl::lock() initialises FLTK's thread support; the main thread keeps the
// lock and Fl::wait releases it while it sleeps, as FLTK documents. Taken once:
// both thread wakeups and wakeup callbacks need it, and a second lock on the
// interface thread would never be released by Fl::wait.
void enable_threads_once()
{
    static bool enabled = false;
    if (!enabled) {
        Fl::lock();
        enabled = true;
    }
}

void wakeup_dispatch(void *data)
{
    auto *entry = static_cast<WakeupEntry *>(data);
    entry->pending.store(false);
    if (entry->callback) {
        entry->callback(0, EVENT_TIMER, "", entry->token);
    }
}

} // namespace

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

widget_id clfl_add_wakeup(clfl_callback callback, widget_id token)
{
    if (!callback) {
        return 0;
    }
    enable_threads_once();
    std::lock_guard<std::mutex> guard(g_wakeups_lock);
    const widget_id id = g_next_wakeup_id++;
    auto entry = std::make_unique<WakeupEntry>();
    entry->callback = callback;
    entry->token = token;
    g_wakeups[id] = std::move(entry);
    return id;
}

int clfl_wake(widget_id id)
{
    WakeupEntry *entry = nullptr;
    {
        std::lock_guard<std::mutex> guard(g_wakeups_lock);
        const auto found = g_wakeups.find(id);
        if (found == g_wakeups.end()) {
            return 0;
        }
        entry = found->second.get();
    }
    if (!entry->pending.exchange(true)) {
        Fl::awake(wakeup_dispatch, entry);
    }
    return 1;
}

int clfl_remove_wakeup(widget_id id)
{
    std::lock_guard<std::mutex> guard(g_wakeups_lock);
    const auto found = g_wakeups.find(id);
    if (found == g_wakeups.end()) {
        return 0;
    }
    found->second->callback = nullptr;
    return 1;
}

void clfl_quit()
{
    request_quit();
}

void clfl_enable_thread_wakeups()
{
    enable_threads_once();
}

void clfl_awake()
{
    Fl::awake();
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

int clfl_wait_for_event()
{
    // The no-argument Fl::wait blocks until an event, a timeout or an awake,
    // and reports whether any window is still open.
    return Fl::wait();
}

}
