/* CFU Proving Ground since 2025-02    Copyright(c) 2025 Archlab. Science Tokyo /
/ Released under the MIT license https://opensource.org/licenses/mit           */

`default_nettype none

module top;
    reg clk   = 1; always #5 clk <= ~clk;
    reg rst_n = 0; initial #50 rst_n = 1;

//==============================================================================
// Perfomance Counter
//------------------------------------------------------------------------------
    reg [63:0] mcycle = 0;
    always @(posedge clk) if (!m0.rst && !cpu_sim_fini) mcycle <= mcycle + 1;

    reg [63:0] minstret     = 0;
    reg [63:0] br_pred_cntr = 0;
    reg [63:0] br_misp_cntr = 0;
    always @(posedge clk) if (!m0.rst && !cpu_sim_fini && !m0.cpu.stall_i) begin
        if (!m0.cpu.stall && m0.cpu.ExMa_v) minstret <= minstret + 1;
        if (m0.cpu.ExMa_is_ctrl_tsfr) br_pred_cntr <= br_pred_cntr + 1;
        if (m0.cpu.ExMa_is_ctrl_tsfr && m0.cpu.Ma_br_misp) br_misp_cntr <= br_misp_cntr + 1;
    end

//==============================================================================
// Dump 
//------------------------------------------------------------------------------
    // initial begin
    //     $dumpfile("dump.vcd");
    //     $dumpvars(0, top);
    // end

//==============================================================================
// Condition for simulation to end
//------------------------------------------------------------------------------
    reg cpu_sim_fini = 0;
    always @(posedge clk) begin
        if (m0.cpu.dbus_addr_o[31] && m0.cpu.dbus_wvalid_o) begin
            if (m0.cpu.dbus_wdata == 32'h00020000) cpu_sim_fini <= 1;
            else begin $write("%c", m0.cpu.dbus_wdata[7:0]); $fflush(); end
            if (m0.cpu.dbus_addr < 32'h10000000) cpu_sim_fini <= 1;
        end
        if (cpu_sim_fini) begin
            $finish(1);
        end
    end

    final begin
        $write("\n");
        $write("===> mcycle                                 : %10d\n", mcycle);
        $write("===> minstret                               : %10d\n", minstret);
        $write("===> Total number of branch predictions     : %10d\n", br_pred_cntr);
        $write("===> Total number of branch mispredictions  : %10d\n", br_misp_cntr);
        $write("===> simulation finish!!\n");
        $write("\n");
    end

//==============================================================================
// Trace Dump
//------------------------------------------------------------------------------
/*
    integer i, j, fp;
    initial begin
        fp=$fopen("trace.txt","w");
        if(fp == 0)begin
            $display("File_Open_Error_!!!!!");
            $finish();
        end
    end
    always @(posedge clk) if (minstret < 32'h10000)begin
        if (!m0.rst && !cpu_sim_fini && !m0.cpu.stall && m0.cpu.MaWb_v && !m0.cpu.stall_i) begin
            $fwrite(fp, "%08d %08x %08x\n", minstret, m0.cpu.MaWb_pc, m0.cpu.MaWb_ir);
            for(i=0;i<4;i=i+1) begin
                for(j=0;j<8;j=j+1) begin
                    $fwrite(fp, "%08x",m0.cpu.xreg.ram[i*8+j]);
                    if(j==7)    $fwrite(fp, "\n");
                    else        $fwrite(fp, " ");
                end
            end
        end
    end
*/

    wire sda, scl, dc, res;
    main m0 (
        .clk_i      (clk),
        .st7789_SDA (sda),
        .st7789_SCL (scl),
        .st7789_DC  (dc),
        .st7789_RES (res)
    );
endmodule
