#include <stdlib.h>

int main () {
    volatile char *dram = (volatile char *)0x20000000;
    volatile char *sdram = (volatile char *)0x10000000;
    volatile int *led = (volatile int *)0xF0000000;
    volatile char *uart = (volatile char *)0xF0001004;

    for (int i = 0; i < 1000; i++) {
        dram[i] = (char)i;
    }

    for (int i = 0; i < 1000; i++) {
        if (dram[i] != (char)i) {
            led[1] = 1; // Error
            while (1);
        }
    }

    return 0;
}
