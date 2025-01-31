#include "st7789.h"
#include "perf.h"

int main () {
    st7789_reset();
    st7789_printf("Hello, World!\n");
    return 0;
}
