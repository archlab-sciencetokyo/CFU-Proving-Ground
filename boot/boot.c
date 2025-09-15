#include "sdram.h"
volatile int *dram = (volatile int *)0x80000000;
volatile int *led = (volatile int *)0x10002000;

volatile int *uart = (volatile int *)0x10000000;

void boot()
{
    if (sdram_init()) {
        *uart = 0x777;
    } else {
        *uart = 0;
    }

    //==========================================================================
    // Write
    //--------------------------------------------------------------------------
    unsigned int write_sum = 0;
    unsigned int write_xor = 0;
    for (unsigned int i = 0; i < 0x10000; i++) {
        int write_data = i;
        dram[i] = write_data;
        write_sum += write_data;
        write_xor ^= write_data;
    }

    //==========================================================================
    // Read
    //--------------------------------------------------------------------------
    unsigned int read_sum = 0;
    unsigned int read_xor = 0;
    for (unsigned int i = 0; i < 0x10000; i++) {
        int read_data = dram[i];
        read_sum += read_data;
        read_xor ^= read_data;
    }

    //==========================================================================
    // Checksum
    //--------------------------------------------------------------------------
    if (write_sum == read_sum && write_xor == read_xor) {
        led[2] = 1;  // Write to LED 6
    } else {
        led[3] = 1;  // Write to LED 7
    }
}
