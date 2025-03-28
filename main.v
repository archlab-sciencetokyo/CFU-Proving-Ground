/* CFU Proving Ground since 2025-02    Copyright(c) 2025 Archlab. Science Tokyo /
/ Released under the MIT license https://opensource.org/licenses/mit           */

`resetall
`default_nettype none

`include "config.vh"

module main (
    input  wire clk_i       ,
    output wire st7789_SDA  ,
    output wire st7789_SCL  ,
    output wire st7789_DC   , 
    output wire st7789_RES 
);
//    wire rst_ni = 1;
    reg rst_ni = 0; initial #15 rst_ni = 1;
    wire clk, locked;

`ifdef USE_CLK_WIZ
    clk_wiz_0 clk_wiz_0 (
        .clk_out1           (clk                ), // output clk_out1
        .reset              (!rst_ni                ), // input reset
        .locked             (locked             ), // output locked
        .clk_in1            (clk_i              )  // input clk_in1
    );
`else
    assign clk      = clk_i ;
    assign locked   = 1'b1  ;
`endif

    wire                        rst             = !rst_ni || !locked;
    wire [`IBUS_ADDR_WIDTH-1:0] imem_raddr  ;
    wire [`IBUS_DATA_WIDTH-1:0] imem_rdata  ;
    wire                        dbus_we     ;
    wire [`DBUS_ADDR_WIDTH-1:0] dbus_addr   ;
    wire [`DBUS_DATA_WIDTH-1:0] dbus_wdata  ;
    wire [`DBUS_STRB_WIDTH-1:0] dbus_wstrb  ;
    wire [`DBUS_DATA_WIDTH-1:0] dbus_rdata  ;

    reg rdata_sel = 0; always @(posedge clk) rdata_sel <= dbus_addr[30];
    assign dbus_rdata = (rdata_sel) ? perf_rdata : dmem_rdata;

    cpu cpu (
        .clk_i              (clk                ), // input  wire
        .rst_i              (rst                ), // input  wire
        .ibus_araddr_o      (imem_raddr         ), // output wire [`IBUS_ADDR_WIDTH-1:0]
        .ibus_rdata_i       (imem_rdata         ), // input  wire [`IBUS_DATA_WIDTH-1:0]
        .dbus_addr_o        (dbus_addr          ), // output wire [`DBUS_ADDR_WIDTH-1:0]
        .dbus_wvalid_o      (dbus_we            ), // output wire
        .dbus_wdata_o       (dbus_wdata         ), // output wire [`DBUS_DATA_WIDTH-1:0]
        .dbus_wstrb_o       (dbus_wstrb         ), // output wire [`DBUS_STRB_WIDTH-1:0]
        .dbus_rdata_i       (dbus_rdata         )  // input  wire [`DBUS_DATA_WIDTH-1:0]
    );

    imem #(
        .RAM_SIZE           (`IMEM_SIZE         )
    ) imem (
        .clk_i              (clk                ), // input  wire
        .raddr_i            (imem_raddr         ), // input  wire [ADDR_WIDTH-1:0]
        .rdata_o            (imem_rdata         )  // output reg  [DATA_WIDTH-1:0]
    );

    wire dmem_we = dbus_we & (dbus_addr[28]);
    wire [31:0] dmem_addr = dbus_addr;
    wire [31:0] dmem_wdata = dbus_wdata;
    wire [3:0] dmem_wstrb = dbus_wstrb;
    wire [31:0] dmem_rdata;
    dmem #(
        .RAM_SIZE           (`DMEM_SIZE         )
    ) dmem (
        .clk_i              (clk                ),   // input  wire
        .we_i               (dmem_we            ),   // input  wire                  
        .addr_i            (dmem_addr         ),   // input  wire [ADDR_WIDTH-1:0] 
        .wdata_i            (dmem_wdata         ),   // input  wire [DATA_WIDTH-1:0] 
        .wstrb_i            (dmem_wstrb         ),   // input  wire [STRB_WIDTH-1:0] 
        .rdata_o            (dmem_rdata         )    // output reg  [DATA_WIDTH-1:0] 
    );

    wire vmem_we = dbus_we & (dbus_addr[29]);
    wire [15:0] vmem_addr =  dbus_addr[15:0];
    wire [ 2:0] vmem_wdata = dbus_wdata[2:0];
    wire [15:0] vmem_raddr;
    wire [ 2:0] vmem_rdata_t;
    vmem vmem (
        .clk_i              (clk                ), // input wire
        .we_i               (vmem_we            ), // input wire
        .waddr_i            (vmem_addr          ), // input wire [15:0]
        .wdata_i            (vmem_wdata         ), // input wire [15:0]
        .raddr_i            (vmem_raddr         ), // input wire [15:0]
        .rdata_o            (vmem_rdata_t       )  // output wire [15:0]
    );

    wire perf_we = dbus_we & (dbus_addr[30]);
    wire [3:0] perf_addr = dbus_addr[3:0];
    wire [2:0] perf_wdata = dbus_wdata[2:0];
    wire [31:0] perf_rdata;
    perf_cntr perf(
        .clk_i              (clk                ), // input  wire
        .addr_i             (perf_addr          ), // input  wire [3:0]
        .wdata_i            (perf_wdata         ), // input  wire [2:0]
        .w_en_i             (perf_we            ), // input  wire
        .rdata_o            (perf_rdata         )  // output wire [31:0]
    );

    wire [15:0] vmem_rdata = {{5{vmem_rdata_t[2]}}, {6{vmem_rdata_t[1]}}, {5{vmem_rdata_t[0]}}};
    m_st7789_disp st7789_disp (
        .w_clk              (clk                ), // input  wire
        .st7789_SDA         (st7789_SDA         ), // output wire
        .st7789_SCL         (st7789_SCL         ), // output wire
        .st7789_DC          (st7789_DC          ), // output wire
        .st7789_RES         (st7789_RES         ), // output wire
        .w_raddr            (vmem_raddr         ), // output wire [15:0]
        .w_rdata            (vmem_rdata         )  // input  wire [15:0]
    );

endmodule

module imem #(
    parameter RAM_SIZE      = 4*1024        ,
    parameter ADDR_WIDTH    = 32            ,
    parameter DATA_WIDTH    = 32
) (
    input  wire                  clk_i      ,
    input  wire [ADDR_WIDTH-1:0] raddr_i    ,
    output reg  [DATA_WIDTH-1:0] rdata_o
);

    localparam OFFSET_WIDTH     = $clog2(DATA_WIDTH/8)          ;
    localparam VALID_ADDR_WIDTH = $clog2(RAM_SIZE)-OFFSET_WIDTH ;
    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] imem [0:(2**VALID_ADDR_WIDTH)-1];
    `include "memi.txt"

    wire [VALID_ADDR_WIDTH-1:0] valid_raddr = raddr_i[VALID_ADDR_WIDTH+OFFSET_WIDTH-1:OFFSET_WIDTH];

    always @(posedge clk_i) begin
        rdata_o <= imem[valid_raddr];
    end

endmodule

module dmem #(
    parameter RAM_SIZE      = 4*1024        ,
    parameter ADDR_WIDTH    = 32            ,
    parameter DATA_WIDTH    = 32            ,
    parameter STRB_WIDTH    = DATA_WIDTH/8
) (
    input  wire                  clk_i      ,
    input  wire                  we_i       ,
    input  wire [ADDR_WIDTH-1:0] addr_i    ,
    input  wire [DATA_WIDTH-1:0] wdata_i    ,
    input  wire [STRB_WIDTH-1:0] wstrb_i    ,
    output wire [DATA_WIDTH-1:0] rdata_o
);

    localparam OFFSET_WIDTH     = $clog2(DATA_WIDTH/8)          ;
    localparam VALID_ADDR_WIDTH = $clog2(RAM_SIZE)-OFFSET_WIDTH ;
    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] dmem [0:(2**VALID_ADDR_WIDTH)-1];
    `include "memd.txt"

    wire [VALID_ADDR_WIDTH-1:0] valid_addr = addr_i[VALID_ADDR_WIDTH+OFFSET_WIDTH-1:OFFSET_WIDTH];

    integer i;
    reg [31:0] rdata = 0;
    always @(posedge clk_i) begin
        if (we_i) begin  ///// data bus
            if (wstrb_i[0]) dmem[valid_addr][7:0]   <= wdata_i[7:0];
            if (wstrb_i[1]) dmem[valid_addr][15:8]  <= wdata_i[15:8];
            if (wstrb_i[2]) dmem[valid_addr][23:16] <= wdata_i[23:16];
            if (wstrb_i[3]) dmem[valid_addr][31:24] <= wdata_i[31:24];
        end
        rdata <= dmem[valid_addr];
    end

    assign rdata_o = rdata; 

endmodule

module perf_cntr (
    input   wire        clk_i,
    input   wire [3:0]  addr_i,
    input   wire [2:0]  wdata_i,
    input   wire        w_en_i,
    output  wire [31:0] rdata_o
);
    reg [63:0]  mcycle      = 0;
    reg [1:0]   cnt_ctrl    = 0;
    reg [31:0]  rdata       = 0;

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
    input wire clk_i,
    input wire        we_i,
    input wire [15:0] waddr_i,
    input wire [2:0] wdata_i,
    input wire [15:0] raddr_i,
    output wire [2:0] rdata_o
);

    reg [2:0] vmem_lo [0:32767]; // vmem
    reg [2:0] vmem_hi [0:32767]; // vmem

    reg [2:0] rdata_lo;
    reg [2:0] rdata_hi;
    reg       sel;

    always @(posedge clk_i) begin
        if (we_i) begin
            if (waddr_i[15]) vmem_hi[waddr_i[14:0]] <= wdata_i;
            else             vmem_lo[waddr_i[14:0]] <= wdata_i;
        end
        sel <= raddr_i[15];
        rdata_lo <= vmem_lo[raddr_i[14:0]];
        rdata_hi <= vmem_hi[raddr_i[14:0]];
    end

    assign rdata_o = (sel) ? rdata_hi : rdata_lo;


`ifndef SYNTHESIS
    reg [15:0] r_adr_p = 0;
    reg [15:0] r_dat_p = 0;

    wire [15:0] data = {{5{wdata_i[2]}}, {6{wdata_i[1]}}, {5{wdata_i[0]}}};
    always @(posedge clk_i) if(we_i) begin
        case (waddr_i[15])
            0: if(vmem_lo[waddr_i] != wdata_i) begin
                r_adr_p <= waddr_i;
                r_dat_p <= data;
                $write("@D%0d_%0d\n", waddr_i ^ r_adr_p, data ^ r_dat_p);
                $fflush();
            end
            1: if(vmem_hi[waddr_i] != wdata_i) begin
                r_adr_p <= waddr_i;
                r_dat_p <= data;
                $write("@D%0d_%0d\n", waddr_i ^ r_adr_p, data ^ r_dat_p);
                $fflush();
            end
        endcase
    end
`endif

endmodule

module m_st7789_disp(
    input  wire w_clk, // main clock signal (100MHz)
    output wire st7789_SDA,
    output wire st7789_SCL,
    output wire st7789_DC,
    output wire st7789_RES,
    output wire [15:0] w_raddr,
    input  wire [15:0] w_rdata
);
    reg [31:0] r_cnt=1;
    always @(posedge w_clk) r_cnt <= (r_cnt==0) ? 0 : r_cnt + 1;
    reg r_RES = 1;
    always @(posedge w_clk) begin
        r_RES <= (r_cnt==100_000) ? 0 : (r_cnt==200_000) ? 1 : r_RES;
    end
    assign st7789_RES = r_RES;    
       
    wire busy; 
    reg r_en = 0;
    reg init_done = 0;
    reg [4:0]  r_state  = 0;   
    reg [19:0] r_state2 = 0;   
    reg [8:0] r_dat = 0;
    reg [15:0] r_c = 16'hf800;
   
    reg [31:0] r_bcnt = 0;
    always @(posedge w_clk) r_bcnt <= (busy) ? 0 : r_bcnt + 1;
    
    always @(posedge w_clk) if(!init_done) begin
        r_en <= (r_cnt>1_000_000 && !busy && r_bcnt>1_000_000); 
    end else begin
        r_en <= (!busy);
    end
    
    always @(posedge w_clk) if(r_en && !init_done) r_state <= r_state  + 1;
    
    always @(posedge w_clk) if(r_en &&  init_done) begin
        r_state2 <= (r_state2==115210) ? 0 : r_state2 + 1; // 11 + 240x240*2 = 11 + 115200 = 115211
    end

    reg [7:0] r_x = 0;
    reg [7:0] r_y = 0;
    always @(posedge w_clk) if(r_en && init_done && r_state2[0]==1) begin
       r_x <= (r_state2<=10 || r_x==239) ? 0 : r_x + 1;
       r_y <= (r_state2<=10) ? 0 : (r_x==239) ? r_y + 1 : r_y;
    end

    wire [7:0] w_nx = 239-r_x;     
    wire [7:0] w_ny = 239-r_y;  
    assign w_raddr = (`LCD_ROTATE==0) ? {r_y, r_x} :  // default
                     (`LCD_ROTATE==1) ? {r_x, w_ny} : // 90 degree rotation
                     (`LCD_ROTATE==2) ? {w_ny, w_nx} : {w_nx, r_y} ; //180 degree, 240 degree rotation
    
    reg  [15:0] r_color = 0;
    always @(posedge w_clk) r_color <= w_rdata;  
 
    always @(posedge w_clk) begin
        case (r_state2) /////
            0:  r_dat<={1'b0, 8'h2A};   // Column Address Set
            1:  r_dat<={1'b1, 8'h00};   // [0]
            2:  r_dat<={1'b1, 8'h00};   // [0]
            3:  r_dat<={1'b1, 8'h00};   // [0]
            4:  r_dat<={1'b1, 8'd239};  // [239]
            5:  r_dat<={1'b0, 8'h2B};   // Row Address Set
            6:  r_dat<={1'b1, 8'h00};   // [0]
            7:  r_dat<={1'b1, 8'h00};   // [0]
            8:  r_dat<={1'b1, 8'h00};   // [0]
            9:  r_dat<={1'b1, 8'd239};  // [239]
            10: r_dat<={1'b0, 8'h2C};   // Memory Write
            default: r_dat <= (r_state2[0]) ? {1'b1, r_color[15:8]} :{ 1'b1, r_color[7:0]}; 
        endcase
    end
    
    reg [8:0] r_init = 0;
    always @(posedge w_clk) begin
        case (r_state) /////
            0:  r_init<={1'b0, 8'h01};  // Software Reset, wait 120msec
            1:  r_init<={1'b0, 8'h11};  // Sleep Out, wait 120msec
            2:  r_init<={1'b0, 8'h3A};  // Interface Pixel Format
            3:  r_init<={1'b1, 8'h55};  // [65K RGB, 16bit/pixel]
            4:  r_init<={1'b0, 8'h36};  // Memory Data Accell Control
            5:  r_init<={1'b1, 8'h00};  // [000000]
            6:  r_init<={1'b0, 8'h21};  // Display Inversion On
            7:  r_init<={1'b0, 8'h13};  // Normal Display Mode On
            8:  r_init<={1'b0, 8'h29};  // Display On
            9 : init_done <= 1;
        endcase
    end

    wire [8:0] w_data = (init_done) ? r_dat : r_init;
    m_spi spi0 (w_clk, r_en, w_data, st7789_SDA, st7789_SCL, st7789_DC, busy);
endmodule

/****** SPI send module,  SPI_MODE_2, MSBFIRST                                           *****/
/*********************************************************************************************/
module m_spi(
    input  wire w_clk,       // 100MHz input clock !!
    input  wire en,          // write enable
    input  wire [8:0] d_in,  // data in
    output wire SDA,         // Serial Data
    output wire SCL,         // Serial Clock
    output wire DC,          // Data/Control
    output wire busy         // busy
);
    reg [5:0] r_state = 0;
    reg [7:0] r_cnt = 0;
    reg r_SCL = 1;
    reg r_DC  = 0;
    reg [7:0] r_data = 0;
    reg r_SDA = 0;

    always @(posedge w_clk) begin
        if(en && r_state==0) begin
            r_state <= 1;
            r_data  <= d_in[7:0];
            r_DC    <= d_in[8];
            r_cnt   <= 0;
        end
        else if (r_state==1) begin
            r_SDA   <= r_data[7];
            r_data  <= {r_data[6:0], 1'b0};
            r_state <= 2;
            r_cnt   <= r_cnt + 1;
        end
        else if (r_state==2) begin
            r_SCL   <= 0;
            r_state <= 3;
        end
        else if (r_state==3) begin
            r_state <= 4;
        end
        else if (r_state==4) begin
            r_SCL   <= 1;
            r_state <= (r_cnt==8) ? 0 : 1;
        end
    end

    assign SDA = r_SDA;
    assign SCL = r_SCL;
    assign DC  = r_DC;
    assign busy = (r_state!=0 || en);
endmodule
/*********************************************************************************************/


`resetall