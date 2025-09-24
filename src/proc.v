/* CFU Proving Ground since 2025-02   Copyright(c) 2025 Archlab. Science Tokyo /
/ Released under the MIT license https://opensource.org/licenses/mit          */
`default_nettype none
`include "config.vh"
/******************************************************************************/
`define ITYPE_W `INSTR_TYPE_WIDTH
`define NOP 32'h00000013 // addi  x0, x0, 0

/******************************************************************************/
//==============================================================================
// This processor isn't completed yet.
// It doesn't work correctly when using store instruction following mul/div
// instruction.
//------------------------------------------------------------------------------
module cpu (
    input  wire        clk_i,
    input  wire        rst_i,
    output wire [31:0] ibus_addr_o,
    input  wire [31:0] ibus_data_i,
    output wire        ibus_rdata_en_o,
    output wire [31:0] dbus_cmd_addr_o,
    output wire        dbus_cmd_valid_o,
    output wire        dbus_cmd_we_o,
    input  wire        dbus_cmd_ack_i,
    input  wire [31:0] dbus_rdata_data_i,
    output wire [31:0] dbus_wdata_data_o,
    output wire  [3:0] dbus_wdata_en_o
);
//==============================================================================
// pipeline registers
//------------------------------------------------------------------------------
    // ID: Instruction Decode
    reg                       IfId_v;
    reg [               31:0] IfId_pc;
    reg                       IfId_br_pred_tkn;
    reg [                1:0] IfId_pattern_hist;
    reg                       IfId_load_muldiv_use;
    reg [       `ITYPE_W-1:0] IfId_instr_type;
    reg                       IfId_rf_we;
    reg [                4:0] IfId_rd;
    reg [                4:0] IfId_rs1;
    reg [                4:0] IfId_rs2;

    // EX: Execution
    reg                       IdEx_v;
    reg [               31:0] IdEx_pc;
    reg [               31:0] IdEx_ir;
    reg                       IdEx_br_pred_tkn;
    reg [                1:0] IdEx_pattern_hist;
    reg [`ALU_CTRL_WIDTH-1:0] IdEx_alu_ctrl;
    reg [`BRU_CTRL_WIDTH-1:0] IdEx_bru_ctrl;
    reg [`LSU_CTRL_WIDTH-1:0] IdEx_lsu_ctrl;
    reg [`MUL_CTRL_WIDTH-1:0] IdEx_mul_ctrl;
    reg [`DIV_CTRL_WIDTH-1:0] IdEx_div_ctrl;
    reg [`CFU_CTRL_WIDTH-1:0] IdEx_cfu_ctrl;
    reg                       IdEx_rs1_fwd_Ma_to_Ex;
    reg                       IdEx_rs2_fwd_Ma_to_Ex;
    reg                       IdEx_rs1_fwd_Wb_to_Ex = 0;
    reg                       IdEx_rs2_fwd_Wb_to_Ex = 0;
    reg                       IdEx_loaduse = 0;
    reg                 [4:0] IdEx_rs1;
    reg                 [4:0] IdEx_rs2;
    reg [               31:0] IdEx_src1;
    reg [               31:0] IdEx_src2;
    reg [               31:0] IdEx_imm;
    reg                       IdEx_rf_we;
    reg [                4:0] IdEx_rd;
    reg [               31:0] IdEx_j_pc4;

    // MA: Memory Access
    reg                       ExMa_v;
    reg [               31:0] ExMa_pc;
    reg [               31:0] ExMa_ir;
    reg [                1:0] ExMa_pattern_hist;
    reg                       ExMa_bru_taken;
    reg                       ExMa_bru_misp;
    reg [               31:0] ExMa_bru_taken_pc;
    reg                       ExMa_pred_we;
    reg [`LSU_CTRL_WIDTH-1:0] ExMa_lsu_ctrl;
    reg [                1:0] ExMa_dbus_offset;
    reg                       ExMa_rf_we;
    reg [                4:0] ExMa_rd;
    reg [               31:0] ExMa_mul_rslt;
    reg [               31:0] ExMa_rslt;
    reg                       ExMa_misp;

    // WB: Write Back
    reg                       MaWb_v;
    reg [               31:0] MaWb_pc;
    reg [               31:0] MaWb_ir;
    reg                       MaWb_rf_we;
    reg [                4:0] MaWb_rd;
    reg [               31:0] MaWb_rslt;

//==============================================================================
// Pipeline Control Signals
//------------------------------------------------------------------------------
    reg  [31:0] pc = 0;
    reg rst; always @(posedge clk_i) rst <= rst_i;

    wire If_stall = Id_stall;
    wire If_v     = ~If_stall;
    wire Id_stall = Ex_stall;
    wire Id_v     = ~ExMa_bru_misp & IfId_v & ~Id_stall;
    wire Ex_stall = Ma_stall | ExMa_loaduse | (IdEx_wait_ex_result & ~Ex_rslt_v);
    wire Ex_v     = ~ExMa_bru_misp & IdEx_v & ~Ex_stall;
    wire Ma_stall = ExMa_wait_cmd_ack;
    wire Ma_v     = ExMa_v & ~Ma_stall;
    wire Wb_stall = 0;
    wire Wb_v     = MaWb_v;

    wire Ex_loaduse          = Id_v & Ex_v & IdEx_lsu_ctrl[`LSU_CTRL_IS_LOAD]
                             & ((IdEx_rd == Id_rs1) | (IdEx_rd == Id_rs2));
    wire Ex_rslt_v           = Ex_mul_valid | Ex_div_valid;
    reg  IdEx_wait_ex_result = 0;
    reg  ExMa_loaduse        = 0;
    reg  ExMa_wait_cmd_ack   = 0;
    always @(posedge clk_i) begin
        if (!Ma_stall) begin
        IdEx_wait_ex_result <= (~IdEx_wait_ex_result & IfId_v & (Id_mul_ctrl[`MUL_CTRL_IS_MUL] | Id_div_ctrl[`DIV_CTRL_IS_DIV]))
                             | (IdEx_wait_ex_result & ~Ex_rslt_v);
        end
        ExMa_wait_cmd_ack   <= (~ExMa_wait_cmd_ack & dbus_cmd_valid_o) | (ExMa_wait_cmd_ack & ~dbus_cmd_ack_i);
    end

//==============================================================================
// IF Stage
//------------------------------------------------------------------------------
    always @(posedge clk_i) if (~If_stall) begin
        pc <= If_pc;
    end
    wire [31:0] If_pc;
    wire  [1:0] If_pred_pattern_hist;
    wire        If_pred_taken;
    wire [31:0] If_pred_pc;
    bimodal bimodal (
        .clk_i          (clk_i),
        .re_i           (~If_stall),
        .raddr_i        (If_pc),
        .we_i           (ExMa_pred_we),
        .waddr_i        (ExMa_pc),
        .pattern_hist_i (ExMa_pattern_hist),
        .istaken_i      (ExMa_bru_taken),
        .taken_pc_i     (ExMa_bru_taken_pc),
        .pattern_hist_o (If_pred_pattern_hist),
        .pred_istaken_o (If_pred_taken),
        .pred_pc_o      (If_pred_pc)
    );
    assign If_pc  = (ExMa_bru_misp) ? ExMa_bru_taken_pc :
                         (If_pred_taken) ? If_pred_pc : pc+4;
    assign ibus_addr_o = If_pc;

//==============================================================================
// ID Stage
//------------------------------------------------------------------------------
    always @(posedge clk_i) if (~Id_stall) begin
        IfId_v            <= If_v;
        IfId_pc           <= If_pc;
        IfId_pattern_hist <= If_pred_pattern_hist;
    end

    wire         [31:0] Id_ir;
    wire [`ITYPE_W-1:0] Id_ir_type;
    wire                Id_rf_we;
    wire          [4:0] Id_rd;
    wire          [4:0] Id_rs1;
    wire          [4:0] Id_rs2;
    assign ibus_rdata_en_o = ~Id_stall;
    assign Id_ir     = ibus_data_i;
    pre_decoder pre_decoder (
        .ir_i        (Id_ir),
        .instr_type_o(Id_ir_type),
        .rf_we_o     (Id_rf_we),
        .rd_o        (Id_rd),
        .rs1_o       (Id_rs1),
        .rs2_o       (Id_rs2)
    );

    wire [`SRC2_CTRL_WIDTH-1:0] Id_src2_ctrl;
    wire [ `ALU_CTRL_WIDTH-1:0] Id_alu_ctrl;
    wire [ `BRU_CTRL_WIDTH-1:0] Id_bru_ctrl;
    wire [ `LSU_CTRL_WIDTH-1:0] Id_lsu_ctrl;
    wire [ `MUL_CTRL_WIDTH-1:0] Id_mul_ctrl;
    wire [ `DIV_CTRL_WIDTH-1:0] Id_div_ctrl;
    wire [ `CFU_CTRL_WIDTH-1:0] Id_cfu_ctrl;
    decoder decoder (
        .ir_i       (Id_ir),
        .src2_ctrl_o(Id_src2_ctrl),
        .alu_ctrl_o (Id_alu_ctrl),
        .bru_ctrl_o (Id_bru_ctrl),
        .lsu_ctrl_o (Id_lsu_ctrl),
        .mul_ctrl_o (Id_mul_ctrl),
        .div_ctrl_o (Id_div_ctrl),
        .cfu_ctrl_o (Id_cfu_ctrl)
    );

    wire [31:0] Id_imm;
    imm_gen imm_gen (
        .ir_i        (Id_ir),
        .instr_type_i(Id_ir_type),
        .imm_o       (Id_imm)
    );

    wire [31:0] Id_xrs1;
    wire [31:0] Id_xrs2;
    regfile xreg (
        .clk_i  (clk_i),
        .rs1_i  (Id_rs1),
        .rs2_i  (Id_rs2),
        .xrs1_o (Id_xrs1),
        .xrs2_o (Id_xrs2),
        .we_i   (Wb_rf_we),
        .rd_i   (MaWb_rd),
        .wdata_i(MaWb_rslt)
    );

    wire Id_rs1_fwd_Ma_to_Ex = IdEx_v && IdEx_rf_we && (IdEx_rd == Id_rs1);
    wire Id_rs2_fwd_Ma_to_Ex = IdEx_v && IdEx_rf_we && (IdEx_rd == Id_rs2);
    wire Id_rs1_fwd_Ma_to_Id = ExMa_v && ExMa_rf_we && (ExMa_rd == Id_rs1);
    wire Id_rs2_fwd_Ma_to_Id = ExMa_v && ExMa_rf_we && (ExMa_rd == Id_rs2);

    wire [31:0] Id_pc_in   = (Id_src2_ctrl[`SRC2_CTRL_USE_AUIPC]) ? IfId_pc : 0;
    wire        Id_use_imm = Id_src2_ctrl[`SRC2_CTRL_USE_AUIPC] | Id_src2_ctrl[`SRC2_CTRL_USE_IMM];

    //source select
    wire [31:0] Id_src1 = (Id_rs1_fwd_Ma_to_Id) ? Ma_rslt : Id_xrs1;
    wire [31:0] Id_src2 = (Id_rs2_fwd_Ma_to_Id) ? Ma_rslt : 
                          (Id_use_imm) ? Id_pc_in + Id_imm  : Id_xrs2;
    wire Id_rs1_fwd_Wb_to_Ex = Ex_v & Ma_v & IdEx_lsu_ctrl[`LSU_CTRL_IS_LOAD] & (Id_rs1 == IdEx_rd);
    wire Id_rs2_fwd_Wb_to_Ex = Ex_v & Ma_v & IdEx_lsu_ctrl[`LSU_CTRL_IS_LOAD] & (Id_rs2 == IdEx_rd);

    // for JAL/JALR
    wire [31:0] Id_j_pc4 = (Id_bru_ctrl[`BRU_CTRL_IS_JAL_JALR]) ? IfId_pc + 4 : 0;

//==============================================================================
// EX Stage
//------------------------------------------------------------------------------
    always @(posedge clk_i) if (~Ex_stall) begin
        IdEx_v                <= Id_v;
        IdEx_pc               <= IfId_pc;
        IdEx_ir               <= Id_ir;
        IdEx_j_pc4            <= Id_j_pc4;
        IdEx_pattern_hist     <= IfId_pattern_hist;
        IdEx_alu_ctrl         <= Id_alu_ctrl;
        IdEx_bru_ctrl         <= Id_bru_ctrl;
        IdEx_lsu_ctrl         <= Id_lsu_ctrl;
        IdEx_mul_ctrl         <= Id_mul_ctrl;
        IdEx_div_ctrl         <= Id_div_ctrl;
        IdEx_rs1              <= Id_rs1;
        IdEx_rs2              <= Id_rs2;
        IdEx_rs1_fwd_Ma_to_Ex <= Id_rs1_fwd_Ma_to_Ex;
        IdEx_rs2_fwd_Ma_to_Ex <= Id_rs2_fwd_Ma_to_Ex;
        IdEx_rs1_fwd_Wb_to_Ex <= Id_rs1_fwd_Wb_to_Ex;
        IdEx_rs2_fwd_Wb_to_Ex <= Id_rs2_fwd_Wb_to_Ex;
        IdEx_src1             <= Id_src1;
        IdEx_src2             <= Id_src2;
        IdEx_imm              <= Id_imm;
        IdEx_rf_we            <= Id_rf_we;
        IdEx_rd               <= Id_rd;
        IdEx_cfu_ctrl         <= Id_cfu_ctrl;
    end

    wire [31:0] Ex_src1 = (IdEx_rs1_fwd_Ma_to_Ex & ExMa_v) ? ExMa_rslt :
                          ((IdEx_rs1 == MaWb_rd) & (MaWb_rd != 0) & MaWb_v) ? MaWb_rslt : IdEx_src1;
    wire [31:0] Ex_src2 = (IdEx_rs2_fwd_Ma_to_Ex & ExMa_v) ? ExMa_rslt :
                          ((IdEx_rs2 == MaWb_rd) & (MaWb_rd != 0) & MaWb_v) ? MaWb_rslt : IdEx_src2;

    wire [31:0] Ex_alu_rslt;
    alu alu (
        .alu_ctrl_i(IdEx_alu_ctrl),
        .src1_i    (Ex_src1),
        .src2_i    (Ex_src2),
        .j_pc4_i   (IdEx_j_pc4),
        .rslt_o    (Ex_alu_rslt)
    );

    wire        Ex_bru_taken;
    wire        Ex_bru_misp;
    wire [31:0] Ex_bru_taken_pc;
    bru bru (
        .bru_ctrl_i     (IdEx_bru_ctrl),
        .valid_i        (Ex_v),
        .src1_i         (Ex_src1),
        .src2_i         (Ex_src2),
        .imm_i          (IdEx_imm),
        .Ex_pc_i        (IdEx_pc),
        .Id_pc_i        (IfId_pc),
        .bru_taken_o    (Ex_bru_taken),
        .bru_misp_o     (Ex_bru_misp),
        .bru_taken_pc_o (Ex_bru_taken_pc)
    );

    wire [1:0] dbus_offset;
    store_unit store_unit (
        .valid_i          (Ex_v),
        .lsu_ctrl_i       (IdEx_lsu_ctrl),
        .src1_i           (Ex_src1),
        .src2_i           (Ex_src2),
        .imm_i            (IdEx_imm),
        .dbus_cmd_addr_o  (dbus_cmd_addr_o),
        .dbus_cmd_we_o    (dbus_cmd_we_o),
        .dbus_cmd_valid_o (dbus_cmd_valid_o),
        .dbus_cmd_offset_o(dbus_offset),
        .dbus_wdata_data_o(dbus_wdata_data_o),
        .dbus_wdata_en_o  (dbus_wdata_en_o)
    );

    wire        Ex_mul_valid;
    wire [31:0] Ex_mul_rslt;
    multiplier multiplier (
        .clk_i(clk_i),
        .rst_i(rst),
        .cmd_valid_i(IdEx_v),
        .cmd_ready_o(),
        .cmd_ctrl_i(IdEx_mul_ctrl),
        .cmd_src1_i(Ex_src1),
        .cmd_src2_i(Ex_src2),
        .rsp_valid_o(Ex_mul_valid),
        .rsp_ready_i(~Ma_stall),
        .rsp_rslt_o(Ex_mul_rslt)
    );


    
    wire        Ex_div_valid;
    wire [31:0] Ex_div_rslt;
    divider divider (
        .clk_i(clk_i),
        .rst_i(rst),
        .cmd_valid_i(IdEx_v),
        .cmd_ctrl_i(IdEx_div_ctrl),
        .cmd_src1_i(Ex_src1),
        .cmd_src2_i(Ex_src2),
        .rsp_valid_o(Ex_div_valid),
        .rsp_ready_i(~Ma_stall),
        .rsp_rslt_o(Ex_div_rslt)
    );

    wire        Ex_cfu_en = IdEx_cfu_ctrl[0] & Ex_v;
    wire        Ex_cfu_stall;
    wire [31:0] Ex_cfu_rslt;
    cfu cfu (
        .clk_i   (clk_i),
        .en_i    (Ex_cfu_en),
        .funct3_i(IdEx_cfu_ctrl[3:1]),
        .funct7_i(IdEx_cfu_ctrl[10:4]),
        .src1_i  (Ex_src1),
        .src2_i  (Ex_src2),
        .stall_o (Ex_cfu_stall),
        .rslt_o  (Ex_cfu_rslt)
    );

//==============================================================================
// MA Stage
//------------------------------------------------------------------------------
    always @(posedge clk_i) if (~Ma_stall) begin
        ExMa_v             <= Ex_v;
        ExMa_pc            <= IdEx_pc;
        ExMa_ir            <= IdEx_ir;
        ExMa_loaduse       <= Ex_loaduse;
        ExMa_pred_we       <= Ex_v & IdEx_bru_ctrl[`BRU_CTRL_IS_CTRL_TSFR];
        ExMa_pattern_hist  <= IdEx_pattern_hist;
        ExMa_bru_misp      <= Ex_bru_misp;
        ExMa_bru_taken     <= Ex_bru_taken;
        ExMa_bru_taken_pc  <= Ex_bru_taken_pc;
        ExMa_lsu_ctrl      <= IdEx_lsu_ctrl;
        ExMa_dbus_offset   <= dbus_offset;
        ExMa_rf_we         <= IdEx_rf_we;
        ExMa_rd            <= IdEx_rd;
        ExMa_rslt          <= Ex_alu_rslt | Ex_mul_rslt | Ex_div_rslt | Ex_cfu_rslt;
        ExMa_misp          <= Ex_bru_misp;
    end
    // load unit
    wire [31:0] Ma_load_rslt;
    load_unit load_unit (
        .lsu_ctrl_i       (ExMa_lsu_ctrl),
        .dbus_offset_i    (ExMa_dbus_offset),
        .dbus_rdata_data_i (dbus_rdata_data_i),
        .dbus_cmd_ack_i   (dbus_cmd_ack_i),
        .waiting_cmd_ack  (),
        .rslt_o           (Ma_load_rslt)
    );

    wire [31:0] Ma_rslt = ExMa_rslt | Ma_load_rslt;

//==============================================================================
// WB Stage
//------------------------------------------------------------------------------
    always @(posedge clk_i) if (~Wb_stall) begin
        MaWb_v     <= Ma_v;
        MaWb_pc    <= ExMa_pc;
        MaWb_ir    <= ExMa_ir;
        MaWb_rf_we <= ExMa_rf_we;
        MaWb_rd    <= ExMa_rd;
        MaWb_rslt  <= Ma_rslt;
    end
    wire Wb_rf_we = Wb_v & MaWb_rf_we;
endmodule  // cpu

/******************************************************************************/
module bimodal (
    input  wire        clk_i,
    input  wire        re_i,
    input  wire [31:0] raddr_i,
    input  wire        we_i,
    input  wire [31:0] waddr_i,
    input  wire  [1:0] pattern_hist_i,
    input  wire        istaken_i,
    input  wire [31:0] taken_pc_i,
    output wire  [1:0] pattern_hist_o,
    output wire        pred_istaken_o,
    output wire [31:0] pred_pc_o
);
    // Init as weakly taken
    integer i;
    reg [31:0] btb [0:`BTB_ENTRY-1];
    initial for (i = 0; i < `BTB_ENTRY; i = i + 1) btb[i] = 2'b01;  

    wire [$clog2(`BTB_ENTRY)-1:0] raddr = raddr_i[$clog2(`BTB_ENTRY)+1:2];
    wire [$clog2(`BTB_ENTRY)-1:0] waddr = waddr_i[$clog2(`BTB_ENTRY)+1:2];
    wire [1:0] count = (istaken_i) ? pattern_hist_i + (pattern_hist_i != 2'b11)
                                   : pattern_hist_i - (pattern_hist_i != 2'b00);

    reg [31:0] rdata = 32'b01;
    always @(posedge clk_i) begin
        if (re_i) rdata <= btb[raddr];
        if (we_i) btb[waddr] <= {taken_pc_i[31:2], count};
    end

    assign pattern_hist_o = rdata[1:0];
    assign pred_istaken_o = rdata[1];
    assign pred_pc_o      = {rdata[31:2], 2'b0};
endmodule

/******************************************************************************/
module pre_decoder (
    input  wire [31:0] ir_i,
    output wire [ 2:0] instr_type_o,
    output wire        rf_we_o,
    output wire [ 4:0] rd_o,
    output wire [ 4:0] rs1_o,
    output wire [ 4:0] rs2_o
);

    wire [4:0] opcode = ir_i[6:2];
    assign instr_type_o = (opcode == 5'b01101) ? `U_TYPE :  // LUI
        (opcode == 5'b00101) ? `U_TYPE :  // AUIPC
        (opcode == 5'b11011) ? `J_TYPE :  // JAL
        (opcode == 5'b11001) ? `I_TYPE :  // JALR
        (opcode == 5'b11000) ? `B_TYPE :  // BRANCH
        (opcode == 5'b00000) ? `I_TYPE :  // LOAD
        (opcode == 5'b01000) ? `S_TYPE :  // STORE
        (opcode == 5'b00100) ? `I_TYPE :  // OP-IMM
        (opcode == 5'b01100) ? `R_TYPE :  // OP
        (opcode == 5'b00010) ? `R_TYPE : `NONE_TYPE;  // CUSTOM-0 : NONE

    assign rd_o = ((instr_type_o == `S_TYPE) | (instr_type_o == `B_TYPE)) ? 0 : ir_i[11:7];
    assign rs1_o = ((instr_type_o == `U_TYPE) | (instr_type_o == `J_TYPE)) ? 0 : ir_i[19:15];
    assign rs2_o = ((instr_type_o==`I_TYPE) | 
                    (instr_type_o==`U_TYPE) | (instr_type_o==`J_TYPE)) ? 0 : ir_i[24:20];
    assign rf_we_o = (rd_o != 0);
endmodule

/******************************************************************************/
module regfile (  ///// register file with bypassing
    input  wire        clk_i,
    input  wire [ 4:0] rs1_i,
    input  wire [ 4:0] rs2_i,
    output wire [31:0] xrs1_o,
    output wire [31:0] xrs2_o,
    input  wire        we_i,
    input  wire [ 4:0] rd_i,
    input  wire [31:0] wdata_i
);

    reg [31:0] ram[0:31];

    assign xrs1_o = (rs1_i == 0) ? 0 : (we_i && rs1_i == rd_i) ? wdata_i : ram[rs1_i];
    assign xrs2_o = (rs2_i == 0) ? 0 : (we_i && rs2_i == rd_i) ? wdata_i : ram[rs2_i];
    always @(posedge clk_i) begin
        if (we_i) begin
            ram[rd_i] <= wdata_i;
        end
    end
endmodule

/******************************************************************************/
module alu (
    input  wire [`ALU_CTRL_WIDTH-1:0] alu_ctrl_i,
    input  wire                [31:0] src1_i    ,
    input  wire                [31:0] src2_i    ,
    input  wire                [31:0] j_pc4_i   ,            
    output wire                [31:0] rslt_o
);

    wire w_signed = alu_ctrl_i[`ALU_CTRL_IS_SIGNED];
    wire w_neg    = alu_ctrl_i[`ALU_CTRL_IS_NEG];
    wire w_less   = alu_ctrl_i[`ALU_CTRL_IS_LESS];

    wire [33:0] adder_src1   = {w_signed && src1_i[31], src1_i, 1'b1};
    wire [33:0] adder_src2   = {w_signed && src2_i[31], src2_i, 1'b0} ^ {34{w_neg}};
    wire [33:0] adder_rslt_t = adder_src1+adder_src2;
    wire        less_rslt    = w_less && adder_rslt_t[33];
    wire [31:0] adder_rslt   = (alu_ctrl_i[`ALU_CTRL_IS_ADD]) ? adder_rslt_t[32:1] : 0;

    wire signed  [32:0] right_shifter_src1 = {w_signed && src1_i[31], src1_i};
    wire  [4:0] shamt              = src2_i[4:0];
    wire [31:0] left_shifter_rslt  = (alu_ctrl_i[`ALU_CTRL_IS_SHIFT_LEFT] ) ?  
                                     src1_i <<  shamt : 0;
    wire [31:0] right_shifter_rslt = (alu_ctrl_i[`ALU_CTRL_IS_SHIFT_RIGHT]) ? 
                                     right_shifter_src1 >>> shamt : 0;

    wire [31:0] bitwise_rslt       = ((alu_ctrl_i[`ALU_CTRL_IS_XOR_OR]) ? 
                                     (src1_i ^ src2_i) : 0) | 
                                     ((alu_ctrl_i[`ALU_CTRL_IS_OR_AND])
                                      ? (src1_i & src2_i) : 0);
    wire [31:0] lui_auipc_rslt     = (alu_ctrl_i[`ALU_CTRL_IS_SRC2]) ? src2_i : 0;

    assign rslt_o = less_rslt | adder_rslt | left_shifter_rslt | right_shifter_rslt | 
                    bitwise_rslt | lui_auipc_rslt | j_pc4_i;
endmodule

/******************************************************************************/
module bru (
    input  wire [`BRU_CTRL_WIDTH-1:0] bru_ctrl_i,
    input  wire                       valid_i,
    input  wire                [31:0] src1_i,
    input  wire                [31:0] src2_i,
    input  wire                [31:0] imm_i,
    input  wire                [31:0] Ex_pc_i,
    input  wire                [31:0] Id_pc_i,
    output wire                       bru_taken_o,
    output wire                       bru_misp_o,
    output wire                [31:0] bru_taken_pc_o
);
    wire signed [32:0] sext_src1 = {bru_ctrl_i[`BRU_CTRL_IS_SIGNED] &&
                                    src1_i[31], src1_i};
    wire signed [32:0] sext_src2 = {bru_ctrl_i[`BRU_CTRL_IS_SIGNED] &&
                                    src2_i[31], src2_i};

    wire w_eq = (src1_i == src2_i);       // equal
    wire w_lt = (sext_src1 < sext_src2);  // less than

    wire istsfr = bru_ctrl_i[`BRU_CTRL_IS_CTRL_TSFR];
    wire istaken = valid_i & ( bru_ctrl_i[`BRU_CTRL_IS_JAL_JALR]     |
                                 (bru_ctrl_i[`BRU_CTRL_IS_BEQ] &  w_eq) |
                                 (bru_ctrl_i[`BRU_CTRL_IS_BNE] & ~w_eq) |
                                 (bru_ctrl_i[`BRU_CTRL_IS_BLT] &  w_lt) |
                                 (bru_ctrl_i[`BRU_CTRL_IS_BGE] & ~w_lt) );
    wire [31:0] taken_pc = ((bru_ctrl_i[`BRU_CTRL_IS_JALR]) ? src1_i : Ex_pc_i) + imm_i;
// Note: I can't think of the situation that predicted `pc (Id_pc)` is correct
//       but predicted `taken` is wrong. Even if the situation exists, I think
//       it can be considered as successful. 

// Note: I found that even if a instruction isn't TSFR, misp_taken has to be
//       considered. For example, when 0xbc is TSFR and 0x400000bc isn't.
//       In this case, even if 0x400000bc is mispredicted as taken, the
//       pipeline cannot be flushed.
    wire misp_taken   = (valid_i & istsfr) && (Id_pc_i != taken_pc);
    wire misp_untaken = valid_i && (Id_pc_i != Ex_pc_i+4);

    assign bru_taken_o    = istaken;
    assign bru_taken_pc_o = (istaken) ? taken_pc   : Ex_pc_i + 4;
    assign bru_misp_o     = (istaken) ? misp_taken : misp_untaken;
endmodule

`define DIV_IDLE  0
`define DIV_CHECK 1
`define DIV_EXEC  2
`define DIV_RET   3
/******************************************************************************/
module divider (
    input  wire        clk_i,
    input  wire        rst_i,
    input  wire        cmd_valid_i,
    input  wire  [2:0] cmd_ctrl_i,
    input  wire [31:0] cmd_src1_i,
    input  wire [31:0] cmd_src2_i,
    output wire        rsp_valid_o,
    input  wire        rsp_ready_i,
    output wire [31:0] rsp_rslt_o
);

    reg        is_dividend_neg;
    reg        is_divisor_neg;
    reg [31:0] remainder;
    reg [31:0] divisor;
    reg [31:0] quotient;
    reg        is_div_rslt_neg;
    reg        is_rem_rslt_neg;
    reg        is_rem;
    reg  [5:0] cntr = 0;
    reg [31:0] rslt;

    wire [31:0] uintx_remainder = (is_dividend_neg) ? ~remainder+1 : remainder;
    wire [31:0] uintx_divisor   = (is_divisor_neg ) ? ~divisor+1   : divisor;
    wire [32:0] difference      = {remainder[30:0], quotient[31]} - divisor;
    wire        q               = !difference[32];

    
    wire w_div    = cmd_ctrl_i[`DIV_CTRL_IS_DIV];
    wire w_signed = cmd_ctrl_i[`DIV_CTRL_IS_SIGNED];
    //wire [1:0] w_state = (w_init) ? `DIV_CHECK :
    //                     (state==`DIV_CHECK && divisor==0) ? `DIV_RET : // Note
    //                     (state==`DIV_CHECK && divisor!=0) ? `DIV_EXEC :
    //                     (state==`DIV_EXEC  && cntr==0) ? `DIV_RET :
    //                     (state==`DIV_EXEC  && cntr!=0) ? `DIV_EXEC : `DIV_IDLE;
    //
    // wire w_init = (state==`DIV_IDLE && valid_i && w_div);

    localparam DIV_STATE_IDLE  = 0;
    localparam DIV_STATE_CHECK = 1;
    localparam DIV_STATE_EXEC  = 2;
    localparam DIV_STATE_RET   = 3;
    reg [1:0] state = DIV_STATE_IDLE;
    always @(posedge clk_i) begin
        case(state)
            DIV_STATE_IDLE: if (cmd_valid_i & w_div) begin
                is_rem          <= cmd_ctrl_i[`DIV_CTRL_IS_REM];
                is_dividend_neg <= w_signed & cmd_src1_i[31];
                is_divisor_neg  <= w_signed & cmd_src2_i[31];
                is_div_rslt_neg <= w_signed & (cmd_src1_i[31] ^ cmd_src2_i[31]);
                is_rem_rslt_neg <= w_signed & cmd_src1_i[31];
                divisor         <= cmd_src2_i;
                {remainder, quotient} <= {cmd_src1_i, 32'd0};
                state           <= DIV_STATE_CHECK;
            end

            DIV_STATE_CHECK: begin
                cntr <= 32;
                if(divisor == 0) begin
                    is_div_rslt_neg <= 0;
                    is_rem_rslt_neg <= 0;
                    {remainder, quotient} <= {remainder, {32{1'b1}}};
                    rslt <= 32'hFFFFFFFF;
                    state <= DIV_STATE_RET;
                end else begin
                    divisor <= uintx_divisor;
                    {remainder, quotient} <= {32'd0, uintx_remainder};
                    state <= DIV_STATE_EXEC;
                end
            end

            DIV_STATE_EXEC: begin
                {remainder, quotient} <= (q) ? {difference[31:0], quotient[30:0], 1'b1} :
                                               {remainder[30:0], quotient, 1'b0};
                cntr <= cntr - 1;
                if (cntr == 0) begin 
                    rslt <= (is_rem) ? ((is_rem_rslt_neg) ? ~remainder+1 : remainder) :
                                       ((is_div_rslt_neg) ? ~quotient+1  : quotient ) ;
                    state <= DIV_STATE_RET;
                end
            end

            DIV_STATE_RET: if (rsp_ready_i) begin
                state <= DIV_STATE_IDLE;
            end
        endcase
        // is_rem            <= (w_init) ? div_ctrl_i[`DIV_CTRL_IS_REM] : is_rem;
        // is_dividend_neg   <= (w_init) ? w_signed && src1_i[31] : is_dividend_neg;
        // is_divisor_neg    <= (w_init) ? w_signed && src2_i[31] : is_divisor_neg;
        // is_div_rslt_neg   <= (w_init) ? w_signed && (src1_i[31] ^ src2_i[31]) :
        //                     (state==`DIV_CHECK && divisor==0) ? 0 : is_div_rslt_neg;
        // is_rem_rslt_neg   <= (w_init) ? w_signed &&  src1_i[31] : 
        //                     (state==`DIV_CHECK && divisor==0) ? 0 : is_rem_rslt_neg;
        
        // divisor <= (w_init) ? src2_i :
        //           (state==`DIV_CHECK && divisor!=0) ? uintx_divisor : divisor;

        // {remainder, quotient} <= (w_init) ? {src1_i, 32'd0} :
        //           (state==`DIV_CHECK && divisor==0) ? {remainder, {32{1'b1}}} :
        //           (state==`DIV_CHECK && divisor!=0) ? {32'd0, uintx_remainder} :
        //           (state==`DIV_EXEC) ? ((q) ? {difference[31:0], quotient[30:0], 1'b1} :
        //                                       {remainder[30:0], quotient, 1'b0}) :
        //           {remainder, quotient};
        // cntr <= (state==`DIV_CHECK) ? 31 : (state==`DIV_EXEC) ?  cntr-1 : cntr;
        // state <= w_state;
    end
    assign rsp_rslt_o  = (state!=DIV_STATE_RET) ? 0 : rslt;
    assign rsp_valid_o = (state==DIV_STATE_RET);
endmodule

`define MUL_IDLE 0
`define MUL_EXEC 1
`define MUL_RET  2
/******************************************************************************/
module multiplier (
    input  wire        clk_i,
    input  wire        rst_i,
    input  wire        cmd_valid_i,
    output wire        cmd_ready_o,
    input  wire [ 3:0] cmd_ctrl_i,
    input  wire [31:0] cmd_src1_i,
    input  wire [31:0] cmd_src2_i,
    output wire        rsp_valid_o,
    input  wire        rsp_ready_i,
    output wire [31:0] rsp_rslt_o
);
    reg signed [32:0] r_multiplicand;
    reg signed [32:0] r_multiplier;
    reg        [63:0] product;
    reg               is_high;

    wire w_mul         = cmd_ctrl_i[`MUL_CTRL_IS_MUL];
    wire w_src1_signed = cmd_ctrl_i[`MUL_CTRL_IS_SRC1_SIGNED];
    wire w_src2_signed = cmd_ctrl_i[`MUL_CTRL_IS_SRC2_SIGNED];
    wire w_is_high     = cmd_ctrl_i[`MUL_CTRL_IS_HIGH];
    //wire [1:0] w_state = (state==`MUL_IDLE && valid_i && w_mul) ? `MUL_EXEC :
    //                     (state==`MUL_EXEC) ? `MUL_RET : `MUL_IDLE;

    localparam MUL_STATE_IDLE = 0;
    localparam MUL_STATE_EXEC = 1;
    localparam MUL_STATE_RET  = 2;
    reg [ 1:0] state = MUL_STATE_IDLE;
    always @(posedge clk_i) begin
        case(state)
            MUL_STATE_IDLE: if (cmd_valid_i & w_mul) begin
                r_multiplicand <= {w_src1_signed && cmd_src1_i[31], cmd_src1_i};
                r_multiplier   <= {w_src2_signed && cmd_src2_i[31], cmd_src2_i};
                is_high        <= w_is_high;
                product        <= 0;
                state          <= MUL_STATE_EXEC;
            end

            MUL_STATE_EXEC: begin
                product <= r_multiplicand * r_multiplier;
                state   <= MUL_STATE_RET;
            end

            MUL_STATE_RET: if (rsp_ready_i) begin
                state <= MUL_STATE_IDLE;
            end
        endcase
        //if (state == `MUL_IDLE) r_multiplicand <= {w_src1_signed && src1_i[31], src1_i};
        //if (state == `MUL_IDLE) r_multiplier <= {w_src2_signed && src2_i[31], src2_i};
        //if (state == `MUL_IDLE) is_high <= w_is_high;
        //if (state == `MUL_EXEC) product <= r_multiplicand * r_multiplier;
    end
    assign rsp_valid_o = (state == `MUL_RET);
    assign rsp_rslt_o  = (state != `MUL_RET) ? 0 :
                         (is_high) ? product[63:32] : product[31:0];
endmodule

/******************************************************************************/
module store_unit (
    input  wire        valid_i,
    input  wire [ 5:0] lsu_ctrl_i,
    input  wire [31:0] src1_i,
    input  wire [31:0] src2_i,
    input  wire [31:0] imm_i,
    output wire [31:0] dbus_cmd_addr_o,
    output wire        dbus_cmd_we_o,
    output wire        dbus_cmd_valid_o,
    output wire  [1:0] dbus_cmd_offset_o,
    output wire [31:0] dbus_wdata_data_o,
    output wire  [3:0] dbus_wdata_en_o
);

    assign dbus_cmd_addr_o   = src1_i + imm_i;  // calculate address with adder
    assign dbus_cmd_offset_o = dbus_cmd_addr_o[1:0];

    assign dbus_cmd_we_o = valid_i && lsu_ctrl_i[`LSU_CTRL_IS_STORE];
    assign dbus_cmd_valid_o = (lsu_ctrl_i[`LSU_CTRL_IS_STORE] | lsu_ctrl_i[`LSU_CTRL_IS_LOAD]) & valid_i;

    wire w_sb = lsu_ctrl_i[`LSU_CTRL_IS_BYTE];
    wire w_sh = lsu_ctrl_i[`LSU_CTRL_IS_HALFWORD];
    wire w_sw = lsu_ctrl_i[`LSU_CTRL_IS_WORD];

    assign dbus_wdata_data_o[7:0]   = src2_i[7:0];
    assign dbus_wdata_data_o[15:8]  = (w_sb) ? src2_i[7:0] : src2_i[15:8];
    assign dbus_wdata_data_o[23:16] = (w_sw) ? src2_i[23:16] : src2_i[7:0];
    assign dbus_wdata_data_o[31:24] = (w_sb) ? src2_i[7:0] : (w_sh) ? src2_i[15:8] : src2_i[31:24];

    assign dbus_wdata_en_o[0] = (w_sb && dbus_cmd_offset_o==0) || (w_sh && dbus_cmd_offset_o[1]==0) || w_sw;
    assign dbus_wdata_en_o[1] = (w_sb && dbus_cmd_offset_o==1) || (w_sh && dbus_cmd_offset_o[1]==0) || w_sw;
    assign dbus_wdata_en_o[2] = (w_sb && dbus_cmd_offset_o==2) || (w_sh && dbus_cmd_offset_o[1]==1) || w_sw;
    assign dbus_wdata_en_o[3] = (w_sb && dbus_cmd_offset_o==3) || (w_sh && dbus_cmd_offset_o[1]==1) || w_sw;
endmodule

/******************************************************************************/
module load_unit (
    input  wire [ 5:0] lsu_ctrl_i,
    input  wire [ 1:0] dbus_offset_i,
    input  wire [31:0] dbus_rdata_data_i,
    input  wire        dbus_cmd_ack_i,
    output wire        waiting_cmd_ack,
    output wire [31:0] rslt_o
);
    assign waiting_cmd_ack = 0; 

    wire        w_lb     = lsu_ctrl_i[`LSU_CTRL_IS_BYTE];
    wire        w_lh     = lsu_ctrl_i[`LSU_CTRL_IS_HALFWORD];
    wire        w_lw     = lsu_ctrl_i[`LSU_CTRL_IS_WORD];
    wire        w_signed = lsu_ctrl_i[`LSU_CTRL_IS_SIGNED];
    wire        w_load   = lsu_ctrl_i[`LSU_CTRL_IS_LOAD];
    wire  [1:0] ost      = dbus_offset_i;  // offset
    wire [31:0] d        = dbus_rdata_data_i;  // data

    wire w_lb_sign = w_lb & ((ost==0) ? d[7] : (ost==1) ? d[15] :(ost==2) ? d[23] : d[31]) & w_signed;
    wire w_lh_sign = w_lh & ((ost[1] == 0) ? d[15] : d[31]) & w_signed;

    wire [7:0] w1, w2, w3, w4;
    assign w1 = (w_load==0) ? 0 : (w_lw || (w_lh & ost[1]==0) || (w_lb & ost==0)) ? d[7:0] : 
                           (w_lb && ost==1) ? d[15:8] : ((w_lb && ost==2) || 
                           (w_lh && ost[1]==1)) ? d[23:16] : d[31:24];
    assign w2 = (w_load==0) ? 0 : (w_lw || (w_lh && ost[1]==0)) ? d[15:8] : 
                           (w_lh && ost[1]==1) ? d[31:24] : (w_lb_sign) ? 8'hff : 0;
    assign w3 = (w_load == 0) ? 0 : (w_lw) ? d[23:16] : ((w_lb_sign) || (w_lh_sign)) ? 8'hff : 0;
    assign w4 = (w_load == 0) ? 0 : (w_lw) ? d[31:24] : ((w_lb_sign) || (w_lh_sign)) ? 8'hff : 0;
    assign rslt_o = {w4, w3, w2, w1};
endmodule

/******************************************************************************/
module imm_gen (
    input  wire [        31:0] ir_i,
    input  wire [`ITYPE_W-1:0] instr_type_i,
    output wire [        31:0] imm_o
);

    wire [31:0] ir = ir_i;
    wire        i_ = (instr_type_i == `I_TYPE);
    wire        s_ = (instr_type_i == `S_TYPE);
    wire        j_ = (instr_type_i == `J_TYPE);
    wire        b_ = (instr_type_i == `B_TYPE);
    wire        u_ = (instr_type_i == `U_TYPE);

    wire        imm0 = (i_) ? ir[20] : (s_) ? ir[7] : 0;
    wire [ 3:0] imm4_1 = (i_ | j_) ? ir[24:21] : (s_ | b_) ? ir[11:8] : 0;
    wire [ 5:0] imm10_5 = (i_ | s_ | b_ | j_) ? ir[30:25] : 0;
    wire        imm11 = (i_ | s_) ? ir[31] : (b_) ? ir[7] : (j_) ? ir[20] : 0;
    wire [ 7:0] imm19_12 = (i_ | s_ | b_) ? {8{ir[31]}} : (u_ | j_) ? ir[19:12] : 0;
    wire [10:0] imm30_20 = (i_ | s_ | b_ | j_) ? {11{ir[31]}} : (u_) ? ir[30:20] : 0;
    assign imm_o = {ir[31], imm30_20, imm19_12, imm11, imm10_5, imm4_1, imm0};
endmodule

/******************************************************************************/
module decoder (
    input  wire [                31:0] ir_i,
    output wire [`SRC2_CTRL_WIDTH-1:0] src2_ctrl_o,
    output wire [ `ALU_CTRL_WIDTH-1:0] alu_ctrl_o,
    output wire [ `BRU_CTRL_WIDTH-1:0] bru_ctrl_o,
    output wire [ `LSU_CTRL_WIDTH-1:0] lsu_ctrl_o,
    output wire [ `MUL_CTRL_WIDTH-1:0] mul_ctrl_o,
    output wire [ `DIV_CTRL_WIDTH-1:0] div_ctrl_o,
    output wire [ `CFU_CTRL_WIDTH-1:0] cfu_ctrl_o
);

    wire [31:0] ir = ir_i;
    wire [ 6:0] opcode = ir[6:0];
    wire [ 4:0] op = ir[6:2];
    wire [ 2:0] f3 = ir[14:12];
    wire [ 6:0] f7 = ir[31:25];
    assign cfu_ctrl_o = (op == 5'b00010) ? {f7, f3, 1'b1} : 0;

    wire src2_c0 = (op == 5'b00101);  // AUIPC
    wire src2_c1 = (op == 5'b01101) | (op == 5'b00100);  // LUI, OP-IMM
    assign src2_ctrl_o = {src2_c1, src2_c0};

    wire bru_c0 = (op == 5'b11011) || (op == 5'b11001) || (op == 5'b11000);  // IS_CTRL_TSFR (JAL, JALR, BRANCH)
    wire bru_c1 = (op == 5'b11000) && (f3 == 4 || f3 == 5);  // IS_SIGNED
    wire bru_c2 = (op == 5'b11000) && (f3 == 0);  // IS_BEQ      
    wire bru_c3 = (op == 5'b11000) && (f3 == 1);  // IS_BNE      
    wire bru_c4 = (op == 5'b11000) && (f3 == 4 || f3 == 6);  // IS_BLT      
    wire bru_c5 = (op == 5'b11000) && (f3 == 5 || f3 == 7);  // IS_BGE      
    wire bru_c6 = (op == 5'b11001);  // IS_JALR     
    wire bru_c7 = (op == 5'b11011) || (op == 5'b11001);  // IS_JAL_JALR 
    assign bru_ctrl_o = {bru_c7, bru_c6, bru_c5, bru_c4, bru_c3, bru_c2, bru_c1, bru_c0};

    wire lsu_c0 = (op == 0);  // IS_LOAD
    wire lsu_c1 = (op == 8);  // IS_STORE
    wire lsu_c2 = (op == 0 && (f3 == 0 || f3 == 1 || f3 == 2));  // IS_SIGNED
    wire lsu_c3 = (op == 0 && (f3 == 0 || f3 == 4)) || (op == 8 && (f3 == 0));  // BYTE
    wire lsu_c4 = (op == 0 && (f3 == 1 || f3 == 5)) || (op == 8 && (f3 == 1));  // HALFWORD
    wire lsu_c5 = (op == 0 && (f3 == 2)) || (op == 8 && (f3 == 2));  // WORD
    assign lsu_ctrl_o = {lsu_c5, lsu_c4, lsu_c3, lsu_c2, lsu_c1, lsu_c0};

    wire mul_c0 = (op == 12) && (f7 == 1) && (f3 == 0 || f3 == 1 || f3 == 2 || f3 == 3);  // IS_MUL
    wire mul_c1 = (op == 12) && (f7 == 1) && (f3 == 1 || f3 == 2);  // IS_SRC1_SIGNED
    wire mul_c2 = (op == 12) && (f7 == 1) && (f3 == 1);  // IS_SRC2_SIGNED
    wire mul_c3 = (op == 12) && (f7 == 1) && (f3 == 1 || f3 == 2 || f3 == 3);  // IS_HIGH
    assign mul_ctrl_o = {mul_c3, mul_c2, mul_c1, mul_c0};

    wire div_c0 = (op == 12) && (f7 == 1) && (f3 == 4 || f3 == 5 || f3 == 6 || f3 == 7);  // IS_DIV
    wire div_c1 = (op == 12) && (f7 == 1) && (f3 == 4 || f3 == 6);  // IS_SIGNED
    wire div_c2 = (op == 12) && (f7 == 1) && (f3 == 6 || f3 == 7);  // IS_REM
    assign div_ctrl_o = {div_c2, div_c1, div_c0};

    wire [9:0] f10 = {f7, f3};
    wire alu_c0 = (op==4 && f3==2) || (op==4 && f3==5 && f7==7'b0100000) ||
                  (op==5'b01100 && (f10==10'b10 || f10==10'b0100000101)); // IS_SIGNED
    wire alu_c1 = (op==4 && (f3==2 || f3==3)) || (op==5'b01100 &&
                  (f10==10'b100000000 || f10==10'b10 || f10==10'b11)); // IS_NEG
    wire alu_c2 = (op==4 && (f3==2 || f3==3)) ||
                  (op==5'b01100 && (f10==10'b10 || f10==10'b11)); // IS_LESS
    wire alu_c3 = (op==4 && f3==0) || 
                  (op==5'b01100 && (f10==10'b0 || f10==10'b100000000)); // IS_ADD
    wire alu_c4 = (op == 4 && f3 == 1 && f7 == 7'b0) || (op == 12 && f10 == 1);  // IS_SHIFT_LEFT
    wire alu_c5 = (op==4 && f3==5 && (f7==7'b0 || f7==7'b100000)) || (op==12 && 
                  (f10==10'b101 || f10==10'b0100000101)); // IS_SHIFT_RIGHT
    wire alu_c6 = (op==4 && (f3==4 || f3==6)) || (op==12 && (f10==4 || f10==6));//IS_XOR_OR
    wire alu_c7 = (op==4 && (f3==6 || f3==7)) || (op==12 && (f10==6 || f10==7));//IS_OR_AND
    wire alu_c8 = (op == 5'b01101 || op == 5'b00101);  // IS_SRC2
    assign alu_ctrl_o = {alu_c8, alu_c7, alu_c6, alu_c5, alu_c4, alu_c3, alu_c2, alu_c1, alu_c0};
endmodule
/******************************************************************************/
