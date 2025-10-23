## This file is a general .xdc for the Arty A7-35 Rev. D and Rev. E
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

## Clock signal
create_clock -period 10.00 [get_ports { clk_i }];
set_property -dict { PACKAGE_PIN E3 IOSTANDARD LVCMOS33 } [get_ports { clk_i }];


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
