#include <stdint.h>

uint64_t perf_cycle(void) {
    uint32_t cycle = *(uint32_t *)0x40000004;
    uint32_t cycleh = *(uint32_t *)0x40000008;
    return ((uint64_t)cycleh << 32) | cycle;
}

void perf_enable(void) {
    *(volatile uint8_t *)0x40000000 = 1;
}

void perf_disable(void) {
    *(volatile uint8_t *)0x40000000 = 2;
}

void perf_reset(void) {
    *(volatile uint8_t *)0x40000000 = 0;
}
