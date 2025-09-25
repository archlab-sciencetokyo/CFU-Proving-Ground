/* CFU Proving Ground since 2025-02    Copyright(c) 2025 Archlab. Science Tokyo /
/ Released under the MIT license https://opensource.org/licenses/mit           */
`resetall `default_nettype none
`include "config.vh"

module main (
    input  wire          clk_i,
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
    output wire          st7789_SDA,
    output wire          st7789_SCL,
    output wire          st7789_DC,
    output wire          st7789_RES,
    input  wire          rxd_i,
    output wire          txd_o
);
//==============================================================================
// Clock and Reset
//------------------------------------------------------------------------------
    wire clk;
    wire locked;
`ifdef SYNTHESIS
    clk_wiz_0 clk_wiz_0 (
        .clk_out1 (clk),      // output clk_out1
        .reset    (0),        // input reset
        .locked   (locked),   // output locked
        .clk_in1  (clk_i)     // input clk_in1
    );
`else
    assign clk    = clk_i;
    assign locked = 1'b1;
`endif
    wire rst = ~locked;

//==============================================================================
// CPU
//------------------------------------------------------------------------------
    wire                      [31:0] ibus_raddr;
    wire                      [31:0] ibus_rdata;
    wire                             ibus_rdata_en;
    wire                      [31:0] dbus_cmd_addr;
    wire                             dbus_cmd_we;
    wire                             dbus_cmd_valid;
    wire                             dbus_cmd_ack;
    wire                      [31:0] dbus_rdata_data;
    wire                      [31:0] dbus_wdata_data;
    wire                       [3:0] dbus_wdata_en;
    cpu cpu (
        .clk_i             (sys_clk),     // input  wire
        .rst_i             (rst),         // input  wire
        .ibus_addr_o       (ibus_raddr),  // output wire [`IBUS_ADDR_WIDTH-1:0]
        .ibus_data_i       (ibus_rdata),  // input  wire [`IBUS_DATA_WIDTH-1:0]
        .ibus_rdata_en_o   (ibus_rdata_en),
        .dbus_cmd_addr_o   (dbus_cmd_addr),
        .dbus_cmd_we_o     (dbus_cmd_we),
        .dbus_cmd_valid_o  (dbus_cmd_valid),
        .dbus_cmd_ack_i    (dbus_cmd_ack),
        .dbus_rdata_data_i (dbus_rdata_data),
        .dbus_wdata_data_o (dbus_wdata_data),
        .dbus_wdata_en_o   (dbus_wdata_en)
    );

//==============================================================================
// 0x0000_0000 - 0x0000_1000 : 4 KiB bootrom
//------------------------------------------------------------------------------ 
    wire  [9:0] bootrom_raddr;
    wire [31:0] bootrom_rdata;
    bootrom bootrom (
        .clk_i   (sys_clk),        // input  wire
        .raddr_i (bootrom_raddr),  // input  wire [ADDR_WIDTH-1:0]
        .rdata_o (bootrom_rdata),  //
        .re_i    (ibus_rdata_en)
    );

//==============================================================================
// 0x0000_1000 - 0x0000_2000 : 4 KiB sdram
//------------------------------------------------------------------------------
    wire  [9:0] sdram_cmd_addr;
    wire        sdram_cmd_valid;
    wire        sdram_cmd_we;
    wire        sdram_cmd_ack;
    wire  [3:0] sdram_wen;
    wire [31:0] sdram_wdata;
    wire [31:0] sdram_rdata;
    sdram sdram (
        .clk_i        (sys_clk),
        .cmd_addr_i   (sdram_cmd_addr),
        .cmd_valid_i  (sdram_cmd_valid),
        .cmd_we_i     (sdram_cmd_we),
        .cmd_ack_o    (sdram_cmd_ack),
        .write_en_i   (sdram_wen),
        .write_data_i (sdram_wdata),
        .read_data_o  (sdram_rdata)
    );

//==============================================================================
// 0x1000_0000 : UART TX
// 0x1000_0004 : UART RX
//------------------------------------------------------------------------------
    wire       uart_txd;
    wire       uart_rxd;
    wire       uart_wvalid;
    wire       uart_wready;
    wire [7:0] uart_wdata;
    wire       uart_rvalid;
    wire       uart_rready;
    wire [7:0] uart_rdata;
    uart uart (
        .clk_i    (sys_clk),
        .rst_i    (rst),
        .txd_o    (uart_txd),
        .rxd_i    (uart_rxd),
        .wvalid_i (uart_wvalid),
        .wready_o (uart_wready),
        .wdata_i  (uart_wdata),
        .rvalid_o (uart_rvalid),
        .rready_i (uart_rready),
        .rdata_o  (uart_rdata)
    );
    assign txd_o    = uart_txd;
    assign uart_rxd = rxd_i;

//==============================================================================
// 0x2000_0000 - 0x2001_0000 : VMEM
//------------------------------------------------------------------------------
    wire        vmem_we;
    wire [15:0] vmem_waddr;
    wire  [2:0] vmem_wdata;
    wire [15:0] vmem_raddr;
    wire  [2:0] vmem_rdata;
    vmem vmem (
        .clk_i   (sys_clk),      // input wire
        .we_i    (vmem_we),      // input wire
        .waddr_i (vmem_waddr),   // input wire [15:0]
        .wdata_i (vmem_wdata),   // input wire [15:0]
        .raddr_i (vmem_raddr),   // input wire [15:0]
        .rdata_o (vmem_rdata)    // output wire [15:0]
    );

    wire [15:0] color_data;
    assign color_data = {{5{vmem_rdata[2]}},
                         {6{vmem_rdata[1]}},
                         {5{vmem_rdata[0]}}};
    m_st7789_disp st7789_disp (
        .w_clk      (sys_clk),         // input  wire
        .st7789_SDA (st7789_SDA),  // output wire
        .st7789_SCL (st7789_SCL),  // output wire
        .st7789_DC  (st7789_DC),   // output wire
        .st7789_RES (st7789_RES),  // output wire
        .w_raddr    (vmem_raddr),  // output wire [15:0]
        .w_rdata    (color_data)   // input  wire [15:0]
    );

//==============================================================================
// 0x4000_0000 - 0x5000_0000 : IMEM
//------------------------------------------------------------------------------
    wire [$clog2(`IMEM_ENTRIES)-1:0] imem_rdata_addr;
    wire                      [31:0] imem_rdata_data;
    wire                             imem_rdata_en;
    wire [$clog2(`IMEM_ENTRIES)-1:0] imem_wdata_addr;
    wire                      [31:0] imem_wdata_data;
    wire                       [3:0] imem_wdata_en;
    wire                             imem_wdata_ack;
    imem imem (
        .clk_i        (sys_clk),
        .rdata_addr_i (imem_rdata_addr),
        .rdata_data_o (imem_rdata_data),
        .rdata_en_i   (imem_rdata_en),
        .wdata_addr_i (imem_wdata_addr),
        .wdata_data_i (imem_wdata_data),
        .wdata_en_i   (imem_wdata_en),
        .wdata_ack_o  (imem_wdata_ack)
    );

//==============================================================================
// 0x8000_0000 - 0x9000_0000 : LiteDRAM
//------------------------------------------------------------------------------
    wire          litedram_init_done;
    wire          litedram_init_error;
    wire          sys_clk;
    wire   [23:0] litedram_cmd_addr;
    wire          litedram_cmd_ready;
    wire          litedram_cmd_valid;
    wire          litedram_cmd_we;
    wire  [127:0] litedram_rdata_data;
    wire          litedram_rdata_ready;
    wire          litedram_rdata_valid;
    wire  [127:0] litedram_wdata_data;
    wire          litedram_wdata_ready;
    wire          litedram_wdata_valid;
    wire   [15:0] litedram_wdata_we;
    wire          sys_rst;
    wire          litedram_ctrl_ack;
    wire   [29:0] litedram_ctrl_adr;
    wire          litedram_ctrl_cyc;
    wire   [31:0] litedram_ctrl_dat_r;
    wire   [31:0] litedram_ctrl_dat_w;
    wire          litedram_ctrl_err;
    wire    [3:0] litedram_ctrl_sel;
    wire          litedram_ctrl_stb;
    wire          litedram_ctrl_we;
`ifdef SYNTHESIS
    litedram litedram(
        .clk                          (clk_i),
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
        .init_error                   (litedram_init_error),
        .pll_locked                   (),
        .rst                          (0),
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
        .wb_ctrl_ack                  (litedram_ctrl_ack),
        .wb_ctrl_adr                  (litedram_ctrl_adr),
        .wb_ctrl_bte                  (0),
        .wb_ctrl_cti                  (0),
        .wb_ctrl_cyc                  (litedram_ctrl_cyc),
        .wb_ctrl_dat_r                (litedram_ctrl_dat_r),
        .wb_ctrl_dat_w                (litedram_ctrl_dat_w),
        .wb_ctrl_err                  (litedram_ctrl_err),
        .wb_ctrl_sel                  (litedram_ctrl_sel),
        .wb_ctrl_stb                  (litedram_ctrl_stb),
        .wb_ctrl_we                   (litedram_ctrl_we)
    );
`else
    litedram_sim litedram (
        .clk                          (clk),                  // input  wire
        .init_done                    (litedram_init_done),   // output wire
        .init_error                   (litedram_init_error),  // output wire
        .sim_trace                    (0),                    // input  wire
        .user_clk                     (sys_clk),              // output wire
        .user_port_native_cmd_addr    (litedram_cmd_addr),    // input  wire   [23:0]
        .user_port_native_cmd_ready   (litedram_cmd_ready),   // output wire
        .user_port_native_cmd_valid   (litedram_cmd_valid),   // input  wire
        .user_port_native_cmd_we      (litedram_cmd_we),      // input  wire
        .user_port_native_rdata_data  (litedram_rdata_data),  // output wire  [127:0]
        .user_port_native_rdata_ready (litedram_rdata_ready), // input  wire
        .user_port_native_rdata_valid (litedram_rdata_valid), // output wire
        .user_port_native_wdata_data  (litedram_wdata_data),  // input  wire  [127:0]
        .user_port_native_wdata_ready (litedram_wdata_ready), // output wire
        .user_port_native_wdata_valid (litedram_wdata_valid), // input  wire
        .user_port_native_wdata_we    (litedram_wdata_we),    // input  wire   [15:0]
        .user_rst                     (sys_rst),              // output wire
        .wb_ctrl_ack                  (litedram_ctrl_ack),    // output wire
        .wb_ctrl_adr                  (litedram_ctrl_adr),    // input  wire   [29:0]
        .wb_ctrl_bte                  (0),                    // input  wire    [1:0]
        .wb_ctrl_cti                  (0),                    // input  wire    [2:0]
        .wb_ctrl_cyc                  (litedram_ctrl_cyc),    // input  wire
        .wb_ctrl_dat_r                (litedram_ctrl_dat_r),  // output wire   [31:0]  
        .wb_ctrl_dat_w                (litedram_ctrl_dat_w),  // input  wire   [31:0]  
        .wb_ctrl_err                  (litedram_ctrl_err),    // output wire           
        .wb_ctrl_sel                  (litedram_ctrl_sel),    // input  wire    [3:0]  
        .wb_ctrl_stb                  (litedram_ctrl_stb),    // input  wire           
        .wb_ctrl_we                   (litedram_ctrl_we)      // input  wire           
    );
`endif

//==============================================================================
// Memory Management Unit
//------------------------------------------------------------------------------
    mmu mmu (
        .clk_i                 (sys_clk),        // input  wire
        .cpu_ibus_raddr_i      (ibus_raddr),     // input  wire [ADDR_WIDTH
        .cpu_ibus_rdata_o      (ibus_rdata),     // output wire [DATA_WIDTH
        .cpu_ibus_rdata_en_i   (ibus_rdata_en),
        .cpu_dbus_cmd_addr_i   (dbus_cmd_addr),
        .cpu_dbus_cmd_we_i     (dbus_cmd_we),
        .cpu_dbus_cmd_valid_i  (dbus_cmd_valid),
        .cpu_dbus_cmd_ack_o    (dbus_cmd_ack),
        .cpu_dbus_rdata_data_o  (dbus_rdata_data),
        .cpu_dbus_wdata_data_i (dbus_wdata_data),
        .cpu_dbus_wdata_en_i   (dbus_wdata_en),

        .bootrom_raddr_o       (bootrom_raddr),  // output wire [ADDR
        .bootrom_rdata_i       (bootrom_rdata),  // input  wire [DATA_WIDTH

        .sdram_cmd_addr_o      (sdram_cmd_addr),
        .sdram_cmd_valid_o     (sdram_cmd_valid),
        .sdram_cmd_we_o        (sdram_cmd_we),
        .sdram_cmd_ack_i       (sdram_cmd_ack),
        .sdram_wen_o           (sdram_wen),
        .sdram_wdata_o         (sdram_wdata),
        .sdram_rdata_i         (sdram_rdata),

        .uart_wdata_valid_o    (uart_wvalid),    // output wire
        .uart_wdata_ready_i    (uart_wready),    // input  wire
        .uart_wdata_data_o     (uart_wdata),     // output wire [7:0]
        .uart_rdata_valid_i    (uart_rvalid),    // input  wire
        .uart_rdata_ready_o    (uart_rready),    // output wire
        .uart_rdata_data_i     (uart_rdata),     // input  wire [7:0]

        .imem_rdata_addr_o     (imem_rdata_addr),
        .imem_rdata_data_i     (imem_rdata_data),
        .imem_rdata_en_o       (imem_rdata_en),
        .imem_wdata_addr_o     (imem_wdata_addr),
        .imem_wdata_data_o     (imem_wdata_data),
        .imem_wdata_en_o       (imem_wdata_en),
        .imem_wdata_ack_i      (imem_wdata_ack),

        .vmem_we_o             (vmem_we),        // output wire
        .vmem_waddr_o          (vmem_waddr),     // output wire [15:0
        .vmem_wdata_o          (vmem_wdata),     // output wire [2:0]

        .litedram_ctrl_ack_i   (litedram_ctrl_ack),
        .litedram_ctrl_adr_o   (litedram_ctrl_adr),
        .litedram_ctrl_cyc_o   (litedram_ctrl_cyc),
        .litedram_ctrl_dat_r_i (litedram_ctrl_dat_r),
        .litedram_ctrl_dat_w_o (litedram_ctrl_dat_w),
        .litedram_ctrl_err_i   (litedram_ctrl_err),
        .litedram_ctrl_sel_o   (litedram_ctrl_sel),
        .litedram_ctrl_stb_o   (litedram_ctrl_stb),
        .litedram_ctrl_we_o    (litedram_ctrl_we),
        .litedram_cmd_addr_o   (litedram_cmd_addr),
        .litedram_cmd_ready_i  (litedram_cmd_ready),
        .litedram_cmd_valid_o  (litedram_cmd_valid),
        .litedram_cmd_we_o     (litedram_cmd_we),
        .litedram_rdata_data_i (litedram_rdata_data),
        .litedram_rdata_ready_o(litedram_rdata_ready),
        .litedram_rdata_valid_i(litedram_rdata_valid),
        .litedram_wdata_data_o (litedram_wdata_data),
        .litedram_wdata_ready_i(litedram_wdata_ready),
        .litedram_wdata_valid_o(litedram_wdata_valid),
        .litedram_wdata_we_o   (litedram_wdata_we)
    );
endmodule  // main

//==============================================================================
// Sub Modules
//------------------------------------------------------------------------------
module mmu (
    input  wire                             clk_i,

    input  wire                      [31:0] cpu_ibus_raddr_i,
    output wire                      [31:0] cpu_ibus_rdata_o,
    input  wire                             cpu_ibus_rdata_en_i,
    input  wire                      [31:0] cpu_dbus_cmd_addr_i,
    input  wire                             cpu_dbus_cmd_we_i,
    input  wire                             cpu_dbus_cmd_valid_i,
    output wire                             cpu_dbus_cmd_ack_o,
    output wire                      [31:0] cpu_dbus_rdata_data_o,
    input  wire                      [31:0] cpu_dbus_wdata_data_i,
    input  wire                       [3:0] cpu_dbus_wdata_en_i,

    output wire                       [9:0] bootrom_raddr_o,
    input  wire                      [31:0] bootrom_rdata_i,

    output wire [$clog2(`DMEM_ENTRIES)-1:0] sdram_cmd_addr_o,
    output wire                             sdram_cmd_valid_o,
    output wire                             sdram_cmd_we_o,
    input  wire                             sdram_cmd_ack_i,
    output wire                       [3:0] sdram_wen_o,
    output wire                      [31:0] sdram_wdata_o,
    input  wire                      [31:0] sdram_rdata_i,

    output wire                             uart_wdata_valid_o,
    input  wire                             uart_wdata_ready_i,
    output wire                       [7:0] uart_wdata_data_o,
    input  wire                             uart_rdata_valid_i,
    output wire                             uart_rdata_ready_o,
    input  wire                       [7:0] uart_rdata_data_i,

    output wire [$clog2(`IMEM_ENTRIES)-1:0] imem_rdata_addr_o,
    input  wire                      [31:0] imem_rdata_data_i,
    output wire                             imem_rdata_en_o,
    output wire [$clog2(`IMEM_ENTRIES)-1:0] imem_wdata_addr_o,
    output wire                      [31:0] imem_wdata_data_o,
    output wire                       [3:0] imem_wdata_en_o,
    input  wire                             imem_wdata_ack_i,

    output wire                             vmem_we_o,
    output wire                      [15:0] vmem_waddr_o,
    output wire                       [2:0] vmem_wdata_o,

    input  wire                             litedram_ctrl_ack_i,
    output wire                      [29:0] litedram_ctrl_adr_o,
    output wire                             litedram_ctrl_cyc_o,
    input  wire                      [31:0] litedram_ctrl_dat_r_i,
    output wire                      [31:0] litedram_ctrl_dat_w_o,
    input  wire                             litedram_ctrl_err_i,
    output wire                       [3:0] litedram_ctrl_sel_o,
    output wire                             litedram_ctrl_stb_o,
    output wire                             litedram_ctrl_we_o,

    output wire                      [23:0] litedram_cmd_addr_o,    // input  wire   [23:0]
    input  wire                             litedram_cmd_ready_i,   // output wire
    output wire                             litedram_cmd_valid_o,   // input  wire
    output wire                             litedram_cmd_we_o,      // input  wire
    input  wire                     [127:0] litedram_rdata_data_i,  // output wire  [127:0]
    output wire                             litedram_rdata_ready_o, // input  wire
    input  wire                             litedram_rdata_valid_i, // output wire
    output wire                     [127:0] litedram_wdata_data_o,  // input  wire  [127:0]
    input  wire                             litedram_wdata_ready_i, // output wire
    output wire                             litedram_wdata_valid_o, // input  wire
    output wire                      [15:0] litedram_wdata_we_o     // input  wire   [15:0]
);
    wire   sdram_access    = (cpu_dbus_cmd_addr_i[31:28] == 4'h0);
    wire   uart_access     = (cpu_dbus_cmd_addr_i[31:28] == 4'h1);
    wire   vmem_access     = (cpu_dbus_cmd_addr_i[31:28] == 4'h2);
    wire   imem_access     = (cpu_dbus_cmd_addr_i[31:28] == 4'h4);
    wire   litedram_access = (cpu_dbus_cmd_addr_i[31:28] == 4'h8);
    wire   csr_access      = (cpu_dbus_cmd_addr_i[31:28] == 4'hF);
//==============================================================================
// IBUS Interface
//------------------------------------------------------------------------------
    reg port_ibus = 0;
    always @(posedge clk_i) if (cpu_ibus_rdata_en_i) begin
        port_ibus <= (cpu_ibus_raddr_i[31:28] == 4'h4);
    end
    assign cpu_ibus_rdata_o  = (port_ibus) ? imem_rdata_data_i : bootrom_rdata_i;
    assign bootrom_raddr_o   = cpu_ibus_raddr_i[31:2];

//==============================================================================
// CPU Command Acknowledge and Read Data Bus
//------------------------------------------------------------------------------
    localparam PORT_SEL_SDRAM    = 3'b000;
    localparam PORT_SEL_UART     = 3'b001;
    localparam PORT_SEL_VMEM     = 3'b010;
    localparam PORT_SEL_IMEM     = 3'b011;
    localparam PORT_SEL_LITEDRAM = 3'b100;
    localparam PORT_SEL_CSR      = 3'b101;
    reg [2:0] port_sel = PORT_SEL_SDRAM;
    always @(posedge clk_i) if (cpu_dbus_cmd_valid_i) begin
        port_sel <= (sdram_access)    ? PORT_SEL_SDRAM :
                    (csr_access)      ? PORT_SEL_CSR :
                    (litedram_access) ? PORT_SEL_LITEDRAM :
                    (imem_access)     ? PORT_SEL_IMEM :
                    (vmem_access)     ? PORT_SEL_VMEM :
                                        PORT_SEL_UART ;
    end
    assign cpu_dbus_cmd_ack_o   = (port_sel == PORT_SEL_SDRAM)    ? sdram_cmd_ack_i
                                : (port_sel == PORT_SEL_CSR)      ? litedram_ctrl_ack_i
                                : (port_sel == PORT_SEL_LITEDRAM) ? (litedram_state == LITEDRAM_STATE_SEND_ACK)
                                : (port_sel == PORT_SEL_IMEM)     ? imem_wdata_ack_i
                                : (port_sel == PORT_SEL_UART)     ? uart_ack
                                : 1;

    assign cpu_dbus_rdata_data_o = (port_sel == PORT_SEL_SDRAM)    ? sdram_rdata_i
                                 : (port_sel == PORT_SEL_CSR)      ? litedram_ctrl_dat_r_i
                                 : (port_sel == PORT_SEL_LITEDRAM) ? litedram_rdata_data
                                 : (port_sel == PORT_SEL_IMEM)     ? imem_rdata_data_i
                                 : (port_sel == PORT_SEL_UART)     ? uart_rdata_data_i
                                 : 0;

//==============================================================================
// SDRAM Control Interface
//------------------------------------------------------------------------------
    assign sdram_cmd_addr_o    = cpu_dbus_cmd_addr_i[15:2];
    assign sdram_cmd_valid_o   = cpu_dbus_cmd_valid_i & sdram_access;
    assign sdram_cmd_we_o      = cpu_dbus_cmd_we_i;
    assign sdram_wen_o         = cpu_dbus_wdata_en_i;
    assign sdram_wdata_o       = cpu_dbus_wdata_data_i;

//==============================================================================
// UART Control Interface
//------------------------------------------------------------------------------
    reg [7:0] uart_send  = 0;
    wire      uart_ack   = (uart_state == UART_STATE_ACK);

    localparam UART_STATE_IDLE = 2'b00;
    localparam UART_STATE_TX   = 2'b01;
    localparam UART_STATE_RX   = 2'b10;
    localparam UART_STATE_ACK  = 2'b11;
    reg [1:0] uart_state = UART_STATE_IDLE;
    always @(posedge clk_i) begin
        case(uart_state)
            UART_STATE_IDLE: if (uart_access & cpu_dbus_cmd_valid_i) begin
                uart_state <= (cpu_dbus_cmd_addr_i[2]) ? UART_STATE_RX : UART_STATE_TX;
                uart_send  <= cpu_dbus_wdata_data_i[7:0];
            end

            UART_STATE_RX: if (uart_rdata_valid_i) begin
                uart_state <= UART_STATE_ACK;
            end

            UART_STATE_TX: if (uart_wdata_ready_i) begin
                uart_state <= UART_STATE_ACK;
            end

            UART_STATE_ACK: begin
                uart_state <= UART_STATE_IDLE;
            end
        endcase
    end

    assign uart_rdata_ready_o = (uart_state == UART_STATE_RX);
    assign uart_wdata_valid_o = (uart_state == UART_STATE_TX);
    assign uart_wdata_data_o  = uart_send;
//==============================================================================
// VMEM Control Interface
//------------------------------------------------------------------------------
    assign vmem_we_o    = (cpu_dbus_cmd_valid_i & cpu_dbus_cmd_we_i & vmem_access);
    assign vmem_waddr_o = cpu_dbus_cmd_addr_i;
    assign vmem_wdata_o = cpu_dbus_wdata_data_i[7:0];

//==============================================================================
// IMEM Control Interface
//------------------------------------------------------------------------------
    assign imem_rdata_addr_o = cpu_ibus_raddr_i[31:2];
    assign imem_rdata_en_o   = cpu_ibus_rdata_en_i;
    assign imem_wdata_addr_o = cpu_dbus_cmd_addr_i[31:2];
    assign imem_wdata_data_o = cpu_dbus_wdata_data_i;
    assign imem_wdata_en_o   = cpu_dbus_wdata_en_i & {4{imem_access}};

//==============================================================================
// LiteDRAM Wishbone Control Interface
//------------------------------------------------------------------------------
    assign litedram_ctrl_adr_o   = cpu_dbus_cmd_addr_i[31:2];
    assign litedram_ctrl_cyc_o   = (csr_access) ? cpu_dbus_cmd_valid_i : 1'b0;
    assign litedram_ctrl_dat_w_o = cpu_dbus_wdata_data_i;
    assign litedram_ctrl_sel_o   = cpu_dbus_wdata_en_i;
    assign litedram_ctrl_stb_o   = (csr_access) ? cpu_dbus_cmd_valid_i : 1'b0;
    assign litedram_ctrl_we_o    = (csr_access) ? cpu_dbus_cmd_we_i : 1'b0;

//==============================================================================
// LiteDRAM Command Interface
//------------------------------------------------------------------------------
    localparam LITEDRAM_STATE_IDLE             = 3'b000;
    localparam LITEDRAM_STATE_WAIT_CMD_READY   = 3'b001;
    localparam LITEDRAM_STATE_WAIT_WDATA_READY = 3'b010;
    localparam LITEDRAM_STATE_WAIT_RDATA_VALID = 3'b011;
    localparam LITEDRAM_STATE_SEND_ACK         = 3'b100;
    reg   [2:0] litedram_state       = LITEDRAM_STATE_IDLE;
    reg  [23:0] litedram_cmd_addr    = 0;
    reg         litedram_cmd_valid   = 0;
    reg         litedram_cmd_we      = 0;
    reg         litedram_rdata_ready = 0;
    reg  [31:0] litedram_rdata_data  = 0;
    reg [127:0] litedram_wdata_data  = 0;
    reg         litedram_wdata_valid = 0;
    reg  [15:0] litedram_wdata_we    = 0;
    reg   [6:0] offset = 0;
    always @(posedge clk_i) begin
        case(litedram_state)
            LITEDRAM_STATE_IDLE: begin
                if (litedram_access & cpu_dbus_cmd_valid_i) begin
                    litedram_cmd_addr   <= cpu_dbus_cmd_addr_i[27:4];
                    offset              <= cpu_dbus_cmd_addr_i[3:2];
                    litedram_cmd_valid  <= 1;
                    litedram_cmd_we     <= cpu_dbus_cmd_we_i;
                    litedram_wdata_data <= cpu_dbus_wdata_data_i;
                    litedram_wdata_we   <= cpu_dbus_wdata_en_i;
                    litedram_state      <= LITEDRAM_STATE_WAIT_CMD_READY;
                end
            end
            LITEDRAM_STATE_WAIT_CMD_READY: begin
                if (litedram_cmd_ready_i) begin
                    litedram_cmd_valid <= 0;
                    if (litedram_cmd_we) begin
                        litedram_wdata_valid <= 1;
                        litedram_wdata_data  <= litedram_wdata_data << (offset << 5);
                        litedram_wdata_we    <= litedram_wdata_we << (offset << 2);
                        litedram_state       <= LITEDRAM_STATE_WAIT_WDATA_READY;
                    end else begin
                        litedram_rdata_ready <= 1;
                        litedram_state       <= LITEDRAM_STATE_WAIT_RDATA_VALID;
                    end
                end
            end
            LITEDRAM_STATE_WAIT_WDATA_READY: begin
                if (litedram_wdata_ready_i) begin
                    litedram_wdata_valid <= 0;
                    litedram_state       <= LITEDRAM_STATE_SEND_ACK;
                end
            end
            LITEDRAM_STATE_WAIT_RDATA_VALID: begin
                if (litedram_rdata_valid_i) begin
                    litedram_rdata_ready <= 0;
                    litedram_state       <= LITEDRAM_STATE_SEND_ACK;
                    litedram_rdata_data  <= (litedram_rdata_data_i >> (offset << 5)) & 32'hFFFF_FFFF;
                end
            end
            LITEDRAM_STATE_SEND_ACK: begin
                litedram_state <= LITEDRAM_STATE_IDLE;
            end
        endcase
    end
    assign litedram_cmd_addr_o    = litedram_cmd_addr;
    assign litedram_cmd_valid_o   = litedram_cmd_valid;
    assign litedram_cmd_we_o      = litedram_cmd_we;
    assign litedram_rdata_ready_o = litedram_rdata_ready;
    assign litedram_wdata_data_o  = litedram_wdata_data;
    assign litedram_wdata_valid_o = litedram_wdata_valid;
    assign litedram_wdata_we_o    = litedram_wdata_we;
endmodule  // mmu

module imem (
    input  wire                             clk_i,
    input  wire [$clog2(`IMEM_ENTRIES)-1:0] rdata_addr_i,
    output wire                      [31:0] rdata_data_o,
    input  wire                             rdata_en_i,
    input  wire [$clog2(`IMEM_ENTRIES)-1:0] wdata_addr_i,
    input  wire                      [31:0] wdata_data_i,
    input  wire                       [3:0] wdata_en_i,
    output wire                             wdata_ack_o
);
    reg [31:0] imem [0:`IMEM_ENTRIES-1];
    `include "imem_init.vh"

    reg                      [31:0] rdata      = 0;
    reg [$clog2(`IMEM_ENTRIES)-1:0] wdata_addr = 0;
    reg                      [31:0] wdata_data = 0;
    reg                       [3:0] wdata_en   = 0;

    localparam IMEM_STATE_IDLE  = 2'b00;
    localparam IMEM_STATE_WRITE = 2'b01;
    localparam IMEM_STATE_ACK   = 2'b10;
    reg [1:0] state;
    always @(posedge clk_i) begin
        if (rdata_en_i) rdata <= imem[rdata_addr_i];
        case(state)
            IMEM_STATE_IDLE: begin
                wdata_addr <= wdata_addr_i;
                wdata_data <= wdata_data_i;
                wdata_en   <= wdata_en_i;
                if (|wdata_en_i) state <= IMEM_STATE_WRITE;
            end

            IMEM_STATE_WRITE: begin
                if (wdata_en[0]) imem[wdata_addr][7:0]   <= wdata_data[7:0];
                if (wdata_en[1]) imem[wdata_addr][15:8]  <= wdata_data[15:8];
                if (wdata_en[2]) imem[wdata_addr][23:16] <= wdata_data[23:16];
                if (wdata_en[3]) imem[wdata_addr][31:24] <= wdata_data[31:24];
                state <= IMEM_STATE_ACK;
            end

            IMEM_STATE_ACK: begin
                state <= IMEM_STATE_IDLE;
            end
        endcase
    end
    assign wdata_ack_o  = (state == IMEM_STATE_ACK);
    assign rdata_data_o = rdata;
endmodule


module bootrom (
    input  wire        clk_i,
    input  wire  [9:0] raddr_i,
    output wire [31:0] rdata_o,
    input  wire        re_i
);
    reg [31:0] rdata = 0;
    reg [31:0] rom [0:1023];
    `include "bootrom_init.vh"

    always @(posedge clk_i) if (re_i) begin
        rdata <= rom[raddr_i];
    end
    assign rdata_o = rdata;
endmodule

module sdram (
    input  wire        clk_i,
    input  wire  [9:0] cmd_addr_i,
    input  wire        cmd_valid_i,
    input  wire        cmd_we_i,
    output wire        cmd_ack_o,
    input  wire  [3:0] write_en_i,
    input  wire [31:0] write_data_i,
    output wire [31:0] read_data_o
);
    reg [31:0] ram [0:1023];
    `include "sdram_init.vh"

    reg  [9:0] cmd_addr    = 0;
    reg [31:0] write_data  = 0;
    reg  [3:0] write_en    = 0;
    reg [31:0] read_data   = 0;

    localparam SDRAM_STATE_IDLE  = 2'b00;
    localparam SDRAM_STATE_WRITE = 2'b01;
    localparam SDRAM_STATE_READ  = 2'b10;
    localparam SDRAM_STATE_ACK   = 2'b11;
    reg  [1:0] sdram_state = SDRAM_STATE_IDLE;
    always @(posedge clk_i) begin
        case(sdram_state)
            SDRAM_STATE_IDLE: begin
                if (cmd_valid_i) begin
                    cmd_addr    <= cmd_addr_i;
                    write_data  <= write_data_i;
                    write_en    <= write_en_i;
                    sdram_state <= (cmd_we_i) ? SDRAM_STATE_WRITE : SDRAM_STATE_READ;
                end
            end
            SDRAM_STATE_WRITE: begin
                if (write_en[0]) ram[cmd_addr][7:0]   <= write_data[7:0];
                if (write_en[1]) ram[cmd_addr][15:8]  <= write_data[15:8];
                if (write_en[2]) ram[cmd_addr][23:16] <= write_data[23:16];
                if (write_en[3]) ram[cmd_addr][31:24] <= write_data[31:24];
                sdram_state <= SDRAM_STATE_ACK;
            end
            SDRAM_STATE_READ: begin
                read_data <= ram[cmd_addr];
                sdram_state <= SDRAM_STATE_ACK;
            end
            SDRAM_STATE_ACK: begin
                sdram_state <= SDRAM_STATE_IDLE;
            end
        endcase
    end

    assign read_data_o = read_data;
    assign cmd_ack_o  = (sdram_state == SDRAM_STATE_ACK);
endmodule

module vmem (
    input  wire        clk_i,
    input  wire        we_i,
    input  wire [15:0] waddr_i,
    input  wire  [2:0] wdata_i,
    input  wire [15:0] raddr_i,
    output wire  [2:0] rdata_o
);

    reg [2:0] vmem_lo[0:32767];  // vmem
    reg [2:0] vmem_hi[0:32767];  // vmem
    integer i;
    initial for (i = 0; i < 32768; i = i + 1) begin
        vmem_lo[i] = 0;
        vmem_hi[i] = 0;
    end

    reg        we;
    reg        top;
    reg [ 2:0] wdata;
    reg [14:0] waddr;

    reg        rtop;
    reg [14:0] raddr;
    reg [ 2:0] rdata_lo;
    reg [ 2:0] rdata_hi;
    reg        sel;

    localparam ADDR_MASK = 16'h7FFF;

    always @(posedge clk_i) begin
        we <= we_i;
        top <= waddr_i[15];
        waddr <= waddr_i[14:0];
        wdata <= wdata_i;

        rtop <= raddr_i[15];
        raddr <= raddr_i[14:0];

        if (we) begin
            if (top) vmem_hi[waddr&ADDR_MASK] <= wdata;
            else vmem_lo[waddr&ADDR_MASK] <= wdata;
        end

        sel <= rtop;
        rdata_lo <= vmem_lo[raddr&ADDR_MASK];
        rdata_hi <= vmem_hi[raddr&ADDR_MASK];
    end

    assign rdata_o = (sel) ? rdata_hi : rdata_lo;

`ifndef SYNTHESIS
    reg  [15:0] r_adr_p = 0;
    reg  [15:0] r_dat_p = 0;

    wire [15:0] data = {{5{wdata_i[2]}}, {6{wdata_i[1]}}, {5{wdata_i[0]}}};
    always @(posedge clk_i)
        if (we_i) begin
            case (waddr_i[15])
                0:
                if (vmem_lo[waddr_i&ADDR_MASK] != wdata_i) begin
                    r_adr_p <= waddr_i;
                    r_dat_p <= data;
                    $write("@D%0d_%0d\n", waddr_i ^ r_adr_p, data ^ r_dat_p);
                    $fflush();
                end
                1:
                if (vmem_hi[waddr_i&ADDR_MASK] != wdata_i) begin
                    r_adr_p <= waddr_i;
                    r_dat_p <= data;
                    $write("@D%0d_%0d\n", waddr_i ^ r_adr_p, data ^ r_dat_p);
                    $fflush();
                end
            endcase
        end
`endif
endmodule

module m_st7789_disp (
    input wire w_clk,  // main clock signal (100MHz)
    output wire st7789_SDA,
    output wire st7789_SCL,
    output wire st7789_DC,
    output wire st7789_RES,
    output wire [15:0] w_raddr,
    input wire [15:0] w_rdata
);
    reg [31:0] r_cnt = 1;
    always @(posedge w_clk) r_cnt <= (r_cnt == 0) ? 0 : r_cnt + 1;
    reg r_RES = 1;
    always @(posedge w_clk) begin
        r_RES <= (r_cnt == 100000) ? 0 : (r_cnt == 200000) ? 1 : r_RES;
    end
    assign st7789_RES = r_RES;

    wire busy;
    reg r_en = 0;
    reg init_done = 0;
    reg [4:0] r_state = 0;
    reg [19:0] r_state2 = 0;
    reg [8:0] r_dat = 0;
    reg [15:0] r_c = 16'hf800;

    reg [31:0] r_bcnt = 0;
    always @(posedge w_clk) r_bcnt <= (busy) ? 0 : r_bcnt + 1;

    always @(posedge w_clk)
        if (!init_done) begin
            r_en <= (r_cnt > 1000000 && !busy && r_bcnt > 1000000);
        end else begin
            r_en <= (!busy);
        end

    always @(posedge w_clk) if (r_en && !init_done) r_state <= r_state + 1;

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

    wire [7:0] w_nx = 239 - r_x;
    wire [7:0] w_ny = 239 - r_y;
    assign w_raddr = (`LCD_ROTATE == 0) ? {r_y, r_x} :  // default
        (`LCD_ROTATE == 1) ? {r_x, w_ny} :  // 90 degree rotation
        (`LCD_ROTATE == 2) ? {w_ny, w_nx} : {w_nx, r_y};  //180 degree, 240 degree rotation

    reg [15:0] r_color = 0;
    always @(posedge w_clk) r_color <= w_rdata;

    always @(posedge w_clk) begin
        case (r_state2)  /////
            0: r_dat <= {1'b0, 8'h2A};  // Column Address Set
            1: r_dat <= {1'b1, 8'h00};  // [0]
            2: r_dat <= {1'b1, 8'h00};  // [0]
            3: r_dat <= {1'b1, 8'h00};  // [0]
            4: r_dat <= {1'b1, 8'd239};  // [239]
            5: r_dat <= {1'b0, 8'h2B};  // Row Address Set
            6: r_dat <= {1'b1, 8'h00};  // [0]
            7: r_dat <= {1'b1, 8'h00};  // [0]
            8: r_dat <= {1'b1, 8'h00};  // [0]
            9: r_dat <= {1'b1, 8'd239};  // [239]
            10: r_dat <= {1'b0, 8'h2C};  // Memory Write
            default: r_dat <= (r_state2[0]) ? {1'b1, r_color[15:8]} : {1'b1, r_color[7:0]};
        endcase
    end

    reg [8:0] r_init = 0;
    always @(posedge w_clk) begin
        case (r_state)  /////
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

    wire [8:0] w_data = (init_done) ? r_dat : r_init;
    m_spi spi0 (
        w_clk,
        r_en,
        w_data,
        st7789_SDA,
        st7789_SCL,
        st7789_DC,
        busy
    );
endmodule

/****** SPI send module,  SPI_MODE_2, MSBFIRST                                           *****/
/*********************************************************************************************/
module m_spi (
    input  wire       w_clk,  // 100MHz input clock !!
    input  wire       en,     // write enable
    input  wire [8:0] d_in,   // data in
    output wire       SDA,    // Serial Data
    output wire       SCL,    // Serial Clock
    output wire       DC,     // Data/Control
    output wire       busy    // busy
);
    reg [5:0] r_state = 0;
    reg [7:0] r_cnt = 0;
    reg r_SCL = 1;
    reg r_DC = 0;
    reg [7:0] r_data = 0;
    reg r_SDA = 0;

    always @(posedge w_clk) begin
        if (en && r_state == 0) begin
            r_state <= 1;
            r_data  <= d_in[7:0];
            r_DC    <= d_in[8];
            r_cnt   <= 0;
        end else if (r_state == 1) begin
            r_SDA   <= r_data[7];
            r_data  <= {r_data[6:0], 1'b0};
            r_state <= 2;
            r_cnt   <= r_cnt + 1;
        end else if (r_state == 2) begin
            r_SCL   <= 0;
            r_state <= 3;
        end else if (r_state == 3) begin
            r_state <= 4;
        end else if (r_state == 4) begin
            r_SCL   <= 1;
            r_state <= (r_cnt == 8) ? 0 : 1;
        end
    end

    assign SDA  = r_SDA;
    assign SCL  = r_SCL;
    assign DC   = r_DC;
    assign busy = (r_state != 0 || en);
endmodule
/*********************************************************************************************/
`resetall
