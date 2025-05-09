/* CFU Proving Ground since 2025-02    Copyright(c) 2025 Archlab. Science Tokyo /
/ Released under the MIT license https://opensource.org/licenses/mit           */

`include "config.vh"

module cfu_add (
    input  wire        clk_i,
    input  wire        en_i,
    input  wire [31:0] src1_i,
    input  wire [31:0] src2_i,
    output wire        stall_o,
    output wire [31:0] rslt_o
);
    assign stall_o = 0;
    assign rslt_o = en_i ? (src1_i + src2_i) : 0;
endmodule

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
    // Operation definitions
    localparam OP_ADD = 3'b000;

    reg op_en_add = 0;

    wire stall_add;

    wire [31:0] rslt_add;
    
    cfu_add add_unit (
        .clk_i(clk_i),
        .en_i(op_en_add),
        .src1_i(src1_i),
        .src2_i(src2_i),
        .stall_o(stall_add),
        .rslt_o(rslt_add)
    );
    
    // input selection logic
    always @(*) begin
        op_en_add = 0; // Default disable

        if (en_i) begin
            case (funct3_i)
                OP_ADD: op_en_add = 1;
                default: begin end
            endcase
        end
    end
    
    // output selection logic
    reg [31:0] result_mux;
    always @(*) begin
        case (funct3_i)
            OP_ADD: result_mux = rslt_add;
            default: result_mux = 32'h0;
        endcase
    end
    
    assign rslt_o = result_mux;
    assign stall_o = (funct3_i == OP_ADD) ? stall_add : 0;
endmodule

