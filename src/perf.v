module perf (
    input  wire        clk_i,
    input  wire        cmd_valid_i,
    output wire        cmd_ready_o,
    input  wire  [3:0] cmd_addr_i,
    input  wire        cmd_data_i,
    output wire        rsp_valid_o,
    input  wire        rsp_ready_i,
    output wire [31:0] rsp_data_o
);
// 0: cycle count rst
// 4: cycle count enable
// 8: cycle count value (low 32bit)
// C: cycle count value (high 32bit)
    reg  [3:0] cmd_addr    = 0;
    reg        cmd_data    = 0;
    reg [31:0] rsp_data    = 0;
    reg [63:0] cycle_count = 0;
    reg        cycle_en    = 0;
    reg        cycle_rst_n = 0;

    localparam PERF_STATE_IDLE = 0;
    localparam PERF_STATE_CMD  = 1;
    localparam PERF_STATE_RSP  = 2;
    reg [1:0] perf_state = PERF_STATE_IDLE;
    always @(posedge clk_i) begin
        case(perf_state)
            PERF_STATE_IDLE: if (cmd_valid_i) begin
                cmd_addr    <= cmd_addr_i;
                cmd_data    <= cmd_data_i;
                perf_state  <= PERF_STATE_CMD;
            end
            PERF_STATE_CMD: begin
                if (cmd_addr == 0) cycle_rst_n <= 0;
                if (cmd_addr == 4) cycle_en    <= cmd_data;
                if (cmd_addr == 8) rsp_data    <= cycle_count[31:0];
                else if (cmd_addr == 12) rsp_data <= cycle_count[63:32];
                perf_state <= PERF_STATE_RSP;
            end
            PERF_STATE_RSP: if (rsp_ready_i) begin
                rsp_data    <= 0;
                cycle_rst_n <= 1;
                perf_state  <= PERF_STATE_IDLE;
            end
        endcase
    end

    always @(posedge clk_i) begin
        cycle_count <= (~cycle_rst_n) ? 0
                     : (cycle_en)     ? cycle_count + 1
                     : cycle_count;
    end

    assign cmd_ready_o = (perf_state == PERF_STATE_IDLE);
    assign rsp_valid_o = (perf_state == PERF_STATE_RSP);
    assign rsp_data_o  = rsp_data;
endmodule
