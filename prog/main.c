#include <stdlib.h>

#include "font.h"

#define UART_RX_ADDR 0xF0001004

void perf_reset() { *(volatile char *)(0xF0002000) = 1; }
void perf_start() { *(volatile char *)(0xF0002004) = 1; }
void perf_stop() { *(volatile char *)(0xF0002004) = 0; }
unsigned long long perf_read() {
    unsigned int low = *(volatile unsigned int *)(0xF0002008);
    unsigned int high = *(volatile unsigned int *)(0xF000200C);
    return ((unsigned long long)high << 32) | low;
}

void pg_lcd_draw_point(int x, int y, char color) {
    *(volatile char *)(0x80000000 + y * 256 + x) = color;
}

void pg_lcd_draw_char(int x, int y, char c, char color, int scale) {
    for (int i = 0; i < (8 << scale); i++) {
        if (y + i >= 240) break;
        for (int j = 0; j < (8 << scale); j++) {
            if (x + j >= 240) break;
            if ((font8x8_basic[c][i >> scale] >> (j >> scale)) & 1) {
                pg_lcd_draw_point(x + j, y + i, color);
            } else {
                pg_lcd_draw_point(x + j, y + i, 0);
            }
        }
    }
}

void RandomChar() {
    while (1) {
        char c = 'A' + rand() % 26;
        pg_lcd_draw_char(rand() % 240, rand() % 240, c, rand() & 0x7, 1);
    }
}

int main () {
    volatile char *dram = (volatile char *)0x20000000;
    volatile int *led = (volatile int *)0xF0000000;

    led[0] = 1;
    for (int i = 0; i < 3072; i++) {
        char data = *(volatile char *)UART_RX_ADDR;
        dram[i] = data;
    }
    led[1] = 1;

    RandomChar();
    return 0;
}
