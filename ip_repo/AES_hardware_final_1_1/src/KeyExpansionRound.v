module KeyExpansionRound (
    input [3:0]    round_count,
    input [127:0]  key_in,
    output [127:0] key_out
);
    genvar i;
    wire [31:0] words [3:0];

    generate
        for (i = 0; i < 4; i = i + 1) begin: KeySplitLoop
            assign words[i] = key_in[127 - i * 32 -: 32];
        end
    endgenerate

    // words[0] = key_in[127:96] = W0 (MSB)
    // words[1] = key_in[95:64]  = W1
    // words[2] = key_in[63:32]  = W2
    // words[3] = key_in[31:0]   = W3 (LSB)

    wire [31:0] w3_rot = {words[3][23:0], words[3][31:24]};

    wire [31:0] w3_sub;
    generate
        for (i = 0; i < 4; i = i + 1) begin: SubWordLoop
            SubTable subtable_inst (
                .data_in(w3_rot[8 * i +: 8]),
                .data_out(w3_sub[8 * i +: 8])
            );
        end
    endgenerate

    wire [7:0] rcon_byte = round_count == 1  ? 8'h01 :
                           round_count == 2  ? 8'h02 :
                           round_count == 3  ? 8'h04 :
                           round_count == 4  ? 8'h08 :
                           round_count == 5  ? 8'h10 :
                           round_count == 6  ? 8'h20 :
                           round_count == 7  ? 8'h40 :
                           round_count == 8  ? 8'h80 :
                           round_count == 9  ? 8'h1b :
                           round_count == 10 ? 8'h36 : 8'h00;

    wire [31:0] rcon = {rcon_byte, 24'h000000};

    assign key_out[127:96] = words[0] ^ w3_sub ^ rcon;
    assign key_out[95:64]  = words[1] ^ key_out[127:96];
    assign key_out[63:32]  = words[2] ^ key_out[95:64];
    assign key_out[31:0]   = words[3] ^ key_out[63:32];

endmodule

module KeyExpansion (
    input [127:0]   key_in,
    output [1407:0] keys_out
);

    localparam Nk = 4;
    localparam Nr = 10;

    // FIXED: Assign input key to LOWEST bits (Round Key 0)
    // Old: assign keys_out[1407:1280] = key_in;
    // New: assign keys_out[127:0] = key_in;
    assign keys_out[127:0] = key_in;

    genvar i;
    generate
        // FIXED: Generate rounds 1-10 in correct order
        // Compute each round key from the previous one
        for (i = 0; i < 10; i = i + 1) begin: KeyExpansionRoundLoop
            KeyExpansionRound keyexp_round (
                .round_count(i[3:0] + 4'b0001),
                .key_in(keys_out[i * 128 +: 128]),           // Read from position i
                .key_out(keys_out[(i + 1) * 128 +: 128])    // Write to position i+1
            );
        end
    endgenerate

endmodule
