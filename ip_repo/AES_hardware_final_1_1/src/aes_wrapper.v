`timescale 1ns / 1ps

module aes_wrapper (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire [3:0]  wstrb,
    input  wire        read_en,
    input  wire        write_en,
    output reg  [31:0] rdata,
    output wire        ready
);

    // --- Memory Map Offset ---
    localparam REG_DATA_IN_0  = 8'h00, REG_DATA_IN_1  = 8'h04,
               REG_DATA_IN_2  = 8'h08, REG_DATA_IN_3  = 8'h0C,
               REG_KEY_0      = 8'h10, REG_KEY_1      = 8'h14,
               REG_KEY_2      = 8'h18, REG_KEY_3      = 8'h1C,
               REG_CONTROL    = 8'h20, REG_STATUS     = 8'h24,
               REG_DATA_OUT_0 = 8'h30, REG_DATA_OUT_1 = 8'h34,
               REG_DATA_OUT_2 = 8'h38, REG_DATA_OUT_3 = 8'h3C,
               REG_IV_0       = 8'h40, REG_IV_1       = 8'h44,
               REG_IV_2       = 8'h48, REG_IV_3       = 8'h4C;

    reg [127:0] data_in_reg;
    reg [127:0] key_reg;
    reg [127:0] iv_reg;
    reg [1:0]   mode_reg;
    reg [127:0] data_out_reg;
    reg         start_pulse;
    reg         aes_done_latched;

    assign ready = 1'b1;

    (* mark_debug = "true" *) wire [127:0] ILA_DATA_IN  = data_in_reg;
    (* mark_debug = "true" *) wire [127:0] ILA_KEY      = key_reg;
    (* mark_debug = "true" *) wire [127:0] ILA_IV       = iv_reg;
    (* mark_debug = "true" *) wire [127:0] ILA_DATA_OUT = data_out_reg;
    (* mark_debug = "true" *) wire         ILA_START    = start_pulse;
    (* mark_debug = "true" *) wire         ILA_DONE     = aes_done_latched;
    (* mark_debug = "true" *) wire [127:0] ILA_CORE_RAW_OUT;

    wire [1:0] core_mode_sel = mode_reg;
    wire [127:0] final_ciphertext;

    // --- 3. Write Logic & Auto-Update IV ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= 128'd0;
            key_reg     <= 128'd0;
            iv_reg      <= 128'd0;
            mode_reg    <= 2'b00;
            start_pulse <= 1'b0;
        end else begin
            start_pulse <= 1'b0;

            // Update the feedback state after each completed block.
            if (core_done_tick) begin
                if (mode_reg == 2'b01 || mode_reg == 2'b11) begin

                    iv_reg <= final_ciphertext;
                end
                else if (mode_reg == 2'b10) begin

                    iv_reg <= iv_reg + 128'd1;
                end
            end

            if (write_en) begin
                case (addr[7:0])
                    REG_DATA_IN_0: data_in_reg[127:96] <= wdata;
                    REG_DATA_IN_1: data_in_reg[95:64]  <= wdata;
                    REG_DATA_IN_2: data_in_reg[63:32]  <= wdata;
                    REG_DATA_IN_3: data_in_reg[31:0]   <= wdata;

                    REG_KEY_0:     key_reg[127:96]     <= wdata;
                    REG_KEY_1:     key_reg[95:64]      <= wdata;
                    REG_KEY_2:     key_reg[63:32]      <= wdata;
                    REG_KEY_3:     key_reg[31:0]       <= wdata;

                    REG_IV_0:      iv_reg[127:96]      <= wdata;
                    REG_IV_1:      iv_reg[95:64]       <= wdata;
                    REG_IV_2:      iv_reg[63:32]       <= wdata;
                    REG_IV_3:      iv_reg[31:0]        <= wdata;

                    REG_CONTROL: begin

                        start_pulse <= wdata[0];
                        mode_reg    <= wdata[2:1];
                    end
                endcase
            end
        end
    end

    wire [1407:0] expanded_keys;
    wire          core_done_tick;
    wire [127:0]  ecb_ciphertext;

    KeyExpansion key_exp_inst (.key_in(ILA_KEY), .keys_out(expanded_keys));

    //wire [127:0] data_to_core = (core_mode_sel == 2'b10 || core_mode_sel == 2'b11) ? ILA_IV :
                                //(core_mode_sel == 2'b01) ? (ILA_DATA_IN ^ ILA_IV) : ILA_DATA_IN;
    wire [127:0] data_to_core = ILA_DATA_IN;

    AESEncrypt aes_core_inst (
        .clk(clk),
        .reset(~rst_n),
        .enable(ILA_START),
        .mode_sel(core_mode_sel),
        .iv_in(ILA_IV),
        .data_in(data_to_core),
        .all_keys(expanded_keys),
        .data_out(ecb_ciphertext),
        .done_tick(core_done_tick)
    );

    //fix cho CTR
    //assign final_ciphertext = (core_mode_sel == 2'b10 || core_mode_sel == 2'b11) ? (ecb_ciphertext ^ ILA_DATA_IN) : ecb_ciphertext;
    // SUA THANH - lay truc tiep output cua core cho moi mode:
    assign final_ciphertext = ecb_ciphertext;
    assign ILA_CORE_RAW_OUT = ecb_ciphertext;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_reg     <= 128'd0;
            aes_done_latched <= 1'b0;
        end else begin
            if (core_done_tick) begin
                data_out_reg     <= final_ciphertext;
                aes_done_latched <= 1'b1;
            end else if (ILA_START) begin
                aes_done_latched <= 1'b0;
            end
        end
    end

    // --- 6. Read Logic ---
    always @(*) begin
        case (addr[7:0])
            REG_STATUS:     rdata = {31'b0, aes_done_latched};
            REG_DATA_OUT_0: rdata = data_out_reg[127:96];
            REG_DATA_OUT_1: rdata = data_out_reg[95:64];
            REG_DATA_OUT_2: rdata = data_out_reg[63:32];
            REG_DATA_OUT_3: rdata = data_out_reg[31:0];
            REG_IV_0:       rdata = iv_reg[127:96];
            REG_IV_1:       rdata = iv_reg[95:64];
            REG_IV_2:       rdata = iv_reg[63:32];
            REG_IV_3:       rdata = iv_reg[31:0];
            default:        rdata = 32'h0;
        endcase
    end
endmodule
