/* CFU Proving Ground since 2025-02    Copyright(c) 2025 Archlab. Science Tokyo /
/ Released under the MIT license https://opensource.org/licenses/mit           */

`include "config.vh"

`ifndef USE_HLS

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
    assign rslt_o  = (en_i) ? src1_i | src2_i : 0;
endmodule

`else

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

    reg cfu_en = 0; always @(posedge clk_i) cfu_en <= (ap_ready) ? 0 : ap_start;
    wire ap_start = en_i || cfu_en;
    wire ap_done;
    wire ap_idle;
    wire ap_ready;
    wire [31:0] rslt;
    cfu_hls cfu_hls (
        .ap_clk         (clk_i          ),
        .ap_start       (ap_start       ),
        .ap_done        (ap_done        ),
        .ap_idle        (ap_idle        ),
        .ap_ready       (ap_ready       ),
        .funct3_i       (funct3_i       ),
        .funct7_i       (funct7_i       ),
        .src1_i         (src1_i         ),
        .src2_i         (src2_i         ),
        .rslt_o         (rslt           )
    );
    assign stall_o = !ap_idle && !ap_done;
    assign rslt_o = (ap_start) ? rslt : 0;
endmodule

`endif
