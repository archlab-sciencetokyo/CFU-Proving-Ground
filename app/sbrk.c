/* CFU Proving Ground since 2025-02    Copyright(c) 2025 Archlab. Science Tokyo /
/ Released under the MIT license https://opensource.org/licenses/mit           */

#include "sbrk.h"
#include "util.h"

extern char _heap_start;
extern char _heap_end;

static char *heap_ptr = 0;

void *_sbrk(int incr)
{
    char *prev_heap_ptr;


    // Initialize heap pointer on first call
    if (heap_ptr == 0) {
        heap_ptr = &_heap_start;
    }

    prev_heap_ptr = heap_ptr;

    if (heap_ptr + incr > &_heap_end) {
        // Out of memory
        return (void *)-1;
    }

    if (heap_ptr + incr < &_heap_start) {
        // Cannot shrink below start of heap
        return (void *)-1;
    }

    heap_ptr += incr;


    return prev_heap_ptr;
}
