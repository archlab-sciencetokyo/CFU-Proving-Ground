`ifndef RVCPU_H_
`define RVCPU_H_

`ifndef CONFIG_VH_
`define CONFIG_VH_

// LCD Display
`define LCD_ROTATE 0 // 0: 0 degree, 1: 90 degree, 2: 180 degree, 3: 270 degree (Left Rotate)

// cpu
`define RESET_VECTOR    'h00000000

`define PHT_ENTRY       8192
`define BTB_ENTRY       512

// ram
`define IMEM_SIZE       (64*1024)
`define DMEM_SIZE       (16*1024)

// uart
`ifndef CLK_FREQ_MHZ
    `define CLK_FREQ_MHZ    100
`endif
`ifndef BAUD_RATE
    `define BAUD_RATE       1000000
`endif
`define DETECT_COUNT    2
`define FIFO_DEPTH      2048

`endif // CONFIG_VH_

// tohost
`define TOHOST_ADDR             'h40008000 // do not modify, this is hard coded in the interconnect

// cpu
`define XLEN                    32
`define XBYTES                  (`XLEN/8)

`define NOP                     32'h00000013 // addi  x0, x0, 0
`define UNIMP                   32'hC0001073 // csrrw x0, cycle, x0

// ram
`define IBUS_ADDR_WIDTH         `XLEN
`define IBUS_DATA_WIDTH         32

`define DBUS_ADDR_WIDTH         `XLEN
`define DBUS_DATA_WIDTH         `XLEN
`define DBUS_STRB_WIDTH         (`DBUS_DATA_WIDTH/8)

// instruction type
`define NONE_TYPE               0
`define R_TYPE                  1
`define I_TYPE                  2
`define S_TYPE                  3
`define B_TYPE                  4
`define U_TYPE                  5
`define J_TYPE                  6
`define INSTR_TYPE_WIDTH        3

// source 2 control
`define SRC2_CTRL_USE_AUIPC     0
`define SRC2_CTRL_USE_IMM       1
`define SRC2_CTRL_WIDTH         2

// alu control
`define ALU_CTRL_IS_SIGNED      0
`define ALU_CTRL_IS_NEG         1
`define ALU_CTRL_IS_LESS        2
`define ALU_CTRL_IS_ADD         3
`define ALU_CTRL_IS_SHIFT_LEFT  4
`define ALU_CTRL_IS_SHIFT_RIGHT 5
`define ALU_CTRL_IS_XOR_OR      6
`define ALU_CTRL_IS_OR_AND      7
`define ALU_CTRL_IS_SRC2        8
`define ALU_CTRL_WIDTH          9

// bru control
`define BRU_CTRL_IS_CTRL_TSFR   0
`define BRU_CTRL_IS_SIGNED      1
`define BRU_CTRL_IS_BEQ         2
`define BRU_CTRL_IS_BNE         3
`define BRU_CTRL_IS_BLT         4
`define BRU_CTRL_IS_BGE         5
`define BRU_CTRL_IS_JALR        6
`define BRU_CTRL_IS_JAL_JALR    7
`define BRU_CTRL_WIDTH          8

// lsu control
`define LSU_CTRL_IS_LOAD        0
`define LSU_CTRL_IS_STORE       1
`define LSU_CTRL_IS_SIGNED      2
`define LSU_CTRL_IS_BYTE        3
`define LSU_CTRL_IS_HALFWORD    4
`define LSU_CTRL_IS_WORD        5
`define LSU_CTRL_WIDTH          6

// perf control
`define PERF_CTRL_IS_CYCLE     0
`define PERF_CTRL_IS_CYCLEH    1
`define PERF_CTRL_IS_INSTRET   2
`define PERF_CTRL_IS_INSTRETH  3
`define PERF_CTRL_WIDTH        4

// mul control
`define MUL_CTRL_IS_MUL         0
`define MUL_CTRL_IS_SRC1_SIGNED 1
`define MUL_CTRL_IS_SRC2_SIGNED 2
`define MUL_CTRL_IS_HIGH        3
`define MUL_CTRL_WIDTH          4

// div control
`define DIV_CTRL_IS_DIV         0
`define DIV_CTRL_IS_SIGNED      1
`define DIV_CTRL_IS_REM         2
`define DIV_CTRL_WIDTH          3

// cfu control
`define CFU_CTRL_WIDTH 10

`endif // RVCPU_H_
