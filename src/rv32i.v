module rv32i (
    input  wire        clk_i,
    output wire [31:0] dbus_cmd_addr_o,
    output wire        dbus_cmd_we_o,
    output wire        dbus_cmd_valid_o,
    input  wire        dbus_cmd_ack_i,
    input  wire [31:0] dbus_read_data_i,
    output wire [31:0] dbus_write_data_o,
    output wire  [3:0] dbus_write_en_o
);
    `include "riscv.vh"

    // Real registers
    reg [31:0] xreg [0:31];
    reg [31:0] pc   = 0;
    reg [31:0] insn = 32'h0000_0013;

    // Used as a wire
    reg [31:0] npc;
    reg        xreg_en;
    reg [31:0] xreg_write_data;
    reg        cmd_we;
    reg [31:0] cmd_addr;
    reg        cmd_valid;
    reg [31:0] write_data;
    reg  [3:0] write_en;

    wire  [6:0] opcode = insn[6:0];
    wire  [4:0] rd     = insn[11:7];
    wire  [2:0] funct3 = insn[14:12];
    wire  [4:0] rs1    = insn[19:15];
    wire  [4:0] rs2    = insn[24:20];
    wire  [6:0] funct7 = insn[31:25];

    wire [31:0] i_imm = {{20{insn[31]}}, insn[31:20]};
    wire [31:0] s_imm = {{20{insn[31]}}, insn[31:25], insn[11:7]};
    wire [31:0] b_imm = {{19{insn[31]}}, insn[31], insn[7], insn[30:25], insn[11:8], 1'b0};
    wire [31:0] u_imm = {insn[31:12], 12'b0};
    wire [31:0] j_imm = {{11{insn[31]}}, insn[31], insn[19:12], insn[20], insn[30:21], 1'b0};

    wire [31:0] branch_target = pc + b_imm;
    wire [31:0] jump_target   = pc + j_imm;

    wire        waiting_dbus = dbus_cmd_valid_o && !dbus_cmd_ack_i;

    assign dbus_cmd_we_o     = cmd_we;
    assign dbus_cmd_addr_o   = (opcode[6:2]==5'b01000) ? (xreg[rs1] + s_imm) : (xreg[rs1] + i_imm);
    assign dbus_cmd_valid_o  = cmd_valid;
    assign dbus_write_data_o = write_data;
    assign dbus_write_en_o   = write_en;

    reg  [31:0] mem [0:3071]; // 12 KiB instruction memory
    `include "imem_init.vh"

    always @(posedge clk_i) if (!waiting_dbus) begin
        pc   <= npc;
        insn <= mem[npc[31:2]];
        if (xreg_en && rd != 0) xreg[rd] <= xreg_write_data;
    end

    always @(*) begin
        npc             = pc + 4;
        xreg_en         = 0;
        xreg_write_data = 0;
        cmd_we          = 0;
        cmd_addr        = 0;
        cmd_valid       = 0;
        write_data      = 0;
        write_en        = 0;
        casez(insn)
            ADD      :begin xreg_en=1; xreg_write_data = xreg[rs1] + xreg[rs2]; end
            ADDI     :begin xreg_en=1; xreg_write_data = xreg[rs1] + i_imm; end
            AND      :begin xreg_en=1; xreg_write_data = xreg[rs1] & xreg[rs2]; end
            ANDI     :begin xreg_en=1; xreg_write_data = xreg[rs1] & i_imm; end
            AUIPC    :begin xreg_en=1; xreg_write_data = pc + u_imm; end
            BEQ      :begin if (xreg[rs1] == xreg[rs2]) npc = branch_target; end
            BGE      :begin if ($signed(xreg[rs1]) >= $signed(xreg[rs2])) npc = branch_target; end
            BGEU     :begin if (xreg[rs1] >= xreg[rs2]) npc = branch_target; end
            BLT      :begin if ($signed(xreg[rs1]) < $signed(xreg[rs2])) npc = branch_target; end
            BLTU     :begin if (xreg[rs1] < xreg[rs2]) npc = branch_target; end
            BNE      :begin if (xreg[rs1] != xreg[rs2]) npc = branch_target; end
            JAL      :begin xreg_en=1; xreg_write_data = pc+4; npc = jump_target; end
            JALR     :begin xreg_en=1; xreg_write_data = pc+4; npc = (xreg[rs1] + i_imm) & ~32'b1; end
            LB       :begin cmd_we=0; cmd_valid=1; xreg_en=1; xreg_write_data = {{24{dbus_read_data_i[7]}}, dbus_read_data_i[7:0]}; end
            LBU      :begin cmd_we=0; cmd_valid=1; xreg_en=1; xreg_write_data = dbus_read_data_i[7:0]; end
            LH       :begin cmd_we=0; cmd_valid=1; xreg_en=1; xreg_write_data = {{16{dbus_read_data_i[15]}}, dbus_read_data_i[15:0]}; end
            LHU      :begin cmd_we=0; cmd_valid=1; xreg_en=1; xreg_write_data = dbus_read_data_i[15:0]; end
            LUI      :begin xreg_en=1; xreg_write_data = u_imm; end
            LW       :begin cmd_we=0; cmd_valid=1; xreg_en=1; xreg_write_data = dbus_read_data_i[31:0]; end
            OR       :begin xreg_en=1; xreg_write_data = xreg[rs1] | xreg[rs2]; end
            ORI      :begin xreg_en=1; xreg_write_data = xreg[rs1] | i_imm; end
            SB       :begin cmd_we=1; cmd_valid=1; write_data=xreg[rs2][7:0]; write_en=4'b0001; end
            SH       :begin cmd_we=1; cmd_valid=1; write_data=xreg[rs2][15:0]; write_en=4'b0011; end
            SLL      :begin xreg_en=1; xreg_write_data = xreg[rs1] << xreg[rs2][4:0]; end
            SLLI     :begin xreg_en=1; xreg_write_data = xreg[rs1] << i_imm[4:0]; end
            SLT      :begin xreg_en=1; xreg_write_data = ($signed(xreg[rs1]) < $signed(xreg[rs2])); end
            SLTI     :begin xreg_en=1; xreg_write_data = ($signed(xreg[rs1]) < $signed(i_imm)); end
            SLTIU    :begin xreg_en=1; xreg_write_data = (xreg[rs1] < i_imm); end
            SLTU     :begin xreg_en=1; xreg_write_data = (xreg[rs1] < xreg[rs2]); end
            SRA      :begin xreg_en=1; xreg_write_data = $signed(xreg[rs1]) >>> xreg[rs2][4:0]; end
            SRAI     :begin xreg_en=1; xreg_write_data = $signed(xreg[rs1]) >>> i_imm[4:0]; end
            SRL      :begin xreg_en=1; xreg_write_data = xreg[rs1] >> xreg[rs2][4:0]; end
            SRLI     :begin xreg_en=1; xreg_write_data = xreg[rs1] >> i_imm[4:0]; end
            SUB      :begin xreg_en=1; xreg_write_data = xreg[rs1] - xreg[rs2]; end
            SW       :begin cmd_we=1; cmd_valid=1; write_data=xreg[rs2][31:0]; write_en=4'b1111; end
            XOR      :begin xreg_en=1; xreg_write_data = xreg[rs1] ^ xreg[rs2]; end
            XORI     :begin xreg_en=1; xreg_write_data = xreg[rs1] ^ i_imm; end
            default  :begin $display("Unknown instruction: 0x%08h", insn); $finish; end
        endcase
    end
endmodule
