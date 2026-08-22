# CFU Proving Ground since 2025-02    Copyright(c) 2025 Archlab. Science Tokyo
# Released under the MIT license https://opensource.org/licenses/mit

proc generate_gowin_rpll {output_dir} {
    set module_name Gowin_rPLL
    set file_name gowin_rpll

    # Search for GowinModGen in the GOWIN_IDE environment variable, or in the parent directory of the current executable.
    if {[info exists ::env(GOWIN_IDE)]} {
        set gowin_ide [file normalize $::env(GOWIN_IDE)]
    } else {
        # gw_sh normally resides in <GOWIN_IDE>/bin.
        set gowin_ide [file dirname [file dirname [file normalize [info nameofexecutable]]]]
    }
    set modgen [file join $gowin_ide bin GowinModGen]
    if {![file executable $modgen]} {
        error "GowinModGen not found: $modgen"
    }

    # Create the output directory and the .mod file for GowinModGen.
    file mkdir $output_dir
    set output_path "[file normalize $output_dir]/"
    set mod_path [file join $output_dir ${file_name}.mod]
    set mod_fd [open $mod_path w]

    # The .mod values are the GUI generator inputs. The generated primitive
    # uses IDIV_SEL=8, FBDIV_SEL=24 and ODIV_SEL=8 for 27 MHz -> 75 MHz.
    puts $mod_fd "-series GW2AR
-device GW2AR-18
-device_version C
-package QFN88
-part_number GW2AR-LV18QN88C8/I7

-mod_name $module_name
-file_name $file_name
-path $output_path
-type PLL
-rPll true
-file_type vlg
-ip_version 1.0
-dev_type GW2AR-18C
-dyn_idiv_sel false
-idiv_sel 9
-dyn_fbdiv_sel false
-fbdiv_sel 25
-dyn_odiv_sel false
-odiv_sel 8
-dyn_da_en true
-rst_sig false
-rst_sig_p false
-fclkin 27
-clkfb_sel 0
-en_lock true
-clkout_bypass false
-clkout_ft_dir 1
-en_clkoutp false
-clkoutp_bypass false
-en_clkoutd false
-clkoutd_bypass false
-en_clkoutd3 false"
    close $mod_fd

    puts "Generating $module_name with GowinModGen"
    if {[catch {exec $modgen -do $mod_path 2>@1} modgen_output]} {
        puts stderr $modgen_output
        error "GowinModGen failed"
    }
    puts $modgen_output

    set generated_verilog [file join $output_dir ${file_name}.v]
    if {![file exists $generated_verilog]} {
        error "Generated rPLL Verilog was not found: $generated_verilog"
    }

    # main.v enables `default_nettype none. GowinModGen emits legacy port
    # declarations, so make their net types explicit before compilation.
    set verilog_fd [open $generated_verilog r]
    set verilog_text [read $verilog_fd]
    close $verilog_fd
    set verilog_text [string map [list \
        "output clkout;" "output wire clkout;" \
        "output lock;"   "output wire lock;" \
        "input clkin;"   "input wire clkin;" \
    ] $verilog_text]
    set verilog_fd [open $generated_verilog w]
    puts -nonewline $verilog_fd $verilog_text
    close $verilog_fd

    foreach expected [list \
        "module Gowin_rPLL" \
        "output wire clkout;" \
        "output wire lock;" \
        "input wire clkin;" \
        "IDIV_SEL = 8" \
        "FBDIV_SEL = 24" \
        "ODIV_SEL = 8" \
        {FCLKIN = "27"} \
        {DEVICE = "GW2AR-18C"} \
    ] {
        if {[string first $expected $verilog_text] < 0} {
            error "Generated rPLL does not contain expected setting: $expected"
        }
    }

    puts "Generated rPLL: $generated_verilog"
    return $generated_verilog
}

set top_dir   [file normalize [pwd]]
set proj_name main
set proj_dir  $top_dir/gowin
set part_name GW2AR-LV18QN88C8/I7

# Tang Nano 20K project: GW2AR-18, QFN88, device version C.
create_project \
    -name $proj_name \
    -dir $proj_dir \
    -pn $part_name \
    -device_version C \
    -force

# Gowin's standard create_ipc/read_ipc Tcl flow does not initialize GW2AR hard
# clock IPs in this EDA release. Generate the rPLL with the IDE's module
# generator, which is also used by the GUI.
set rpll_dir [file join $proj_dir $proj_name src gowin_rpll]
set rpll_verilog [generate_gowin_rpll $rpll_dir]

# Common RTL. config.vh, memi.txt and memd.txt are included by main.v.
add_file -type verilog $top_dir/proc.v
add_file -type verilog $top_dir/cfu.v
add_file -type verilog $rpll_verilog

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
