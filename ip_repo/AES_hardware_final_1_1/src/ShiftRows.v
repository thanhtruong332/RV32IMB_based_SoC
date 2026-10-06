module ShiftRows (
    input [127:0]  data_in,
    output [127:0] data_out
);
    // Row 0: Bytes 0, 4, 8, 12 (Không đổi)
    assign data_out[127:120] = data_in[127:120]; // B0
    assign data_out[95:88]   = data_in[95:88];   // B4
    assign data_out[63:56]   = data_in[63:56];   // B8
    assign data_out[31:24]   = data_in[31:24];   // B12

    // Row 1: Bytes 1, 5, 9, 13 (Dịch trái 1) -> 5, 9, 13, 1
    assign data_out[119:112] = data_in[87:80];   // B1_out = B5_in
    assign data_out[87:80]   = data_in[55:48];   // B5_out = B9_in
    assign data_out[55:48]   = data_in[23:16];   // B9_out = B13_in
    assign data_out[23:16]   = data_in[119:112]; // B13_out = B1_in

    // Row 2: Bytes 2, 6, 10, 14 (Dịch trái 2) -> 10, 14, 2, 6
    assign data_out[111:104] = data_in[47:40];   // B2_out = B10_in
    assign data_out[79:72]   = data_in[15:8];    // B6_out = B14_in
    assign data_out[47:40]   = data_in[111:104]; // B10_out = B2_in
    assign data_out[15:8]    = data_in[79:72];   // B14_out = B6_in

    // Row 3: Bytes 3, 7, 11, 15 (Dịch trái 3) -> 15, 3, 7, 11
    assign data_out[103:96]  = data_in[7:0];     // B3_out = B15_in
    assign data_out[71:64]   = data_in[103:96];  // B7_out = B3_in
    assign data_out[39:32]   = data_in[71:64];   // B11_out = B7_in
    assign data_out[7:0]     = data_in[39:32];   // B15_out = B11_in
endmodule
