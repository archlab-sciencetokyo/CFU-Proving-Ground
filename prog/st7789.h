#include <stdint.h>
#include <stdarg.h>

void draw_point(uint16_t x, uint16_t y, uint16_t color);
void draw_char(uint16_t x, uint16_t y, char c, uint16_t color, int scale);
uint16_t hue_to_color(float h);
void st7789_printf(const char *fmt, ...);
void st7789_reset();
