# CFU Proving Ground since 2025-02    Copyright(c) 2025 Archlab. Science Tokyo
# Released under the MIT license https://opensource.org/licenses/mit

#===============================================================================
# 変数の定義
#-------------------------------------------------------------------------------
set vivado_dir [pwd]
set src_dir $vivado_dir/../src
set build_dir $vivado_dir/../build
set proj_name main
set part_name xc7a35tcsg324-1
set src_files [list $src_dir/main.v $src_dir/proc.v $src_dir/cfu.v $src_dir/uart.v \
$src_dir/config.vh $src_dir/litedram.v $build_dir/bootrom_init.vh $build_dir/sdram_init.vh \
$build_dir/user_config.vh]
set nproc [exec nproc]

#===============================================================================
# 実行クロックサイクルのロード
#-------------------------------------------------------------------------------
source $build_dir/user_config.tcl

#===============================================================================
# プロジェクトの作成
#-------------------------------------------------------------------------------
create_project -force $proj_name -part $part_name
set_property strategy Flow_PerfOptimized_high [get_runs synth_1]
set_property strategy Performance_ExplorePostRoutePhysOpt [get_runs impl_1]

add_files -force -scan_for_includes $src_files
add_files -fileset constrs_1 $vivado_dir/../constrs/arty_a7.xdc

if {[regexp {CRITICAL WARNING:} [check_syntax -return_string -fileset sources_1]]} {
    puts "Syntax check failed. Exiting..."
    exit 1
}

create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name clk_wiz_0
set_property -dict [list \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ $clk_freq_mhz \
    CONFIG.JITTER_SEL {Min_O_Jitter} \
    CONFIG.MMCM_BANDWIDTH {HIGH} \
] [get_ips clk_wiz_0]

generate_target all [get_files  $proj_name.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0.xci]
create_ip_run [get_ips clk_wiz_0]

update_compile_order -fileset sources_1
launch_runs impl_1 -to_step write_bitstream -jobs $nproc
wait_on_run impl_1

open_run impl_1
report_utilization -hierarchical
report_timing
close_project
quit
