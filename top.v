`default_nettype none

module top;
    reg clk = 1; always #5 clk = ~clk;
    reg rst_n = 0; initial #50 rst_n = 1;
    reg rxd = 1;
    wire txd; 

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
        if (!m0.rst && !cpu_sim_fini)  ++mcycle; 
        if (!m0.rst && !cpu_sim_fini && !m0.cpu.stall && m0.cpu.ExMa_v) ++minstret;
        if (!m0.rst && !cpu_sim_fini && m0.cpu.ExMa_is_ctrl_tsfr) ++br_pred_cntr; 
        if (!m0.rst && !cpu_sim_fini && m0.cpu.ExMa_is_ctrl_tsfr && m0.cpu.Ma_br_misp) ++br_misp_cntr;
    end

//==============================================================================
// Condition for simulation to end
//------------------------------------------------------------------------------
    reg cpu_sim_fini = 0;
    always @(posedge clk) begin
        if (m0.cpu.dbus_addr_o == 32'h40008000
            && m0.cpu.dbus_wdata_o[17:16] == 2'b10)
                cpu_sim_fini <= 1;
        if (cpu_sim_fini) begin
            $finish(1);
        end
    end

    final begin
        $write("\n"                                                                                                       );
        $write("===> mtime                                  : %10d\n"    , mtime                                          );
        $write("===> mcycle                                 : %10d\n"    , mcycle                                         );
        $write("===> mcycle (CSR)                           : %10d\n"    , m0.cpu.mcycle                                  );
        $write("===> minstret                               : %10d\n"    , minstret                                       );
        $write("===> minstret (CSR)                         : %10d\n"    , m0.cpu.minstret                                );
        $write("===> Total number of branch predictions     : %10d\n"    , br_pred_cntr                                   );
        $write("===> Total number of branch mispredictions  : %10d\n"    , br_misp_cntr                                   );
        $write("===> Branch misprediction rate              :   %f\n"  , $itor(br_misp_cntr) / $itor(br_pred_cntr)        );
        $write("===> Branch prediction hit rate             :   %f\n"  , 1 - ($itor(br_misp_cntr) / $itor(br_pred_cntr))  );
        $write("===> IPC (Instructions Per Cycle)           :   %f\n"  , $itor(minstret) / $itor(mcycle)                  );
        $write("===> simulation finish!!\n"                                                                             );
        $write("\n"                                                                                                     );
    end

//==============================================================================
// Instantiate the SoC
//------------------------------------------------------------------------------
    main m0 (
        .clk_i          (clk        ),
        .rst_ni         (rst_n      ),
        .st7789_SDA     (           ),
        .st7789_SCL     (           ),
        .st7789_DC      (           ),
        .st7789_RES     (           )
    );

endmodule

