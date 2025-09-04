import yaml
import os

YAML_FILE = 'src/user_config.yml'
VH_FILE = 'build/user_config.vh'
LINKER_FILE = 'build/region.ld'

if not os.path.exists(YAML_FILE):
    print(f"{YAML_FILE} could not be found.")
    exit(1)

try:
    with open(YAML_FILE, 'r') as f:
        config_data = yaml.safe_load(f)
except yaml.YAMLError as e:
    print(f"Error parsing {YAML_FILE}: {e}")
    exit(1)

verilog_content = []

linker_content = []
linker_content.append('MEMORY {\n')

if 'lcd_rotate' in config_data:
    verilog_content.append(f'`define LCD_ROTATE {config_data["lcd_rotate"]}\n')

if 'clk_freq_mhz' in config_data:
    verilog_content.append(f'`define CLK_FREQ_MHZ {config_data["clk_freq_mhz"]}\n')

if 'btb_entries' in config_data:
    verilog_content.append(f'`define BTB_ENTRY {config_data["btb_entries"]}\n')

if 'imem_size_kbyte' in config_data:
    verilog_content.append(f'`define IMEM_ENTRIES {config_data["imem_size_kbyte"] * 1024 // 4}\n')
    linker_content.append(f"    imem : ORIGIN = 0x00000000, LENGTH = {config_data['imem_size_kbyte']}K\n")

if 'dmem_size_kbyte' in config_data:
    verilog_content.append(f'`define DMEM_ENTRIES {config_data["dmem_size_kbyte"] * 1024 // 4}\n')
    linker_content.append(f"    dmem : ORIGIN = 0x10000000, LENGTH = {config_data['dmem_size_kbyte']}K\n")

linker_content.append('}\n')

try:
    with open(VH_FILE, 'w') as f:
        f.writelines(verilog_content)
    print(f"'{VH_FILE}' has been generated successfully.")
except IOError as e:
    print(f"Error occurred while writing to file: {e}")

try:
    with open(LINKER_FILE, 'w') as f:
        f.writelines(linker_content)
    print(f"'{LINKER_FILE}' has been generated successfully.")
except IOError as e:
    print(f"Error occurred while writing to file: {e}")

