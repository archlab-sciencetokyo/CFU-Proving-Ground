#include "st7789.h"

void perf_enable(void) {
    volatile uint8_t *reg_pref_enable = (volatile uint8_t *)0x20000000;
    *reg_pref_enable = 1;
}

void perf_disable(void) {
    volatile uint8_t *reg_pref_enable = (volatile uint8_t *)0x20000000;
    *reg_pref_enable = 0;
}

void perf_reset(void) {
    volatile uint8_t *reg_pref_reset = (volatile uint8_t *)0x20000001;
    *reg_pref_reset = 1;
    asm volatile("nop");
}

inline void cfu_init(int x) {
    asm volatile("nq.init zero, %0, zero"::"r"(x));
}
inline uint32_t cfu_exec() {
    uint32_t ret;
    asm volatile("nq.exec %0, zero, zero":"=r"(ret));
    return ret;
}
inline uint32_t cfu_get_ret(void){
    uint32_t ret;
    asm volatile("nq.ret %0, zero, zero":"=r"(ret));
    return ret;
}

uint64_t get_cycle(void) {
    return *(uint64_t *)0x20000008 << 32 | *(uint64_t *)0x20000004;
}
uint64_t get_instret(void) {
    return *(uint64_t *)0x20000010 << 32 | *(uint64_t *)0x2000000C;
}

#define N 17
uint64_t cycle_hw = 0;
uint64_t cycle_sw = 0;
void hw_qn(){
    int i;
    long long answers = 0;

    int h = 0;
    int r = 0;
    int ret = 0;

    perf_enable();
    for(i=0; i<(N/2+N%2); i++){
        cfu_init(i);
        while(cfu_exec());
        ret = cfu_get_ret();
        answers += ret;
        if(i!=N/2) answers += ret;
    }
    perf_disable();
  
    st7789_printf("hw_nq=%d\n", (int)answers);
    cycle_hw = get_cycle();
    st7789_printf("cyc %llu\n", cycle_hw);
    st7789_printf("ret %llu\n", get_instret());
}
/*****************************************************************************/

/**** N-queens since 2003-10   by Kenji KISE ****/
/**** N-queens Simple Version in C           ****/
/************************************************/

/************************************************/
#define NAME "qn24b base"
#define VER  "version 1.0.1 2004-09-02"
#define MAX 29 /** 32 is a real max! **/
#define MIN 2

/************************************************/
typedef struct array_t{
  unsigned int cdt; /* candidates        */
  unsigned int col; /* column            */
  unsigned int pos; /* positive diagonal */
  unsigned int neg; /* negative diagonal */
} array;

/** N-queens kernel                            **/
/** n: problem size, h: height, r: row         **/
/************************************************/
long long qn(int n, int h, int r, array *a){
  long long answers = 0;

  for(;;){
    if(r){
      int lsb = (-r) & r;
      a[h+1].cdt = (       r & ~lsb);
      a[h+1].col = (a[h].col & ~lsb);
      a[h+1].pos = (a[h].pos |  lsb) << 1;
      a[h+1].neg = (a[h].neg |  lsb) >> 1;
      
      r = a[h+1].col & ~(a[h+1].pos | a[h+1].neg);
      h++;
    }
    else{
      r = a[h].cdt;
      h--;

      if(h==0) break;
      if(h==n) answers++;
    }
  }
  return answers;
}

/** main function                              **/
/************************************************/
void sw_qn(){
  int i;
  int n    = N;
  array a[MAX];
  long long answers = 0;

  perf_reset();
  perf_enable();
  for(i=0; i<(n/2+n%2); i++){
    long long ret;
    int h = 1;      /* height or level  */
    int r = 1 << i; /* candidate vector */
    a[h].col = (1<<n)-1;
    a[h].pos = 0;
    a[h].neg = 0;

    ret = qn(n, h, r, a); /* kernel loop */

    answers += ret;
    if(i!=n/2) answers += ret;
  }
  perf_disable();

  st7789_printf("\nsw_nq = %d\n", (int)answers);
  cycle_sw =  get_cycle();
  st7789_printf("cyc %llu\n", cycle_sw);
  st7789_printf("ret %llu\n", get_instret());
}
/************************************************/

int main(void)
{
    st7789_reset();
    st7789_printf("--nqueen\nn=%d\n\n", N);
    hw_qn();
    sw_qn();
    st7789_printf("\n--spedup\n%f\n", (float)cycle_sw / cycle_hw);
    return 0;
}
/*****************************************************************************/
