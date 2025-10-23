/* CFU Proving Ground since 2025-02    Copyright(c) 2025 Archlab. Science Tokyo /
/ Released under the MIT license https://opensource.org/licenses/mit           */

#include <stdlib.h>

#include "st7789.h"
#include "perf.h"
#include "util.h"

void RandomChar() {
    int count = 0;
    while (1) {
        count++;
        char c = 'A' + rand() % 26;
        pg_lcd_draw_char(rand() % 240, rand() % 240, c, rand() & 0x7, 1);
        pg_lcd_set_pos(0, 14);
        pg_lcd_prints("steps :");
        pg_lcd_printd(count);
    }
}

int main () {
    pg_lcd_reset();
    RandomChar();
    return 0;
}
