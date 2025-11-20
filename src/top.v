module top;
    reg clk = 1; always #5 clk = ~clk;
    reg [31:0] cc = 0; always @(posedge clk) cc <= cc + 1;

    wire user_led0;
    wire user_led1;
    wire user_led2;
    wire user_led3;
    main main(
        .clk100(clk),
        .ddram_a(),
        .ddram_ba(),
        .ddram_cas_n(),
        .ddram_cke(),
        .ddram_clk_n(),
        .ddram_clk_p(),
        .ddram_cs_n(),
        .ddram_dm(),
        .ddram_dq(),
        .ddram_dqs_n(),
        .ddram_dqs_p(),
        .ddram_odt(),
        .ddram_ras_n(),
        .ddram_reset_n(),
        .ddram_we_n(),
        .serial_tx(),
        .user_led0(user_led0),
        .user_led1(user_led1),
        .user_led2(user_led2),
        .user_led3(user_led3),
        .st7789_SDA(),
        .st7789_SCL(),
        .st7789_DC(),
        .st7789_RES(),
        .uart_rxd()
    );

    initial begin
        $dumpfile("top.vcd");
        $dumpvars(0, top);
    end

    reg timeout_detected = 0;
    reg finish_detected  = 0;
    reg error_detected   = 0;
    always @(posedge clk) begin
        if (cc > 32'h10000) timeout_detected <= 1;
        if (user_led1)      error_detected   <= 1;
        if (user_led3)      finish_detected  <= 1;

        if (cc[7:0] == 0) begin
            if (error_detected) begin
                $display("\033[31mTEST FAILED\033[0m");
                $finish;
            end
            else if (finish_detected) begin
                $display("\033[32mTEST PASSED\033[0m");
                $finish;
            end
            else if (timeout_detected) begin
                $display("\033[33mTEST TIMEOUT\033[0m");
                $finish;
            end
        end
    end
endmodule
