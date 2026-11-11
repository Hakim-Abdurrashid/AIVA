// Detects PATTERN in a serial stream, MSB first.
module fsm #(
    parameter int unsigned DATA_WIDTH = 8,
    parameter logic [DATA_WIDTH-1:0] PATTERN = '1
) (
    input  logic clk,       // Clock
    input  logic rst,       // Active-high synchronous reset.
    input  logic data_in,   // One bit is consumed on each rising edge.
    output logic detected   // High after an edge that completes a match.
);
    // STATE_WIDTH is large enough to hold 0 - DATA_WIDTH
    localparam int unsigned STATE_WIDTH = (DATA_WIDTH < 2) ? 1 : $clog2(DATA_WIDTH + 1);

    // State Registers
    logic [STATE_WIDTH-1:0] state;
    logic [STATE_WIDTH-1:0] next_state;

    // Defines if a candidate match is valid
    logic prefix_match;

    always_comb begin
        next_state = '0;
        prefix_match = 1'b0;

        // Try each prefix length and retain the longest match, including overlaps.
        for (int length = 1; length <= DATA_WIDTH; length++) begin
            // State can only increment by 1
            prefix_match = (length <= int'(state) + 1);

            for (int index = 0; index < DATA_WIDTH; index++) begin
                if (index == length - 1) begin
                    // Compare new input bit
                    prefix_match = prefix_match && (data_in == PATTERN[DATA_WIDTH-1-index]);
                end else if (index < length && length <= int'(state) + 1) begin
                    // Compare earlier bits with the previously matched prefix. (overlaps)
                    prefix_match = prefix_match &&
                        (PATTERN[DATA_WIDTH - 1 - (int'(state) - (length - 1) + index)] ==
                         PATTERN[DATA_WIDTH - 1 - index]);
                end
            end

            // Keep longest subsequence match
            if (prefix_match) begin
                next_state = STATE_WIDTH'(length);
            end
        end
    end

    // Synchronous state transition
    always_ff @(posedge clk) begin
        if (rst) begin
            state <= '0;
        end else begin
            state <= next_state;
        end
    end

    assign detected = (state == STATE_WIDTH'(DATA_WIDTH));

endmodule
