module cfu (
    input  wire        ap_clk  ,
    input  wire        ap_start,
    output wire        ap_done ,
    output wire        ap_idle ,
    output wire        ap_ready,
    input  wire [2:0]  funct3_i,
    input  wire [6:0]  funct7_i,
    input  wire [31:0] src1_i  ,
    input  wire [31:0] src2_i  ,
    output wire [31:0] rslt_o
);

    assign ap_done = ap_start;
    assign ap_idle = 1'b1;
    assign ap_ready = ap_start;

    assign rslt_o = src1_i | src2_i;

endmodule