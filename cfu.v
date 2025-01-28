`include "config.vh"
`define MAX 31
`define MIN 2
`define N   10

module cfu (
    input  wire                       clk_i     ,
    input  wire                       rst_i     ,
    input  wire                       stall_i   ,
    input  wire                       valid_i   ,
    input  wire [`CFU_CTRL_WIDTH-1:0] cfu_ctrl_i,
    input  wire           [`XLEN-1:0] src1_i    ,
    input  wire           [`XLEN-1:0] src2_i    ,
    output wire                       stall_o   ,
    output wire           [`XLEN-1:0] rslt_o
);
    assign stall_o = 0;
 
    assign rslt_o = (cfu_ctrl_i[0]) ? 1 : 0;
endmodule
