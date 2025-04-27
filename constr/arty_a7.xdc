## This file is a general .xdc for the Arty A7-35 Rev. D and Rev. E
## To use it in a project:
## - uncomment the lines corresponding to used pins
## - rename the used ports (in each line, after get_ports) according to the top level signal names in the project

## Clock signal
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { clk_i }]; #IO_L12P_T1_MRCC_35 Sch=gclk[100]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { clk_i }];


## Pmod Header JC
set_property -dict { PACKAGE_PIN U12 IOSTANDARD LVCMOS33 } [get_ports { st7789_DC  }]; # Pin 1
set_property -dict { PACKAGE_PIN V12 IOSTANDARD LVCMOS33 } [get_ports { st7789_RES }]; # Pin 2
set_property -dict { PACKAGE_PIN V10 IOSTANDARD LVCMOS33 } [get_ports { st7789_SDA }]; # Pin 3
set_property -dict { PACKAGE_PIN V11 IOSTANDARD LVCMOS33 } [get_ports { st7789_SCL }]; # Pin 4

## USB-UART Interface
set_property -dict { PACKAGE_PIN A9    IOSTANDARD LVCMOS33 } [get_ports { rxd_i }]; #IO_L14N_T2_SRCC_16 Sch=uart_txd_in
set_property -dict { PACKAGE_PIN D10   IOSTANDARD LVCMOS33 } [get_ports { txd_o }]; #IO_L19N_T3_VREF_16 Sch=uart_rxd_out

##
create_pblock PB0
resize_pblock [get_pblocks PB0] -add CLOCKREGION_X1Y1
add_cells_to_pblock [get_pblocks PB0] [get_cells -quiet [list {cpu}]]
add_cells_to_pblock [get_pblocks PB0] [get_cells -quiet [list {imem}]]
