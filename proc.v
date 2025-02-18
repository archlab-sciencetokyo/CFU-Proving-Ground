`resetall
`default_nettype none

`include "config.vh"

module cpu (
    input  wire                        clk_i            ,
    input  wire                        rst_i            ,
    output wire [`IBUS_ADDR_WIDTH-1:0] ibus_araddr_o    ,
    input  wire [`IBUS_DATA_WIDTH-1:0] ibus_rdata_i     ,
    output wire [`DBUS_ADDR_WIDTH-1:0] dbus_addr_o      ,
    output wire                        dbus_wvalid_o    ,
    output wire [`DBUS_DATA_WIDTH-1:0] dbus_wdata_o     ,
    output wire [`DBUS_STRB_WIDTH-1:0] dbus_wstrb_o     ,
    input  wire [`DBUS_DATA_WIDTH-1:0] dbus_rdata_i
);
    wire stall_i = 0;
    wire dbus_arvalid_o;
    localparam DBUS_OFFSET_WIDTH = $clog2(`XBYTES);
//==============================================================================
// Performance Counter
//------------------------------------------------------------------------------
    reg        mcountinhibit = 0;
    reg [63:0] mcycle    = 0;
    reg [63:0] minstret  = 0;
    reg [`PERF_CTRL_WIDTH-1:0] ExMa_perf_ctrl;
    reg perf_rst = 0;
    always @(posedge clk_i) begin
        if (rst_i) begin
            mcountinhibit <= 0;
            mcycle    <= 0;
            minstret  <= 0;
            ExMa_perf_ctrl <= 0;
        end else begin
            if (!stall && dbus_wvalid_o && (dbus_addr_o == 32'h20000000) && dbus_wdata_o[1:0] != 0)  begin
                mcountinhibit <= (dbus_wdata_o[1:0] == 1) ? 1 : 0;
            end
            if (!stall) begin
                ExMa_perf_ctrl[`PERF_CTRL_IS_CYCLE]    <= (dbus_addr_o == 32'h20000004);
                ExMa_perf_ctrl[`PERF_CTRL_IS_CYCLEH]   <= (dbus_addr_o == 32'h20000008);
                ExMa_perf_ctrl[`PERF_CTRL_IS_INSTRET] <= (dbus_addr_o == 32'h2000000C);
                ExMa_perf_ctrl[`PERF_CTRL_IS_INSTRETH] <= (dbus_addr_o == 32'h20000010);
            end
            if (dbus_wvalid_o && dbus_addr_o == 32'h20000000 && dbus_wdata_o[1:0] == 0) begin
                perf_rst <= 0;
                mcycle    <= 0;
                minstret  <= 0;
                mcountinhibit <= 0;
            end
            else begin
                if (mcountinhibit)  mcycle <= mcycle + 1;
                if (mcountinhibit && !stall && ExMa_v) minstret <= minstret + 1;
            end
        end
    end

//==============================================================================
// pipeline registers
//------------------------------------------------------------------------------
    // IF: Instruction Fetch
    reg             [`XLEN-1:0]    r_pc                     ;

    // ID: Instruction Decode
    reg                         IfId_v                      ;
    reg             [`XLEN-1:0] IfId_pc                     ;
    reg                  [31:0] IfId_ir                     ;
    reg                         IfId_br_pred_tkn            ;
    reg                   [1:0] IfId_pat_hist               ;
    reg                         IfId_load_muldiv_use        ;
    reg [`INSTR_TYPE_WIDTH-1:0] IfId_instr_type             ;
    reg                         IfId_rf_we                  ;
    reg                   [4:0] IfId_rd                     ;
    reg                   [4:0] IfId_rs1                    ;
    reg                   [4:0] IfId_rs2                    ;

    // EX: Execution
    reg                         IdEx_v                      ;
    reg             [`XLEN-1:0] IdEx_pc                     ;
    reg                  [31:0] IdEx_ir                     ;
    reg                         IdEx_br_pred_tkn            ;
    reg                   [1:0] IdEx_pat_hist               ;
    reg   [`ALU_CTRL_WIDTH-1:0] IdEx_alu_ctrl               ;
    reg   [`BRU_CTRL_WIDTH-1:0] IdEx_bru_ctrl               ;
    reg   [`LSU_CTRL_WIDTH-1:0] IdEx_lsu_ctrl               ;
    reg   [`MUL_CTRL_WIDTH-1:0] IdEx_mul_ctrl               ;
    reg   [`DIV_CTRL_WIDTH-1:0] IdEx_div_ctrl               ;
    reg   [`CFU_CTRL_WIDTH-1:0] IdEx_cfu_ctrl               ;
    reg                         IdEx_rs1_fwd_from_Ma_to_Ex  ;
    reg                         IdEx_rs2_fwd_from_Ma_to_Ex  ;
    reg                         IdEx_rs1_fwd_from_Wb_to_Ex  ;
    reg                         IdEx_rs2_fwd_from_Wb_to_Ex  ;
    reg             [`XLEN-1:0] IdEx_src1                   ;
    reg             [`XLEN-1:0] IdEx_src2                   ;
    reg             [`XLEN-1:0] IdEx_imm                    ;
    reg                         IdEx_rf_we                  ;
    reg                   [4:0] IdEx_rd                     ;

    // MA: Memory Access
    reg                         ExMa_v                      ;
    reg             [`XLEN-1:0] ExMa_pc                     ;
    reg                  [31:0] ExMa_ir                     ;
    reg                   [1:0] ExMa_pat_hist               ;
    reg                         ExMa_is_ctrl_tsfr           ;
    reg                         ExMa_br_tkn                 ;
    reg                         ExMa_br_misp_rslt1          ;
    reg                         ExMa_br_misp_rslt2          ;
    reg             [`XLEN-1:0] ExMa_br_tkn_pc              ;
    reg   [`LSU_CTRL_WIDTH-1:0] ExMa_lsu_ctrl               ;
    reg [DBUS_OFFSET_WIDTH-1:0] ExMa_dbus_offset            ;
    reg                         ExMa_rf_we                  ;
    reg                   [4:0] ExMa_rd                     ;
    reg             [`XLEN-1:0] ExMa_rslt                   ;

    // WB: Write Back
    reg                         MaWb_v                      ;
    reg             [`XLEN-1:0] MaWb_pc                     ;
    reg                  [31:0] MaWb_ir                     ;
    reg                         MaWb_rf_we                  ;
    reg                   [4:0] MaWb_rd                     ;
    reg             [`XLEN-1:0] MaWb_rslt                   ;

//==============================================================================
// pipeline control
//------------------------------------------------------------------------------
    reg rst; always @(posedge clk_i) rst <= rst_i;

    wire             Ma_br_tkn      = (ExMa_v && ExMa_br_tkn);
    wire             Ma_br_misp     = (ExMa_v && ExMa_is_ctrl_tsfr && ((Ma_br_tkn) ? ExMa_br_misp_rslt1 : ExMa_br_misp_rslt2));
    wire [`XLEN-1:0] Ma_br_true_pc  = (ExMa_br_tkn) ? ExMa_br_tkn_pc : ExMa_pc+'h4;

    wire Ma_mul_stall                                   ;
    wire Ma_div_stall                                   ;
    wire Ex_cfu_stall                                   ;
    wire stall = stall_i || Ma_mul_stall || Ma_div_stall;

    wire If_v = (Ma_br_misp                        ) ? 1'b0 : (IfId_load_muldiv_use) ? IfId_v : 1'b1  ;
    wire Id_v = (Ma_br_misp || IfId_load_muldiv_use) ? 1'b0 :                                   IfId_v;
    wire Ex_v = (Ma_br_misp                        ) ? 1'b0 :                                   IdEx_v;
    wire Ma_v =                                                                                 ExMa_v;

//==============================================================================
// BP: Branch Prediction
//------------------------------------------------------------------------------
    wire [`XLEN-1:0] bpu_access_pc  ;
    wire       [1:0] If_pat_hist    ;
    wire             If_br_pred_tkn ;
    wire [`XLEN-1:0] If_br_pred_pc  ;

    assign bpu_access_pc = (Ma_br_misp          ) ? Ma_br_true_pc:
                           (IfId_load_muldiv_use) ? r_pc         :
                           (If_br_pred_tkn      ) ? If_br_pred_pc:
                                                    r_pc+'h4     ;

    bimodal bimodal (
        .clk_i              (clk_i                  ), // input  wire
        .rst_i              (rst                    ), // input  wire
        .stall_i            (stall                  ), // input  wire
        .raddr_i            (bpu_access_pc          ), // input  wire [`XLEN-1:0]
        .pat_hist_o         (  If_pat_hist          ), // output reg        [1:0]
        .br_pred_tkn_o      (  If_br_pred_tkn       ), // output wire
        .br_pred_pc_o       (  If_br_pred_pc        ), // output reg  [`XLEN-1:0]
        .br_tkn_i           (  Ma_br_tkn            ), // input  wire
        .br_misp_i          (  Ma_br_misp           ), // input  wire
        .waddr_i            (ExMa_pc                ), // input  wire [`XLEN-1:0]
        .pat_hist_i         (ExMa_pat_hist          ), // input  wire       [1:0]
        .br_tkn_pc_i        (ExMa_br_tkn_pc         )  // input  wire [`XLEN-1:0]
    );

    wire [`XLEN-1:0] pc = (rst                 ) ? `RESET_VECTOR:
                          (stall               ) ? r_pc         :
                          (Ma_br_misp          ) ? Ma_br_true_pc:
                          (IfId_load_muldiv_use) ? r_pc         :
                          (If_br_pred_tkn      ) ? If_br_pred_pc:
                                                   r_pc+'h4     ;

    always @(posedge clk_i) r_pc <= pc;

    assign ibus_araddr_o = pc;

//==============================================================================
// IF: Instruction Fetch
//------------------------------------------------------------------------------
    wire                  [31:0] If_ir          = ibus_rdata_i  ;
    wire [`INSTR_TYPE_WIDTH-1:0] If_instr_type                  ;
    wire                         If_rf_we                       ;
    wire                   [4:0] If_rd                          ;
    wire                   [4:0] If_rs1                         ;
    wire                   [4:0] If_rs2                         ;

    pre_decoder pre_decoder (
        .ir_i               (  If_ir                ), // input  wire                  [31:0]
        .instr_type_o       (  If_instr_type        ), // output wire [`INSTR_TYPE_WIDTH-1:0]
        .rf_we_o            (  If_rf_we             ), // output wire
        .rd_o               (  If_rd                ), // output wire                   [4:0]
        .rs1_o              (  If_rs1               ), // output wire                   [4:0]
        .rs2_o              (  If_rs2               )  // output wire                   [4:0]
    );

    wire If_load_muldiv_use = IfId_v && !Ma_br_misp && !IfId_load_muldiv_use
                            && (Id_lsu_ctrl[`LSU_CTRL_IS_LOAD] || Id_mul_ctrl[`MUL_CTRL_IS_MUL] || Id_div_ctrl[`DIV_CTRL_IS_DIV])
                            && IfId_rf_we && ((IfId_rd==If_rs1) || (IfId_rd==If_rs2));

    always @(posedge clk_i) begin
        if (rst) begin
            IfId_v                      <= 1'b0                         ;
            IfId_pc                     <= 'h0                          ;
            IfId_ir                     <= `NOP                         ;
        end else if (!stall) begin
            IfId_v                      <=   If_v                       ;
            IfId_load_muldiv_use        <=   If_load_muldiv_use         ;
            if (!IfId_load_muldiv_use) begin
                IfId_pc                     <=    r_pc                      ;
                IfId_ir                     <=   If_ir                      ;
                IfId_br_pred_tkn            <=   If_br_pred_tkn             ;
                IfId_pat_hist               <=   If_pat_hist                ;
                IfId_instr_type             <=   If_instr_type              ;
                IfId_rf_we                  <=   If_rf_we                   ;
                IfId_rd                     <=   If_rd                      ;
                IfId_rs1                    <=   If_rs1                     ;
                IfId_rs2                    <=   If_rs2                     ;
            end
        end
    end

//==============================================================================
// ID: Instruction Decode
//------------------------------------------------------------------------------
    // instruction decoder
    wire [`SRC2_CTRL_WIDTH-1:0] Id_src2_ctrl;
    wire  [`ALU_CTRL_WIDTH-1:0] Id_alu_ctrl ;
    wire  [`BRU_CTRL_WIDTH-1:0] Id_bru_ctrl ;
    wire  [`LSU_CTRL_WIDTH-1:0] Id_lsu_ctrl ;
    wire  [`MUL_CTRL_WIDTH-1:0] Id_mul_ctrl ;
    wire  [`DIV_CTRL_WIDTH-1:0] Id_div_ctrl ;
    wire  [`CFU_CTRL_WIDTH-1:0] Id_cfu_ctrl ;
    decoder decoder (
        .ir_i               (IfId_ir                ), // input  wire                 [31:0]
        .src2_ctrl_o        (  Id_src2_ctrl         ), // output wire [`SRC2_CTRL_WIDTH-1:0]
        .alu_ctrl_o         (  Id_alu_ctrl          ), // output wire  [`ALU_CTRL_WIDTH-1:0]
        .bru_ctrl_o         (  Id_bru_ctrl          ), // output wire  [`BRU_CTRL_WIDTH-1:0]
        .lsu_ctrl_o         (  Id_lsu_ctrl          ), // output wire  [`LSU_CTRL_WIDTH-1:0]
        .mul_ctrl_o         (  Id_mul_ctrl          ), // output wire  [`MUL_CTRL_WIDTH-1:0]
        .div_ctrl_o         (  Id_div_ctrl          ), // output wire  [`DIV_CTRL_WIDTH-1:0]
        .cfu_ctrl_o         (  Id_cfu_ctrl          )  // output wire  [`CFU_CTRL_WIDTH-1:0]
    );

    // immediate value generator
    wire [`XLEN-1:0] Id_imm ;
    imm_gen imm_gen (
        .ir_i               (IfId_ir                ), // input  wire                  [31:0]
        .instr_type_i       (IfId_instr_type        ), // input  wire [`INSTR_TYPE_WIDTH-1;0]
        .imm_o              (  Id_imm               )  // output wire             [`XLEN-1:0]
    );

    // register file
    wire [`XLEN-1:0] Id_xrs1    ;
    wire [`XLEN-1:0] Id_xrs2    ;
    wire             Wb_rf_we   = MaWb_v && MaWb_rf_we  ;
    regfile xreg (
        .clk_i              (clk_i                  ), // input  wire
        .stall_i            (stall                  ), // input  wire
        .rs1_i              (IfId_rs1               ), // input  wire       [4:0]
        .rs2_i              (IfId_rs2               ), // input  wire       [4:0]
        .xrs1_o             (  Id_xrs1              ), // output wire [`XLEN-1:0]
        .xrs2_o             (  Id_xrs2              ), // output wire [`XLEN-1:0]
        .we_i               (  Wb_rf_we             ), // input  wire
        .rd_i               (MaWb_rd                ), // input  wire       [4:0]
        .wdata_i            (MaWb_rslt              )  // input  wire [`XLEN-1:0]
    );

    // data forwarding
    wire Id_rs1_fwd_from_Ma_to_Ex = IdEx_v && IdEx_rf_we && (IdEx_rd==IfId_rs1);
    wire Id_rs2_fwd_from_Ma_to_Ex = IdEx_v && IdEx_rf_we && (IdEx_rd==IfId_rs2);
    wire Id_rs1_fwd_from_Wb_to_Ex = ExMa_v && ExMa_rf_we && (ExMa_rd==IfId_rs1);
    wire Id_rs2_fwd_from_Wb_to_Ex = ExMa_v && ExMa_rf_we && (ExMa_rd==IfId_rs2);
    wire Id_rs1_fwd_from_Wb_to_Id = MaWb_v && MaWb_rf_we && (MaWb_rd==IfId_rs1);
    wire Id_rs2_fwd_from_Wb_to_Id = MaWb_v && MaWb_rf_we && (MaWb_rd==IfId_rs2);

    // source select
    wire [`XLEN-1:0] Id_src1 = (Id_rs1_fwd_from_Wb_to_Id          ) ?          MaWb_rslt :
                                                                                 Id_xrs1 ;
    wire [`XLEN-1:0] Id_src2 = (Id_src2_ctrl[`SRC2_CTRL_USE_AUIPC]) ?  IfId_pc+  Id_imm  :
                               (Id_src2_ctrl[`SRC2_CTRL_USE_IMM]  ) ?            Id_imm  :
                               (Id_rs2_fwd_from_Wb_to_Id          ) ?          MaWb_rslt :
                                                                                 Id_xrs2 ;

    always @(posedge clk_i) begin
        if (rst) begin
            IdEx_v                      <= 1'b0                         ;
            IdEx_pc                     <= 'h0                          ;
            IdEx_ir                     <= `NOP                         ;
        end else if (!stall) begin
            IdEx_v                      <=   Id_v                       ;
            IdEx_pc                     <= IfId_pc                      ;
            IdEx_ir                     <= IfId_ir                      ;
            IdEx_br_pred_tkn            <= IfId_br_pred_tkn             ;
            IdEx_pat_hist               <= IfId_pat_hist                ;
            IdEx_alu_ctrl               <=   Id_alu_ctrl                ;
            IdEx_bru_ctrl               <=   Id_bru_ctrl                ;
            IdEx_lsu_ctrl               <=   Id_lsu_ctrl                ;
            IdEx_mul_ctrl               <=   Id_mul_ctrl                ;
            IdEx_div_ctrl               <=   Id_div_ctrl                ;
            IdEx_cfu_ctrl               <=   Id_cfu_ctrl                ;
            IdEx_rs1_fwd_from_Ma_to_Ex  <=   Id_rs1_fwd_from_Ma_to_Ex   ;
            IdEx_rs2_fwd_from_Ma_to_Ex  <=   Id_rs2_fwd_from_Ma_to_Ex   ;
            IdEx_rs1_fwd_from_Wb_to_Ex  <=   Id_rs1_fwd_from_Wb_to_Ex   ;
            IdEx_rs2_fwd_from_Wb_to_Ex  <=   Id_rs2_fwd_from_Wb_to_Ex   ;
            IdEx_src1                   <=   Id_src1                    ;
            IdEx_src2                   <=   Id_src2                    ;
            IdEx_imm                    <=   Id_imm                     ;
            IdEx_rf_we                  <= IfId_rf_we                   ;
            IdEx_rd                     <= IfId_rd                      ;
        end
    end

//==============================================================================
// EX: Execution
//------------------------------------------------------------------------------
    wire Ex_valid = IdEx_v && !Ma_br_misp && !Ma_mul_stall && !Ma_div_stall;

    // data forwarding
    wire [`XLEN-1:0] Ex_src1 = (IdEx_rs1_fwd_from_Ma_to_Ex) ? ExMa_rslt : (IdEx_rs1_fwd_from_Wb_to_Ex) ? MaWb_rslt : IdEx_src1;
    wire [`XLEN-1:0] Ex_src2 = (IdEx_rs2_fwd_from_Ma_to_Ex) ? ExMa_rslt : (IdEx_rs2_fwd_from_Wb_to_Ex) ? MaWb_rslt : IdEx_src2;

    // arithmetic logic unit
    wire [`XLEN-1:0] Ex_alu_rslt;
    alu alu (
        .alu_ctrl_i         (IdEx_alu_ctrl          ), // input  wire [`ALU_CTRL_WIDTH-1:0]
        .src1_i             (  Ex_src1              ), // input  wire           [`XLEN-1:0]
        .src2_i             (  Ex_src2              ), // input  wire           [`XLEN-1:0]
        .rslt_o             (  Ex_alu_rslt          )  // output wire           [`XLEN-1:0]
    );

    // branch resolution unit
    wire             Ex_is_ctrl_tsfr    ;
    wire             Ex_br_tkn          ;
    wire             Ex_br_misp_rslt1   ;
    wire             Ex_br_misp_rslt2   ;
    wire [`XLEN-1:0] Ex_br_tkn_pc       ;
    wire [`XLEN-1:0] Ex_bru_rslt        ;
    bru bru (
        .bru_ctrl_i         (IdEx_bru_ctrl          ), // input  wire [`BRU_CTRL_WIDTH-1:0]
        .src1_i             (  Ex_src1              ), // input  wire           [`XLEN-1:0]
        .src2_i             (  Ex_src2              ), // input  wire           [`XLEN-1:0]
        .pc_i               (IdEx_pc                ), // input  wire           [`XLEN-1:0]
        .imm_i              (IdEx_imm               ), // input  wire           [`XLEN-1:0]
        .npc_i              (IfId_pc                ), // input  wire           [`XLEN-1:0]
        .br_pred_tkn_i      (IdEx_br_pred_tkn       ), // input  wire
        .is_ctrl_tsfr_o     (  Ex_is_ctrl_tsfr      ), // output wire
        .br_tkn_o           (  Ex_br_tkn            ), // output wire
        .br_misp_rslt1_o    (  Ex_br_misp_rslt1     ), // output wire
        .br_misp_rslt2_o    (  Ex_br_misp_rslt2     ), // output wire
        .br_tkn_pc_o        (  Ex_br_tkn_pc         ), // output wire           [`XLEN-1:0]
        .rslt_o             (  Ex_bru_rslt          )  // output wire           [`XLEN-1:0]
    );

    wire [`XLEN-1:0] Ex_rslt = Ex_alu_rslt | Ex_bru_rslt | Ex_cfu_rslt;

    // store unit
    wire             [`XLEN-1:0] dbus_addr      ;
    wire [DBUS_OFFSET_WIDTH-1:0] dbus_offset    ;
    wire                         dbus_arvalid   ;
    wire             [`XLEN-1:0] dbus_rdata     ;
    wire                         dbus_wvalid    ;
    wire             [`XLEN-1:0] dbus_wdata     ;
    wire           [`XBYTES-1:0] dbus_wstrb     ;
    store_unit store_unit (
        .valid_i            (  Ex_valid             ), // input  wire
        .lsu_ctrl_i         (IdEx_lsu_ctrl          ), // input  wire [`LSU_CTRL_WIDTH-1:0]
        .src1_i             (  Ex_src1              ), // input  wire           [`XLEN-1:0]
        .src2_i             (  Ex_src2              ), // input  wire           [`XLEN-1:0]
        .imm_i              (IdEx_imm               ), // input  wire           [`XLEN-1:0]
        .dbus_addr_o        (dbus_addr              ), // output wire           [`XLEN-1:0]
        .dbus_offset_o      (dbus_offset            ), // output wire    [OFFSET_WIDTH-1:0]
        .dbus_arvalid_o     (dbus_arvalid           ), // output wire
        .dbus_wvalid_o      (dbus_wvalid            ), // output wire
        .dbus_wdata_o       (dbus_wdata             ), // output wire           [`XLEN-1:0]
        .dbus_wstrb_o       (dbus_wstrb             )  // output wire         [`XBYTES-1:0]
    );

    assign dbus_addr_o      = dbus_addr     ;
    assign dbus_wvalid_o    = dbus_wvalid   ;
    assign dbus_wdata_o     = dbus_wdata    ;
    assign dbus_wstrb_o     = dbus_wstrb    ;
    assign dbus_arvalid_o   = dbus_arvalid  ;

    always @(posedge clk_i) begin
        if (rst) begin
            ExMa_v                      <= 1'b0                         ;
            ExMa_pc                     <= 'h0                          ;
            ExMa_ir                     <= `NOP                         ;
        end else if (!stall) begin
            ExMa_v                      <=   Ex_v                       ;
            ExMa_pc                     <= IdEx_pc                      ;
            ExMa_ir                     <= IdEx_ir                      ;
            ExMa_pat_hist               <= IdEx_pat_hist                ;
            ExMa_is_ctrl_tsfr           <=   Ex_is_ctrl_tsfr            ;
            ExMa_br_tkn                 <=   Ex_br_tkn                  ;
            ExMa_br_misp_rslt1          <=   Ex_br_misp_rslt1           ;
            ExMa_br_misp_rslt2          <=   Ex_br_misp_rslt2           ;
            ExMa_br_tkn_pc              <=   Ex_br_tkn_pc               ;
            ExMa_lsu_ctrl               <= IdEx_lsu_ctrl                ;
            ExMa_dbus_offset            <= dbus_offset                  ;
            ExMa_rf_we                  <= IdEx_rf_we                   ;
            ExMa_rd                     <= IdEx_rd                      ;
            ExMa_rslt                   <=   Ex_rslt                    ;
        end
    end

    // multiplier unit
    wire [`XLEN-1:0] Ma_mul_rslt;
    multiplier multiplier (
        .clk_i              (clk_i                  ), // input  wire
        .rst_i              (rst                    ), // input  wire
        .stall_i            (stall_i || Ma_div_stall), // input  wire
        .valid_i            (  Ex_valid             ), // input  wire
        .mul_ctrl_i         (IdEx_mul_ctrl          ), // input  wire [`MUL_CTRL_WIDTH-1:0]
        .src1_i             (  Ex_src1              ), // input  wire           [`XLEN-1:0]
        .src2_i             (  Ex_src2              ), // input  wire           [`XLEN-1:0]
        .stall_o            (  Ma_mul_stall         ), // output wire
        .rslt_o             (  Ma_mul_rslt          )  // output wire           [`XLEN-1:0]
    );

    // divider unit
    wire [`XLEN-1:0] Ma_div_rslt;
    divider divider (
        .clk_i              (clk_i                  ), // input  wire
        .rst_i              (rst                    ), // input  wire
        .stall_i            (stall_i || Ma_mul_stall), // input  wire
        .valid_i            (  Ex_valid             ), // input  wire
        .div_ctrl_i         (IdEx_div_ctrl          ), // input  wire [`DIV_CTRL_WIDTH-1:0]
        .src1_i             (  Ex_src1              ), // input  wire           [`XLEN-1:0]
        .src2_i             (  Ex_src2              ), // input  wire           [`XLEN-1:0]
        .stall_o            (  Ma_div_stall         ), // output wire
        .rslt_o             (  Ma_div_rslt          )  // output wire           [`XLEN-1:0]
    );

    wire [`XLEN-1:0] Ex_cfu_rslt;
    cfu cfu (
        .clk_i              (clk_i                  ), // input  wire
        .rst_i              (rst                    ), // input  wire
        .stall_i            (stall_i                ), // input  wire
        .valid_i            (  Ex_valid             ), // input  wire
        .cfu_ctrl_i         (IdEx_cfu_ctrl          ), // input  wire [`CFU_CTRL_WIDTH-1:0]
        .src1_i             (  Ex_src1              ), // input  wire           [`XLEN-1:0]
        .src2_i             (  Ex_src2              ), // input  wire           [`XLEN-1:0]
        .stall_o            (  Ex_cfu_stall         ), // output wire
        .rslt_o             (  Ex_cfu_rslt          )  // output wire           [`XLEN-1:0]
    );

//==============================================================================
// MA: Memory Access
//------------------------------------------------------------------------------
    // load unit
    wire [`XLEN-1:0] Ma_load_rslt;
    load_unit load_unit (
        .lsu_ctrl_i         (ExMa_lsu_ctrl          ), // input  wire  [`LSU_CTRL_WIDTH-1:0]
        .dbus_offset_i      (ExMa_dbus_offset       ), // input  wire     [OFFSET_WIDTH-1:0]
        .dbus_rdata_i       (dbus_rdata_i           ), // input  wire            [`XLEN-1:0]
        .perf_ctrl_i        (ExMa_perf_ctrl         ), // input  wire [`PERF_CTRL_WIDTH-1:0]
        .mcycle_i           (mcycle                 ), // input  wire                 [31:0]
        .minstret_i         (minstret               ), // input  wire                 [31:0]
        .rslt_o             (  Ma_load_rslt         )  // output wire            [`XLEN-1:0]
    );

    wire [`XLEN-1:0] Ma_rslt = ExMa_rslt | Ma_mul_rslt | Ma_div_rslt | Ma_load_rslt;

    always @(posedge clk_i) begin
        if (rst) begin
            MaWb_v                      <= 1'b0                         ;
            MaWb_pc                     <= 'h0                          ;
            MaWb_ir                     <= `NOP                         ;
        end else if (!stall) begin
            MaWb_v                      <=   Ma_v                       ;
            MaWb_pc                     <= ExMa_pc                      ;
            MaWb_ir                     <= ExMa_ir                      ;
            MaWb_rf_we                  <= ExMa_rf_we                   ;
            MaWb_rd                     <= ExMa_rd                      ;
            MaWb_rslt                   <=   Ma_rslt                    ;
        end
    end

//==============================================================================
// WB: Write Back
//------------------------------------------------------------------------------

endmodule

module bimodal (
    input  wire             clk_i               ,
    input  wire             rst_i               ,
    input  wire             stall_i             ,
    input  wire [`XLEN-1:0] raddr_i             ,
    output reg        [1:0] pat_hist_o          ,
    output wire             br_pred_tkn_o       ,
    output reg  [`XLEN-1:0] br_pred_pc_o        ,
    input  wire             br_tkn_i            ,
    input  wire             br_misp_i           ,
    input  wire [`XLEN-1:0] waddr_i             ,
    input  wire       [1:0] pat_hist_i          ,
    input  wire [`XLEN-1:0] br_tkn_pc_i
);

    integer i;
    localparam OFFSET_WIDTH = $clog2(`XBYTES)   ;

    // pattern history table
    reg [1:0] pht [0:`PHT_ENTRY-1]; initial for (i=0; i<`PHT_ENTRY; i=i+1) pht[i] = 2'b01;

    localparam VALID_PHT_INDEX_WIDTH            = $clog2(`PHT_ENTRY);
    wire [VALID_PHT_INDEX_WIDTH-1:0] pht_ridx   = raddr_i[VALID_PHT_INDEX_WIDTH+OFFSET_WIDTH-1:OFFSET_WIDTH];
    wire [VALID_PHT_INDEX_WIDTH-1:0] pht_widx   = waddr_i[VALID_PHT_INDEX_WIDTH+OFFSET_WIDTH-1:OFFSET_WIDTH];

    wire [1:0] wr_pat_hist = (br_tkn_i) ? pat_hist_i+(pat_hist_i<2'd3) : pat_hist_i-(pat_hist_i>2'd0);

    always @(posedge clk_i) begin
        if (!stall_i) begin
            pat_hist_o  <= pht[pht_ridx]    ;
            if (br_misp_i) begin
                pht[pht_widx]   <= wr_pat_hist  ;
            end
        end
    end

    // branch target buffer
    (* ram_style = "block" *) reg [`XLEN:0] btb [0:`BTB_ENTRY-1]; initial for (i=0; i<`BTB_ENTRY; i=i+1) btb[i]='h0;

    localparam VALID_BTB_INDEX_WIDTH    = $clog2(`BTB_ENTRY);
    wire [VALID_BTB_INDEX_WIDTH-1:0] btb_ridx   = raddr_i[VALID_BTB_INDEX_WIDTH+OFFSET_WIDTH-1:OFFSET_WIDTH];
    wire [VALID_BTB_INDEX_WIDTH-1:0] btb_widx   = waddr_i[VALID_BTB_INDEX_WIDTH+OFFSET_WIDTH-1:OFFSET_WIDTH];

    reg br_tgt_v;
    always @(posedge clk_i) begin
        if (!stall_i) begin
            {br_tgt_v, br_pred_pc_o} <= btb[btb_ridx];
            if (br_tkn_i) begin
                btb[btb_widx] <= {1'b1, br_tkn_pc_i};
            end
        end
    end

    // branch prediction
    assign br_pred_tkn_o = (br_tgt_v && pat_hist_o[1]);

endmodule

module pre_decoder (
    input  wire                  [31:0] ir_i            ,
    output wire [`INSTR_TYPE_WIDTH-1:0] instr_type_o    ,
    output wire                         rf_we_o         ,
    output wire                   [4:0] rd_o            ,
    output wire                   [4:0] rs1_o           ,
    output wire                   [4:0] rs2_o
);

    wire                  [31:0] ir         = ir_i      ;
    wire                   [4:0] opcode_6_2 = ir[6:2]   ;

    reg  [`INSTR_TYPE_WIDTH-1:0] instr_type             ;
    reg                    [4:0] rd                     ;
    reg                    [4:0] rs1                    ;
    reg                    [4:0] rs2                    ;

    assign instr_type_o = instr_type    ;
    assign rf_we_o      = |rd           ;
    assign rd_o         = rd            ;
    assign rs1_o        = rs1           ;
    assign rs2_o        = rs2           ;

    always @(*) begin
        case (opcode_6_2)
            5'b01101: instr_type    = `U_TYPE   ; // LUI
            5'b00101: instr_type    = `U_TYPE   ; // AUIPC
            5'b11011: instr_type    = `J_TYPE   ; // JAL
            5'b11001: instr_type    = `I_TYPE   ; // JALR
            5'b11000: instr_type    = `B_TYPE   ; // BRANCH
            5'b00000: instr_type    = `I_TYPE   ; // LOAD
            5'b01000: instr_type    = `S_TYPE   ; // STORE
            5'b00100: instr_type    = `I_TYPE   ; // OP-IMM
            5'b01100: instr_type    = `R_TYPE   ; // OP
            5'b00010: instr_type    = `R_TYPE   ; // CUSTOM-0
            default : instr_type    = `NONE_TYPE;
        endcase
        case (instr_type)
            `S_TYPE, `B_TYPE            : rd    = 5'd0      ;
            default                     : rd    = ir[11:7]  ;
        endcase
        case (instr_type)
            `U_TYPE, `J_TYPE            : rs1   = 5'd0      ;
            default                     : rs1   = ir[19:15] ;
        endcase
        case (instr_type)
            `I_TYPE, `U_TYPE, `J_TYPE   : rs2   = 5'd0      ;
            default                     : rs2   = ir[24:20] ;
        endcase
    end

endmodule

module decoder (
    input  wire                 [31:0] ir_i         ,
    output wire [`SRC2_CTRL_WIDTH-1:0] src2_ctrl_o  ,
    output wire  [`ALU_CTRL_WIDTH-1:0] alu_ctrl_o   ,
    output wire  [`BRU_CTRL_WIDTH-1:0] bru_ctrl_o   ,
    output wire  [`LSU_CTRL_WIDTH-1:0] lsu_ctrl_o   ,
    output wire  [`MUL_CTRL_WIDTH-1:0] mul_ctrl_o   ,
    output wire  [`DIV_CTRL_WIDTH-1:0] div_ctrl_o   ,
    output wire  [`CFU_CTRL_WIDTH-1:0] cfu_ctrl_o
);

    wire                 [31:0] ir          = ir_i      ;
    wire                  [6:0] opcode      = ir[ 6: 0] ;
    wire                  [2:0] funct3      = ir[14:12] ;
    wire                  [6:0] funct7      = ir[31:25] ;

    reg  [`SRC2_CTRL_WIDTH-1:0] src2_ctrl               ;
    reg   [`ALU_CTRL_WIDTH-1:0] alu_ctrl                ;
    reg   [`BRU_CTRL_WIDTH-1:0] bru_ctrl                ;
    reg   [`LSU_CTRL_WIDTH-1:0] lsu_ctrl                ;
    reg   [`MUL_CTRL_WIDTH-1:0] mul_ctrl                ;
    reg   [`DIV_CTRL_WIDTH-1:0] div_ctrl                ;
    reg   [`CFU_CTRL_WIDTH-1:0] cfu_ctrl                ;

    assign src2_ctrl_o  = src2_ctrl ;
    assign alu_ctrl_o   = alu_ctrl  ;
    assign bru_ctrl_o   = bru_ctrl  ;
    assign lsu_ctrl_o   = lsu_ctrl  ;
    assign mul_ctrl_o   = mul_ctrl  ;
    assign div_ctrl_o   = div_ctrl  ;
    assign cfu_ctrl_o   = cfu_ctrl  ;

    always @(*) begin
        src2_ctrl   = 'h0       ;
        alu_ctrl    = 'h0       ;
        bru_ctrl    = 'h0       ;
        lsu_ctrl    = 'h0       ;
        mul_ctrl    = 'h0       ;
        div_ctrl    = 'h0       ;
        cfu_ctrl    = 'h0       ;
        // control signal
        case (opcode[1:0])
            2'b00: ;
            2'b01: ;
            2'b10: ;
            2'b11: begin
                case (opcode[6:2])
                    5'b01101: begin // LUI
                        src2_ctrl[`SRC2_CTRL_USE_IMM]       = 1'b1      ;
                        alu_ctrl[`ALU_CTRL_IS_SRC2]         = 1'b1      ;
                    end
                    5'b00101: begin // AUIPC
                        src2_ctrl[`SRC2_CTRL_USE_AUIPC]     = 1'b1      ;
                        alu_ctrl[`ALU_CTRL_IS_SRC2]         = 1'b1      ;
                    end
                    5'b11011: begin // JAL
                        bru_ctrl[`BRU_CTRL_IS_CTRL_TSFR]    = 1'b1      ;
                        bru_ctrl[`BRU_CTRL_IS_JAL_JALR]     = 1'b1      ;
                    end
                    5'b11001: begin // JALR
                        bru_ctrl[`BRU_CTRL_IS_CTRL_TSFR]    = 1'b1      ;
                        bru_ctrl[`BRU_CTRL_IS_JAL_JALR]     = 1'b1      ;
                        bru_ctrl[`BRU_CTRL_IS_JALR]         = 1'b1      ;
                    end
                    5'b11000: begin // BRANCH
                        bru_ctrl[`BRU_CTRL_IS_CTRL_TSFR]    = 1'b1      ;
                        case (funct3)
                            3'b000 : begin                                       bru_ctrl[`BRU_CTRL_IS_BEQ] = 1'b1; end // beq
                            3'b001 : begin                                       bru_ctrl[`BRU_CTRL_IS_BNE] = 1'b1; end // bne
                            3'b100 : begin bru_ctrl[`BRU_CTRL_IS_SIGNED] = 1'b1; bru_ctrl[`BRU_CTRL_IS_BLT] = 1'b1; end // blt
                            3'b101 : begin bru_ctrl[`BRU_CTRL_IS_SIGNED] = 1'b1; bru_ctrl[`BRU_CTRL_IS_BGE] = 1'b1; end // bge
                            3'b110 : begin                                       bru_ctrl[`BRU_CTRL_IS_BLT] = 1'b1; end // bltu
                            3'b111 : begin                                       bru_ctrl[`BRU_CTRL_IS_BGE] = 1'b1; end // bgeu
                            default: ;
                        endcase
                    end
                    5'b00000: begin // LOAD
                        lsu_ctrl[`LSU_CTRL_IS_LOAD]         = 1'b1      ;
                        case (funct3)
                            3'b000 : begin lsu_ctrl[`LSU_CTRL_IS_SIGNED] = 1'b1; lsu_ctrl[`LSU_CTRL_IS_BYTE]     = 1'b1; end // lb
                            3'b001 : begin lsu_ctrl[`LSU_CTRL_IS_SIGNED] = 1'b1; lsu_ctrl[`LSU_CTRL_IS_HALFWORD] = 1'b1; end // lh
                            3'b010 : begin lsu_ctrl[`LSU_CTRL_IS_SIGNED] = 1'b1; lsu_ctrl[`LSU_CTRL_IS_WORD]     = 1'b1; end // lw
                            3'b100 : begin                                       lsu_ctrl[`LSU_CTRL_IS_BYTE]     = 1'b1; end // lbu
                            3'b101 : begin                                       lsu_ctrl[`LSU_CTRL_IS_HALFWORD] = 1'b1; end // lhu
                            default: ;
                        endcase
                    end
                    5'b01000: begin // STORE
                        lsu_ctrl[`LSU_CTRL_IS_STORE]        = 1'b1      ;
                        case (funct3)
                            3'b000 : lsu_ctrl[`LSU_CTRL_IS_BYTE]     = 1'b1; // sb
                            3'b001 : lsu_ctrl[`LSU_CTRL_IS_HALFWORD] = 1'b1; // sh
                            3'b010 : lsu_ctrl[`LSU_CTRL_IS_WORD]     = 1'b1; // sw
                            default: ;
                        endcase
                    end
                    5'b00100: begin // OP-IMM
                        src2_ctrl[`SRC2_CTRL_USE_IMM]       = 1'b1      ;
                        case (funct3)
                            3'b000 : begin                                                                             alu_ctrl[`ALU_CTRL_IS_ADD]         = 1'b1; end // addi
                            3'b010 : begin alu_ctrl[`ALU_CTRL_IS_SIGNED] = 1'b1; alu_ctrl[`ALU_CTRL_IS_NEG]    = 1'b1; alu_ctrl[`ALU_CTRL_IS_LESS]        = 1'b1; end // slti
                            3'b011 : begin                                       alu_ctrl[`ALU_CTRL_IS_NEG]    = 1'b1; alu_ctrl[`ALU_CTRL_IS_LESS]        = 1'b1; end // sltui
                            3'b100 : begin                                       alu_ctrl[`ALU_CTRL_IS_XOR_OR] = 1'b1;                                            end // xori
                            3'b110 : begin                                       alu_ctrl[`ALU_CTRL_IS_XOR_OR] = 1'b1; alu_ctrl[`ALU_CTRL_IS_OR_AND]      = 1'b1; end // ori
                            3'b111 : begin                                                                             alu_ctrl[`ALU_CTRL_IS_OR_AND]      = 1'b1; end // andi
                            3'b001 : begin // slli
                                if (funct7==7'b0000000) begin alu_ctrl[`ALU_CTRL_IS_SHIFT_LEFT]  = 1'b1; end // slli
                                else ;
                            end
                            3'b101 : begin // srli/srai
                                case (funct7)
                                    7'b0000000: begin                                       alu_ctrl[`ALU_CTRL_IS_SHIFT_RIGHT] = 1'b1; end // srli
                                    7'b0100000: begin alu_ctrl[`ALU_CTRL_IS_SIGNED] = 1'b1; alu_ctrl[`ALU_CTRL_IS_SHIFT_RIGHT] = 1'b1; end // srai
                                    default: ;
                                endcase
                                
                            end
                            default: ;
                        endcase
                    end
                    5'b00010: cfu_ctrl = {funct7, funct3}; // CFU
                    5'b01100: begin // OP
                        case ({funct7, funct3})
                            10'b0000000000 : begin                                                                             alu_ctrl[`ALU_CTRL_IS_ADD]         = 1'b1; end // add
                            10'b0100000000 : begin                                       alu_ctrl[`ALU_CTRL_IS_NEG]    = 1'b1; alu_ctrl[`ALU_CTRL_IS_ADD]         = 1'b1; end // sub
                            10'b0000000001 : begin                                                                             alu_ctrl[`ALU_CTRL_IS_SHIFT_LEFT]  = 1'b1; end // sll
                            10'b0000000010 : begin alu_ctrl[`ALU_CTRL_IS_SIGNED] = 1'b1; alu_ctrl[`ALU_CTRL_IS_NEG]    = 1'b1; alu_ctrl[`ALU_CTRL_IS_LESS]        = 1'b1; end // slt
                            10'b0000000011 : begin                                       alu_ctrl[`ALU_CTRL_IS_NEG]    = 1'b1; alu_ctrl[`ALU_CTRL_IS_LESS]        = 1'b1; end // sltu
                            10'b0000000100 : begin                                       alu_ctrl[`ALU_CTRL_IS_XOR_OR] = 1'b1;                                            end // xor
                            10'b0000000101 : begin                                                                             alu_ctrl[`ALU_CTRL_IS_SHIFT_RIGHT] = 1'b1; end // srl
                            10'b0100000101 : begin alu_ctrl[`ALU_CTRL_IS_SIGNED] = 1'b1;                                       alu_ctrl[`ALU_CTRL_IS_SHIFT_RIGHT] = 1'b1; end // sra
                            10'b0000000110 : begin                                       alu_ctrl[`ALU_CTRL_IS_XOR_OR] = 1'b1; alu_ctrl[`ALU_CTRL_IS_OR_AND]      = 1'b1; end // or
                            10'b0000000111 : begin                                                                             alu_ctrl[`ALU_CTRL_IS_OR_AND]      = 1'b1; end // and
                            10'b0000001000 : begin mul_ctrl[`MUL_CTRL_IS_MUL] = 1'b1;                                                                                                                           end // mul
                            10'b0000001001 : begin mul_ctrl[`MUL_CTRL_IS_MUL] = 1'b1; mul_ctrl[`MUL_CTRL_IS_SRC1_SIGNED] = 1'b1; mul_ctrl[`MUL_CTRL_IS_SRC2_SIGNED] = 1'b1; mul_ctrl[`MUL_CTRL_IS_HIGH] = 1'b1; end // mulh
                            10'b0000001010 : begin mul_ctrl[`MUL_CTRL_IS_MUL] = 1'b1; mul_ctrl[`MUL_CTRL_IS_SRC1_SIGNED] = 1'b1;                                            mul_ctrl[`MUL_CTRL_IS_HIGH] = 1'b1; end // mulhsu
                            10'b0000001011 : begin mul_ctrl[`MUL_CTRL_IS_MUL] = 1'b1;                                                                                       mul_ctrl[`MUL_CTRL_IS_HIGH] = 1'b1; end // mulhu
                            10'b0000001100 : begin div_ctrl[`DIV_CTRL_IS_DIV] = 1'b1; div_ctrl[`DIV_CTRL_IS_SIGNED] = 1'b1;                                    end // div
                            10'b0000001101 : begin div_ctrl[`DIV_CTRL_IS_DIV] = 1'b1;                                                                          end // divu
                            10'b0000001110 : begin div_ctrl[`DIV_CTRL_IS_DIV] = 1'b1; div_ctrl[`DIV_CTRL_IS_SIGNED] = 1'b1; div_ctrl[`DIV_CTRL_IS_REM] = 1'b1; end // rem
                            10'b0000001111 : begin div_ctrl[`DIV_CTRL_IS_DIV] = 1'b1;                                       div_ctrl[`DIV_CTRL_IS_REM] = 1'b1; end // remu
                            default: ;
                        endcase
                    end
                    default: ;
                endcase
            end
            default: ;
        endcase
    end

endmodule

module imm_gen (
    input  wire                  [31:0] ir_i        ,
    input  wire [`INSTR_TYPE_WIDTH-1:0] instr_type_i,
    output wire             [`XLEN-1:0] imm_o
);

    wire                  [31:0] ir         = ir_i          ;
    wire [`INSTR_TYPE_WIDTH-1:0] instr_type = instr_type_i  ;

    reg [`XLEN-1:0] imm;
    always @(*) begin
        // generate immediate value
        case (instr_type)
            `I_TYPE                             : imm[    0] =    ir[   20]     ;
            `S_TYPE                             : imm[    0] =    ir[    7]     ;
            default                             : imm[    0] =     1'b0         ;
        endcase
        case (instr_type)
            `I_TYPE, `J_TYPE                    : imm[ 4: 1] =    ir[24:21]     ;
            `S_TYPE, `B_TYPE                    : imm[ 4: 1] =    ir[11: 8]     ;
            default                             : imm[ 4: 1] = { 4{1'b0}}       ;
        endcase
        case (instr_type)
            `I_TYPE, `S_TYPE, `B_TYPE, `J_TYPE  : imm[10: 5] =    ir[30:25]     ;
            default                             : imm[10: 5] = { 6{1'b0}}       ;
        endcase
        case (instr_type)
            `I_TYPE, `S_TYPE                    : imm[   11] =    ir[   31]     ;
            `B_TYPE                             : imm[   11] =    ir[    7]     ;
            `J_TYPE                             : imm[   11] =    ir[   20]     ;
            default                             : imm[   11] =     1'b0         ;
        endcase
        case (instr_type)
            `I_TYPE, `S_TYPE, `B_TYPE           : imm[19:12] = { 8{ir[   31]}}  ;
            `U_TYPE, `J_TYPE                    : imm[19:12] =     ir[19:12]    ;
            default                             : imm[19:12] = { 8{1'b0}};
        endcase
        case (instr_type)
            `I_TYPE, `S_TYPE, `B_TYPE, `J_TYPE  : imm[30:20] = {11{ir[   31]}}  ;
            `U_TYPE                             : imm[30:20] =     ir[30:20]    ;
            default                             : imm[30:20] = {11{1'b0}}       ;
        endcase
        imm[31] = ir[31];
    end

    assign imm_o    = imm   ;

endmodule

module regfile (
    input  wire             clk_i   ,
    input  wire             stall_i ,
    input  wire       [4:0] rs1_i   ,
    input  wire       [4:0] rs2_i   ,
    output wire [`XLEN-1:0] xrs1_o  ,
    output wire [`XLEN-1:0] xrs2_o  ,
    input  wire             we_i    ,
    input  wire       [4:0] rd_i    ,
    input  wire [`XLEN-1:0] wdata_i
);

    reg [`XLEN-1:0] ram [0:31];

    assign xrs1_o   = (rs1_i==5'd0) ? 'h0 : ram[rs1_i];
    assign xrs2_o   = (rs2_i==5'd0) ? 'h0 : ram[rs2_i];
    always @(posedge clk_i) begin
        if (!stall_i) begin
            if (we_i) begin
                ram[rd_i] <= wdata_i;
            end
        end
    end

endmodule

module alu (
    input  wire [`ALU_CTRL_WIDTH-1:0] alu_ctrl_i,
    input  wire           [`XLEN-1:0] src1_i    ,
    input  wire           [`XLEN-1:0] src2_i    ,
    output wire           [`XLEN-1:0] rslt_o
);

    wire         [`XLEN+1:0] adder_src1         = {alu_ctrl_i[`ALU_CTRL_IS_SIGNED] && src1_i[`XLEN-1], src1_i, 1'b1};
    wire         [`XLEN+1:0] adder_src2         = {alu_ctrl_i[`ALU_CTRL_IS_SIGNED] && src2_i[`XLEN-1], src2_i, 1'b0} ^ {(`XLEN+2){alu_ctrl_i[`ALU_CTRL_IS_NEG]}};
    wire         [`XLEN+1:0] adder_rslt_t       = adder_src1+adder_src2;
    wire                     less_rslt          = alu_ctrl_i[`ALU_CTRL_IS_LESS] && adder_rslt_t[`XLEN+1];
    wire         [`XLEN-1:0] adder_rslt         = (alu_ctrl_i[`ALU_CTRL_IS_ADD]) ? adder_rslt_t[`XLEN:1] : 0;

    wire signed    [`XLEN:0] right_shifter_src1 = {alu_ctrl_i[`ALU_CTRL_IS_SIGNED] && src1_i[`XLEN-1], src1_i};
    wire [$clog2(`XLEN)-1:0] shamt              = src2_i[$clog2(`XLEN)-1:0];
    wire         [`XLEN-1:0] left_shifter_rslt  = (alu_ctrl_i[`ALU_CTRL_IS_SHIFT_LEFT] ) ?             src1_i <<  shamt : 0;
    wire         [`XLEN-1:0] right_shifter_rslt = (alu_ctrl_i[`ALU_CTRL_IS_SHIFT_RIGHT]) ? right_shifter_src1 >>> shamt : 0;

    wire         [`XLEN-1:0] bitwise_rslt       = ((alu_ctrl_i[`ALU_CTRL_IS_XOR_OR]) ? (src1_i ^ src2_i) : 0) | ((alu_ctrl_i[`ALU_CTRL_IS_OR_AND]) ? (src1_i & src2_i) : 0);
    wire         [`XLEN-1:0] lui_auipc_rslt     = (alu_ctrl_i[`ALU_CTRL_IS_SRC2]) ? src2_i : 0;

    assign rslt_o = less_rslt | adder_rslt | left_shifter_rslt | right_shifter_rslt | bitwise_rslt | lui_auipc_rslt;

endmodule

module bru (
    input  wire [`BRU_CTRL_WIDTH-1:0] bru_ctrl_i        ,
    input  wire           [`XLEN-1:0] src1_i            ,
    input  wire           [`XLEN-1:0] src2_i            ,
    input  wire           [`XLEN-1:0] pc_i              ,
    input  wire           [`XLEN-1:0] imm_i             ,
    input  wire           [`XLEN-1:0] npc_i             ,
    input  wire                       br_pred_tkn_i     ,
    output wire                       is_ctrl_tsfr_o    ,
    output wire                       br_tkn_o          ,
    output wire                       br_misp_rslt1_o   ,
    output wire                       br_misp_rslt2_o   ,
    output wire           [`XLEN-1:0] br_tkn_pc_o       ,
    output wire           [`XLEN-1:0] rslt_o
);

    wire signed [`XLEN:0] sext_src1 = {bru_ctrl_i[`BRU_CTRL_IS_SIGNED] && src1_i[`XLEN-1], src1_i};
    wire signed [`XLEN:0] sext_src2 = {bru_ctrl_i[`BRU_CTRL_IS_SIGNED] && src2_i[`XLEN-1], src2_i};

    wire beq_bne_tkn        = (     src1_i==     src2_i) ? bru_ctrl_i[`BRU_CTRL_IS_BEQ] : bru_ctrl_i[`BRU_CTRL_IS_BNE];
    wire blt_bge_tkn        = (sext_src1  < sext_src2  ) ? bru_ctrl_i[`BRU_CTRL_IS_BLT] : bru_ctrl_i[`BRU_CTRL_IS_BGE];
    assign br_tkn_o         = beq_bne_tkn | blt_bge_tkn | bru_ctrl_i[`BRU_CTRL_IS_JAL_JALR];

    wire [`XLEN-1:0] br_tkn_pc_t;
    assign br_tkn_pc_t      = ((bru_ctrl_i[`BRU_CTRL_IS_JALR]) ? src1_i : pc_i) + imm_i;
    assign br_tkn_pc_o      = {br_tkn_pc_t[`XLEN-1:1], 1'b0};

    assign is_ctrl_tsfr_o   = (bru_ctrl_i[`BRU_CTRL_IS_CTRL_TSFR] || br_pred_tkn_i);

    assign br_misp_rslt1_o  = (npc_i!=br_tkn_pc_o   );
    assign br_misp_rslt2_o  = (npc_i!=(pc_i+'h4)    );

    assign rslt_o           = (bru_ctrl_i[`BRU_CTRL_IS_JAL_JALR]) ? pc_i+4 : 0;

endmodule

module store_unit #(
    parameter OFFSET_WIDTH  = $clog2(`XBYTES)
) (
    input  wire                       valid_i       ,
    input  wire [`LSU_CTRL_WIDTH-1:0] lsu_ctrl_i    ,
    input  wire           [`XLEN-1:0] src1_i        ,
    input  wire           [`XLEN-1:0] src2_i        ,
    input  wire           [`XLEN-1:0] imm_i         ,
    output wire           [`XLEN-1:0] dbus_addr_o   ,
    output wire    [OFFSET_WIDTH-1:0] dbus_offset_o ,
    output wire                       dbus_arvalid_o,
    output wire                       dbus_wvalid_o ,
    output wire           [`XLEN-1:0] dbus_wdata_o  ,
    output wire         [`XBYTES-1:0] dbus_wstrb_o
);

    // address
    assign dbus_addr_o          = src1_i+imm_i                  ;
    assign dbus_offset_o        = dbus_addr_o[OFFSET_WIDTH-1:0] ;

    // valid
    assign dbus_arvalid_o       = valid_i && lsu_ctrl_i[`LSU_CTRL_IS_LOAD]  ;
    assign dbus_wvalid_o        = valid_i && lsu_ctrl_i[`LSU_CTRL_IS_STORE] ;

    // write data
    wire       [7:0] sb_data_t  = src2_i[ 7:0]  ;
    wire      [15:0] sh_data_t  = src2_i[15:0]  ;
    wire      [31:0] sw_data_t  = src2_i[31:0]  ;
    wire [`XLEN-1:0] sb_data    = (lsu_ctrl_i[`LSU_CTRL_IS_BYTE]    ) ? {`XBYTES  {sb_data_t}} : 'h0;
    wire [`XLEN-1:0] sh_data    = (lsu_ctrl_i[`LSU_CTRL_IS_HALFWORD]) ? {`XBYTES/2{sh_data_t}} : 'h0;
    wire [`XLEN-1:0] sw_data    = (lsu_ctrl_i[`LSU_CTRL_IS_WORD]    ) ? {`XBYTES/4{sw_data_t}} : 'h0;
    assign dbus_wdata_o         = sb_data | sh_data | sw_data   ;

    // write strobe
    wire [`XBYTES-1:0] sb_strb  = (lsu_ctrl_i[`LSU_CTRL_IS_BYTE]    ) ? ('b00000001 <<  dbus_offset_o                         ) : 'h0;
    wire [`XBYTES-1:0] sh_strb  = (lsu_ctrl_i[`LSU_CTRL_IS_HALFWORD]) ? ('b00000011 << {dbus_offset_o[OFFSET_WIDTH-1:1], 1'b0}) : 'h0;
    wire [`XBYTES-1:0] sw_strb  = (lsu_ctrl_i[`LSU_CTRL_IS_WORD]    ) ? ('b00001111                                           ) : 'h0;
    assign dbus_wstrb_o         = sb_strb | sh_strb | sw_strb   ;

endmodule


module multiplier (
    input  wire                       clk_i     ,
    input  wire                       rst_i     ,
    input  wire                       stall_i   ,
    input  wire                       valid_i   ,
    input  wire [`MUL_CTRL_WIDTH-1:0] mul_ctrl_i,
    input  wire           [`XLEN-1:0] src1_i    ,
    input  wire           [`XLEN-1:0] src2_i    ,
    output wire                       stall_o   ,
    output wire           [`XLEN-1:0] rslt_o
);

    localparam IDLE = 2'd0, EXEC = 2'd1, RET = 2'd2;
    reg [1:0] state_q = IDLE, state_d;

    assign stall_o = (state_q!=IDLE);

    reg signed [`XLEN:0] multiplicand_q , multiplicand_d;
    reg signed [`XLEN:0] multiplier_q   , multiplier_d  ;
    reg    [`XLEN*2-1:0] product_q      , product_d     ;
    reg                  is_high_q      , is_high_d     ;
    reg      [`XLEN-1:0] rslt_q         , rslt_d        ;

    assign rslt_o = rslt_q;

    always @(*) begin
        multiplicand_d  = multiplicand_q;
        multiplier_d    = multiplier_q  ;
        product_d       = product_q     ;
        is_high_d       = is_high_q     ;
        rslt_d          = 'h0           ;
        state_d         = state_q       ;
        case (state_q)
            IDLE    : begin
                if (valid_i && mul_ctrl_i[`MUL_CTRL_IS_MUL]) begin
                    multiplicand_d  = {mul_ctrl_i[`MUL_CTRL_IS_SRC1_SIGNED] && src1_i[`XLEN-1], src1_i} ;
                    multiplier_d    = {mul_ctrl_i[`MUL_CTRL_IS_SRC2_SIGNED] && src2_i[`XLEN-1], src2_i} ;
                    is_high_d       = mul_ctrl_i[`MUL_CTRL_IS_HIGH]                                     ;
                    state_d         = EXEC                                                              ;
                end
            end
            EXEC    : begin
                product_d   = multiplicand_q * multiplier_q ;
                state_d     = RET                           ;
            end
            RET     : begin
                rslt_d      = (is_high_q) ? product_q[`XLEN*2-1:`XLEN] : product_q[`XLEN-1:0]   ;
                state_d     = IDLE                                                              ;
            end
            default : begin
                state_d     = IDLE  ;
            end
        endcase
    end

    always @(posedge clk_i) begin
        if (rst_i) begin
            state_q         <= IDLE             ;
        end else if (!stall_i) begin
            multiplicand_q  <= multiplicand_d   ;
            multiplier_q    <= multiplier_d     ;
            product_q       <= product_d        ;
            is_high_q       <= is_high_d        ;
            rslt_q          <= rslt_d           ;
            state_q         <= state_d          ;
        end
    end

endmodule

module divider (
    input  wire                       clk_i     ,
    input  wire                       rst_i     ,
    input  wire                       stall_i   ,
    input  wire                       valid_i   ,
    input  wire [`DIV_CTRL_WIDTH-1:0] div_ctrl_i,
    input  wire           [`XLEN-1:0] src1_i    ,
    input  wire           [`XLEN-1:0] src2_i    ,
    output wire                       stall_o   ,
    output wire           [`XLEN-1:0] rslt_o
);

    localparam IDLE = 2'd0, CHECK = 2'd1, EXEC = 2'd2, RET = 2'd3;
    reg [1:0] state_q = IDLE, state_d;

    assign stall_o = (state_q!=IDLE);

    reg                       is_dividend_neg_q , is_dividend_neg_d ;
    reg                       is_divisor_neg_q  , is_divisor_neg_d  ;
    reg           [`XLEN-1:0] remainder_q       , remainder_d       ;
    reg           [`XLEN-1:0] divisor_q         , divisor_d         ;
    reg           [`XLEN-1:0] quotient_q        , quotient_d        ;
    reg                       is_div_rslt_neg_q , is_div_rslt_neg_d ;
    reg                       is_rem_rslt_neg_q , is_rem_rslt_neg_d ;
    reg                       is_rem_q          , is_rem_d          ;
    reg           [`XLEN-1:0] rslt_q            , rslt_d            ;
    reg [$clog2(`XLEN+1)-1:0] cntr_q            , cntr_d            ;

    wire [`XLEN-1:0] uintx_remainder    = (is_dividend_neg_q) ? ~remainder_q+1 : remainder_q        ;
    wire [`XLEN-1:0] uintx_divisor      = (is_divisor_neg_q ) ? ~divisor_q+1   : divisor_q          ;
    wire   [`XLEN:0] difference         = {remainder_q[`XLEN-2:0], quotient_q[`XLEN-1]} - divisor_q ;
    wire             q                  = !difference[`XLEN]                                        ;

    assign rslt_o = rslt_q;

    always @(*) begin
        is_dividend_neg_d   = is_dividend_neg_q ;
        is_divisor_neg_d    = is_divisor_neg_q  ;
        remainder_d         = remainder_q       ;
        divisor_d           = divisor_q         ;
        quotient_d          = quotient_q        ;
        is_div_rslt_neg_d   = is_div_rslt_neg_q ;
        is_rem_rslt_neg_d   = is_rem_rslt_neg_q ;
        is_rem_d            = is_rem_q          ;
        rslt_d              = 'h0               ;
        cntr_d              = cntr_q            ;
        state_d             = state_q           ;
        case (state_q)
            IDLE    : begin
                if (valid_i && div_ctrl_i[`DIV_CTRL_IS_DIV]) begin
                    is_dividend_neg_d   = div_ctrl_i[`DIV_CTRL_IS_SIGNED] &&  src1_i[`XLEN-1]                   ;
                    is_divisor_neg_d    = div_ctrl_i[`DIV_CTRL_IS_SIGNED] &&  src2_i[`XLEN-1]                   ;
                    remainder_d         = src1_i                                                                ;
                    divisor_d           = src2_i                                                                ;
                    is_div_rslt_neg_d   = div_ctrl_i[`DIV_CTRL_IS_SIGNED] && (src1_i[`XLEN-1] ^ src2_i[`XLEN-1]);
                    is_rem_rslt_neg_d   = div_ctrl_i[`DIV_CTRL_IS_SIGNED] &&  src1_i[`XLEN-1]                   ;
                    is_rem_d            = div_ctrl_i[`DIV_CTRL_IS_REM]                                          ;
                    state_d             = CHECK                                                                 ;
                end
            end
            CHECK   : begin
                if (divisor_q=='h00000000) begin
                    quotient_d                  = {`XLEN{1'b1}}                     ;
                    is_div_rslt_neg_d           = 1'b0                              ;
                    is_rem_rslt_neg_d           = 1'b0                              ;
                    state_d                     = RET                               ;
                end else begin
                    {remainder_d, quotient_d}   = {{`XLEN{1'b0}}, uintx_remainder}  ;
                    divisor_d                   = uintx_divisor                     ;
                    cntr_d                      = `XLEN-1                           ;
                    state_d                     = EXEC                              ;
                end
            end
            EXEC    : begin
                {remainder_d, quotient_d}       = (q) ? { difference[`XLEN-1:0], quotient_q[`XLEN-2:0], 1'b1} :
                                                        {remainder_q[`XLEN-2:0], quotient_q           , 1'b0} ;
                cntr_d      = cntr_q-'h1                                            ;
                if (~|cntr_q) begin // (cntr_q==0)
                    state_d = RET                                                   ;
                end
            end
            RET     : begin
                rslt_d      = (is_rem_q) ? ((is_rem_rslt_neg_q) ? ~remainder_q+1 : remainder_q) :
                                           ((is_div_rslt_neg_q) ? ~quotient_q+1  : quotient_q ) ;
                state_d     = IDLE                                                  ;
            end
            default : begin
                state_d     = IDLE                                                  ;
            end
        endcase
    end

    always @(posedge clk_i) begin
        if (rst_i) begin
            state_q             <= IDLE             ;
        end else if (!stall_i) begin
            is_dividend_neg_q   <= is_dividend_neg_d;
            is_divisor_neg_q    <= is_divisor_neg_d ;
            remainder_q         <= remainder_d      ;
            divisor_q           <= divisor_d        ;
            quotient_q          <= quotient_d       ;
            is_div_rslt_neg_q   <= is_div_rslt_neg_d;
            is_rem_rslt_neg_q   <= is_rem_rslt_neg_d;
            is_rem_q            <= is_rem_d         ;
            rslt_q              <= rslt_d           ;
            cntr_q              <= cntr_d           ;
            state_q             <= state_d          ;
        end
    end

endmodule

module load_unit #(
    parameter OFFSET_WIDTH  = $clog2(`XBYTES)
) (
    input  wire  [`LSU_CTRL_WIDTH-1:0] lsu_ctrl_i    ,
    input  wire     [OFFSET_WIDTH-1:0] dbus_offset_i ,
    input  wire            [`XLEN-1:0] dbus_rdata_i  ,
    input  wire [`PERF_CTRL_WIDTH-1:0] perf_ctrl_i   ,
    input  wire                 [63:0] mcycle_i      ,
    input  wire                 [63:0] minstret_i    ,
    output wire            [`XLEN-1:0] rslt_o
);

    wire      [31:0] lw_data_t  =                                      dbus_rdata_i[31:0];
    wire      [15:0] lh_data_t  = (dbus_offset_i[1]) ? lw_data_t[31:16] : lw_data_t[15:0];
    wire       [7:0] lb_data_t  = (dbus_offset_i[0]) ? lh_data_t[15: 8] : lh_data_t[ 7:0];
    wire [`XLEN-1:0] lb_data    = (lsu_ctrl_i[`LSU_CTRL_IS_BYTE]    ) ? {{(`XLEN- 8){lsu_ctrl_i[`LSU_CTRL_IS_SIGNED] && lb_data_t[ 7]}}, lb_data_t} : 'h0;
    wire [`XLEN-1:0] lh_data    = (lsu_ctrl_i[`LSU_CTRL_IS_HALFWORD]) ? {{(`XLEN-16){lsu_ctrl_i[`LSU_CTRL_IS_SIGNED] && lh_data_t[15]}}, lh_data_t} : 'h0;
    wire [`XLEN-1:0] lw_data    = (lsu_ctrl_i[`LSU_CTRL_IS_WORD]    ) ?                                                                  lw_data_t  : 'h0;

    wire [31:0] mcycle = (perf_ctrl_i[`PERF_CTRL_IS_CYCLE]) ? mcycle_i[31:0] : 0;
    wire [31:0] mcycleh = (perf_ctrl_i[`PERF_CTRL_IS_CYCLEH]) ? mcycle_i[63:32] : 0;
    wire [31:0] minstret = (perf_ctrl_i[`PERF_CTRL_IS_INSTRET]) ? minstret_i[31:0] : 0;
    wire [31:0] minstreth = (perf_ctrl_i[`PERF_CTRL_IS_INSTRETH]) ? minstret_i[63:32] : 0;

    assign rslt_o = (perf_ctrl_i) ? (mcycle | mcycleh | minstret | minstreth) :
                    (lsu_ctrl_i[`LSU_CTRL_IS_LOAD]) ? (lb_data | lh_data | lw_data) : 'h0;

endmodule

`resetall