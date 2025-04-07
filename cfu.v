/* CFU Proving Ground since 2025-02    Copyright(c) 2025 Archlab. Science Tokyo /
/ Released under the MIT license https://opensource.org/licenses/mit           */

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
    output reg            [`XLEN-1:0] rslt_o
);

    wire       cmd_valid = valid_i && cfu_ctrl_i[`CFU_CTRL_IS_CFU];
    wire [2:0] funct3 = cfu_ctrl_i[3:1];
    wire [6:0] funct7 = cfu_ctrl_i[10:4];

    reg state = 0;
    assign stall_o = state;

    reg [2:0] cnt = 0;
    always @(posedge clk_i) begin
        if (funct3 == 0 && cmd_valid) state <= 1;
        else if (state == 1 && cnt == 7) state <= 0;

        if (state == 1) cnt <= cnt + 1;
    end

endmodule

