#include <stdint.h>

uint64_t perf_cycle(void);
uint64_t perf_instret(void);
void perf_enable(void);
void perf_disable(void);
void perf_reset(void);
