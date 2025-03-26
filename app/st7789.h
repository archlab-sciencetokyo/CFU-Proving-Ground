#define PG_BLACK    0
#define PG_RED      1
#define PG_GREEN    2
#define PG_BLUE     3
#define PG_YELLOW   4
#define PG_PURPLE   5
#define PG_CYAN     6
#define PG_WHITE    7

void pg_lcd_draw_point(int x, int y, char color);
void pg_lcd_draw_char(int x,  int y, char c, char color, int scale);
void pg_lcd_fill(char color);
void pg_lcd_reset();
void pg_lcd_printd(int x);
void pg_lcd_printh(int x);
void pg_lcd_prints(const char *str);
void pg_lcd_set_pos(int x, int y);
