/* CFU Proving Ground since 2025-02    Copyright(c) 2025 Archlab. Science Tokyo /
/ Released under the MIT license https://opensource.org/licenses/mit           */

#define PG_BLACK    0
#define PG_BLUE     1
#define PG_GREEN    2
#define PG_CYAN     3
#define PG_RED      4
#define PG_PURPLE   5
#define PG_YELLOW   6
#define PG_WHITE    7

void pg_lcd_draw_point(int x, int y, char color);
void pg_lcd_draw_char(int x,  int y, char c, char color, int scale);
void pg_lcd_fill(char color);
void pg_lcd_reset();
void pg_lcd_printd(long long x);
void pg_lcd_printh(unsigned int x);
void pg_lcd_prints(const char *str);
void pg_lcd_set_pos(int x, int y);
void pg_lcd_prints_8x8(const char *str);
