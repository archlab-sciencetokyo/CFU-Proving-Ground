#include <math.h>
#include "st7789.h"
#include "util.h"
#include "perf.h"

#define M_PI		3.14159265358979323846	/* pi */

#define SAMPLE_RATE 44100
#define SIN_FREQ 440

#define FFT_POINT   1024
#define FFT_POINT_2 512
#define FFT_STAGES  10

static float W_N[2*FFT_POINT];
static float f[2*FFT_POINT];

#define VERIFY_RESULTS 1
static float f_verif[2*FFT_POINT];

void fft(float *f)
{
    int block_offset = 2;
    int butterflies_offset = 1;

    for (int cnt_stages = 0; cnt_stages < FFT_STAGES; ++cnt_stages) {
        for (int cnt_blocks = 0; cnt_blocks < (FFT_POINT_2 >> cnt_stages); ++cnt_blocks) {
            int idx_blocks = cnt_blocks * block_offset;
            int cnt_twiddle = 0;
            for (int cnt_butterflies = 0; cnt_butterflies < (1 << cnt_stages); ++cnt_butterflies) {
                int idx_upper = idx_blocks + cnt_butterflies;
                int idx_lower = idx_upper + butterflies_offset;

                float temp_var1 = f[(idx_lower<<1)]   * W_N[(cnt_twiddle<<1)]  ;
                float temp_var2 = f[(idx_lower<<1)+1] * W_N[(cnt_twiddle<<1)+1];
                float temp_var3 = f[(idx_lower<<1)]   * W_N[(cnt_twiddle<<1)+1];
                float temp_var4 = f[(idx_lower<<1)+1] * W_N[(cnt_twiddle<<1)]  ;
                float temp_var1_2 = temp_var1 - temp_var2;
                float temp_var3_4 = temp_var3 + temp_var4;

                float real = f[(idx_upper<<1)];
                float imag = f[(idx_upper<<1)+1];

                f[(idx_upper<<1)]   = real + temp_var1_2;
                f[(idx_upper<<1)+1] = imag + temp_var3_4;
                f[(idx_lower<<1)]   = real - temp_var1_2;
                f[(idx_lower<<1)+1] = imag - temp_var3_4;

                cnt_twiddle += (FFT_POINT_2 >> cnt_stages);
            }
        }

        block_offset <<= 1;
        butterflies_offset <<= 1;
    }
}

void init_W_N()
{
    int i_start = 0;
    int i_end = FFT_POINT;
    for (int i = i_start; i < i_end; i++) {
        W_N[(i<<1)]   = cosf(-2.0 * M_PI * i / FFT_POINT);
        W_N[(i<<1)+1] = sinf(-2.0 * M_PI * i / FFT_POINT);
    }
}

void init_f(float* f)
{
    float t;
    int i_start = 0;
    int i_end = FFT_POINT;
    for (int i = i_start; i < i_end; i++) {
        t = 1.0 * i / SAMPLE_RATE;
        f[(i<<1)] = sinf(2.0 * M_PI * SIN_FREQ * t);
        f[(i<<1)+1] = 0;
    }
}

void do_bit_reversal(float* f)
{
    int i_start = 0;
    int i_end = FFT_POINT;
    int j;
    float tmp;
    for (int i = i_start; i < i_end; i++) {
        j = ((i & 0xFF00) >> 8) | ((i & 0x00FF) << 8);
        j = ((j & 0xF0F0) >> 4) | ((j & 0x0F0F) << 4);
        j = ((j & 0xCCCC) >> 2) | ((j & 0x3333) << 2);
        j = ((j & 0xAAAA) >> 1) | ((j & 0x5555) << 1);
        j >>= (16 - FFT_STAGES);

        if (i < j) {
            tmp = f[i<<1];
            f[i<<1] = f[j<<1];
            f[j<<1] = tmp;

            tmp = f[(i<<1)+1];
            f[(i<<1)+1] = f[(j<<1)+1];
            f[(j<<1)+1] = tmp;
        }
    }
}

unsigned long long start_measurement()
{
    unsigned long long start;
    pg_perf_reset();
    start = pg_perf_cycle();
    pg_perf_enable();
    return start;
}

unsigned long long end_measurement()
{
    unsigned long long end;
    pg_perf_disable();
    end = pg_perf_cycle();
    return end;
}

int main ()
{
    init_W_N();
    init_f(f);

    unsigned long long start = start_measurement();

    do_bit_reversal(f);

    fft(f);

    unsigned long long end = end_measurement();
    unsigned long long cycles = end - start;
    pg_prints("FFT cycles:\n");
    pg_printd(cycles);
    pg_prints("\n");

    return 0;
}
