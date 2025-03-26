set top_dir [pwd]
set proj_name main
set part_name xc7a35ticpg236-1L
set src_files [list $top_dir/config.vh $top_dir/proc.v $top_dir/cfu.v $top_dir/main.v]
set nproc [exec nproc]


create_project -force $proj_name $top_dir/vivado -part $part_name
set_property strategy Flow_PerfOptimized_high [get_runs synth_1]
set_property strategy Performance_ExplorePostRoutePhysOpt [get_runs impl_1]
add_files -norecurse $src_files
add_files -fileset constrs_1 -norecurse $top_dir/main.xdc
update_compile_order -fileset sources_1
set_property verilog_define {USE_CLK_WIZ} [get_fileset sources_1]

create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name clk_wiz_0
set_property -dict [list \
  CONFIG.CLKIN1_JITTER_PS {833.33} \
  CONFIG.CLKOUT1_JITTER {479.872} \
  CONFIG.CLKOUT1_PHASE_ERROR {668.310} \
  CONFIG.MMCM_CLKFBOUT_MULT_F {62.500} \
  CONFIG.MMCM_CLKIN1_PERIOD {83.333} \
  CONFIG.MMCM_CLKIN2_PERIOD {10.0} \
  CONFIG.MMCM_CLKOUT0_DIVIDE_F {7.500} \
  CONFIG.PRIM_IN_FREQ {12} \
] [get_ips clk_wiz_0]
generate_target {instantiation_template} [get_files $top_dir/vivado/$proj_name.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0.xci]
generate_target all [get_files  $top_dir/vivado/$proj_name.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0.xci]
catch { config_ip_cache -export [get_ips -all clk_wiz_0] }
export_ip_user_files -of_objects [get_files $top_dir/vivado/$proj_name.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0.xci] -no_script -sync -force -quiet
create_ip_run [get_files -of_objects [get_fileset sources_1] $top_dir/vivado/$proj_name.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0.xci]
launch_runs clk_wiz_0_synth_1 -jobs $nproc
wait_on_run clk_wiz_0_synth_1

launch_runs impl_1 -to_step write_bitstream -jobs $nproc
wait_on_run impl_1
