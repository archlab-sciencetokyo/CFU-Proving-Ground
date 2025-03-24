/********************************************************************************/
#include <cstdint>
#include <cmath>
#include <stdio.h>
#include "st7789.h"
#include "perf.h"

void RandomChar() {
    int count = 0;
    st7789_set_pos(0, 14);
    while (true) {
        count++;
        char c = 'A' + rand() % 26;
        draw_char(rand() % 240, rand() % 240, c, rand() & 0x7, 1);
        char buffer[13];
        sprintf(buffer, "steps :%6d\r", count);
        LCD_prints(buffer);
    }
}

int main () {
    st7789_reset();
    RandomChar();
    return 0;
}
