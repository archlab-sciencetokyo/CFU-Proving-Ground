long long pg_perf_cycle(void) {
    int cycle =  *(int *)0x40000004;
    int cycleh = *(int *)0x40000008;
    return ((long long)cycleh << 32) | cycle;
}

void pg_perf_reset(void) {
    *(char *)0x40000000 = 0;
}

void pg_perf_enable(void) {
    *(char *)0x40000000 = 1;
}

void pg_perf_disable(void) {
    *(char *)0x40000000 = 2;
}
