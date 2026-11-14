// Floating point traps around the bridge.
//
// A Lisp runs with some floating point traps enabled: SBCL traps invalid
// operations, division by zero and overflow. FLTK and what it stands on
// compute with NaN and infinity as a matter of course, Cocoa and CoreText
// above all, and under those traps that arithmetic ends the process with
// SIGFPE. The Lisp side therefore masks every trap on its way into the bridge
// and puts its own back on the way out, and does the reverse around a
// callback, with the two functions here.
//
// They touch the control registers directly because this pair runs around
// every call into the bridge. SBCL's own setter saves and loads the whole x87
// environment on x86-64, which measured about 70 ns a time; the pair here
// costs about 25 ns a call together.

#include <cstdint>

extern "C" {

/// Masks every floating point trap for the calling thread and returns the
/// control state that was in force, for clfl_float_traps_restore.
std::uint64_t clfl_float_traps_mask();

/// Puts back the control state STATE that clfl_float_traps_mask returned,
/// dropping any exception flags raised since.
void clfl_float_traps_restore(std::uint64_t state);

#if defined(__x86_64__)

// The state is the SSE control and status register in the low half and the
// x87 control word above it. SBCL enables its traps in both.

std::uint64_t clfl_float_traps_mask()
{
    std::uint32_t mxcsr = 0;
    std::uint16_t control = 0;
    __asm__ __volatile__("stmxcsr %0" : "=m"(mxcsr));
    __asm__ __volatile__("fnstcw %0" : "=m"(control));
    // Bits 7 to 12 of MXCSR and bits 0 to 5 of the x87 control word mask the
    // six exceptions when set.
    const std::uint32_t masked_mxcsr = mxcsr | 0x1f80u;
    const std::uint16_t masked_control = static_cast<std::uint16_t>(control | 0x3fu);
    __asm__ __volatile__("ldmxcsr %0" : : "m"(masked_mxcsr));
    __asm__ __volatile__("fldcw %0" : : "m"(masked_control));
    return (static_cast<std::uint64_t>(control) << 32) | mxcsr;
}

void clfl_float_traps_restore(std::uint64_t state)
{
    const std::uint32_t mxcsr = static_cast<std::uint32_t>(state);
    const std::uint16_t control = static_cast<std::uint16_t>(state >> 32);
    // An x87 exception flag left set would trap at the next x87 instruction
    // once its mask is lifted, so the flags go first. Loading the saved MXCSR
    // replaces the SSE flags along with the masks.
    __asm__ __volatile__("fnclex");
    __asm__ __volatile__("fldcw %0" : : "m"(control));
    __asm__ __volatile__("ldmxcsr %0" : : "m"(mxcsr));
}

#elif defined(__aarch64__)

// The state is the control register FPCR in the low half and the status
// register FPSR above it.

std::uint64_t clfl_float_traps_mask()
{
    std::uint64_t control = 0;
    std::uint64_t status = 0;
    __asm__ __volatile__("mrs %0, fpcr" : "=r"(control));
    __asm__ __volatile__("mrs %0, fpsr" : "=r"(status));
    // Bits 8 to 12 and bit 15 of FPCR enable the six traps when set.
    const std::uint64_t masked_control = control & ~static_cast<std::uint64_t>(0x9f00);
    __asm__ __volatile__("msr fpcr, %0" : : "r"(masked_control));
    return (status << 32) | (control & 0xffffffffu);
}

void clfl_float_traps_restore(std::uint64_t state)
{
    const std::uint64_t control = state & 0xffffffffu;
    const std::uint64_t status = state >> 32;
    __asm__ __volatile__("msr fpsr, %0" : : "r"(status));
    __asm__ __volatile__("msr fpcr, %0" : : "r"(control));
}

#else
#error "Lightfast masks floating point traps on x86-64 and arm64 only; teach native/api_floats.cpp this architecture."
#endif

}
