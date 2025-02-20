`include "config.vh"

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
    wire [2:0] funct3 = cfu_ctrl_i[2:0];
    wire [6:0] funct7 = cfu_ctrl_i[9:3];

    assign rslt_o = (funct3 == 1) ? src1_i + src2_i :
                    (funct3 == 2) ? src1_i - src2_i : 0;
endmodule

