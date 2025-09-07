module uart (
    input  wire       clk_i     ,
    input  wire       rst_i     ,
    output wire       txd_o     ,
    input  wire       rxd_i     ,
    input  wire       wvalid_i  ,
    output wire       wready_o  ,
    input  wire [7:0] wdata_i   ,
    output wire       rvalid_o  ,
    input  wire       rready_i  ,
    output wire [7:0] rdata_o
);
    localparam FIFO_DEPTH   = 2048;
    localparam DETECT_COUNT = 4;

    wire       uart_wvalid  ;
    wire       uart_wready  ;
    wire [7:0] uart_wdata   ;

    // FIFO for UART transmitter
    fifo #(
        .DATA_WIDTH     (8              ),
        .FIFO_DEPTH     (FIFO_DEPTH     )
    ) tx_fifo (
        .clk_i          (clk_i          ),
        .rst_i          (rst_i          ),
        .wvalid_i       (wvalid_i       ),
        .wready_o       (wready_o       ),
        .wdata_i        (wdata_i        ),
        .rvalid_o       (uart_wvalid    ),
        .rready_i       (uart_wready    ),
        .rdata_o        (uart_wdata     )
    );

    // UART transmitter
    uart_tx #(
        .CLK_FREQ_MHZ   (`CLK_FREQ_MHZ   ),
        .BAUD_RATE      (`UART_BAUDRATE )
    ) uart_tx (
        .clk_i          (clk_i          ),
        .rst_i          (rst_i          ),
        .txd_o          (txd_o          ),
        .wvalid_i       (uart_wvalid    ),
        .wready_o       (uart_wready    ),
        .wdata_i        (uart_wdata     )
    );

    // UART receiver
    uart_rx #(
        .CLK_FREQ_MHZ   (`CLK_FREQ_MHZ  ),
        .BAUD_RATE      (`UART_BAUDRATE),
        .DETECT_COUNT   (DETECT_COUNT   )
    ) uart_rx (
        .clk_i          (clk_i          ),
        .rst_i          (rst_i          ),
        .rxd_i          (rxd_i          ),
        .rvalid_o       (rvalid_o       ),
        .rready_i       (rready_i       ),
        .rdata_o        (rdata_o        )
    );
endmodule  // uart

module fifo #(
    parameter DATA_WIDTH    = 32    ,
    parameter FIFO_DEPTH    = 2048
) (
    input  wire                  clk_i      ,
    input  wire                  rst_i      ,
    input  wire                  wvalid_i   ,
    output wire                  wready_o   ,
    input  wire [DATA_WIDTH-1:0] wdata_i    ,
    output wire                  rvalid_o   ,
    input  wire                  rready_i   ,
    output reg  [DATA_WIDTH-1:0] rdata_o
);

    reg [DATA_WIDTH-1:0] ram [0:FIFO_DEPTH-1];

    reg                            full_nq  , full_nd   ;
    reg                            empty_nq , empty_nd  ;
    reg   [$clog2(FIFO_DEPTH)-1:0] waddr_q  , waddr_d   ;
    reg   [$clog2(FIFO_DEPTH)-1:0] raddr_q  , raddr_d   ;
    reg [$clog2(FIFO_DEPTH+1)-1:0] count_q  , count_d   ;
    reg                            rvalid_q , rvalid_d  ;

    assign wready_o = full_nq   ;
    assign rvalid_o = rvalid_q  ;

    always @(*) begin
        full_nd     = full_nq   ;
        empty_nd    = empty_nq  ;
        waddr_d     = waddr_q   ;
        raddr_d     = raddr_q   ;
        count_d     = count_q   ;
        rvalid_d    = empty_nq  ;
        if (rvalid_o && rready_i) begin
            raddr_d     = raddr_q+'h1   ;
            rvalid_d    = 1'b0          ;
        end
        if (wvalid_i && wready_o) begin
            waddr_d     = waddr_q+'h1   ;
        end
        casez ({wvalid_i && wready_o, rvalid_o && rready_i}) // {fifo_write, fifo_read}
            2'b10  : begin
                if (count_q==FIFO_DEPTH-1) full_nd  = 1'b0  ;
                empty_nd    = 1'b1          ;
                count_d     = count_q+'h1   ;
            end
            2'b01  : begin
                full_nd     = 1'b1          ;
                if (count_q=='h1         ) empty_nd = 1'b0  ;
                count_d     = count_q-'h1   ;
            end
            default: ;
        endcase
    end

    // FIFO read/write
    always @(posedge clk_i) begin
        rdata_o <= ram[raddr_q];
        if (wvalid_i && wready_o) begin
            ram[waddr_q] <= wdata_i;
        end
    end

    always @(posedge clk_i) begin
        if (rst_i) begin
            full_nq     <= 1'b1     ;
            empty_nq    <= 1'b0     ;
            waddr_q     <= 'h0      ;
            raddr_q     <= 'h0      ;
            count_q     <= 'h0      ;
            rvalid_q    <= 1'b0     ;
        end else begin
            full_nq     <= full_nd  ;
            empty_nq    <= empty_nd ;
            waddr_q     <= waddr_d  ;
            raddr_q     <= raddr_d  ;
            count_q     <= count_d  ;
            rvalid_q    <= rvalid_d ;
        end
    end
endmodule  // fifo

module uart_rx #(
    parameter CLK_FREQ_MHZ  = 100   ,
    parameter BAUD_RATE     = 115200,
    parameter DETECT_COUNT  = 4
) (
    input  wire       clk_i     ,
    input  wire       rst_i     ,
    input  wire       rxd_i     ,
    output wire       rvalid_o  ,
    input  wire       rready_i  ,
    output wire [7:0] rdata_o
);

    localparam WAIT_COUNT = ((CLK_FREQ_MHZ*1000*1000)/BAUD_RATE);

    // 2-FF synchronizer
    wire rxd;
    synchronizer sync_rxd (
        .clk_i   (clk_i     ),
        .d_i     (rxd_i     ),
        .q_o     (rxd       )
    );

    // FSM
    reg state_q, state_d;
    localparam IDLE = 1'b0;
    localparam RUN  = 1'b1;

    reg [$clog2(DETECT_COUNT+1)-1:0] detect_cntr_q  , detect_cntr_d ;
    reg                              rvalid_q       , rvalid_d      ;
    reg                        [7:0] rx_data_q      , rx_data_d     ;
    reg                        [7:0] buf_q          , buf_d         ;
    reg                        [3:0] bit_cntr_q     , bit_cntr_d    ;
    reg     [$clog2(WAIT_COUNT)-1:0] wait_cntr_q    , wait_cntr_d   ;

    assign rvalid_o = rvalid_q  ;
    assign rdata_o  = rx_data_q ;

    always @(*) begin
        detect_cntr_d   = (rxd) ? 'h0 : detect_cntr_q+'h1;
        rvalid_d        = rvalid_q          ;
        rx_data_d       = rx_data_q         ;
        buf_d           = buf_q             ;
        bit_cntr_d      = bit_cntr_q        ;
        wait_cntr_d     = wait_cntr_q-'h1   ;
        state_d         = state_q           ;
        if (rvalid_o && rready_i) begin
            rvalid_d = 1'b0;
        end
        case (state_q)
            IDLE: begin
                if (detect_cntr_q>=DETECT_COUNT-1) begin
                    bit_cntr_d      = 4'd9                          ;
                    wait_cntr_d     = WAIT_COUNT-DETECT_COUNT-'h3   ;
                    state_d         = RUN                           ;
                end
            end
            RUN: begin
                if (wait_cntr_q==(WAIT_COUNT/2)) begin
                    if (~|bit_cntr_q) begin // bit_cntr_q==0
                        rvalid_d    = 1'b1                          ;
                        rx_data_d   = buf_q                         ;
                        state_d     = IDLE                          ;
                    end
                    buf_d           = {rxd, buf_q[7:1]}             ;
                    bit_cntr_d      = bit_cntr_q-4'd1               ;
                end
                if (~|wait_cntr_q) begin // wait_cntr_q==0
                    wait_cntr_d     = WAIT_COUNT-'h1                ;
                end
            end
            default: begin
                rvalid_d            = 1'b0                          ;
                state_d             = IDLE                          ;
            end
        endcase
    end

    always @(posedge clk_i) begin
        if (rst_i) begin
            detect_cntr_q   <= 'h0          ;
            rvalid_q        <= 1'b0         ;
            state_q         <= IDLE         ;
        end else begin
            detect_cntr_q   <= detect_cntr_d;
            rvalid_q        <= rvalid_d     ;
            rx_data_q       <= rx_data_d    ;
            buf_q           <= buf_d        ;
            bit_cntr_q      <= bit_cntr_d   ;
            wait_cntr_q     <= wait_cntr_d  ;
            state_q         <= state_d      ;
        end
    end

endmodule  // uart_rx

module uart_tx #(
    parameter CLK_FREQ_MHZ  = 100   ,
    parameter BAUD_RATE     = 115200
) (
    input  wire       clk_i     ,
    input  wire       rst_i     ,
    output wire       txd_o     ,
    input  wire       wvalid_i  ,
    output wire       wready_o  ,
    input  wire [7:0] wdata_i
);

    localparam WAIT_COUNT = ((CLK_FREQ_MHZ*1000*1000)/BAUD_RATE);

    // FSM
    reg state_q, state_d;
    localparam IDLE = 1'b0;
    localparam RUN  = 1'b1;

    reg                          wready_q       , wready_d      ;
    reg                    [8:0] buf_q = 9'h1   , buf_d         ;
    reg                    [3:0] bit_cntr_q     , bit_cntr_d    ;
    reg [$clog2(WAIT_COUNT)-1:0] wait_cntr_q    , wait_cntr_d   ;

    assign txd_o    = buf_q[0]          ;
    assign wready_o = wready_q          ;

    always @(*) begin
        wready_d    = wready_q          ;
        buf_d       = buf_q             ;
        bit_cntr_d  = bit_cntr_q        ;
        wait_cntr_d = wait_cntr_q-'h1   ;
        state_d     = state_q           ;
        case (state_q)
            IDLE: begin
                if (wvalid_i) begin // (wvalid_i && wready_o)
                    wready_d        = 1'b0              ;
                    buf_d           = {wdata_i, 1'b0}   ;
                    bit_cntr_d      = 4'd9              ;
                    wait_cntr_d     = WAIT_COUNT-'h1    ;
                    state_d         = RUN               ;
                end
            end
            RUN: begin
                if (~|wait_cntr_q) begin // (wait_cntr_q==0)
                    buf_d           = {1'b1, buf_q[8:1]};
                    bit_cntr_d      = bit_cntr_q-4'd1   ;
                    wait_cntr_d     = WAIT_COUNT-'h1    ;
                end
                if (wait_cntr_q==((WAIT_COUNT-1)/2)) begin
                    if (~|bit_cntr_q) begin // (bit_cntr_q==0)
                        wready_d    = 1'b1              ;
                        state_d     = IDLE              ;
                    end
                end
            end
            default: begin
                wready_d            = 1'b1              ;
                buf_d               = 9'h1              ; // txd_o <= 1'b1;
                state_d             = IDLE              ;
            end
        endcase
    end

    always @(posedge clk_i) begin
        if (rst_i) begin
            wready_q    <= 1'b1         ;
            buf_q       <= 9'h1         ; // txd_o <= 1'b1;
            state_q     <= IDLE         ;
        end else begin
            wready_q    <= wready_d     ;
            buf_q       <= buf_d        ;
            bit_cntr_q  <= bit_cntr_d   ;
            wait_cntr_q <= wait_cntr_d  ;
            state_q     <= state_d      ;
        end
    end

endmodule  // uart_tx

module synchronizer (
    input  wire clk_i   ,
    input  wire d_i     ,
    output wire q_o
);

    reg ff1, ff2;
    always @(posedge clk_i) begin
        ff1 <= d_i  ;
        ff2 <= ff1  ;
    end
    assign q_o = ff2;

endmodule  // synchronizer
