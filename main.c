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

class Ant {
public:
    char pos_x;
    char pos_y;
    Direction dir;

    Ant(char x, char y, Direction d) : pos_x(x), pos_y(y), dir(d) {}

    void move() {
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
    }
    void turn(bool right) {
        dir = static_cast<Direction>((static_cast<uint8_t>(dir) + (right ? 1 : 3)) % 4);
    }
    uint8_t get_x() const {
        return pos_x;
    }
    uint8_t get_y() const {
        return pos_y;
    }
    Direction get_dir() const {
        return dir;
    }
};

char buffer[13];
uint64_t count = 0;
static uint32_t map[256][8];
void LangtonAnt () {
    st7789_set_pos(0, 14);
    for (int i = 0; i < 256; i++) {
        for (int j = 0; j < 8; j++) {
            map[i][j] = false;
        }
    }
    
    Ant A(110, 110, Direction::DOWN);
    Ant B(130, 130, Direction::UP);

    while (true) {
        if (map[A.get_y()][A.get_x() >> 5] & (1 << (A.get_x() & 0x1F))) {
            map[A.get_y()][A.get_x() >> 5] &= ~(1 << (A.get_x() & 0x1F));
            draw_point(A.get_x(), A.get_y(), 0x0); // Draw point with color 0xF
            A.turn(true);
        } else {
            map[A.get_y()][A.get_x() >> 5] |= (1 << (A.get_x() & 0x1F));
            draw_point(A.get_x(), A.get_y(), 0x5); // Draw point with color 0x4
            A.turn(false);
        }
        
        if (map[B.get_y()][B.get_x() >> 5] & (1 << (B.get_x() & 0x1F))) {
            map[B.get_y()][B.get_x() >> 5] &= ~(1 << (B.get_x() & 0x1F));
            draw_point(B.get_x(), B.get_y(), 0x0); // Draw point with color 0x4
            B.turn(true);
        } else {
            map[B.get_y()][B.get_x() >> 5] |= (1 << (B.get_x() & 0x1F));
            draw_point(B.get_x(), B.get_y(), 0x3); // Draw point with color 0xF
            B.turn(false);
        }
        A.move();
        B.move();
//        if (!(map[pos_y][pos_x >> 5] & (1 << (pos_x & 0x1F)))) {
//            map[pos_y][pos_x >> 5] |= (1 << (pos_x & 0x1F));
//            draw_point(pos_x, pos_y, 0x4); // Draw point with color 0x4
//            dir = static_cast<Direction>((static_cast<uint8_t>(dir) + 1) % 4);
//        } else {
//            map[pos_y][pos_x >> 5] &= ~(1 << (pos_x & 0x1F));
//            draw_point(pos_x, pos_y, 0x0); // Draw point with color 0xF
//            dir = static_cast<Direction>((static_cast<uint8_t>(dir) + 3) % 4);
//        }
        
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
    // LangtonAnt();
    RandomChar();
    while (1);
    return 0;
}
