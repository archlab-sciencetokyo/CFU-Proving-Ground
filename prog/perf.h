#include <stdint.h>

uint64_t get_cycle(void);
uint64_t get_instret(void);
void perf_enable(void);
void perf_disable(void);
void perf_reset(void);
