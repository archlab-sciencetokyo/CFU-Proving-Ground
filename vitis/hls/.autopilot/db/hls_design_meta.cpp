#include "hls_design_meta.h"
const Port_Property HLS_Design_Meta::port_props[]={
	Port_Property("ap_clk", 1, hls_in, -1, "", "", 1),
	Port_Property("ap_start", 1, hls_in, -1, "", "", 1),
	Port_Property("ap_done", 1, hls_out, -1, "", "", 1),
	Port_Property("ap_idle", 1, hls_out, -1, "", "", 1),
	Port_Property("ap_ready", 1, hls_out, -1, "", "", 1),
	Port_Property("funct3_i", 8, hls_in, 0, "ap_none", "in_data", 1),
	Port_Property("funct7_i", 8, hls_in, 1, "ap_none", "in_data", 1),
	Port_Property("src1_i", 32, hls_in, 2, "ap_none", "in_data", 1),
	Port_Property("src2_i", 32, hls_in, 3, "ap_none", "in_data", 1),
	Port_Property("rslt_o", 32, hls_out, 4, "ap_none", "out_data", 1),
};
const char* HLS_Design_Meta::dut_name = "cfu_hls";
