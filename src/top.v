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
// Perfomance Counter
//------------------------------------------------------------------------------
    int unsigned mtime = 0;
    int unsigned mcycle = 0;
    int unsigned minstret = 0;
    int unsigned br_pred_cntr = 0;
    int unsigned br_misp_cntr = 0;
    always @(posedge clk) begin
        ++mtime;
        if (!m0.rst && !cpu_sim_fini) ++mcycle;
        if (!m0.rst && !cpu_sim_fini && !m0.cpu.stall && m0.cpu.ExMa_v)++minstret;
        if (!m0.rst && !cpu_sim_fini && m0.cpu.ExMa_is_ctrl_tsfr)++br_pred_cntr;
        if (!m0.rst && !cpu_sim_fini && m0.cpu.ExMa_is_ctrl_tsfr && m0.cpu.Ma_br_misp)
            ++br_misp_cntr;
    end

//==============================================================================
// Dump 
//------------------------------------------------------------------------------
    // `define DEBUG
    // `ifdef DEBUG
    //     initial begin
    //         $dumpfile("dump.vcd");
    //         $dumpvars(0, top);
    //     end
    // `endif

//==============================================================================
// Condition for simulation to end
//------------------------------------------------------------------------------
    reg cpu_sim_fini = 0;
    always @(posedge clk) begin
        if (cc >= 1500) begin
            $write("\033[31mTEST FAILED: Timeout\033[0m\n");
            $fatal;
        end
        if (m0.cpu.dbus_addr_o[28] && m0.cpu.dbus_wvalid_o) begin
            if (m0.cpu.dbus_wdata_o == 32'h777) begin
                $write("\033[32mTEST PASSED\033[0m\n");
                $finish;
            end
            else begin
                $write("\033[31mTEST FAILED: %h\033[0m\n", m0.cpu.dbus_wdata_o);
                $fatal;
            end
        end
        if (cpu_sim_fini) begin
            // $finish(1);
        end
    end

    //    final begin
    //        $write("\n"                                                                                                       );
    //        $write("===> mtime                                  : %10d\n"    , mtime                                          );
    //        $write("===> mcycle                                 : %10d\n"    , mcycle                                         );
    //        $write("===> minstret                               : %10d\n"    , minstret                                       );
    //        $write("===> Total number of branch predictions     : %10d\n"    , br_pred_cntr                                   );
    //        $write("===> Total number of branch mispredictions  : %10d\n"    , br_misp_cntr                                   );
    //        $write("===> simulation finish!!\n"                                                                               );
    //        $write("\n"                                                                                                       );
    //    end


endmodule

