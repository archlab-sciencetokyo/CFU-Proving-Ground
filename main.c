/********************************************************************************/
#include <cstdint>
#include <cmath>
#include <stdio.h>
#include "st7789.h"
#include "perf.h"

enum class Direction : uint8_t {
    UP = 0,
    RIGHT = 1,
    DOWN = 2,
    LEFT = 3
};

char buffer[13];
uint64_t count = 0;
static uint32_t map[256][8];
void LangtonAnt (uint8_t x, uint8_t y, Direction dir) {
    for (int i = 0; i < 256; i++) {
        for (int j = 0; j < 8; j++) {
            map[i][j] = false;
        }
    }
    uint8_t pos_x = x;
    uint8_t pos_y = y;
    uint32_t count = 0;
    st7789_set_pos(0, 14);
    while (true) {
        if (!(map[pos_y][pos_x >> 5] & (1 << (pos_x & 0x1F)))) {
            map[pos_y][pos_x >> 5] |= (1 << (pos_x & 0x1F));
            draw_point(pos_x, pos_y, 0x4); // Draw point with color 0x4
            dir = static_cast<Direction>((static_cast<uint8_t>(dir) + 1) % 4);
        } else {
            map[pos_y][pos_x >> 5] &= ~(1 << (pos_x & 0x1F));
            draw_point(pos_x, pos_y, 0x0); // Draw point with color 0xF
            dir = static_cast<Direction>((static_cast<uint8_t>(dir) + 3) % 4);
        }
        switch (dir) {
            case Direction::UP:
            pos_y--;
            break;
            case Direction::RIGHT:
            pos_x++;
            break;
            case Direction::DOWN:
            pos_y++;
            break;
            case Direction::LEFT:
            pos_x--;
            break;
        }
        
        sprintf(buffer, "steps :%6d\r", count);
        LCD_prints(buffer);
        count++;
    }
}

void RandomChar() {
    int count = 0;
    st7789_set_pos(0, 14);
    while (true) {
        count++;
        char c = 'A' + rand() % 26;
        draw_char(rand() % 240, rand() % 240, c, rand() & 0x7, 1);
        sprintf(buffer, "steps :%6d\r", count);
        LCD_prints(buffer);
    }
}

int main () {
    st7789_reset();
    // LangtonAnt(120, 120, Direction::UP);
    RandomChar();
    while (1);
    return 0;
}