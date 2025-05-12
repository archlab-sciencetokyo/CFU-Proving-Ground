#include <stdbool.h>

void cfu(
    bool   clk_i   ,
    bool   en_i    ,
    char   funct3_i,
    char   funct7_i,
    int    src1_i  ,
    int    src2_i  ,
    bool*  stall_o ,
    int*   rslt_o  ) {

#pragma HLS INTERFACE ap_ctrl_none port=return
#pragma HLS INTERFACE ap_none port=stall_o
#pragma HLS INTERFACE ap_none port=rslt_o

    *stall_o = 0;

    if (en_i) {
        *rslt_o = src1_i | src2_i;
    } else {
        *rslt_o = 0;
    }
}
