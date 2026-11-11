`timescale 1ns/1ps

// Run the same tests for each pattern using an independent reference model.
module fsm_checker #(
    parameter integer DATA_WIDTH = 3,
    parameter logic [DATA_WIDTH-1:0] PATTERN = 3'b101
) (
    input logic clk,
    output logic done
);
    // Module inputs
    logic rst = 0;
    logic data_in = 0;
    logic detected;

    // Shift register reference model register
    logic [DATA_WIDTH-1:0] history = '0;
    integer bits_seen = 0;

    // Testbench metrics
    integer checks = 0;
    logic expected;

    // Random seed
    logic [31:0] random_state = 32'hdeadbeef;

    fsm #(.DATA_WIDTH(DATA_WIDTH), .PATTERN(PATTERN)) dut (
        .clk(clk), .rst(rst), .data_in(data_in), .detected(detected)
    );

    // Send one bit and compare the output after the rising edge.
    task automatic step(input logic reset_value, input logic bit_value);
        // Drive inputs on falling edge
        @(negedge clk);
        rst = reset_value;
        data_in = bit_value;

        // Update outputs on rising edge
        @(posedge clk);
        if (reset_value) begin
            history = '0;
            bits_seen = 0;
        end else begin
            // Keep the most recent DATA_WIDTH input bits.
            history = (history << 1) | DATA_WIDTH'(bit_value);
            if (bits_seen < DATA_WIDTH) bits_seen = bits_seen + 1;
        end
        expected = (bits_seen == DATA_WIDTH) && (history == PATTERN);
        #1;
        checks = checks + 1;
        if (detected !== expected) begin
            $fatal(1, "width=%0d pattern=%b check=%0d reset=%b input=%b expected=%b actual=%b",
                   DATA_WIDTH, PATTERN, checks, reset_value, bit_value, expected, detected);
        end
    endtask

    // Send specified pattern
    task automatic send_pattern;
        for (int i = DATA_WIDTH - 1; i >= 0; i = i - 1)
            step(0, PATTERN[i]);
    endtask

    initial begin : run_checks
        integer stream;
        done = 0;

        // Check a back to back matches
        step(1, 0);
        send_pattern;
        send_pattern;

        // Test when reset applies
        @(negedge clk);
        rst = 1;
        data_in = 0;
        #1;
        if (detected !== 1'b1)
            $fatal(1, "width=%0d pattern=%b: reset changed output before clock", DATA_WIDTH, PATTERN);
        @(posedge clk);
        history = '0;
        bits_seen = 0;
        #1;
        checks = checks + 1;
        if (detected !== 1'b0) $fatal(1, "synchronous reset did not clear detection");
        step(1, 1);
        step(1, 0);

        // Reset behavior during parital match
        for (int prefix = 0; prefix < DATA_WIDTH; prefix = prefix + 1) begin
            step(1, 0);
            for (int i = 0; i < prefix; i = i + 1)
                step(0, PATTERN[DATA_WIDTH-1-i]);
            step(1, 1);
            send_pattern;
        end

        // Flip each pattern bit to test near matches
        for (int wrong = 0; wrong < DATA_WIDTH; wrong = wrong + 1) begin
            step(1, 0);
            for (int i = DATA_WIDTH - 1; i >= 0; i = i - 1)
                step(0, PATTERN[i] ^ (i == wrong));
            send_pattern;
        end

        // Overlapping matches
        if (DATA_WIDTH <= 4) begin
            for (stream = 0; stream < (1 << (2 * DATA_WIDTH)); stream = stream + 1) begin
                step(1, 0);
                for (int i = 2 * DATA_WIDTH - 1; i >= 0; i = i - 1)
                    step(0, (stream >> i) & 1);
            end
        end

        // Long streams of randomized vectors
        step(1, 0);
        for (int i = 0; i < 2048; i = i + 1) begin
            random_state = random_state ^ (random_state << 13);
            random_state = random_state ^ (random_state >> 17);
            random_state = random_state ^ (random_state << 5);
            step((i % 173) == 172, random_state[0]);
        end

        $display("PASS width=%0d pattern=%b checks=%0d", DATA_WIDTH, PATTERN, checks);
        done = 1;
    end
endmodule

module fsm_tb;
    logic clk = 0;
    logic [6:0] done;
    always #5 clk = ~clk;

    // Test across different pattern lengths and patterns
    fsm_checker #(.DATA_WIDTH(1), .PATTERN(1'b0))        zero_bit (clk, done[0]);
    fsm_checker #(.DATA_WIDTH(1), .PATTERN(1'b1))        one_bit  (clk, done[1]);
    fsm_checker #(.DATA_WIDTH(3), .PATTERN(3'b101))      overlap  (clk, done[2]);
    fsm_checker #(.DATA_WIDTH(4), .PATTERN(4'b1111))     ones     (clk, done[3]);
    fsm_checker #(.DATA_WIDTH(4), .PATTERN(4'b0000))     zeros    (clk, done[4]);
    fsm_checker #(.DATA_WIDTH(4), .PATTERN(4'b0010))     leading_zeros (clk, done[5]);
    fsm_checker #(.DATA_WIDTH(8), .PATTERN(8'b10011001)) wider    (clk, done[6]);

    initial begin
        wait (&done);
        $display("All FSM checks passed.");
        $finish;
    end

    initial begin
        #200000;
        $fatal(1, "FSM testbench timed out");
    end
endmodule
