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

//==============================================================================
// Init Sequence
//------------------------------------------------------------------------------
    reg  [31:0] imem [0:`IMEM_ENTRIES-1];
    reg  [31:0] dram [0:`DMEM_ENTRIES-1];
    `include "imem_init.vh"
    `include "dram_init.vh"
    reg  [31:0] p      = 0;
    wire  [1:0] offset = p & 3;
    wire [31:2] addr   = p >> 2;

    localparam INIT_STATE_IDLE = 0;
    localparam INIT_STATE_IMEM = 1;
    localparam INIT_STATE_DMEM = 2;
    localparam INIT_STATE_DONE = 3;
    reg [1:0] init_state = INIT_STATE_IDLE;
    always @(posedge clk) begin
        case(init_state)
            INIT_STATE_IDLE: begin
                if (cc > 400000) init_state <= INIT_STATE_IMEM;
            end

            INIT_STATE_IMEM: begin
                if (uart_wready & ~uart_wvalid) begin
                    uart_wvalid <= 1;
                    uart_wdata  <= imem[addr][8*offset +: 8];
                    p           <= p+1;
                end else begin
                    uart_wvalid <= 0;
                    if (p[31:2] == `IMEM_ENTRIES) begin
                        p          <= 0;
                        init_state <= INIT_STATE_DMEM;
                    end
                end
            end

            INIT_STATE_DMEM: begin
                if (uart_wready & ~uart_wvalid) begin
                    uart_wvalid <= 1;
                    uart_wdata  <= dram[addr][8*offset +: 8];
                    p           <= p+1;
                end else begin
                    uart_wvalid <= 0;
                    if (p[31:2] == `DMEM_ENTRIES) begin
                        p          <= 0;
                        init_state <= INIT_STATE_DONE;
                        $write("init done\n");
                    end
                end
            end

            INIT_STATE_DONE: begin
                uart_wvalid <= 0;
            end
        endcase
    end

//==============================================================================
// DUT
//------------------------------------------------------------------------------
    main m0 (
        .clk_i         (clk),
        .ddram_a       (),
        .ddram_ba      (),
        .ddram_cas_n   (),
        .ddram_cke     (),
        .ddram_clk_n   (),
        .ddram_clk_p   (),
        .ddram_cs_n    (),
        .ddram_dm      (),
        .ddram_dq      (),
        .ddram_dqs_n   (),
        .ddram_dqs_p   (),
        .ddram_odt     (),
        .ddram_ras_n   (),
        .ddram_reset_n (),
        .ddram_we_n    (),
        .st7789_SDA    (),
        .st7789_SCL    (),
        .st7789_DC     (),
        .st7789_RES    (),
        .rxd_i         (uart_txd),
        .txd_o         (uart_rxd),
        .user_led0     (),
        .user_led1     (),
        .user_led2     (),
        .user_led3     ()
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
        //if (cc > 15000000) cpu_sim_fini <= 1; // timeout
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

