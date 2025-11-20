# CFU Proving Ground since 2025-02    Copyright(c) 2025 Archlab. Science Tokyo
# Released under the MIT license https://opensource.org/licenses/mit

set top_dir [pwd]
set proj_name main
set part_name xc7a35tcsg324-1
set src_files [list \
    $top_dir/build/user_config.vh \
    $top_dir/src/config.vh \
    $top_dir/litedram/gateware/litedram_core.v \
    $top_dir/src/main.v \
    $top_dir/src/lsu.v \
    $top_dir/src/proc.v \
    $top_dir/src/perf.v \
    $top_dir/src/cfu.v \
    $top_dir/build/imem_init.vh \
]
set nproc [exec nproc]

create_project -force $proj_name $top_dir/vivado -part $part_name
set_property strategy Flow_PerfOptimized_high [get_runs synth_1]
set_property strategy Performance_ExplorePostRoutePhysOpt [get_runs impl_1]

add_files -force -scan_for_includes $src_files
add_files -fileset constrs_1 $top_dir/constrs/arty_a7.xdc

update_compile_order -fileset sources_1
launch_runs impl_1 -to_step write_bitstream -jobs $nproc
wait_on_run impl_1

open_run impl_1
report_utilization -hierarchical
report_timing
close_project
quit
