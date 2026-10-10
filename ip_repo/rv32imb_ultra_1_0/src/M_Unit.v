module M_Unit (
    input  wire        clk,
    input  wire [31:0] rs1,
    input  wire [31:0] rs2,
    input  wire [2:0]  funct3,
    output reg  [31:0] m_result
);

    wire signed [63:0] mul_signed   = $signed(rs1) * $signed(rs2);
    wire signed [63:0] mul_su       = $signed(rs1) * $signed({1'b0, rs2});
    wire        [63:0] mul_unsigned = rs1 * rs2;

    // Iterative state for multiplication and division operations.
    reg [63:0] qr;
    reg [31:0] d;
    reg [5:0]  count;
    reg [31:0] out_div, out_rem;
    reg [31:0] old_rs1, old_rs2;

    always @(posedge clk) begin
        // Start division when the CPU supplies a new operand pair.
        if (rs1 != old_rs1 || rs2 != old_rs2) begin
            qr <= {32'b0, rs1};
            d  <= rs2;
            count <= 32;
            old_rs1 <= rs1;
            old_rs2 <= rs2;
        end
        // Iterative shift-and-subtract division using one 32-bit subtractor.
        else if (count > 0) begin
            if (qr[62:31] >= d) begin
                qr <= { (qr[62:31] - d), qr[30:0], 1'b1 };
            end else begin
                qr <= { qr[62:31], qr[30:0], 1'b0 };
            end
            count <= count - 1;
        end

        else begin
            out_div <= (d == 0) ? 32'hFFFF_FFFF : qr[31:0];
            out_rem <= (d == 0) ? old_rs1 : qr[63:32];
        end
    end

    always @(*) begin
        case (funct3)
            3'b000: m_result = mul_signed[31:0];   // MUL
            3'b001: m_result = mul_signed[63:32];  // MULH
            3'b010: m_result = mul_su[63:32];      // MULHSU
            3'b011: m_result = mul_unsigned[63:32];// MULHU

            3'b100: m_result = out_div;
            3'b101: m_result = out_div;            // DIVU
            3'b110: m_result = out_rem;
            3'b111: m_result = out_rem;            // REMU
            default: m_result = 32'b0;
        endcase
    end
endmodule
