# CFU Proving Ground since 2025-02    Copyright(c) 2025 Archlab. Science Tokyo
# Released under the MIT license https://opensource.org/licenses/mit

set top_dir [pwd]
set proj_name main
set part_name xc7a35tcsg324-1
set src_files [list $top_dir/proc.v $top_dir/cfu.v $top_dir/main.v]
set nproc [exec nproc]

set file [open "$top_dir/config.vh"]
if {[regexp {`define\s+CLK_FREQ_MHZ\s+(\d+)} [read $file] -> freq]} {
    puts "Found frequency: $freq MHz"
} else {
    puts "CLK_FREQ_MHZ not found in config.vh"
    close $file
    exit 1
}
close $file

create_project -force $proj_name $top_dir/vivado -part $part_name
set_property strategy Flow_PerfOptimized_high [get_runs synth_1]
set_property strategy Performance_ExplorePostRoutePhysOpt [get_runs impl_1]

for {set i 0} {$i < $argc} {incr i} {
    if {[lindex $argv $i] eq "--hls"} {
        puts "HLS mode enabled. Adding HLS source files."
        set src_files [concat $src_files [glob -nocomplain $top_dir/cfu/*.v]]
        set tcl_files [glob -nocomplain $top_dir/cfu/*.tcl]
        foreach tcl_file $tcl_files {source $tcl_file}
        set_property verilog_define {USE_HLS} [get_filesets  sources_1]
        update_compile_order -fileset sources_1
        break;
    }
}

add_files -force -scan_for_includes $src_files
add_files -fileset constrs_1 $top_dir/main.xdc

if {[regexp {CRITICAL WARNING:} [check_syntax -return_string -fileset sources_1]]} {
    puts "Syntax check failed. Exiting..."
    exit 1
}

create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name clk_wiz_0
set_property -dict [list \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ $freq \
    CONFIG.JITTER_SEL {Min_O_Jitter} \
    CONFIG.MMCM_BANDWIDTH {HIGH} \
] [get_ips clk_wiz_0]

generate_target all [get_files  $top_dir/vivado/$proj_name.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0.xci]
create_ip_run [get_ips clk_wiz_0]

update_compile_order -fileset sources_1
launch_runs impl_1 -to_step write_bitstream -jobs $nproc
wait_on_run impl_1

open_run impl_1
report_utilization -hierarchical
report_timing
close_project
