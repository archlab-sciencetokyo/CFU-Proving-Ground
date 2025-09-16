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
// DUT
//------------------------------------------------------------------------------
    wire sda;
    wire scl;
    wire dc;
    wire res;
    wire txd;
    reg  rxd = 1;
    main m0 (
        .clk_i     (clk),
        .st7789_SDA(sda),
        .st7789_SCL(scl),
        .st7789_DC (dc),
        .st7789_RES(res),
        .rxd_i    (rxd),
        .txd_o    (txd)
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
        // if (cc >= 1_000_000) cpu_sim_fini <= 1;
        if (m0.cpu.dbus_cmd_addr_o[31:28] == 4'h1 && m0.cpu.dbus_cmd_we_o) begin
            if (m0.cpu.dbus_wdata_data_o == 32'h777) begin
                $write("\033[32mTEST PASSED\033[0m\n");
                cpu_sim_fini <= 1;
            end
            else begin
                $write("\033[31mTEST FAILED: %h\033[0m\n", m0.cpu.dbus_wdata_data_o);
                cpu_sim_fini <= 1;
            end
        end
        if (cpu_sim_fini) begin
            $finish(1);
        end
    end
endmodule

