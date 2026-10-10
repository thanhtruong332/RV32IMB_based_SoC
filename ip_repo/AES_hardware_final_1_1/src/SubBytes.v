module SubBytes (
    input [127:0]  data_in,
    output [127:0] data_out
);
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin: SubTableLoop

            SubTable subtable_inst (
                .data_in (data_in [127 - 8*i -: 8]),
                .data_out(data_out[127 - 8*i -: 8])
            );
        end
    endgenerate
endmodule
