#include "sdram.h"

void boot()
{
    volatile  int *uart = (volatile  int *)0x10000000;
    volatile  int *led  = (volatile  int *)0x10002000;
    volatile  int *imem = (volatile  int *)0x40000000;
    volatile  int *dram = (volatile  int *)0x80000000;

//==============================================================================
// LiteX Init (Error Code: 0xa)
//------------------------------------------------------------------------------
    if (!sdram_init()) *uart = 0xa;
    
//==============================================================================
// Write Test
//------------------------------------------------------------------------------
    unsigned int write_sum = 0;
    unsigned int write_xor = 0;
    for (unsigned int i = 0; i < 100; i++) {
        unsigned int write_data = i * 17;
        dram[i] = write_data;
        write_sum += write_data;
        write_xor ^= write_data;
    }
    *uart = 0x777;
    
//==============================================================================
// Read Test
//------------------------------------------------------------------------------
    unsigned int read_sum = 0;
    unsigned int read_xor = 0;
    for (unsigned int i = 0; i < 100; i++) {
        unsigned int read_data = dram[i];
        read_sum += read_data;
        read_xor ^= read_data;
    }

//==============================================================================
// Checksum (Error Code: 0xb)
//------------------------------------------------------------------------------
    if (write_sum != read_sum || write_xor != read_xor) *uart = 0xb;
    else *uart = 0x777;

//==============================================================================
// LOAD From UART
//------------------------------------------------------------------------------
    for (int i = 0; i < 0x1000; i++) imem[i] = *uart;
    for (int i = 0; i < 0x1000; i++) dram[i] = *uart;
}
