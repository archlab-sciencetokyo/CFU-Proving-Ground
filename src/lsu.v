module lsu (
    input  wire         clk_i,
    input  wire         cmd_valid_i,
    output wire         cmd_ready_o,
    input  wire  [31:0] cmd_addr_i,
    input  wire  [31:0] cmd_data_i,
    input  wire         cmd_we_i,
    input  wire   [3:0] cmd_wdata_we_i,
    output wire  [23:0] litedram_cmd_addr_o,
    input  wire         litedram_cmd_ready_i,
    output wire         litedram_cmd_valid_o,
    output wire         litedram_cmd_we_o,
    input  wire [127:0] litedram_rdata_data_i,
    output wire         litedram_rdata_ready_o,
    input  wire         litedram_rdata_valid_i,
    output wire [127:0] litedram_wdata_data_o,
    input  wire         litedram_wdata_ready_i,
    output wire         litedram_wdata_valid_o,
    output wire  [15:0] litedram_wdata_we_o,
    output wire         rsp_valid_o,
    input  wire         rsp_ready_i,
    output wire  [31:0] rsp_data_o
);
    reg  [31:0] cmd_data             = 0;
    reg  [15:0] cmd_addr_offset      = 0;
    reg         cmd_we               = 0;
    reg  [23:0] litedram_cmd_addr    = 0;
    reg         litedram_cmd_we      = 0;
    reg         litedram_rdata_ready = 0;
    reg [127:0] litedram_wdata_data  = 0;
    reg  [15:0] litedram_wdata_we    = 0;
    reg  [31:0] rsp_data             = 0;

    localparam LSU_STATE_IDLE     = 3'b000;
    localparam LSU_STATE_CMD_SEND = 3'b001;
    localparam LSU_STATE_WRITE    = 3'b010;
    localparam LSU_STATE_READ     = 3'b011;
    localparam LSU_STATE_RSP      = 3'b100;
    reg [2:0] lsu_state = LSU_STATE_IDLE;
    always @(posedge clk_i) begin
        case(lsu_state)
            LSU_STATE_IDLE: if (cmd_valid_i) begin
                litedram_cmd_addr      <= cmd_addr_i[27:4];
                litedram_wdata_we[3:0] <= cmd_wdata_we_i;
                litedram_cmd_we        <= cmd_we_i;
                litedram_wdata_data    <= cmd_data_i;
                cmd_addr_offset[3:0]   <= cmd_addr_i[3:0];
                lsu_state              <= LSU_STATE_CMD_SEND;
            end
            LSU_STATE_CMD_SEND: if (litedram_cmd_ready_i) begin
                litedram_cmd_we     <= 1'b0;
                litedram_cmd_addr   <= 24'b0;
                litedram_wdata_we   <= litedram_wdata_we << cmd_addr_offset;
                litedram_wdata_data <= litedram_wdata_data << (cmd_addr_offset << 3);
                cmd_addr_offset     <= cmd_addr_offset << 3;
                lsu_state           <= (litedram_cmd_we) ? LSU_STATE_WRITE : LSU_STATE_READ;
            end
            LSU_STATE_WRITE: if (litedram_wdata_ready_i) begin
                litedram_wdata_data <= 128'b0;
                litedram_wdata_we   <= 16'b0;
                cmd_addr_offset     <= 16'b0;
                lsu_state           <= LSU_STATE_RSP;
            end
            LSU_STATE_READ: if (litedram_rdata_valid_i) begin
                rsp_data            <= (litedram_rdata_data_i >> cmd_addr_offset);
                litedram_wdata_data <= 128'b0;
                litedram_wdata_we   <= 16'b0;
                cmd_addr_offset     <= 16'b0;
                lsu_state           <= LSU_STATE_RSP;
            end
            LSU_STATE_RSP: if (rsp_ready_i) begin
                rsp_data  <= 32'b0;
                lsu_state <= LSU_STATE_IDLE;
            end
            default: lsu_state <= LSU_STATE_IDLE;
        endcase
    end

    assign cmd_ready_o            = (lsu_state == LSU_STATE_IDLE);
    assign litedram_cmd_addr_o    = litedram_cmd_addr;
    assign litedram_cmd_valid_o   = (lsu_state == LSU_STATE_CMD_SEND);
    assign litedram_cmd_we_o      = litedram_cmd_we;
    assign litedram_rdata_ready_o = (lsu_state == LSU_STATE_READ);
    assign litedram_wdata_data_o  = litedram_wdata_data;
    assign litedram_wdata_valid_o = (lsu_state == LSU_STATE_WRITE);
    assign litedram_wdata_we_o    = litedram_wdata_we;
    assign rsp_valid_o            = (lsu_state == LSU_STATE_RSP);
    assign rsp_data_o             = rsp_data;
endmodule
