module AddRoundKey (
    input [127:0]  state,
    input [127:0]  round_key,
    output [127:0] state_out
);

    assign state_out = state ^ round_key;

endmodule
