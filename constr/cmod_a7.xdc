###############################################################################################
## main.xdc for Cmod A7-35T    ArchLab, Institute of Science Tokyo / Tokyo Tech
## FPGA: XC7A35T-1CPG236C
###############################################################################################

## 12MHz system clock
###############################################################################################
set_property -dict { PACKAGE_PIN L17 IOSTANDARD LVCMOS33} [get_ports { clk_i }];
create_clock -add -name sys_clk -period 83.33 [get_ports { clk_i }]

###############################################################################################

##### 240x240 ST7789 mini display #####
###############################################################################################
###### GPIO
set_property -dict { PACKAGE_PIN U7 IOSTANDARD LVCMOS33 } [get_ports { st7789_DC  }]; # P45
set_property -dict { PACKAGE_PIN W7 IOSTANDARD LVCMOS33 } [get_ports { st7789_RES }]; # P46
set_property -dict { PACKAGE_PIN U8 IOSTANDARD LVCMOS33 } [get_ports { st7789_SDA }]; # P47
set_property -dict { PACKAGE_PIN V8 IOSTANDARD LVCMOS33 } [get_ports { st7789_SCL }]; # P48

###############################################################################################
###### Pmod Header for MPU-6050
###### Pin 3 and Pin 4
set_property -dict { PACKAGE_PIN N18 IOSTANDARD LVCMOS33 PULLUP TRUE } [get_ports { sda }];
set_property -dict { PACKAGE_PIN L18 IOSTANDARD LVCMOS33 PULLUP TRUE } [get_ports { scl }];

###############################################################################################
##### GPIO for Motor driver
set_property -dict { PACKAGE_PIN T1 IOSTANDARD LVCMOS33 } [get_ports { motor_stby }]; # P29
set_property -dict { PACKAGE_PIN T2 IOSTANDARD LVCMOS33 } [get_ports { motor_ain1 }]; # P30
set_property -dict { PACKAGE_PIN U1 IOSTANDARD LVCMOS33 } [get_ports { motor_ain2 }]; # P31
set_property -dict { PACKAGE_PIN W2 IOSTANDARD LVCMOS33 } [get_ports { motor_pwma }]; # P32
###############################################################################################
