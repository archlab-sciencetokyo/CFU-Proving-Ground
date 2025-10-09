###############################################################################################
## main.xdc for Cmod A7-35T    ArchLab, Institute of Science Tokyo / Tokyo Tech
## CFU Proving Ground since 2025-02    Copyright(c) 2025 Archlab. Science Tokyo
## Released under the MIT license https://opensource.org/licenses/mit
## FPGA: XC7A35T-1CPG236C
###############################################################################################

## 12MHz system clock
###############################################################################################
set_property -dict { PACKAGE_PIN L17 IOSTANDARD LVCMOS33} [get_ports { clk_i }];
create_clock -add -name sys_clk -period 83.33 [get_ports { clk_i }]

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design] 
set_property BITSTREAM.CONFIG.CONFIGRATE 50  [current_design] 
set_property CONFIG_MODE SPIx4               [current_design] 

###############################################################################################

##### 240x240 ST7789 mini display #####
###############################################################################################
## Pmod Header JA
set_property -dict { PACKAGE_PIN G17   IOSTANDARD LVCMOS33 } [get_ports { st7789_DC }]; #IO_L5N_T0_D07_14 Sch=ja[1]
set_property -dict { PACKAGE_PIN G19   IOSTANDARD LVCMOS33 } [get_ports { st7789_RES }]; #IO_L4N_T0_D05_14 Sch=ja[2]
set_property -dict { PACKAGE_PIN N18   IOSTANDARD LVCMOS33 } [get_ports { st7789_SDA }]; #IO_L9P_T1_DQS_14 Sch=ja[3]
set_property -dict { PACKAGE_PIN L18   IOSTANDARD LVCMOS33 } [get_ports { st7789_SCL }]; #IO_L8P_T1_D11_14 Sch=ja[4]
