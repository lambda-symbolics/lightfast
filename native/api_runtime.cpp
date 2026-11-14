#include "cl_fltk_bridge.hpp"

#include <atomic>
#include <mutex>
#include <thread>

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
//
// The thread that takes the lock is the interface thread, remembered so that
// a request from any other thread can be told apart and handed over.
std::atomic<bool> g_threads_enabled{false};
std::thread::id g_interface_thread;

void enable_threads_once()
{
    if (!g_threads_enabled.load()) {
        Fl::lock();
        g_interface_thread = std::this_thread::get_id();
        g_threads_enabled.store(true);
    }
}

bool on_another_thread()
{
    return g_threads_enabled.load() && std::this_thread::get_id() != g_interface_thread;
}

void quit_dispatch(void *)
{
    request_quit();
}

void no_operation(void *)
{
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

namespace clfl_bridge {

// A callback that hides the last window, or quits, expects the event loop to
// return. From a timer it would not: FLTK goes on to wait for the next event,
// and on macOS a window going away sends none, so the loop slept until
// something else happened to wake it. Fl::awake is no remedy, since it does
// nothing before Fl::lock, which a program without threads never calls. A
// timeout that is already due bounds the wait in progress on every platform.
void break_event_wait()
{
    if (!Fl::has_timeout(no_operation)) {
        Fl::add_timeout(0.0, no_operation);
    }
    Fl::awake();
}

} // namespace clfl_bridge

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

/// Quits now on the interface thread. From any other thread, once thread
/// wakeups are enabled, the quit is handed to the interface thread, which
/// carries it out when it next wakes: hiding windows from elsewhere is
/// against FLTK's rule everywhere and ends the process on macOS, where only
/// the main thread may touch Cocoa.
void clfl_quit()
{
    if (on_another_thread()) {
        Fl::awake(quit_dispatch, nullptr);
        return;
    }
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
