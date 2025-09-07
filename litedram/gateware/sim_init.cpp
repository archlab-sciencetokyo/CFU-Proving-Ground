#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "Vsim.h"
#include <verilated.h>
#include "sim_header.h"

extern "C" void litex_sim_init_tracer(void *vsim, long start, long end);
extern "C" void litex_sim_tracer_dump();

extern "C" void litex_sim_dump()
{
}

extern "C" void litex_sim_init(void **out)
{
    Vsim *sim;

    sim = new Vsim;

    litex_sim_init_tracer(sim, 0, -1);

    sim_trace[0].signal = &sim->sim_trace;
    litex_sim_register_pads(sim_trace, (char*)"sim_trace", 0);

    clk[0].signal = &sim->clk;
    litex_sim_register_pads(clk, (char*)"clk", 0);

    init_done[0].signal = &sim->init_done;
    litex_sim_register_pads(init_done, (char*)"init_done", 0);

    init_error[0].signal = &sim->init_error;
    litex_sim_register_pads(init_error, (char*)"init_error", 0);

    wb_ctrl[0].signal = &sim->wb_ctrl_adr;
    wb_ctrl[1].signal = &sim->wb_ctrl_dat_w;
    wb_ctrl[2].signal = &sim->wb_ctrl_dat_r;
    wb_ctrl[3].signal = &sim->wb_ctrl_sel;
    wb_ctrl[4].signal = &sim->wb_ctrl_cyc;
    wb_ctrl[5].signal = &sim->wb_ctrl_stb;
    wb_ctrl[6].signal = &sim->wb_ctrl_ack;
    wb_ctrl[7].signal = &sim->wb_ctrl_we;
    wb_ctrl[8].signal = &sim->wb_ctrl_cti;
    wb_ctrl[9].signal = &sim->wb_ctrl_bte;
    wb_ctrl[10].signal = &sim->wb_ctrl_err;
    litex_sim_register_pads(wb_ctrl, (char*)"wb_ctrl", 0);

    user_clk[0].signal = &sim->user_clk;
    litex_sim_register_pads(user_clk, (char*)"user_clk", 0);

    user_rst[0].signal = &sim->user_rst;
    litex_sim_register_pads(user_rst, (char*)"user_rst", 0);

    user_port_native[0].signal = &sim->user_port_native_cmd_valid;
    user_port_native[1].signal = &sim->user_port_native_cmd_ready;
    user_port_native[2].signal = &sim->user_port_native_cmd_we;
    user_port_native[3].signal = &sim->user_port_native_cmd_addr;
    user_port_native[4].signal = &sim->user_port_native_wdata_valid;
    user_port_native[5].signal = &sim->user_port_native_wdata_ready;
    user_port_native[6].signal = &sim->user_port_native_wdata_we;
    user_port_native[7].signal = &sim->user_port_native_wdata_data;
    user_port_native[8].signal = &sim->user_port_native_rdata_valid;
    user_port_native[9].signal = &sim->user_port_native_rdata_ready;
    user_port_native[10].signal = &sim->user_port_native_rdata_data;
    litex_sim_register_pads(user_port_native, (char*)"user_port_native", 0);

    *out=sim;
}
