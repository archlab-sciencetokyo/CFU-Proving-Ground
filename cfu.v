/* CFU Proving Ground since 2025-02    Copyright(c) 2025 Archlab. Science Tokyo /
/ Released under the MIT license https://opensource.org/licenses/mit           */

`include "config.vh"


module cfu (
    input  wire        clk_i,
    input  wire        en_i,
    input  wire [ 2:0] funct3_i,
    input  wire [ 6:0] funct7_i,
    input  wire [31:0] src1_i,
    input  wire [31:0] src2_i,
    output wire        stall_o,
    output reg  [31:0] rslt_o
);

    reg [31:0] r_src1 = 0, r_src2 = 0;
    reg r_en = 0;
    always @(posedge clk_i) begin
        r_en <= en_i;
        r_src1 <= src1_i;
        r_src2 <= src2_i;
        rslt_o <= (r_en) ? r_src1 + r_src2 : 0;
    end
    assign stall_o = r_en;
endmodule

/*
module cfu (
    input  wire        clk_i,
    input  wire        en_i,
    input  wire [ 2:0] funct3_i,
    input  wire [ 6:0] funct7_i,
    input  wire [31:0] src1_i,
    input  wire [31:0] src2_i,
    output wire        stall_o,
    output wire [31:0] rslt_o
);
    assign stall_o = 0;
    assign rslt_o = 0;
endmodule
*/
