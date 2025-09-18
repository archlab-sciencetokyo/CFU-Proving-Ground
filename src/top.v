/* CFU Proving Ground since 2025-02    Copyright(c) 2025 Archlab. Science Tokyo /
/ Released under the MIT license https://opensource.org/licenses/mit           */

`default_nettype none

module top;
//==============================================================================
// Clock and Reset
//------------------------------------------------------------------------------
    reg        clk   = 1; always #5 clk <= ~clk;
    reg        rst_n = 0; initial #100 rst_n = 1;
    reg [63:0] cc    = 0; always @(posedge clk) cc <= cc + 1;
    
//==============================================================================
// Simulated UART
//------------------------------------------------------------------------------
    wire       uart_txd;
    wire       uart_rxd;
    reg        uart_wvalid;
    wire       uart_wready;
    reg  [7:0] uart_wdata;
    wire       uart_rvalid;
    wire       uart_rready;
    wire [7:0] uart_rdata;
    //uart uart (
    //    .clk_i    (clk),
    //    .rst_i    (0),
    //    .txd_o    (uart_txd),
    //    .rxd_i    (uart_rxd),
    //    .wvalid_i (uart_wvalid),
    //    .wready_o (uart_wready),
    //    .wdata_i  (uart_wdata),
    //    .rvalid_o (uart_rvalid),
    //    .rready_i (uart_rready),
    //    .rdata_o  (uart_rdata)
    //);
    uart_tx #(
        .CLK_FREQ_MHZ   (`CLK_FREQ_MHZ   ),
        .BAUD_RATE      (`UART_BAUDRATE )
    ) uart_tx (
        .clk_i          (clk         ),
        .rst_i          (0           ),
        .txd_o          (uart_txd    ),
        .wvalid_i       (uart_wvalid ),
        .wready_o       (uart_wready ),
        .wdata_i        (uart_wdata  )
    );

    reg  [31:0] imem [0:`IMEM_ENTRIES-1];
    `include "imem_init.vh"
    reg  [31:0] dram [0:`DMEM_ENTRIES-1];
    `include "dram_init.vh"
    reg  [31:0] p      = 0;
    wire  [1:0] offset = p & 3;
    wire [31:2] addr   = p >> 2;
    localparam WAITING_CARIB = 0;
    localparam INIT_IMEM = 1;
    localparam INIT_DMEM = 2;
    localparam DONE = 3;
    reg [1:0] init_state = WAITING_CARIB;
    always @(posedge clk) begin
        case(init_state)
            WAITING_CARIB: begin
                if (cc > 190000) init_state <= INIT_IMEM;
            end

            INIT_IMEM: begin
                if (uart_wready & ~uart_wvalid) begin
                    uart_wvalid <= 1;
                    uart_wdata  <= imem[addr][8*offset +: 8];
                    p           <= p+1;
                end else begin
                    uart_wvalid <= 0;
                    if (p[31:2] == `IMEM_ENTRIES) begin
                        p          <= 0;
                        init_state <= INIT_DMEM;
                    end
                end
            end

            INIT_DMEM: begin
                if (uart_wready & ~uart_wvalid) begin
                    uart_wvalid <= 1;
                    uart_wdata  <= dram[addr][8*offset +: 8];
                    p           <= p+1;
                end else begin
                    uart_wvalid <= 0;
                    if (p[31:2] == `DMEM_ENTRIES) begin
                        p          <= 0;
                        init_state <= DONE;
                    end
                end
            end

            DONE: begin
                uart_wvalid <= 0;
            end
        endcase
    end

//==============================================================================
// DUT
//------------------------------------------------------------------------------
    wire sda;
    wire scl;
    wire dc;
    wire res;
    main m0 (
        .clk_i     (clk),
        .st7789_SDA(sda),
        .st7789_SCL(scl),
        .st7789_DC (dc),
        .st7789_RES(res),
        .rxd_i     (uart_txd),
        .txd_o     (uart_rxd)
    );

//==============================================================================
// Dump 
//------------------------------------------------------------------------------
    //initial begin
    //    $dumpfile("build/sim.vcd");
    //    $dumpvars(0, top);
    //end

//==============================================================================
// Condition for simulation to end
//------------------------------------------------------------------------------
    reg cpu_sim_fini = 0;
    always @(posedge clk) begin
        if (cc > 8000000) cpu_sim_fini <= 1;
        if (m0.cpu.dbus_cmd_addr_o == 32'h1000_0000 && m0.cpu.dbus_cmd_we_o) begin
            if (m0.cpu.dbus_wdata_data_o == 32'h777) begin
                $write("\033[32mCC %08d: TEST PASSED\033[0m\n", cc);
                cpu_sim_fini <= 1;
            end
            else begin
                $write("\033[31mCC %08d: TEST FAILED: %h\033[0m\n", cc, m0.cpu.dbus_wdata_data_o);
                cpu_sim_fini <= 1;
            end
        end
        if (cpu_sim_fini) begin
            $finish(1);
        end
    end
endmodule

