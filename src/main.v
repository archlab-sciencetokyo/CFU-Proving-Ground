/* CFU Proving Ground since 2025-02    Copyright(c) 2025 Archlab. Science Tokyo /
/ Released under the MIT license https://opensource.org/licenses/mit           */
`resetall `default_nettype none
`include "config.vh"

module main (
    input  wire clk_i,
    output wire st7789_SDA,
    output wire st7789_SCL,
    output wire st7789_DC,
    output wire st7789_RES
);
//==============================================================================
// Clock and Reset
//------------------------------------------------------------------------------
    reg  rst_ni = 1;
    wire clk;
    wire locked;
    wire rst;
`ifdef SYNTHESIS
    clk_wiz_0 clk_wiz_0 (
        .clk_out1(clk),      // output clk_out1
        .reset   (!rst_ni),  // input reset
        .locked  (locked),   // output locked
        .clk_in1 (clk_i)     // input clk_in1
    );
`else
    assign clk    = clk_i;
    assign locked = 1'b1;
`endif
    assign rst    = ~rst_ni | ~locked;

//==============================================================================
// CPU
//------------------------------------------------------------------------------
    wire [$clog2(`IMEM_ENTRIES)-1:0] ibus_raddr;
    wire                      [31:0] ibus_rdata;
    wire                      [31:0] dbus_addr;
    wire                             dbus_we;
    wire                      [31:0] dbus_wdata;
    wire                      [ 3:0] dbus_wstrb;
    wire                      [31:0] dbus_rdata;
    cpu cpu (
        .clk_i        (clk),         // input  wire
        .rst_i        (rst),         // input  wire
        .ibus_addr_o  (ibus_raddr),  // output wire [`IBUS_ADDR_WIDTH-1:0]
        .ibus_data_i  (ibus_rdata),  // input  wire [`IBUS_DATA_WIDTH-1:0]
        .dbus_addr_o  (dbus_addr),   // output wire [`DBUS_ADDR_WIDTH-1:0]
        .dbus_wvalid_o(dbus_we),     // output wire
        .dbus_wdata_o (dbus_wdata),  // output wire [`DBUS_DATA_WIDTH-1:0]
        .dbus_wstrb_o (dbus_wstrb),  // output wire [`DBUS_STRB_WIDTH-1:0]
        .dbus_rdata_i (dbus_rdata)   // input  wire [`DBUS_DATA_WIDTH-1:0]
    );

//==============================================================================
// 0x0000_0000 - 0x0000_2000 : 8 KiB bootrom
//------------------------------------------------------------------------------ 
    wire [$clog2(`IMEM_ENTRIES)-1:0] bootrom_raddr;
    wire                      [31:0] bootrom_rdata;
    bootrom bootrom (
        .clk_i  (clk),            // input  wire
        .raddr_i(bootrom_raddr),  // input  wire [ADDR_WIDTH-1:0]
        .rdata_o(bootrom_rdata)   // output reg  [DATA_WIDTH-1:0]
    );

//==============================================================================
// 0x2000_0000 - 0x2007_0800 : VMEM
//------------------------------------------------------------------------------
    wire        vmem_we;
    wire [15:0] vmem_addr;
    wire  [2:0] vmem_wdata;
    wire [15:0] vmem_raddr;
    wire [15:0] vmem_rdata;
    vmem vmem (
        .clk_i  (clk),          // input wire
        .we_i   (vmem_we),      // input wire
        .waddr_i(vmem_addr),    // input wire [15:0]
        .wdata_i(vmem_wdata),   // input wire [15:0]
        .raddr_i(vmem_raddr),   // input wire [15:0]
        .rdata_o(vmem_rdata)  // output wire [15:0]
    );

    wire [15:0] color_data;
    assign color_data = {{5{vmem_rdata[2]}},
                         {6{vmem_rdata[1]}},
                         {5{vmem_rdata[0]}}};
    m_st7789_disp st7789_disp (
        .w_clk     (clk),         // input  wire
        .st7789_SDA(st7789_SDA),  // output wire
        .st7789_SCL(st7789_SCL),  // output wire
        .st7789_DC (st7789_DC),   // output wire
        .st7789_RES(st7789_RES),  // output wire
        .w_raddr   (vmem_raddr),  // output wire [15:0]
        .w_rdata   (color_data)   // input  wire [15:0]
    );

//==============================================================================
// 0x8000_0000 - 0x9000_0000 : DMEM
//------------------------------------------------------------------------------
    wire        dmem_we;
    wire [31:0] dmem_addr;
    wire [31:0] dmem_wdata;
    wire  [3:0] dmem_wstrb;
    wire [31:0] dmem_rdata;
    m_dmem dmem (
        .clk_i  (clk),         // input  wire
        .we_i   (dmem_we),     // input  wire                  
        .addr_i (dmem_addr),   // input  wire [ADDR_WIDTH-1:0] 
        .wdata_i(dmem_wdata),  // input  wire [DATA_WIDTH-1:0] 
        .wstrb_i(dmem_wstrb),  // input  wire [STRB_WIDTH-1:0] 
        .rdata_o(dmem_rdata)   // output reg  [DATA_WIDTH-1:0] 
    );

//==============================================================================
// Memory Management Unit
//------------------------------------------------------------------------------
    mmu mmu (
        .clk_i         (clk),            // input  wire
        .cpu_ibus_raddr(ibus_raddr),     // input  wire [ADDR_WIDTH
        .cpu_ibus_rdata(ibus_rdata),     // output wire [DATA_WIDTH
        .cpu_dbus_addr (dbus_addr),      // input  wire [ADDR_WIDTH
        .cpu_dbus_we   (dbus_we),        // input  wire
        .cpu_dbus_wdata(dbus_wdata),     // input  wire [DATA_WIDTH
        .cpu_dbus_wstrb(dbus_wstrb),     // input  wire [
        .cpu_dbus_rdata(dbus_rdata),     // output wire [DATA_WIDTH
        .bootrom_raddr (bootrom_raddr),  // output wire [ADDR
        .bootrom_rdata (bootrom_rdata),  // input  wire [DATA_WIDTH
        .vmem_we       (vmem_we),        // output wire
        .vmem_addr     (vmem_addr),      // output wire [15:0
        .vmem_wdata    (vmem_wdata),     // output wire [2:0]
        .dmem_we       (dmem_we),        // output wire
        .dmem_addr     (dmem_addr),      // output wire [ADDR_WIDTH
        .dmem_wdata    (dmem_wdata),     // output wire [DATA
        .dmem_wstrb    (dmem_wstrb),     // output wire [STRB_WIDTH
        .dmem_rdata    (dmem_rdata)      // input  wire [
    );
endmodule  // main

module mmu (
    input  wire                             clk_i,
    // CPU
    input  wire [$clog2(`IMEM_ENTRIES)-1:0] cpu_ibus_raddr,
    output wire                      [31:0] cpu_ibus_rdata,
    input  wire                      [31:0] cpu_dbus_addr,
    input  wire                             cpu_dbus_we,
    input  wire                      [31:0] cpu_dbus_wdata,
    input  wire                      [ 3:0] cpu_dbus_wstrb,
    output wire                      [31:0] cpu_dbus_rdata,
    // bootrom
    output wire [$clog2(`IMEM_ENTRIES)-1:0] bootrom_raddr,
    input  wire                      [31:0] bootrom_rdata,
    // VMEM
    output wire        vmem_we,
    output wire [15:0] vmem_addr,
    output wire  [2:0] vmem_wdata,
    // DMEM
    output wire        dmem_we,
    output wire [31:0] dmem_addr,
    output wire [31:0] dmem_wdata,
    output wire  [3:0] dmem_wstrb,
    input  wire [31:0] dmem_rdata
);
    // CPU <-> bootrom
    assign bootrom_raddr  = cpu_ibus_raddr;
    assign cpu_ibus_rdata = bootrom_rdata;

    // CPU <-> VMEM
    assign vmem_we    = cpu_dbus_we & (cpu_dbus_addr[29]);
    assign vmem_addr  = cpu_dbus_addr[15:0];
    assign vmem_wdata = cpu_dbus_wdata[2:0];

    // CPU <-> DMEM
    assign dmem_we    = cpu_dbus_we & (cpu_dbus_addr[31]);
    assign dmem_addr  = cpu_dbus_addr;
    assign dmem_wdata = cpu_dbus_wdata;
    assign dmem_wstrb = cpu_dbus_wstrb;
    assign cpu_dbus_rdata = dmem_rdata;
endmodule  // mmu

module bootrom (
    input  wire        clk_i,
    input  wire [$clog2(`IMEM_ENTRIES)-1:0] raddr_i,
    output wire [31:0] rdata_o
);
    reg [31:0] imem[0:`IMEM_ENTRIES-1];
    reg [31:0] rdata = 0;
    `include "imem_init.vh"

    always @(posedge clk_i) begin
        rdata <= imem[raddr_i];
    end
    assign rdata_o = rdata;
endmodule

module m_dmem (
    input  wire        clk_i,
    input  wire        we_i,
    input  wire [31:0] addr_i,
    input  wire [31:0] wdata_i,
    input  wire [ 3:0] wstrb_i,
    output wire [31:0] rdata_o
);

    (* ram_style = "block" *) reg [31:0] dmem[0:`DMEM_ENTRIES-1];
    `include "dmem_init.vh"

    wire [$clog2(`DMEM_ENTRIES)-1:0] valid_addr = addr_i[$clog2(`DMEM_ENTRIES)+1:2];

    reg [31:0] rdata = 0;
    always @(posedge clk_i) begin
        if (we_i) begin  ///// data bus
            if (wstrb_i[0]) dmem[valid_addr][7:0] <= wdata_i[7:0];
            if (wstrb_i[1]) dmem[valid_addr][15:8] <= wdata_i[15:8];
            if (wstrb_i[2]) dmem[valid_addr][23:16] <= wdata_i[23:16];
            if (wstrb_i[3]) dmem[valid_addr][31:24] <= wdata_i[31:24];
        end
        rdata <= dmem[valid_addr];
    end
    assign rdata_o = rdata;
endmodule

module perf_cntr (
    input  wire        clk_i,
    input  wire [ 3:0] addr_i,
    input  wire [ 2:0] wdata_i,
    input  wire        w_en_i,
    output wire [31:0] rdata_o
);
    reg [63:0] mcycle = 0;
    reg [ 1:0] cnt_ctrl = 0;
    reg [31:0] rdata = 0;

    always @(posedge clk_i) begin
        rdata <= (addr_i[2]) ? mcycle[31:0] : mcycle[63:32];
        if (w_en_i && addr_i == 0) cnt_ctrl <= wdata_i[1:0];
        case (cnt_ctrl)
            0: mcycle <= 0;
            1: mcycle <= mcycle + 1;
            default: ;
        endcase
    end

    assign rdata_o = rdata;
endmodule

module vmem (
    input  wire        clk_i,
    input  wire        we_i,
    input  wire [15:0] waddr_i,
    input  wire [ 2:0] wdata_i,
    input  wire [15:0] raddr_i,
    output wire [ 2:0] rdata_o
);

    reg [2:0] vmem_lo[0:32767];  // vmem
    reg [2:0] vmem_hi[0:32767];  // vmem
    integer i;
    initial
        for (i = 0; i < 32768; i = i + 1) begin
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
