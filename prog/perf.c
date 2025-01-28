#include "perf.h"

uint64_t get_cycle(void) {
    return *(uint64_t *)0x20000008 << 32 | *(uint64_t *)0x20000004;
}

uint64_t get_instret(void) {
    return *(uint64_t *)0x20000010 << 32 | *(uint64_t *)0x2000000C;
}

void perf_enable(void) {
    volatile uint8_t *reg_pref_enable = (volatile uint8_t *)0x20000000;
    *reg_pref_enable = 1;
}

void perf_disable(void) {
    volatile uint8_t *reg_pref_enable = (volatile uint8_t *)0x20000000;
    *reg_pref_enable = 0;
}

void perf_reset(void) {
    volatile uint8_t *reg_pref_reset = (volatile uint8_t *)0x20000001;
    *reg_pref_reset = 1;
    asm volatile("nop");
}
