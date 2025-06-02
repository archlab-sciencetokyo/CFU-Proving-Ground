/********************************************************************************/
/***** 240x240 ST7789 mini display project  Ver.2024-12-21a                 *****/
/***** Copyright (c) 2024 Archlab. Science Tokyo                            *****/
/***** Released under the MIT license https://opensource.org/licenses/mit   *****/
/********************************************************************************/

#include "st7789.h"

#define X_PIX     240 // display width
#define Y_PIX     240 // display height
#define ITER_MAX  256 // max iteration of mandelbrot

/********************************************************************************/
float x_min = 0.270851;
float x_max = 0.270900;
float y_min = 0.004641;
float y_max = 0.004713;

/********************************************************************************/
void draw_pixel(int x, int y, int k)
{
    int color = ((k & 0x7f) << 11) ^ ((k & 0x7f) << 7) ^ (k & 0x7f);
    int addr = ((x << 8) & 0xFF00) | (y & 0xFF);
    pg_lcd_draw_point(x, y, color);
}

static inline unsigned int cfu_op(unsigned int funct7, unsigned int funct3, 
                                unsigned int rs1, unsigned int rs2, unsigned int* rd) {
    unsigned int result;
    asm volatile(
        ".insn r CUSTOM_0, %3, %4, %0, %1, %2"
        : "=r"(result)
        : "r"(rs1), "r"(rs2), "i"(funct3), "i"(funct7)
        :
    );
    *rd = result;
}

/********************************************************************************/
void cfu_hls();
void mandelbrot()
{
    while (1) {
        y_min += 0.00000010;
        x_min += 0.00000010;
        float dx = (x_max - x_min) / X_PIX;
        float dy = (y_max - y_min) / Y_PIX;
        for (int j = 1; j <= Y_PIX; j++) {
            float y = y_min + j * dy;
            for(int i = 1; i <= X_PIX; i++) {
                int k;
                float x = x_min + i * dx;
                int src1; src1 = *((int *)&x);
                int src2; src2 = *((int *)&y);
                //cfu_hls(0, 0, src1, src2, &k);
                cfu_op(0, 0, src1, src2, &k);
                draw_pixel(i, j, k);
            }
        }
    }
}

/********************************************************************************/
int main()
{
    mandelbrot();
    return 0;
}
/********************************************************************************/
