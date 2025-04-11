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

    always @(posedge clk_i) begin
        rslt_o <= (en_i) ? src1_i + src2_i : 0;
    end
    assign stall_o = 0;
endmodule
