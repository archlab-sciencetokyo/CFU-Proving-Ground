void cfu_hls(
    char   funct3_i,
    char   funct7_i,
    int    src1_i  ,
    int    src2_i  ,
    int*   rslt_o  ) {

    *rslt_o = src1_i | src2_i;
}
