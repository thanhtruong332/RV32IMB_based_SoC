module AESEncrypt (
    input [127:0]   data_in,
    input [1407:0]  all_keys,  
    input [127:0]   iv_in,     
    input [1:0]     mode_sel,  // 00:ECB, 01:CBC, 10:CTR, 11:CFB
    output reg [127:0] data_out,
    output reg      done_tick, 
    input           clk,
    input           enable,    
    input           reset
);

    localparam Nr = 10;
    
    // Các trạng thái FSM
    localparam IDLE = 2'b00;
    localparam WORK = 2'b01;
    localparam DONE = 2'b10;

    reg [1:0] state, next_state;
    reg [3:0] round, next_round; 
    reg [127:0] state_reg, next_state_reg; 

    wire [127:0] subbyte_out;
    wire [127:0] shiftrow_out;
    wire [127:0] mixcol_out;
    wire [127:0] addroundkey_out;
    wire [127:0] current_key;
    wire [127:0] round_input;

    // --- 1. DATAPATH ---

    assign current_key = all_keys[round * 128 +: 128];

    SubBytes subbytes_inst (
        .data_in (state_reg),
        .data_out(subbyte_out)
    );

    ShiftRows shiftrows_inst (
        .data_in (subbyte_out),
        .data_out(shiftrow_out)
    );

    MixColumns mixcols_inst (
        .data_in (shiftrow_out),
        .data_out(mixcol_out)
    );

    assign round_input = (round == 10) ? shiftrow_out : mixcol_out;

    AddRoundKey addroundkey_inst (
        .state    (round_input),
        .round_key(current_key),
        .state_out(addroundkey_out)
    );

    // --- 2. STATE MACHINE (FSM) ---

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state     <= IDLE;
            round     <= 0;
            state_reg <= 128'd0;
            data_out  <= 128'd0;
            done_tick <= 0;
        end else begin
            state     <= next_state;
            round     <= next_round;
            state_reg <= next_state_reg;
            
            // Xử lý Output tùy Mode khi hoàn thành mã hóa
            if (state == DONE) begin
                if (mode_sel == 2'b10 || mode_sel == 2'b11) begin
                    // ⏱️ CTR & CFB: Output = Keystream ^ Plaintext
                    data_out <= state_reg ^ data_in; 
                end else begin
                    // 🔓 ECB & CBC: Output = Kết quả AES thuần
                    data_out <= state_reg;
                end
                done_tick <= 1;
            end else begin
                done_tick <= 0;
            end
        end
    end

    // Next State Logic
    always @(*) begin
        next_state = state;
        next_round = round;
        next_state_reg = state_reg;

        case (state)
            IDLE: begin
                if (enable) begin
                    // Xử lý Input tùy Mode trước khi đưa vào AES
                    if (mode_sel == 2'b01) begin
                        // 🔐 CBC: (Plaintext ^ IV) ^ Key0
                        next_state_reg = (data_in ^ iv_in) ^ all_keys[0 +: 128];
                    end 
                    else if (mode_sel == 2'b10 || mode_sel == 2'b11) begin
                        // ⏱️ CTR & CFB: IV_Counter ^ Key0 (Không nạp data_in)
                        next_state_reg = iv_in ^ all_keys[0 +: 128]; 
                    end 
                    else begin
                        // 🔓 ECB: Plaintext ^ Key0
                        next_state_reg = data_in ^ all_keys[0 +: 128];
                    end
                    
                    next_round = 1; 
                    next_state = WORK;
                end
            end

            WORK: begin
                next_state_reg = addroundkey_out;
                if (round == 10) begin
                    next_state = DONE;
                end else begin
                    next_round = round + 1;
                end
            end

            DONE: begin
                next_state = IDLE;
            end
        endcase
    end

endmodule
