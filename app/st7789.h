#include <stdint.h>
#include <stdarg.h>

void draw_point(uint16_t x, uint16_t y, uint16_t color);
void draw_char(uint16_t x, uint16_t y, char c, uint16_t color, int scale);
void LCD_prints(const char *str);
void st7789_reset();
void st7789_set_pos(int x, int y);
