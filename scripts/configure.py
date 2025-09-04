import yaml
import os

YAML_FILE = 'src/config.yml'
VH_FILE = 'build/config.vh'
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
verilog_content.append('/* CFU Proving Ground since 2025-02    Copyright(c) 2025 Archlab. Science Tokyo /\n')
verilog_content.append('/ Released under the MIT license https://opensource.org/licenses/mit           */\n\n')

linker_content = []
linker_content.append('MEMORY {\n')

if 'device' in config_data:
    verilog_content.append('// --- Device Configuration ---\n')
    device_config = config_data['device']
    if 'lcd_rotate' in device_config:
        verilog_content.append(f'`define LCD_ROTATE {device_config["lcd_rotate"]}\n')

if 'cpu' in config_data:
    verilog_content.append('\n// --- CPU Configuration ---\n')
    cpu_config = config_data['cpu']
    if 'clk_freq_mhz' in cpu_config:
        verilog_content.append(f'`define CLK_FREQ_MHZ {cpu_config["clk_freq_mhz"]}\n')
    if 'btb_entries' in cpu_config:
        verilog_content.append(f'`define BTB_ENTRY {cpu_config["btb_entries"]}\n')

if 'memory' in config_data:
    verilog_content.append('\n// --- Memory Configuration ---\n')
    mem_config = config_data['memory']
    if 'imem_size_kbyte' in mem_config:
        verilog_content.append(f'`define IMEM_ENTRIES {mem_config["imem_size_kbyte"] * 1024 // 4}\n')
        linker_content.append(f"    imem : ORIGIN = 0x00000000, LENGTH = {mem_config['imem_size_kbyte']}K\n")
    if 'dmem_size_kbyte' in mem_config:
        verilog_content.append(f'`define DMEM_ENTRIES {mem_config["dmem_size_kbyte"] * 1024 // 4}\n')
        linker_content.append(f"    dmem : ORIGIN = 0x10000000, LENGTH = {mem_config['dmem_size_kbyte']}K\n")

verilog_content.append("`define NONE_TYPE 0\n")
verilog_content.append("`define R_TYPE 1\n")
verilog_content.append("`define I_TYPE 2\n")
verilog_content.append("`define S_TYPE 3\n")
verilog_content.append("`define B_TYPE 4\n")
verilog_content.append("`define U_TYPE 5\n")
verilog_content.append("`define J_TYPE 6\n")
verilog_content.append("`define INSTR_TYPE_WIDTH 3\n")

verilog_content.append("`define SRC2_CTRL_USE_AUIPC 0\n")
verilog_content.append("`define SRC2_CTRL_USE_IMM 1\n")
verilog_content.append("`define SRC2_CTRL_WIDTH 2\n")

verilog_content.append("`define ALU_CTRL_IS_SIGNED 0\n")
verilog_content.append("`define ALU_CTRL_IS_NEG 1\n")
verilog_content.append("`define ALU_CTRL_IS_LESS 2\n")
verilog_content.append("`define ALU_CTRL_IS_ADD 3\n")
verilog_content.append("`define ALU_CTRL_IS_SHIFT_LEFT 4\n")
verilog_content.append("`define ALU_CTRL_IS_SHIFT_RIGHT 5\n")
verilog_content.append("`define ALU_CTRL_IS_XOR_OR 6\n")
verilog_content.append("`define ALU_CTRL_IS_OR_AND 7\n")
verilog_content.append("`define ALU_CTRL_IS_SRC2 8\n")
verilog_content.append("`define ALU_CTRL_WIDTH 9\n")

verilog_content.append("`define BRU_CTRL_IS_CTRL_TSFR 0\n")
verilog_content.append("`define BRU_CTRL_IS_SIGNED 1\n")
verilog_content.append("`define BRU_CTRL_IS_BEQ 2\n")
verilog_content.append("`define BRU_CTRL_IS_BNE 3\n")
verilog_content.append("`define BRU_CTRL_IS_BLT 4\n")
verilog_content.append("`define BRU_CTRL_IS_BGE 5\n")
verilog_content.append("`define BRU_CTRL_IS_JALR 6\n")
verilog_content.append("`define BRU_CTRL_IS_JAL_JALR 7\n")
verilog_content.append("`define BRU_CTRL_WIDTH 8\n")

verilog_content.append("`define LSU_CTRL_IS_LOAD 0\n")
verilog_content.append("`define LSU_CTRL_IS_STORE 1\n")
verilog_content.append("`define LSU_CTRL_IS_SIGNED 2\n")
verilog_content.append("`define LSU_CTRL_IS_BYTE 3\n")
verilog_content.append("`define LSU_CTRL_IS_HALFWORD 4\n")
verilog_content.append("`define LSU_CTRL_IS_WORD 5\n")
verilog_content.append("`define LSU_CTRL_WIDTH 6\n")

verilog_content.append("`define PERF_CTRL_IS_CYCLE 0\n")
verilog_content.append("`define PERF_CTRL_IS_CYCLEH 1\n")
verilog_content.append("`define PERF_CTRL_IS_INSTRET 2\n")
verilog_content.append("`define PERF_CTRL_IS_INSTRETH 3\n")
verilog_content.append("`define PERF_CTRL_WIDTH 4\n")

verilog_content.append("`define MUL_CTRL_IS_MUL 0\n")
verilog_content.append("`define MUL_CTRL_IS_SRC1_SIGNED 1\n")
verilog_content.append("`define MUL_CTRL_IS_SRC2_SIGNED 2\n")
verilog_content.append("`define MUL_CTRL_IS_HIGH 3\n")
verilog_content.append("`define MUL_CTRL_WIDTH 4\n")

verilog_content.append("`define DIV_CTRL_IS_DIV 0\n")
verilog_content.append("`define DIV_CTRL_IS_SIGNED 1\n")
verilog_content.append("`define DIV_CTRL_IS_REM 2\n")
verilog_content.append("`define DIV_CTRL_WIDTH 3\n")

verilog_content.append("`define CFU_CTRL_IS_CFU 0\n")
verilog_content.append("`define CFU_CTRL_WIDTH 11\n")

linker_content.append('}\n')

# tmp
verilog_content.append("`define XLEN 32\n")
verilog_content.append("`define XBYTES 4\n")
verilog_content.append("`define RESET_VECTOR 32'h00000000\n")
verilog_content.append("`define NOP 32'h00000013\n")
verilog_content.append("`define IMEM_SIZE (32*1024) // instruction memory size in byte\n")
verilog_content.append("`define DMEM_SIZE (16*1024) // data memory size in byte\n")
verilog_content.append("`define IMEM_ADDRW ($clog2(`IMEM_ENTRIES))\n")
verilog_content.append("`define DMEM_ADDRW ($clog2(`DMEM_ENTRIES))\n")
verilog_content.append("`define IBUS_ADDR_WIDTH `XLEN\n")
verilog_content.append("`define IBUS_DATA_WIDTH 32\n")
verilog_content.append("`define DBUS_ADDR_WIDTH `XLEN\n")
verilog_content.append("`define DBUS_DATA_WIDTH `XLEN\n")
verilog_content.append("`define DBUS_STRB_WIDTH (`DBUS_DATA_WIDTH/8)\n")


# try:
#     with open(VH_FILE, 'w') as f:
#         f.writelines(verilog_content)
#     print(f"'{VH_FILE}' has been generated successfully.")
# except IOError as e:
#     print(f"Error occurred while writing to file: {e}")

try:
    with open(LINKER_FILE, 'w') as f:
        f.writelines(linker_content)
    print(f"'{LINKER_FILE}' has been generated successfully.")
except IOError as e:
    print(f"Error occurred while writing to file: {e}")

