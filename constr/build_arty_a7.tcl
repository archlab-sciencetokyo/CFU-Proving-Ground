# CFU Proving Ground since 2025-02    Copyright(c) 2025 Archlab. Science Tokyo
# Released under the MIT license https://opensource.org/licenses/mit

set top_dir [pwd]
set proj_name main
set part_name xc7a35tcsg324-1
set src_files [list $top_dir/config.vh $top_dir/proc.v $top_dir/cfu.v $top_dir/main.v]
set nproc [exec nproc]

create_project -force $proj_name $top_dir/vivado -part $part_name
set_property strategy Flow_PerfOptimized_high [get_runs synth_1]
set_property strategy Performance_ExplorePostRoutePhysOpt [get_runs impl_1]
add_files -norecurse $src_files
add_files -fileset constrs_1 -norecurse $top_dir/main.xdc
update_compile_order -fileset sources_1

launch_runs impl_1 -to_step write_bitstream -jobs $nproc
wait_on_run impl_1