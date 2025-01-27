`include "config.vh"
`define MAX 31
`define MIN 2
`define N   17

module cfu (
    input  wire                       clk_i     ,
    input  wire                       rst_i     ,
    input  wire                       stall_i   ,
    input  wire                       valid_i   ,
    input  wire [`CFU_CTRL_WIDTH-1:0] cfu_ctrl_i,
    input  wire           [`XLEN-1:0] src1_i    ,
    input  wire           [`XLEN-1:0] src2_i    ,
    output wire                       stall_o   ,
    output wire           [`XLEN-1:0] rslt_o
);

    assign stall_o = 0;

    wire cfu_init     = cfu_ctrl_i[0];
    wire cfu_kernel   = cfu_ctrl_i[1];
    wire cfu_get_ret  = cfu_ctrl_i[2];

    wire cmd_valid    = valid_i && cfu_ctrl_i[2:0];

    reg [31:0] a_cdt [0:`MAX]; /* candidates        */
    reg [31:0] a_col [0:`MAX]; /* column            */
    reg [31:0] a_pos [0:`MAX]; /* positive diagonal */
    reg [31:0] a_neg [0:`MAX]; /* negative diagonal */
  
    reg [31:0] reg_h    = 0;       /* height or level  */
    reg [31:0] reg_r    = 0;       /* candidate vector */
    reg [31:0] reg_ret  = 0;       /* return value      */

    integer i;
    initial begin
      for (i = 0; i <= `MAX; i = i + 1) begin
        a_cdt[i] = 0;
        a_col[i] = 0;
        a_pos[i] = 0;
        a_neg[i] = 0;
      end
    end
  
    wire        w_bool      = ~(reg_r == 0 && reg_h == 1);
    wire [31:0] lsb1        = (~reg_r + 1) & reg_r;
    wire [31:0] r2          = (a_col[reg_h] & ~lsb1) & 
                             ~(((a_pos[reg_h] |  lsb1) << 1) |
                               ((a_neg[reg_h] |  lsb1) >> 1));
    wire [31:0] lsb2        = (~r2 + 1) & r2;
    wire [31:0] lsb3        = (~a_cdt[reg_h] + 1) & a_cdt[reg_h];
  
    always @(posedge clk_i) begin
      if (stall_i);
      else if (cmd_valid) begin
        if (cfu_init) begin
          reg_ret   <= 0;
          reg_h     <= 1;
          reg_r     <= 1 << (src1_i);
          a_col[1]  <= (1 << `N) - 1;
          a_pos[1]  <= 0;
          a_neg[1]  <= 0;
        end
        
        else if (cfu_kernel) begin
          if (reg_r) begin
            a_cdt[reg_h+1] <= (       reg_r & ~lsb1);
            a_col[reg_h+1] <= (a_col[reg_h] & ~lsb1);
            a_pos[reg_h+1] <= ((a_pos[reg_h] |  lsb1) << 1);
            a_neg[reg_h+1] <= ((a_neg[reg_h] |  lsb1) >> 1);
  
            if (r2) begin
              a_cdt[reg_h+2] <= (       r2 & ~lsb2);
              a_col[reg_h+2] <= ((a_col[reg_h] & ~lsb1) & ~lsb2);
              a_pos[reg_h+2] <= ((((a_pos[reg_h] |  lsb1) << 1) |  lsb2) << 1);
              a_neg[reg_h+2] <= ((((a_neg[reg_h] |  lsb1) >> 1) |  lsb2) >> 1);
              reg_r          <= ((a_col[reg_h] & ~lsb1) & ~lsb2) &
                               ~(((((a_pos[reg_h] |  lsb1) << 1) |  lsb2) << 1) |
                                 ((((a_neg[reg_h] |  lsb1) >> 1) |  lsb2) >> 1));
              reg_h          <= reg_h + 2;
            end else begin
              if (reg_h >= `N) reg_ret <= reg_ret + 1;
              reg_r <= (reg_r & ~lsb1);
            end
  
          end else if (a_cdt[reg_h]) begin
            if (reg_h == `N + 1) reg_ret <= reg_ret + 1;
            a_cdt[reg_h] <= (  a_cdt[reg_h] & ~lsb3);
            a_col[reg_h] <= (a_col[reg_h-1] & ~lsb3);
            a_pos[reg_h] <= ((a_pos[reg_h-1] |  lsb3) << 1);
            a_neg[reg_h] <= ((a_neg[reg_h-1] |  lsb3) >> 1);
            reg_r        <= (a_col[reg_h-1] & ~lsb3) &
                           ~(((a_pos[reg_h-1] |  lsb3) << 1) |
                             ((a_neg[reg_h-1] |  lsb3) >> 1));
                             
          end else begin
            if (reg_h == `N + 1) reg_ret <= reg_ret + 1;
            reg_r <= a_cdt[reg_h - 1];
            reg_h <= reg_h - 2;
          end
          
        end
      end
    end
 
  assign rslt_o = (!cmd_valid)  ? 0       :
                  (cfu_init)    ? 0       :
                  (cfu_kernel)  ? w_bool  :
                  (cfu_get_ret) ? reg_ret : 0;
endmodule
