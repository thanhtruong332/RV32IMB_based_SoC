module MixColumns (
    input [127:0]  data_in,
    output [127:0] data_out
);
    function [7:0] xtime;
        input [7:0] in;
        xtime = (in[7]) ? (in << 1) ^ 8'h1B : (in << 1);
    endfunction

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin: col_loop

            wire [7:0] s0 = data_in[127 - 32*i -: 8];
            wire [7:0] s1 = data_in[119 - 32*i -: 8];
            wire [7:0] s2 = data_in[111 - 32*i -: 8];
            wire [7:0] s3 = data_in[103 - 32*i -: 8];

            assign data_out[127 - 32*i -: 8] = xtime(s0) ^ (xtime(s1)^s1) ^ s2 ^ s3;
            assign data_out[119 - 32*i -: 8] = s0 ^ xtime(s1) ^ (xtime(s2)^s2) ^ s3;
            assign data_out[111 - 32*i -: 8] = s0 ^ s1 ^ xtime(s2) ^ (xtime(s3)^s3);
            assign data_out[103 - 32*i -: 8] = (xtime(s0)^s0) ^ s1 ^ s2 ^ xtime(s3);
        end
    endgenerate
endmodule
