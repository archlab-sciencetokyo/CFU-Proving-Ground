################################################################################
# IO constraints
################################################################################
# clk100:0
set_property PACKAGE_PIN E3 [get_ports clk100]
set_property IOSTANDARD LVCMOS33 [get_ports clk100]

# cpu_reset:0
set_property PACKAGE_PIN C2 [get_ports cpu_reset]
set_property IOSTANDARD LVCMOS33 [get_ports cpu_reset]

# eth_ref_clk:0
set_property PACKAGE_PIN G18 [get_ports eth_ref_clk]
set_property IOSTANDARD LVCMOS33 [get_ports eth_ref_clk]

# serial:0.tx
set_property PACKAGE_PIN D10 [get_ports serial_tx]
set_property IOSTANDARD LVCMOS33 [get_ports serial_tx]

# serial:0.rx
set_property PACKAGE_PIN A9 [get_ports serial_rx]
set_property IOSTANDARD LVCMOS33 [get_ports serial_rx]

# ddram:0.a
set_property PACKAGE_PIN R2 [get_ports {ddram_a[0]}]
set_property SLEW FAST [get_ports {ddram_a[0]}]
set_property IOSTANDARD SSTL135 [get_ports {ddram_a[0]}]

# ddram:0.a
set_property PACKAGE_PIN M6 [get_ports {ddram_a[1]}]
set_property SLEW FAST [get_ports {ddram_a[1]}]
set_property IOSTANDARD SSTL135 [get_ports {ddram_a[1]}]

# ddram:0.a
set_property PACKAGE_PIN N4 [get_ports {ddram_a[2]}]
set_property SLEW FAST [get_ports {ddram_a[2]}]
set_property IOSTANDARD SSTL135 [get_ports {ddram_a[2]}]

# ddram:0.a
set_property PACKAGE_PIN T1 [get_ports {ddram_a[3]}]
set_property SLEW FAST [get_ports {ddram_a[3]}]
set_property IOSTANDARD SSTL135 [get_ports {ddram_a[3]}]

# ddram:0.a
set_property PACKAGE_PIN N6 [get_ports {ddram_a[4]}]
set_property SLEW FAST [get_ports {ddram_a[4]}]
set_property IOSTANDARD SSTL135 [get_ports {ddram_a[4]}]

# ddram:0.a
set_property PACKAGE_PIN R7 [get_ports {ddram_a[5]}]
set_property SLEW FAST [get_ports {ddram_a[5]}]
set_property IOSTANDARD SSTL135 [get_ports {ddram_a[5]}]

# ddram:0.a
set_property PACKAGE_PIN V6 [get_ports {ddram_a[6]}]
set_property SLEW FAST [get_ports {ddram_a[6]}]
set_property IOSTANDARD SSTL135 [get_ports {ddram_a[6]}]

# ddram:0.a
set_property PACKAGE_PIN U7 [get_ports {ddram_a[7]}]
set_property SLEW FAST [get_ports {ddram_a[7]}]
set_property IOSTANDARD SSTL135 [get_ports {ddram_a[7]}]

# ddram:0.a
set_property PACKAGE_PIN R8 [get_ports {ddram_a[8]}]
set_property SLEW FAST [get_ports {ddram_a[8]}]
set_property IOSTANDARD SSTL135 [get_ports {ddram_a[8]}]

# ddram:0.a
set_property PACKAGE_PIN V7 [get_ports {ddram_a[9]}]
set_property SLEW FAST [get_ports {ddram_a[9]}]
set_property IOSTANDARD SSTL135 [get_ports {ddram_a[9]}]

# ddram:0.a
set_property PACKAGE_PIN R6 [get_ports {ddram_a[10]}]
set_property SLEW FAST [get_ports {ddram_a[10]}]
set_property IOSTANDARD SSTL135 [get_ports {ddram_a[10]}]

# ddram:0.a
set_property PACKAGE_PIN U6 [get_ports {ddram_a[11]}]
set_property SLEW FAST [get_ports {ddram_a[11]}]
set_property IOSTANDARD SSTL135 [get_ports {ddram_a[11]}]

# ddram:0.a
set_property PACKAGE_PIN T6 [get_ports {ddram_a[12]}]
set_property SLEW FAST [get_ports {ddram_a[12]}]
set_property IOSTANDARD SSTL135 [get_ports {ddram_a[12]}]

# ddram:0.a
set_property PACKAGE_PIN T8 [get_ports {ddram_a[13]}]
set_property SLEW FAST [get_ports {ddram_a[13]}]
set_property IOSTANDARD SSTL135 [get_ports {ddram_a[13]}]

# ddram:0.ba
set_property PACKAGE_PIN R1 [get_ports {ddram_ba[0]}]
set_property SLEW FAST [get_ports {ddram_ba[0]}]
set_property IOSTANDARD SSTL135 [get_ports {ddram_ba[0]}]

# ddram:0.ba
set_property PACKAGE_PIN P4 [get_ports {ddram_ba[1]}]
set_property SLEW FAST [get_ports {ddram_ba[1]}]
set_property IOSTANDARD SSTL135 [get_ports {ddram_ba[1]}]

# ddram:0.ba
set_property PACKAGE_PIN P2 [get_ports {ddram_ba[2]}]
set_property SLEW FAST [get_ports {ddram_ba[2]}]
set_property IOSTANDARD SSTL135 [get_ports {ddram_ba[2]}]

# ddram:0.ras_n
set_property PACKAGE_PIN P3 [get_ports ddram_ras_n]
set_property SLEW FAST [get_ports ddram_ras_n]
set_property IOSTANDARD SSTL135 [get_ports ddram_ras_n]

# ddram:0.cas_n
set_property PACKAGE_PIN M4 [get_ports ddram_cas_n]
set_property SLEW FAST [get_ports ddram_cas_n]
set_property IOSTANDARD SSTL135 [get_ports ddram_cas_n]

# ddram:0.we_n
set_property PACKAGE_PIN P5 [get_ports ddram_we_n]
set_property SLEW FAST [get_ports ddram_we_n]
set_property IOSTANDARD SSTL135 [get_ports ddram_we_n]

# ddram:0.cs_n
set_property PACKAGE_PIN U8 [get_ports ddram_cs_n]
set_property SLEW FAST [get_ports ddram_cs_n]
set_property IOSTANDARD SSTL135 [get_ports ddram_cs_n]

# ddram:0.dm
set_property PACKAGE_PIN L1 [get_ports {ddram_dm[0]}]
set_property SLEW FAST [get_ports {ddram_dm[0]}]
set_property IOSTANDARD SSTL135 [get_ports {ddram_dm[0]}]

# ddram:0.dm
set_property PACKAGE_PIN U1 [get_ports {ddram_dm[1]}]
set_property SLEW FAST [get_ports {ddram_dm[1]}]
set_property IOSTANDARD SSTL135 [get_ports {ddram_dm[1]}]

# ddram:0.dq
set_property PACKAGE_PIN K5 [get_ports {ddram_dq[0]}]
set_property SLEW FAST [get_ports {ddram_dq[0]}]
set_property IOSTANDARD SSTL135 [get_ports {ddram_dq[0]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_dq[0]}]

# ddram:0.dq
set_property PACKAGE_PIN L3 [get_ports {ddram_dq[1]}]
set_property SLEW FAST [get_ports {ddram_dq[1]}]
set_property IOSTANDARD SSTL135 [get_ports {ddram_dq[1]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_dq[1]}]

# ddram:0.dq
set_property PACKAGE_PIN K3 [get_ports {ddram_dq[2]}]
set_property SLEW FAST [get_ports {ddram_dq[2]}]
set_property IOSTANDARD SSTL135 [get_ports {ddram_dq[2]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_dq[2]}]

# ddram:0.dq
set_property PACKAGE_PIN L6 [get_ports {ddram_dq[3]}]
set_property SLEW FAST [get_ports {ddram_dq[3]}]
set_property IOSTANDARD SSTL135 [get_ports {ddram_dq[3]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_dq[3]}]

# ddram:0.dq
set_property PACKAGE_PIN M3 [get_ports {ddram_dq[4]}]
set_property SLEW FAST [get_ports {ddram_dq[4]}]
set_property IOSTANDARD SSTL135 [get_ports {ddram_dq[4]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_dq[4]}]

# ddram:0.dq
set_property PACKAGE_PIN M1 [get_ports {ddram_dq[5]}]
set_property SLEW FAST [get_ports {ddram_dq[5]}]
set_property IOSTANDARD SSTL135 [get_ports {ddram_dq[5]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_dq[5]}]

# ddram:0.dq
set_property PACKAGE_PIN L4 [get_ports {ddram_dq[6]}]
set_property SLEW FAST [get_ports {ddram_dq[6]}]
set_property IOSTANDARD SSTL135 [get_ports {ddram_dq[6]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_dq[6]}]

# ddram:0.dq
set_property PACKAGE_PIN M2 [get_ports {ddram_dq[7]}]
set_property SLEW FAST [get_ports {ddram_dq[7]}]
set_property IOSTANDARD SSTL135 [get_ports {ddram_dq[7]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_dq[7]}]

# ddram:0.dq
set_property PACKAGE_PIN V4 [get_ports {ddram_dq[8]}]
set_property SLEW FAST [get_ports {ddram_dq[8]}]
set_property IOSTANDARD SSTL135 [get_ports {ddram_dq[8]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_dq[8]}]

# ddram:0.dq
set_property PACKAGE_PIN T5 [get_ports {ddram_dq[9]}]
set_property SLEW FAST [get_ports {ddram_dq[9]}]
set_property IOSTANDARD SSTL135 [get_ports {ddram_dq[9]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_dq[9]}]

# ddram:0.dq
set_property PACKAGE_PIN U4 [get_ports {ddram_dq[10]}]
set_property SLEW FAST [get_ports {ddram_dq[10]}]
set_property IOSTANDARD SSTL135 [get_ports {ddram_dq[10]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_dq[10]}]

# ddram:0.dq
set_property PACKAGE_PIN V5 [get_ports {ddram_dq[11]}]
set_property SLEW FAST [get_ports {ddram_dq[11]}]
set_property IOSTANDARD SSTL135 [get_ports {ddram_dq[11]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_dq[11]}]

# ddram:0.dq
set_property PACKAGE_PIN V1 [get_ports {ddram_dq[12]}]
set_property SLEW FAST [get_ports {ddram_dq[12]}]
set_property IOSTANDARD SSTL135 [get_ports {ddram_dq[12]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_dq[12]}]

# ddram:0.dq
set_property PACKAGE_PIN T3 [get_ports {ddram_dq[13]}]
set_property SLEW FAST [get_ports {ddram_dq[13]}]
set_property IOSTANDARD SSTL135 [get_ports {ddram_dq[13]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_dq[13]}]

# ddram:0.dq
set_property PACKAGE_PIN U3 [get_ports {ddram_dq[14]}]
set_property SLEW FAST [get_ports {ddram_dq[14]}]
set_property IOSTANDARD SSTL135 [get_ports {ddram_dq[14]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_dq[14]}]

# ddram:0.dq
set_property PACKAGE_PIN R3 [get_ports {ddram_dq[15]}]
set_property SLEW FAST [get_ports {ddram_dq[15]}]
set_property IOSTANDARD SSTL135 [get_ports {ddram_dq[15]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_dq[15]}]

# ddram:0.dqs_p
set_property SLEW FAST [get_ports {ddram_dqs_p[0]}]
set_property IOSTANDARD DIFF_SSTL135 [get_ports {ddram_dqs_p[0]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_dqs_p[0]}]

# ddram:0.dqs_p
set_property SLEW FAST [get_ports {ddram_dqs_p[1]}]
set_property IOSTANDARD DIFF_SSTL135 [get_ports {ddram_dqs_p[1]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_dqs_p[1]}]

# ddram:0.dqs_n
set_property PACKAGE_PIN N2 [get_ports {ddram_dqs_p[0]}]
set_property PACKAGE_PIN N1 [get_ports {ddram_dqs_n[0]}]
set_property SLEW FAST [get_ports {ddram_dqs_n[0]}]
set_property IOSTANDARD DIFF_SSTL135 [get_ports {ddram_dqs_n[0]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_dqs_n[0]}]

# ddram:0.dqs_n
set_property PACKAGE_PIN U2 [get_ports {ddram_dqs_p[1]}]
set_property PACKAGE_PIN V2 [get_ports {ddram_dqs_n[1]}]
set_property SLEW FAST [get_ports {ddram_dqs_n[1]}]
set_property IOSTANDARD DIFF_SSTL135 [get_ports {ddram_dqs_n[1]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_dqs_n[1]}]

# ddram:0.clk_p
set_property SLEW FAST [get_ports ddram_clk_p]
set_property IOSTANDARD DIFF_SSTL135 [get_ports ddram_clk_p]

# ddram:0.clk_n
set_property PACKAGE_PIN U9 [get_ports ddram_clk_p]
set_property PACKAGE_PIN V9 [get_ports ddram_clk_n]
set_property SLEW FAST [get_ports ddram_clk_n]
set_property IOSTANDARD DIFF_SSTL135 [get_ports ddram_clk_n]

# ddram:0.cke
set_property PACKAGE_PIN N5 [get_ports ddram_cke]
set_property SLEW FAST [get_ports ddram_cke]
set_property IOSTANDARD SSTL135 [get_ports ddram_cke]

# ddram:0.odt
set_property PACKAGE_PIN R5 [get_ports ddram_odt]
set_property SLEW FAST [get_ports ddram_odt]
set_property IOSTANDARD SSTL135 [get_ports ddram_odt]

# ddram:0.reset_n
set_property PACKAGE_PIN K6 [get_ports ddram_reset_n]
set_property SLEW FAST [get_ports ddram_reset_n]
set_property IOSTANDARD SSTL135 [get_ports ddram_reset_n]

# user_led:0
set_property PACKAGE_PIN H5 [get_ports user_led0]
set_property IOSTANDARD LVCMOS33 [get_ports user_led0]

# user_led:1
set_property PACKAGE_PIN J5 [get_ports user_led1]
set_property IOSTANDARD LVCMOS33 [get_ports user_led1]

# user_led:2
set_property PACKAGE_PIN T9 [get_ports user_led2]
set_property IOSTANDARD LVCMOS33 [get_ports user_led2]

# user_led:3
set_property PACKAGE_PIN T10 [get_ports user_led3]
set_property IOSTANDARD LVCMOS33 [get_ports user_led3]

################################################################################
# Design constraints
################################################################################
set_property INTERNAL_VREF 0.675 [get_iobanks 34]

################################################################################
# Pmod Header JC
################################################################################

# Pin 1
set_property PACKAGE_PIN U12 [get_ports st7789_DC]
set_property IOSTANDARD LVCMOS33 [get_ports st7789_DC]

# Pin 2
set_property PACKAGE_PIN V12 [get_ports st7789_RES]
set_property IOSTANDARD LVCMOS33 [get_ports st7789_RES]

# Pin 3
set_property PACKAGE_PIN V10 [get_ports st7789_SDA]
set_property IOSTANDARD LVCMOS33 [get_ports st7789_SDA]

# Pin 4
set_property PACKAGE_PIN V11 [get_ports st7789_SCL]
set_property IOSTANDARD LVCMOS33 [get_ports st7789_SCL]

################################################################################
# UART (0xF0001000 - 0xF0001004)
################################################################################
set_property PACKAGE_PIN A9 [get_ports uart_rxd]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rxd]

################################################################################
# Clock constraints
################################################################################
create_clock -period 10.000 -name clk100 [get_ports clk100]
set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks -of [get_nets sys_clk]]

################################################################################
# False path constraints
################################################################################
set_false_path -through [get_nets -hierarchical -filter {mr_ff == TRUE}] -quiet
set_false_path -to [get_pins -filter {REF_PIN_NAME == PRE} -of_objects [get_cells -hierarchical -filter {ars_ff1 == TRUE || ars_ff2 == TRUE}]] -quiet
set_max_delay -from [get_pins -filter {REF_PIN_NAME == C} -of_objects [get_cells -hierarchical -filter {ars_ff1 == TRUE}]] -to [get_pins -filter {REF_PIN_NAME == D} -of_objects [get_cells -hierarchical -filter {ars_ff2 == TRUE}]] 2.000 -quiet

## Pmod Header JC
set_property -dict { PACKAGE_PIN U12 IOSTANDARD LVCMOS33 } [get_ports { st7789_DC  }]; # Pin 1
set_property -dict { PACKAGE_PIN V12 IOSTANDARD LVCMOS33 } [get_ports { st7789_RES }]; # Pin 2
set_property -dict { PACKAGE_PIN V10 IOSTANDARD LVCMOS33 } [get_ports { st7789_SDA }]; # Pin 3
set_property -dict { PACKAGE_PIN V11 IOSTANDARD LVCMOS33 } [get_ports { st7789_SCL }]; # Pin 4

## USB-UART Interface
set_property -dict { PACKAGE_PIN A9    IOSTANDARD LVCMOS33 } [get_ports { rxd_i }];
set_property -dict { PACKAGE_PIN D10   IOSTANDARD LVCMOS33 } [get_ports { txd_o }];

#####
create_pblock PB0
resize_pblock [get_pblocks PB0] -add SLICE_X36Y50:SLICE_X65Y74
add_cells_to_pblock [get_pblocks PB0] [get_cells -quiet [list {cpu}]]
## add_cells_to_pblock [get_pblocks PB0] [get_cells -quiet [list {imem}]]
## add_cells_to_pblock [get_pblocks PB0] [get_cells -quiet [list {dmem}]]
## resize_pblock [get_pblocks PB0] -add CLOCKREGION_X1Y1

#####
create_pblock PB1
resize_pblock [get_pblocks PB1] -add CLOCKREGION_X1Y1
add_cells_to_pblock [get_pblocks PB1] [get_cells -quiet [list {imem}]]
add_cells_to_pblock [get_pblocks PB1] [get_cells -quiet [list {dmem}]]

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design] 
set_property BITSTREAM.CONFIG.CONFIGRATE 50  [current_design] 
set_property CONFIG_MODE SPIx4               [current_design] 
