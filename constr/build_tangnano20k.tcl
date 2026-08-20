# CFU Proving Ground since 2025-02    Copyright(c) 2025 Archlab. Science Tokyo
# Released under the MIT license https://opensource.org/licenses/mit

set top_dir   [file normalize [pwd]]
set proj_name main
set proj_dir  $top_dir/gowin
set part_name GW2AR-LV18QN88C8/I7

# Tang Nano 20K project: GW2A-18, QFN88, device version C.
create_project \
    -name $proj_name \
    -dir $proj_dir \
    -pn $part_name \
    -device_version C \
    -force

# Common RTL. config.vh, memi.txt and memd.txt are included by main.v.
add_file -type verilog $top_dir/proc.v
add_file -type verilog $top_dir/cfu.v
add_file -type verilog $top_dir/gowin_ip/gowin_rpll/gowin_rpll.v

# Define GOWIN only in the Gowin compilation unit. Vivado continues to compile
# main.v directly and therefore selects clk_wiz_0.
set gowin_main $proj_dir/main_gowin.v
set main_fd [open $gowin_main w]
puts $main_fd {`define GOWIN
`include "main.v"}
close $main_fd
add_file -type verilog $gowin_main
add_file -type cst     $top_dir/main.cst
add_file -type sdc     $top_dir/main.sdc

set_option -top_module main
set_option -include_path $top_dir
set_option -verilog_std v2001
set_option -looplimit 100000
set_option -output_base_name main

run all
