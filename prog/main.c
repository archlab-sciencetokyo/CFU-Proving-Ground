#include "st7789.h"
#include "perf.h"
#include "cfu.h"

#include <stdio.h>
#include <stdlib.h>

#define MAX 29 /** 32 is a real max! **/
#define N 12

typedef struct array_t{
  unsigned int cdt; /* candidates        */
  unsigned int col; /* column            */
  unsigned int pos; /* positive diagonal */
  unsigned int neg; /* negative diagonal */
} array;

int n;
int h;
int r;
array a[MAX];
long long answers;

int cfu_exec() {
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

      if(h==0) return 0;
      if(h==n) answers++;
    }
    return 1;
}

int cfu_ret() {
  return answers;
}

long long qn(){
  for(;;){
    if(!cfu_exec()) break;
  }
    
  return cfu_ret();
}

void cfu_init(int i) {
    h = 1;      /* height or level  */
    r = 1 << i; /* candidate vector */
    a[h].col = (1<<n)-1;
    a[h].pos = 0;
    a[h].neg = 0;
    answers = 0;
}

int main(int argc, char *argv[]){

  int i;
  n = N;
  long long ans = 0;
  
  for(i=0; i<(n/2+n%2); i++){
    long long ret;
    cfu_init(i);

    ret = qn(); /* kernel loop */

    ans += ret;
    if(i!=n/2) ans += ret;
  }

  st7789_printf("NQ(%d)=%llu\n", n, ans);
  return 0;
}
/************************************************/
