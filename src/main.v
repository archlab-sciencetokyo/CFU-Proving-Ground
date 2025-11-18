module main(
    input  wire          clk100,
    output wire   [13:0] ddram_a,
    output wire    [2:0] ddram_ba,
    output wire          ddram_cas_n,
    output wire          ddram_cke,
    output wire          ddram_clk_n,
    output wire          ddram_clk_p,
    output wire          ddram_cs_n,
    output wire    [1:0] ddram_dm,
    inout  wire   [15:0] ddram_dq,
    inout  wire    [1:0] ddram_dqs_n,
    inout  wire    [1:0] ddram_dqs_p,
    output wire          ddram_odt,
    output wire          ddram_ras_n,
    output wire          ddram_reset_n,
    output wire          ddram_we_n,
    output wire          serial_tx,
    output wire          user_led0,
    output wire          user_led1,
    output wire          user_led2,
    output wire          user_led3,
    output wire          st7789_SDA,
    output wire          st7789_SCL,
    output wire          st7789_DC,
    output wire          st7789_RES,
    input  wire          uart_rxd
);

//==============================================================================
// RV32I Processor
//------------------------------------------------------------------------------
    wire        sys_clk;
    wire        sys_rst;
    wire        proc_cmd_we;
    wire [31:0] proc_cmd_addr;
    wire        proc_cmd_valid;
    wire        proc_cmd_ack;
    wire [31:0] proc_read_data;
    wire [31:0] proc_write_data;
    wire  [3:0] proc_write_en;
    rv32i proc (
        .clk_i             (sys_clk),
        .dbus_cmd_addr_o   (proc_cmd_addr),
        .dbus_cmd_we_o     (proc_cmd_we),
        .dbus_cmd_valid_o  (proc_cmd_valid),
        .dbus_cmd_ack_i    (proc_cmd_ack),
        .dbus_read_data_i  (proc_read_data),
        .dbus_write_data_o (proc_write_data),
        .dbus_write_en_o   (proc_write_en)
    );

//==============================================================================
// 0x10000000 - 0x10002000: DRAM
//------------------------------------------------------------------------------
    wire [31:0] dram_cmd_addr;
    wire        dram_cmd_we;
    wire        dram_cmd_valid;
    wire        dram_cmd_ack;
    wire [31:0] dram_read_data;
    wire [31:0] dram_write_data;
    wire  [3:0] dram_write_en;
    dram dram(
        .sys_clk      (sys_clk),
        .cmd_addr_i   (dram_cmd_addr),
        .cmd_we_i     (dram_cmd_we),
        .cmd_valid_i  (dram_cmd_valid),
        .cmd_ack_o    (dram_cmd_ack),
        .read_data_o  (dram_read_data),
        .write_data_i (dram_write_data),
        .write_en_i   (dram_write_en)
    );

//==============================================================================
// 0x20000000 - 0x30000000: LiteDRAM Interface
//------------------------------------------------------------------------------
    wire        lsu_cmd_valid;
    wire        lsu_cmd_ready;
    wire [31:0] lsu_cmd_addr;
    wire [31:0] lsu_cmd_data;
    wire        lsu_cmd_we;
    wire  [3:0] lsu_cmd_wdata_we;
    wire        lsu_rsp_valid;
    wire        lsu_rsp_ready;
    wire [31:0] lsu_rsp_data;

    lsu lsu (
        .clk_i                  (sys_clk),
        .cmd_valid_i            (lsu_cmd_valid),
        .cmd_ready_o            (lsu_cmd_ready),
        .cmd_addr_i             (lsu_cmd_addr),
        .cmd_data_i             (lsu_cmd_data),
        .cmd_we_i               (lsu_cmd_we),
        .cmd_wdata_we_i         (lsu_cmd_wdata_we),
        .litedram_cmd_addr_o    (litedram_cmd_addr),
        .litedram_cmd_ready_i   (litedram_cmd_ready),
        .litedram_cmd_valid_o   (litedram_cmd_valid),
        .litedram_cmd_we_o      (litedram_cmd_we),
        .litedram_rdata_data_i  (litedram_rdata_data),
        .litedram_rdata_ready_o (litedram_rdata_ready),
        .litedram_rdata_valid_i (litedram_rdata_valid),
        .litedram_wdata_data_o  (litedram_wdata_data),
        .litedram_wdata_ready_i (litedram_wdata_ready),
        .litedram_wdata_valid_o (litedram_wdata_valid),
        .litedram_wdata_we_o    (litedram_wdata_we),
        .rsp_valid_o            (lsu_rsp_valid),
        .rsp_ready_i            (lsu_rsp_ready),
        .rsp_data_o             (lsu_rsp_data)
    );

    wire  [23:0] litedram_cmd_addr;
    wire         litedram_cmd_ready;
    wire         litedram_cmd_valid;
    wire         litedram_cmd_we;
    wire [127:0] litedram_rdata_data;
    wire         litedram_rdata_ready;
    wire         litedram_rdata_valid;
    wire [127:0] litedram_wdata_data;
    wire         litedram_wdata_ready;
    wire         litedram_wdata_valid;
    wire  [15:0] litedram_wdata_we;
    wire         wb_ctrl_ack;
    wire  [29:0] wb_ctrl_adr;
    wire   [1:0] wb_ctrl_bte;
    wire   [2:0] wb_ctrl_cti;
    wire         wb_ctrl_cyc;
    wire  [31:0] wb_ctrl_dat_r;
    wire  [31:0] wb_ctrl_dat_w;
    wire         wb_ctrl_err;
    wire   [3:0] wb_ctrl_sel;
    wire         wb_ctrl_stb;
    wire         wb_ctrl_we;
`ifdef SYNTHESIS
    litedram_core litedram(
        .clk                          (clk100),
        .ddram_a                      (ddram_a),
        .ddram_ba                     (ddram_ba),
        .ddram_cas_n                  (ddram_cas_n),
        .ddram_cke                    (ddram_cke),
        .ddram_clk_n                  (ddram_clk_n),
        .ddram_clk_p                  (ddram_clk_p),
        .ddram_cs_n                   (ddram_cs_n),
        .ddram_dm                     (ddram_dm),
        .ddram_dq                     (ddram_dq),
        .ddram_dqs_n                  (ddram_dqs_n),
        .ddram_dqs_p                  (ddram_dqs_p),
        .ddram_odt                    (ddram_odt),
        .ddram_ras_n                  (ddram_ras_n),
        .ddram_reset_n                (ddram_reset_n),
        .ddram_we_n                   (ddram_we_n),
        .init_done                    (litedram_init_done),
        .init_error                   (),
        .pll_locked                   (),
        .rst                          (1'b0),
        .user_clk                     (sys_clk),
        .user_port_native_cmd_addr    (litedram_cmd_addr),
        .user_port_native_cmd_ready   (litedram_cmd_ready),
        .user_port_native_cmd_valid   (litedram_cmd_valid),
        .user_port_native_cmd_we      (litedram_cmd_we),
        .user_port_native_rdata_data  (litedram_rdata_data),
        .user_port_native_rdata_ready (litedram_rdata_ready),
        .user_port_native_rdata_valid (litedram_rdata_valid),
        .user_port_native_wdata_data  (litedram_wdata_data),
        .user_port_native_wdata_ready (litedram_wdata_ready),
        .user_port_native_wdata_valid (litedram_wdata_valid),
        .user_port_native_wdata_we    (litedram_wdata_we),
        .user_rst                     (),
        .wb_ctrl_ack                  (wb_ctrl_ack),
        .wb_ctrl_adr                  (wb_ctrl_adr),
        .wb_ctrl_bte                  (wb_ctrl_bte),
        .wb_ctrl_cti                  (wb_ctrl_cti),
        .wb_ctrl_cyc                  (wb_ctrl_cyc),
        .wb_ctrl_dat_r                (wb_ctrl_dat_r),
        .wb_ctrl_dat_w                (wb_ctrl_dat_w),
        .wb_ctrl_err                  (wb_ctrl_err),
        .wb_ctrl_sel                  (wb_ctrl_sel),
        .wb_ctrl_stb                  (wb_ctrl_stb),
        .wb_ctrl_we                   (wb_ctrl_we)
    );
`else
    litedram_sim litedram_sim (
        .clk                          (clk100),
        .init_done                    (),
        .init_error                   (),
        .sim_trace                    (0),
        .user_clk                     (sys_clk),
        .user_port_native_cmd_addr    (litedram_cmd_addr),
        .user_port_native_cmd_ready   (litedram_cmd_ready),
        .user_port_native_cmd_valid   (litedram_cmd_valid),
        .user_port_native_cmd_we      (litedram_cmd_we),
        .user_port_native_rdata_data  (litedram_rdata_data),
        .user_port_native_rdata_ready (litedram_rdata_ready),
        .user_port_native_rdata_valid (litedram_rdata_valid),
        .user_port_native_wdata_data  (litedram_wdata_data),
        .user_port_native_wdata_ready (litedram_wdata_ready),
        .user_port_native_wdata_valid (litedram_wdata_valid),
        .user_port_native_wdata_we    (litedram_wdata_we),
        .user_rst                     (sys_rst),
        .wb_ctrl_ack                  (wb_ctrl_ack),
        .wb_ctrl_adr                  (wb_ctrl_adr),
        .wb_ctrl_bte                  (wb_ctrl_bte),
        .wb_ctrl_cti                  (wb_ctrl_cti),
        .wb_ctrl_cyc                  (wb_ctrl_cyc),
        .wb_ctrl_dat_r                (wb_ctrl_dat_r),
        .wb_ctrl_dat_w                (wb_ctrl_dat_w),
        .wb_ctrl_err                  (wb_ctrl_err),
        .wb_ctrl_sel                  (wb_ctrl_sel),
        .wb_ctrl_stb                  (wb_ctrl_stb),
        .wb_ctrl_we                   (wb_ctrl_we)
    );
`endif
//==============================================================================
// 0x80000000 - 0x80020000: Video Memory
//------------------------------------------------------------------------------
    wire        vmem_we;
    wire [15:0] vmem_waddr;
    wire  [2:0] vmem_wdata;
    vmem vmem (
        .clk_i   (sys_clk),
        .we_i    (vmem_we),
        .waddr_i (vmem_waddr),
        .wdata_i (vmem_wdata),
        .raddr_i (st7789_raddr),
        .rdata_o (st7789_rdata)
    );

    wire [15:0] st7789_raddr;
    wire [15:0] st7789_rdata;
    m_st7789_disp st7789_disp (
        .w_clk      (clk100),
        .st7789_SDA (st7789_SDA),
        .st7789_SCL (st7789_SCL),
        .st7789_DC  (st7789_DC),
        .st7789_RES (st7789_RES),
        .w_raddr    (st7789_raddr),
        .w_rdata    (st7789_rdata)
    );

//==============================================================================
// LED 0: 0xF0000000
// LED 1: 0xF0000004
// LED 2: 0xF0000008
// LED 3: 0xF000000C
//------------------------------------------------------------------------------
    reg  [3:0] led      = 4'b0000; // LED 0
    reg [31:0] cmd_addr = 0;
    reg        cmd_valid = 0;
    always @(posedge clk100) begin
        cmd_addr  <= proc_cmd_addr;
        cmd_valid <= proc_cmd_valid & proc_cmd_we;
        if (cmd_valid && cmd_addr == 32'hF000_0000) led[0] <= 1; // LED 4 is on
        if (cmd_valid && cmd_addr == 32'hF000_0004) led[1] <= 1; // LED 5 is on
        if (cmd_valid && cmd_addr == 32'hF000_0008) led[2] <= 1; // LED 6 is on
        if (cmd_valid && cmd_addr == 32'hF000_000c) led[3] <= 1; // LED 7 is on
    end
    assign user_led0 = led[0];
    assign user_led1 = led[1];
    assign user_led2 = led[2];
    assign user_led3 = led[3];

//==============================================================================
// Uart Rx: 0xF0001004
//------------------------------------------------------------------------------
    wire       uart_valid;
    wire       uart_ready;
    wire [7:0] uart_rdata_data;
    uart_rx uart_rx (
        .clk_i     (sys_clk),
        .rst_i     (0),
        .rxd_i     (uart_rxd),
        .rvalid_o  (uart_valid),
        .rready_i  (uart_ready),
        .rdata_o   (uart_rdata_data)
    );

//==============================================================================
// Performance Counter: 0xF0002000 - 0xF000200C
//------------------------------------------------------------------------------
    wire        perf_cmd_valid;
    wire        perf_cmd_ready;
    wire  [3:0] perf_cmd_addr;
    wire        perf_cmd_data;
    wire        perf_rsp_valid;
    wire        perf_rsp_ready;
    wire [31:0] perf_rsp_data;
    perf perf_counter (
        .clk_i        (sys_clk),
        .cmd_valid_i  (perf_cmd_valid),
        .cmd_ready_o  (perf_cmd_ready),
        .cmd_addr_i   (perf_cmd_addr),
        .cmd_data_i   (perf_cmd_data),
        .rsp_valid_o  (perf_rsp_valid),
        .rsp_ready_i  (perf_rsp_ready),
        .rsp_data_o   (perf_rsp_data)
    );

//==============================================================================
// Inter Connect
//------------------------------------------------------------------------------
    ic ic (
        .sys_clk                (sys_clk),

        .proc_cmd_we_i          (proc_cmd_we),
        .proc_cmd_addr_i        (proc_cmd_addr),
        .proc_cmd_valid_i       (proc_cmd_valid),
        .proc_cmd_ack_o         (proc_cmd_ack),
        .proc_read_data_o       (proc_read_data),
        .proc_write_data_i      (proc_write_data),
        .proc_write_en_i        (proc_write_en),

        .dram_cmd_addr_o        (dram_cmd_addr),
        .dram_cmd_we_o          (dram_cmd_we),
        .dram_cmd_valid_o       (dram_cmd_valid),
        .dram_cmd_ack_i         (dram_cmd_ack),
        .dram_read_data_i       (dram_read_data),
        .dram_write_data_o      (dram_write_data),
        .dram_write_en_o        (dram_write_en),

        .lsu_cmd_valid_o        (lsu_cmd_valid),
        .lsu_cmd_ready_i        (lsu_cmd_ready),
        .lsu_cmd_addr_o         (lsu_cmd_addr),
        .lsu_cmd_data_o         (lsu_cmd_data),
        .lsu_cmd_we_o           (lsu_cmd_we),
        .lsu_cmd_wdata_we_o     (lsu_cmd_wdata_we),
        .lsu_rsp_valid_i        (lsu_rsp_valid),
        .lsu_rsp_ready_o        (lsu_rsp_ready),
        .lsu_rsp_data_i         (lsu_rsp_data),

        .wb_ctrl_ack_i          (wb_ctrl_ack),
        .wb_ctrl_adr_o          (wb_ctrl_adr),
        .wb_ctrl_bte_o          (wb_ctrl_bte),
        .wb_ctrl_cti_o          (wb_ctrl_cti),
        .wb_ctrl_cyc_o          (wb_ctrl_cyc),
        .wb_ctrl_dat_r_i        (wb_ctrl_dat_r),
        .wb_ctrl_dat_w_o        (wb_ctrl_dat_w),
        .wb_ctrl_err_i          (wb_ctrl_err),
        .wb_ctrl_sel_o          (wb_ctrl_sel),
        .wb_ctrl_stb_o          (wb_ctrl_stb),
        .wb_ctrl_we_o           (wb_ctrl_we),

        .vmem_we_o              (vmem_we),
        .vmem_waddr_o           (vmem_waddr),
        .vmem_wdata_o           (vmem_wdata),

        .uart_valid_i           (uart_valid),
        .uart_ready_o           (uart_ready),
        .uart_rdata_data_i      (uart_rdata_data),

        .perf_cmd_valid_o       (perf_cmd_valid),
        .perf_cmd_ready_i       (perf_cmd_ready),
        .perf_cmd_addr_o        (perf_cmd_addr),
        .perf_cmd_data_o        (perf_cmd_data),
        .perf_rsp_valid_i       (perf_rsp_valid),
        .perf_rsp_ready_o       (perf_rsp_ready),
        .perf_rsp_data_i        (perf_rsp_data)
    );
endmodule

module dram(
    input  wire        sys_clk, 
    input  wire [31:0] cmd_addr_i,
    input  wire        cmd_we_i,
    input  wire        cmd_valid_i,
    output wire        cmd_ack_o,
    output wire [31:0] read_data_o,
    input  wire [31:0] write_data_i,
    input  wire  [3:0] write_en_i
);
    reg [31:0] mem [0:3071]; // 12 KiB DRAM (32-bit words)
    // `include "dmem_init.vh"
    
    localparam IDLE = 0, READ = 1, WRITE = 2, ACK = 3;
    localparam SB = 0, SH = 1, SW = 2; // Store Byte, Halfword, Word
    reg  [1:0] state      = IDLE;
    reg  [1:0] store_type = SB; // 0: Byte, 1: Halfword, 2: Word
    reg [31:0] write_data = 0;
    reg  [3:0] write_en   = 0;
    reg [31:0] read_data  = 0;
    reg [29:0] cmd_addr   = 0;
    reg  [1:0] cmd_offset = 0;
    reg  [4:0] shamt      = 0;
    always @(posedge sys_clk) begin
        case(state)
            IDLE: begin
                if (cmd_valid_i) begin
                    cmd_addr   <= cmd_addr_i[31:2];
                    cmd_offset <= cmd_addr_i[1:0];
                    shamt      <= (cmd_addr_i[1:0] == 1) ? 8
                                : (cmd_addr_i[1:0] == 2) ? 16
                                : (cmd_addr_i[1:0] == 3) ? 24
                                : 0; // Shift amount for byte/halfword access
                    store_type <= (write_en_i==4'b1111) ? SW
                                : (write_en_i==4'b0011) ? SH
                                : SB;
                    write_data <= write_data_i;
                    write_en   <= write_en_i;
                    state      <= cmd_we_i ? WRITE : READ;
                end
            end
            READ: begin
                read_data <= mem[cmd_addr];
                state     <= ACK;
            end
            WRITE: begin
                case (store_type)
                    SB: begin
                        case (cmd_offset)
                            2'b00: mem[cmd_addr][7:0]   <= write_data[7:0];
                            2'b01: mem[cmd_addr][15:8]  <= write_data[7:0];
                            2'b10: mem[cmd_addr][23:16] <= write_data[7:0];
                            2'b11: mem[cmd_addr][31:24] <= write_data[7:0];
                        endcase
                    end
                    SH: begin
                        if (cmd_offset[1]) mem[cmd_addr][31:16] <= write_data[15:0];
                        else               mem[cmd_addr][15:0]  <= write_data[15:0];
                    end
                    SW: begin
                        mem[cmd_addr] <= write_data;
                    end
                endcase
                state <= ACK;
            end
            ACK: begin
                state <= IDLE;
            end
        endcase
    end
    assign cmd_ack_o   = (state == ACK);
    assign read_data_o = (read_data >> shamt);
endmodule

module ic(
    input  wire        sys_clk,

    input  wire        proc_cmd_we_i,
    input  wire [31:0] proc_cmd_addr_i,
    input  wire        proc_cmd_valid_i,
    output wire        proc_cmd_ack_o,
    output wire [31:0] proc_read_data_o,
    input  wire [31:0] proc_write_data_i,
    input  wire  [3:0] proc_write_en_i,

    output wire [31:0] dram_cmd_addr_o,
    output wire        dram_cmd_we_o,
    output wire        dram_cmd_valid_o,
    input  wire        dram_cmd_ack_i,
    input  wire [31:0] dram_read_data_i,
    output wire [31:0] dram_write_data_o,
    output wire  [3:0] dram_write_en_o,

    output wire        lsu_cmd_valid_o,
    input  wire        lsu_cmd_ready_i,
    output wire [31:0] lsu_cmd_addr_o,
    output wire [31:0] lsu_cmd_data_o,
    output wire        lsu_cmd_we_o,
    output wire  [3:0] lsu_cmd_wdata_we_o,
    input  wire        lsu_rsp_valid_i,
    output wire        lsu_rsp_ready_o,
    input  wire [31:0] lsu_rsp_data_i,

    input  wire        wb_ctrl_ack_i,
    output wire [29:0] wb_ctrl_adr_o,
    output wire  [1:0] wb_ctrl_bte_o,
    output wire  [2:0] wb_ctrl_cti_o,
    output wire        wb_ctrl_cyc_o,
    input  wire [31:0] wb_ctrl_dat_r_i,
    output wire [31:0] wb_ctrl_dat_w_o,
    input  wire        wb_ctrl_err_i,
    output wire  [3:0] wb_ctrl_sel_o,
    output wire        wb_ctrl_stb_o,
    output wire        wb_ctrl_we_o,

    output wire        vmem_we_o,
    output wire [15:0] vmem_waddr_o,
    output wire  [2:0] vmem_wdata_o,

    input  wire        uart_valid_i,
    output wire        uart_ready_o,
    input  wire  [7:0] uart_rdata_data_i,

    output wire        perf_cmd_valid_o,
    input  wire        perf_cmd_ready_i,
    output wire  [3:0] perf_cmd_addr_o,
    output wire        perf_cmd_data_o,
    input  wire        perf_rsp_valid_i,
    output wire        perf_rsp_ready_o,
    input  wire [31:0] perf_rsp_data_i
);
    wire dram_access     = (proc_cmd_addr_i[31:28] == 4'b0001);
    wire litedram_access = (proc_cmd_addr_i[31:28] == 4'b0010);
    wire csr_access      = (proc_cmd_addr_i[31:28] == 4'b0100);
    wire vmem_access     = (proc_cmd_addr_i[31:28] == 4'b1000);
    wire uart_access     = (proc_cmd_addr_i[31:8] == 24'hF00010); // 0xF0001000 - 0xF0001004
    wire perf_access     = (proc_cmd_addr_i[31:4] == 28'hF000200); // 0xF0002000 - 0xF000200C
//==============================================================================
// Processor Command Acknowledge and Read Data
//------------------------------------------------------------------------------
    assign proc_cmd_ack_o   = (dram_access)      ? dram_cmd_ack_i
                            : (csr_access)       ? wb_ctrl_ack_i
                            : (litedram_access)  ? lsu_rsp_valid_i
                            : (uart_access)      ? uart_valid_i
                            : (perf_access)      ? perf_rsp_valid_i
                            : 1'b1; // LED and vmem

    assign proc_read_data_o = (dram_access)     ? dram_read_data_i
                            : (csr_access)      ? wb_ctrl_dat_r_i
                            : (litedram_access) ? lsu_rsp_data_i
                            : (uart_access)     ? {24'b0, uart_rdata_data_i}
                            : (perf_access)     ? perf_rsp_data_i
                            : 32'b0;
//==============================================================================
// DRAM Command Interface
//------------------------------------------------------------------------------
    assign dram_cmd_addr_o   = proc_cmd_addr_i;
    assign dram_cmd_we_o     = proc_cmd_we_i;
    assign dram_cmd_valid_o  = (dram_access) ? proc_cmd_valid_i : 1'b0;
    assign dram_write_data_o = proc_write_data_i;
    assign dram_write_en_o   = proc_write_en_i;

//==============================================================================
// Video Memory Command Interface
//------------------------------------------------------------------------------
    assign vmem_we_o    = vmem_access & proc_cmd_valid_i;
    assign vmem_waddr_o = proc_cmd_addr_i;
    assign vmem_wdata_o = proc_write_data_i;

//==============================================================================
// Serial Tx Command Interface
//=============================================================================
    assign uart_ready_o = 1;

//==============================================================================
// Performance Counter Command Interface
//------------------------------------------------------------------------------
    assign perf_cmd_valid_o = (perf_access & proc_cmd_valid_i);
    assign perf_cmd_addr_o  = proc_cmd_addr_i[3:0];
    assign perf_cmd_data_o  = proc_write_data_i[0];
    assign perf_rsp_ready_o = 1'b1;

//==============================================================================
// LiteDRAM Command Interface
//------------------------------------------------------------------------------
    assign lsu_cmd_valid_o    = (litedram_access & proc_cmd_valid_i);
    assign lsu_cmd_addr_o     = proc_cmd_addr_i;
    assign lsu_cmd_data_o     = proc_write_data_i;
    assign lsu_cmd_we_o       = proc_cmd_we_i;
    assign lsu_cmd_wdata_we_o = proc_write_en_i;
    assign lsu_rsp_ready_o    = 1'b1;

//==============================================================================
// LiteDRAM Wishbone Control Interface
//------------------------------------------------------------------------------
    assign wb_ctrl_adr_o   = proc_cmd_addr_i[31:2];
    assign wb_ctrl_bte_o   = 0;
    assign wb_ctrl_cti_o   = 0;
    assign wb_ctrl_cyc_o   = (csr_access) ? proc_cmd_valid_i : 1'b0;
    assign wb_ctrl_dat_w_o = proc_write_data_i;
    assign wb_ctrl_sel_o   = proc_write_en_i;
    assign wb_ctrl_stb_o   = (csr_access) ? proc_cmd_valid_i : 1'b0;
    assign wb_ctrl_we_o    = (csr_access) ? proc_cmd_we_i : 1'b0;
endmodule

module vmem (
    input  wire        clk_i,
    input  wire        we_i,
    input  wire [15:0] waddr_i,
    input  wire  [2:0] wdata_i,
    input  wire [15:0] raddr_i,
    output wire [15:0] rdata_o
);
    reg [2:0] vmem_lo[0:32767];
    reg [2:0] vmem_hi[0:32767];
    integer i;
    initial for (i = 0; i < 32768; i = i + 1) begin
        vmem_lo[i] = 3'b111;
        vmem_hi[i] = 3'b000;
    end

    reg        we;
    reg        top;
    reg  [2:0] wdata;
    reg [14:0] waddr;

    reg        rtop;
    reg [14:0] raddr;
    reg  [2:0] rdata_lo;
    reg  [2:0] rdata_hi;
    reg        sel;

    always @(posedge clk_i) begin
        we    <= we_i;
        top   <= waddr_i[15];
        waddr <= waddr_i[14:0];
        wdata <= wdata_i;

        rtop  <= raddr_i[15];
        raddr <= raddr_i[14:0];

        if (we) begin
            if (top) vmem_hi[waddr] <= wdata;
            else     vmem_lo[waddr] <= wdata;
        end

        sel      <= rtop;
        rdata_lo <= vmem_lo[raddr];
        rdata_hi <= vmem_hi[raddr];
    end

    wire [15:0] rdata_hi_ext = { {5{rdata_hi[2]}}, {6{rdata_hi[1]}}, {5{rdata_hi[0]}} };
    wire [15:0] rdata_lo_ext = { {5{rdata_lo[2]}}, {6{rdata_lo[1]}}, {5{rdata_lo[0]}} };
    assign rdata_o = (sel) ? rdata_hi_ext : rdata_lo_ext;
endmodule

module m_st7789_disp (
    input  wire        w_clk,  // main clock signal (100MHz)
    output wire        st7789_SDA,
    output wire        st7789_SCL,
    output wire        st7789_DC,
    output wire        st7789_RES,
    output wire [15:0] w_raddr,
    input  wire [15:0] w_rdata
);
    
    reg [24:0] timer    = 0;
    reg  [8:0] r_init   = 0;
    reg        reset_n  = 0;
    always @(posedge w_clk) begin
        timer   <= (timer[24]) ? 0 : timer + 1; //167.77215msec @100MHz
        reset_n <= reset_n | timer[24];
        if(reset_n) begin
            r_en  <= (~init_done) ? timer[24] : spi_wdata_ready;
            if (timer[24] & ~init_done) r_state <= r_state + 1;
            case (r_state)
                0: r_init <= {1'b0, 8'h01};  // Software Reset, wait 120msec
                1: r_init <= {1'b0, 8'h11};  // Sleep Out, wait 120msec
                2: r_init <= {1'b0, 8'h3A};  // Interface Pixel Format
                3: r_init <= {1'b1, 8'h55};  // [65K RGB, 16bit/pixel]
                4: r_init <= {1'b0, 8'h36};  // Memory Data Accell Control
                5: r_init <= {1'b1, 8'h00};  // [000000]
                6: r_init <= {1'b0, 8'h21};  // Display Inversion On
                7: r_init <= {1'b0, 8'h13};  // Normal Display Mode On
                8: r_init <= {1'b0, 8'h29};  // Display On
                9: init_done <= 1;
            endcase
        end
    end

    reg        r_en      = 0;
    reg        init_done = 0;
    reg  [4:0] r_state   = 0;
    reg [19:0] r_state2  = 0;
    reg  [8:0] r_dat     = 0;

    always @(posedge w_clk)
        if (r_en && init_done) begin
            r_state2 <= (r_state2==115210) ? 0 : r_state2 + 1; // 11 + 240x240*2 = 11 + 115200 = 115211
        end

    reg [7:0] r_x = 0;
    reg [7:0] r_y = 0;
    always @(posedge w_clk)
        if (r_en && init_done && r_state2[0] == 1) begin
            r_x <= (r_state2 < 11 || r_x == 239) ? 0 : r_x + 1;
            r_y <= (r_state2 < 11) ? 0 : (r_x == 239) ? r_y + 1 : r_y;
        end
    

    reg [15:0] r_color = 0;
    always @(posedge w_clk) r_color <= w_rdata;

    always @(posedge w_clk) begin
        case (r_state2)  /////
            0:  r_dat <= {1'b0, 8'h2A};  // Column Address Set
            1:  r_dat <= {1'b1, 8'h00};  // [0]
            2:  r_dat <= {1'b1, 8'h00};  // [0]
            3:  r_dat <= {1'b1, 8'h00};  // [0]
            4:  r_dat <= {1'b1, 8'd239};  // [239]
            5:  r_dat <= {1'b0, 8'h2B};  // Row Address Set
            6:  r_dat <= {1'b1, 8'h00};  // [0]
            7:  r_dat <= {1'b1, 8'h00};  // [0]
            8:  r_dat <= {1'b1, 8'h00};  // [0]
            9:  r_dat <= {1'b1, 8'd239};  // [239]
            10: r_dat <= {1'b0, 8'h2C};  // Memory Write
            default: r_dat <= (r_state2[0]) ? {1'b1, r_color[15:8]} : {1'b1, r_color[7:0]};
        endcase
    end

    wire [8:0] w_data = (init_done) ? r_dat : r_init;
    wire spi_wdata_ready;
    spi spi (
        .clk100_i      (w_clk),
        .wdata_en_i    (r_en),
        .wdata_data_i  (w_data),
        .wdata_ready_o (spi_wdata_ready),
        .sda_o         (st7789_SDA),
        .scl_o         (st7789_SCL),
        .dc_o          (st7789_DC)
    );
    assign st7789_RES = reset_n;
    assign w_raddr = {r_y, r_x};
endmodule

/****** SPI send module,  SPI_MODE_2, MSBFIRST                                           *****/
/*********************************************************************************************/
module spi (
    input  wire       clk100_i,       // 100MHz input clock !!
    input  wire       wdata_en_i,     // write enable
    input  wire [8:0] wdata_data_i,   // data in
    output wire       wdata_ready_o,  // busy
    output wire       sda_o,          // Serial Data
    output wire       scl_o,          // Serial Clock
    output wire       dc_o            // Data/Control
);
    localparam SPI_STATE_IDLE = 0;
    localparam SPI_STATE_BIT  = 1;
    localparam SPI_STATE_LOW  = 2;
    localparam SPI_STATE_WAIT = 3;
    localparam SPI_STATE_HI   = 4;

    reg [2:0] spi_state   = SPI_STATE_IDLE;
    reg [2:0] count_bit   = 0;
    reg [7:0] wdata_data  = 0;
    reg       scl         = 1;
    reg       dc          = 0;
    reg       sda         = 0;

    always @(posedge clk100_i) begin
        case (spi_state)
            SPI_STATE_IDLE: begin
                scl <= 1;
                if (wdata_en_i) begin
                    spi_state  <= SPI_STATE_BIT;
                    wdata_data <= wdata_data_i[7:0];
                    dc         <= wdata_data_i[8];
                    count_bit  <= 0;
                end
            end
            SPI_STATE_BIT: begin
                sda        <= wdata_data[7];
                wdata_data <= (wdata_data << 1);
                spi_state  <= SPI_STATE_LOW;
            end
            SPI_STATE_LOW: begin
                scl       <= 0;
                spi_state <= SPI_STATE_WAIT;
            end
            SPI_STATE_WAIT: begin
                spi_state <= SPI_STATE_HI;
            end
            SPI_STATE_HI: begin
                scl       <= 1;
                spi_state <= (count_bit == 7) ? SPI_STATE_IDLE : SPI_STATE_BIT;
                count_bit <= count_bit + 1;
            end
        endcase
    end

    assign sda_o         = sda;
    assign scl_o         = scl;
    assign dc_o          = dc;
    assign wdata_ready_o = (spi_state == SPI_STATE_IDLE && !wdata_en_i);
endmodule
/*********************************************************************************************/

module uart_rx #(
    parameter CLK_FREQ_MHZ  = 50   ,
    parameter BAUD_RATE     = 1000000,
    parameter DETECT_COUNT  = 4
) (
    input  wire       clk_i,
    input  wire       rst_i,
    input  wire       rxd_i,
    output wire       rvalid_o,
    input  wire       rready_i,
    output wire [7:0] rdata_o
);

    localparam WAIT_COUNT = ((CLK_FREQ_MHZ*1000*1000)/BAUD_RATE);

    // 2-FF synchronizer
    wire rxd;
    synchronizer sync_rxd (
        .clk_i   (clk_i     ),
        .d_i     (rxd_i     ),
        .q_o     (rxd       )
    );

    // FSM
    reg state_q, state_d;
    localparam IDLE = 1'b0;
    localparam RUN  = 1'b1;

    reg [$clog2(DETECT_COUNT+1)-1:0] detect_cntr_q  , detect_cntr_d ;
    reg                              rvalid_q       , rvalid_d      ;
    reg                        [7:0] rx_data_q      , rx_data_d     ;
    reg                        [7:0] buf_q          , buf_d         ;
    reg                        [3:0] bit_cntr_q     , bit_cntr_d    ;
    reg     [$clog2(WAIT_COUNT)-1:0] wait_cntr_q    , wait_cntr_d   ;

    assign rvalid_o = rvalid_q  ;
    assign rdata_o  = rx_data_q ;

    always @(*) begin
        detect_cntr_d   = (rxd) ? 'h0 : detect_cntr_q+'h1;
        rvalid_d        = rvalid_q          ;
        rx_data_d       = rx_data_q         ;
        buf_d           = buf_q             ;
        bit_cntr_d      = bit_cntr_q        ;
        wait_cntr_d     = wait_cntr_q-'h1   ;
        state_d         = state_q           ;
        if (rvalid_o && rready_i) begin
            rvalid_d = 1'b0;
        end
        case (state_q)
            IDLE: begin
                if (detect_cntr_q>=DETECT_COUNT-1) begin
                    bit_cntr_d      = 4'd9                          ;
                    wait_cntr_d     = WAIT_COUNT-DETECT_COUNT-'h3   ;
                    state_d         = RUN                           ;
                end
            end
            RUN: begin
                if (wait_cntr_q==(WAIT_COUNT/2)) begin
                    if (~|bit_cntr_q) begin // bit_cntr_q==0
                        rvalid_d    = 1'b1                          ;
                        rx_data_d   = buf_q                         ;
                        state_d     = IDLE                          ;
                    end
                    buf_d           = {rxd, buf_q[7:1]}             ;
                    bit_cntr_d      = bit_cntr_q-4'd1               ;
                end
                if (~|wait_cntr_q) begin // wait_cntr_q==0
                    wait_cntr_d     = WAIT_COUNT-'h1                ;
                end
            end
            default: begin
                rvalid_d            = 1'b0                          ;
                state_d             = IDLE                          ;
            end
        endcase
    end

    always @(posedge clk_i) begin
        if (rst_i) begin
            detect_cntr_q   <= 'h0          ;
            rvalid_q        <= 1'b0         ;
            state_q         <= IDLE         ;
        end else begin
            detect_cntr_q   <= detect_cntr_d;
            rvalid_q        <= rvalid_d     ;
            rx_data_q       <= rx_data_d    ;
            buf_q           <= buf_d        ;
            bit_cntr_q      <= bit_cntr_d   ;
            wait_cntr_q     <= wait_cntr_d  ;
            state_q         <= state_d      ;
        end
    end

endmodule

module synchronizer (
    input  wire clk_i   ,
    input  wire d_i     ,
    output wire q_o
);

    reg ff1, ff2;
    always @(posedge clk_i) begin
        ff1 <= d_i  ;
        ff2 <= ff1  ;
    end
    assign q_o = ff2;

endmodule
