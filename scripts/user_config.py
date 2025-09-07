import yaml
import os

YAML_FILE      = 'src/user_config.yml'
VH_FILE        = 'build/user_config.vh'
TCL_FILE       = 'build/user_config.tcl'
LINKER_FILE    = 'build/region.ld'
DRAM_BASE_ADDR = 0x80000000

#===============================================================================
# Load YAML and generate files
#===============================================================================
if not os.path.exists(YAML_FILE):
    print(f'{YAML_FILE} could not be found.')
    exit(1)

try:
    with open(YAML_FILE, 'r') as f:
        config_data = yaml.safe_load(f)
except yaml.YAMLError as e:
    print(f'Error parsing {YAML_FILE}: {e}')
    exit(1)

#===============================================================================
# Generate Verilog Header, Linker Script, and TCL files
#===============================================================================
verilog_content = []
linker_content = []
linker_content.append('MEMORY {\n')
tcl_content = []

if 'lcd_rotate' in config_data:
    verilog_content.append(f'`define LCD_ROTATE {config_data["lcd_rotate"]}\n')

if 'clk_freq_mhz' in config_data:
    verilog_content.append(f'`define CLK_FREQ_MHZ {config_data["clk_freq_mhz"]}\n')
    tcl_content.append(f'set clk_freq_mhz {config_data["clk_freq_mhz"]}\n')

if 'btb_entries' in config_data:
    verilog_content.append(f'`define BTB_ENTRY {config_data["btb_entries"]}\n')

if 'imem_size_kbyte' in config_data:
    verilog_content.append(f'`define IMEM_ENTRIES {config_data["imem_size_kbyte"] * 1024 // 4}\n')
    linker_content.append(f"    imem : ORIGIN = 0x00000000, LENGTH = {config_data['imem_size_kbyte']}K\n")

if 'dmem_size_kbyte' in config_data:
    verilog_content.append(f'`define DMEM_ENTRIES {config_data["dmem_size_kbyte"] * 1024 // 4}\n')
    linker_content.append(f'    dmem : ORIGIN = {DRAM_BASE_ADDR:#x}, LENGTH = {config_data["dmem_size_kbyte"]}K\n')

if 'uart_baudrate' in config_data:
    verilog_content.append(f'`define UART_BAUDRATE {config_data["uart_baudrate"]}\n')

linker_content.append('}\n')

#===============================================================================
# Write to files
#===============================================================================
try:
    with open(VH_FILE, 'w') as f:
        f.writelines(verilog_content)
    print(f'"{VH_FILE}" has been generated successfully.')
except IOError as e:
    print(f'Error occurred while writing to file: {e}')

try:
    with open(LINKER_FILE, 'w') as f:
        f.writelines(linker_content)
    print(f'"{LINKER_FILE}" has been generated successfully.')
except IOError as e:
    print(f'Error occurred while writing to file: {e}')

try:
    with open(TCL_FILE, 'w') as f:
        f.writelines(tcl_content)
    print(f'"{TCL_FILE}" has been updated successfully.')
except IOError as e:
    print(f'Error occurred while writing to file: {e}')
