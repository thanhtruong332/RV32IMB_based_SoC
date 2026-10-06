`timescale 1ns / 1ps
// Portable hardware regression (RV32IMB_based_SoC): CBC_256B hardware AES payload scaling.
// Raw timing window: first plaintext AXI AW handshake -> final BRAM W handshake.
// The firmware runs three complete messages. Each message loads key and IV/counter
// once, keeps CBC/CFB feedback or CTR counter continuous, and never writes CTRL=0.
module tb_hw_rv32imb_CBC_256B;
    localparam integer BLOCK_COUNT = 16;
    localparam integer PAYLOAD_BYTES = 256;
    localparam integer WORDS_PER_MESSAGE = 4 * BLOCK_COUNT;
    localparam integer REPEAT_COUNT = 3;
    localparam [1:0] EXPECTED_MODE = 2'd1;
    localparam integer EXPECTED_IV_WORD_WRITES = 4;
    localparam [127:0] EXPECTED_KEY = 128'h404142434445464748494a4b4c4d4e4f;

    reg clk_in1_0;
    reg reset_0;
    reg uart_rx;
    wire uart_tx;
    reg monitor_enable;

    initial clk_in1_0 = 1'b0;
    always #5 clk_in1_0 = ~clk_in1_0;

    design_1_wrapper uut (
        .clk_in1_0(clk_in1_0),
        .reset_0(reset_0),
        .rx_0(uart_rx),
        .tx_0(uart_tx)
    );

    wire soc_clk = uut.design_1_i.clk_wiz_0.clk_out1;

    // Firmware is selected through scripts/run_test.tcl and the matching COE file.

    initial begin
        uart_rx = 1'b1;
        reset_0 = 1'b1;
        monitor_enable = 1'b0;
        force uut.design_1_i.clk_wiz_0.locked = 1'b1;
        #300 reset_0 = 1'b0;
        monitor_enable = 1'b1;
    end

    // AES wrapper signals used for correctness and state-continuity checks.
    wire [127:0] key_reg = uut.design_1_i.AES_hardware_final_0.inst.aes_inst.key_reg;
    wire [127:0] data_in_reg = uut.design_1_i.AES_hardware_final_0.inst.aes_inst.data_in_reg;
    wire [127:0] state_in_reg = uut.design_1_i.AES_hardware_final_0.inst.aes_inst.iv_reg;
    wire [127:0] data_out_reg = uut.design_1_i.AES_hardware_final_0.inst.aes_inst.data_out_reg;
    wire [1:0] mode_reg = uut.design_1_i.AES_hardware_final_0.inst.aes_inst.mode_reg;
    wire start_pulse = uut.design_1_i.AES_hardware_final_0.inst.aes_inst.start_pulse;
    wire core_done_tick = uut.design_1_i.AES_hardware_final_0.inst.aes_inst.core_done_tick;

    // AES AXI-Lite monitor.
    wire [31:0] aes_awaddr = uut.design_1_i.AES_hardware_final_0.inst.S_AXI_AWADDR;
    wire aes_awvalid = uut.design_1_i.AES_hardware_final_0.inst.S_AXI_AWVALID;
    wire aes_awready = uut.design_1_i.AES_hardware_final_0.inst.S_AXI_AWREADY;
    wire [31:0] aes_wdata = uut.design_1_i.AES_hardware_final_0.inst.S_AXI_WDATA;
    wire aes_wvalid = uut.design_1_i.AES_hardware_final_0.inst.S_AXI_WVALID;
    wire aes_wready = uut.design_1_i.AES_hardware_final_0.inst.S_AXI_WREADY;
    wire [31:0] aes_araddr = uut.design_1_i.AES_hardware_final_0.inst.S_AXI_ARADDR;
    wire aes_arvalid = uut.design_1_i.AES_hardware_final_0.inst.S_AXI_ARVALID;
    wire aes_arready = uut.design_1_i.AES_hardware_final_0.inst.S_AXI_ARREADY;
    wire [31:0] aes_rdata = uut.design_1_i.AES_hardware_final_0.inst.S_AXI_RDATA;
    wire aes_rvalid = uut.design_1_i.AES_hardware_final_0.inst.S_AXI_RVALID;
    wire aes_rready = uut.design_1_i.AES_hardware_final_0.inst.S_AXI_RREADY;

    // BRAM writeback endpoint; the final W handshake closes the raw window.
    wire bram_awvalid = uut.design_1_i.axi_bram_ctrl_0.s_axi_awvalid;
    wire bram_awready = uut.design_1_i.axi_bram_ctrl_0.s_axi_awready;
    wire [31:0] bram_wdata = uut.design_1_i.axi_bram_ctrl_0.s_axi_wdata;
    wire bram_wvalid = uut.design_1_i.axi_bram_ctrl_0.s_axi_wvalid;
    wire bram_wready = uut.design_1_i.axi_bram_ctrl_0.s_axi_wready;

    reg [31:0] expected_ct_word [0:WORDS_PER_MESSAGE-1];
    reg [127:0] expected_state [0:BLOCK_COUNT-1];
    reg [127:0] expected_plaintext [0:BLOCK_COUNT-1];
    initial begin
        $readmemh("CBC_256B_ciphertext_words.hex", expected_ct_word);
        $readmemh("CBC_256B_state_blocks.hex", expected_state);
        $readmemh("CBC_256B_plaintext_blocks.hex", expected_plaintext);
    end

    reg [63:0] cycle_counter;
    reg [63:0] counter_start [0:REPEAT_COUNT-1];
    reg [63:0] counter_stop [0:REPEAT_COUNT-1];
    reg [63:0] raw_cycles [0:REPEAT_COUNT-1];
    reg [63:0] first_ct_cycle [0:REPEAT_COUNT-1];
    reg [127:0] observed_state_first;
    reg [127:0] observed_state_last;
    reg [31:0] read_addr_q;

    // These scalar aliases are intended for clear waveform screenshots.
    wire [63:0] raw_counter_start_r1 = counter_start[0];
    wire [63:0] raw_counter_stop_r1 = counter_stop[0];
    wire [63:0] raw_cycles_r1 = raw_cycles[0];
    wire [63:0] raw_counter_start_r2 = counter_start[1];
    wire [63:0] raw_counter_stop_r2 = counter_stop[1];
    wire [63:0] raw_cycles_r2 = raw_cycles[1];
    wire [63:0] raw_counter_start_r3 = counter_start[2];
    wire [63:0] raw_counter_stop_r3 = counter_stop[2];
    wire [63:0] raw_cycles_r3 = raw_cycles[2];
    wire [127:0] state_entering_aes_block1 = observed_state_first;
    wire [127:0] state_entering_aes_last_block = observed_state_last;

    integer repeat_number;
    integer block_start_count;
    integer block_done_count;
    integer bram_word_count;
    integer errors_this_repeat;
    integer key_word_writes;
    integer iv_word_writes;
    integer ctrl_zero_writes;
    integer reset_between_blocks;
    integer aes_aw_total;
    integer aes_ar_total;
    integer status_reads_total;
    integer bram_aw_total;
    integer bram_w_total;
    integer aes_aw_at_start;
    integer aes_ar_at_start;
    integer status_at_start;
    integer bram_aw_at_start;
    integer bram_w_at_start;
    integer core_start_cycle;
    integer observed_core_cycles;
    integer result_file;
    integer state_file;
    integer i;
    reg message_active;
    reg all_repeats_pass;

    task finish_repeat;
        integer idx;
        integer repeat_pass;
        begin
            idx = repeat_number - 1;
            counter_stop[idx] = cycle_counter;
            raw_cycles[idx] = counter_stop[idx] - counter_start[idx];
            repeat_pass = 1;
            if (block_start_count != BLOCK_COUNT) repeat_pass = 0;
            if (block_done_count != BLOCK_COUNT) repeat_pass = 0;
            if (bram_word_count != WORDS_PER_MESSAGE) repeat_pass = 0;
            if (key_word_writes != 4) repeat_pass = 0;
            if (iv_word_writes != EXPECTED_IV_WORD_WRITES) repeat_pass = 0;
            if (ctrl_zero_writes != 0) repeat_pass = 0;
            if (reset_between_blocks != 0) repeat_pass = 0;
            if (errors_this_repeat != 0) repeat_pass = 0;
            if ((repeat_number > 1) && (raw_cycles[idx] != raw_cycles[0]))
                repeat_pass = 0;
            if (!repeat_pass) all_repeats_pass = 1'b0;

            $fdisplay(result_file,
              "CBC_256B,CBC,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0s",
              repeat_number, PAYLOAD_BYTES, BLOCK_COUNT,
              counter_start[idx], counter_stop[idx], raw_cycles[idx],
              first_ct_cycle[idx] - counter_start[idx], raw_cycles[idx],
              16*BLOCK_COUNT, observed_core_cycles,
              status_reads_total-status_at_start,
              aes_aw_total-aes_aw_at_start, aes_ar_total-aes_ar_at_start,
              bram_w_total-bram_w_at_start,
              (aes_aw_total-aes_aw_at_start)+(aes_ar_total-aes_ar_at_start)+
              (bram_w_total-bram_w_at_start),
              bram_aw_total-bram_aw_at_start,
              key_word_writes, iv_word_writes,
              repeat_pass ? "PASS" : "FAIL");
            $display("[EXP C] CBC_256B repeat=%0d start=%0d stop=%0d raw=%0d result=%s",
              repeat_number, counter_start[idx], counter_stop[idx], raw_cycles[idx],
              repeat_pass ? "PASS" : "FAIL");

            message_active = 1'b0;
            block_start_count = 0;
            block_done_count = 0;
            bram_word_count = 0;
            errors_this_repeat = 0;
            key_word_writes = 0;
            iv_word_writes = 0;
            ctrl_zero_writes = 0;
            reset_between_blocks = 0;
            observed_core_cycles = 0;

            if (repeat_number == REPEAT_COUNT) begin
                $display("[EXP C] CBC_256B FINAL=%s raw R1/R2/R3=%0d/%0d/%0d",
                  all_repeats_pass && repeat_pass ? "PASS" : "FAIL",
                  raw_cycles[0], raw_cycles[1], raw_cycles[2]);
                $fclose(result_file);
                $fclose(state_file);
                #50 $finish;
            end
        end
    endtask

    initial begin
        cycle_counter = 0;
        repeat_number = 0;
        block_start_count = 0;
        block_done_count = 0;
        bram_word_count = 0;
        errors_this_repeat = 0;
        key_word_writes = 0;
        iv_word_writes = 0;
        ctrl_zero_writes = 0;
        reset_between_blocks = 0;
        aes_aw_total = 0;
        aes_ar_total = 0;
        status_reads_total = 0;
        bram_aw_total = 0;
        bram_w_total = 0;
        observed_core_cycles = 0;
        message_active = 1'b0;
        all_repeats_pass = 1'b1;
        read_addr_q = 0;
        observed_state_first = 0;
        observed_state_last = 0;
        for (i=0; i<REPEAT_COUNT; i=i+1) begin
            counter_start[i] = 0;
            counter_stop[i] = 0;
            raw_cycles[i] = 0;
            first_ct_cycle[i] = 0;
        end
        result_file = $fopen("hardware_rv32imb_CBC_256B_results.csv", "w");
        state_file = $fopen("hardware_rv32imb_CBC_256B_state.csv", "w");
        $fdisplay(result_file,
          "case,mode,repeat,payload_bytes,number_of_blocks,counter_start,counter_stop,exact_integer_cycle_count,pt_to_ct_cycles,pt_to_bram_total_cycles,aes_core_cycles,aes_internal_cycles_observed,number_of_polls,aes_write_transactions,aes_read_transactions,bram_write_transactions,axi_transactions_total,bram_aw_handshakes,key_word_writes,iv_counter_word_writes,result");
        $fdisplay(state_file,
          "case,mode,repeat,block,expected_state_entering_aes,observed_state_entering_aes,result");
    end

    always @(posedge soc_clk) begin
        if (monitor_enable) begin
            cycle_counter = cycle_counter + 1;

            if (aes_awvalid && aes_awready) begin
                aes_aw_total = aes_aw_total + 1;
                if ((aes_awaddr >= 32'h40000010) && (aes_awaddr <= 32'h4000001c))
                    key_word_writes = key_word_writes + 1;
                if ((aes_awaddr >= 32'h40000040) && (aes_awaddr <= 32'h4000004c))
                    iv_word_writes = iv_word_writes + 1;
                if ((aes_awaddr == 32'h40000020) && aes_wvalid && aes_wready &&
                    (aes_wdata == 32'h00000000))
                    ctrl_zero_writes = ctrl_zero_writes + 1;

                // The first plaintext word is the exact raw counter start.
                if ((aes_awaddr == 32'h40000000) && !message_active) begin
                    repeat_number = repeat_number + 1;
                    message_active = 1'b1;
                    counter_start[repeat_number-1] = cycle_counter;
                    first_ct_cycle[repeat_number-1] = 0;
                    // Include this first plaintext AW handshake in the window count.
                    aes_aw_at_start = aes_aw_total - 1;
                    aes_ar_at_start = aes_ar_total;
                    status_at_start = status_reads_total;
                    bram_aw_at_start = bram_aw_total;
                    bram_w_at_start = bram_w_total;
                end
            end

            if (aes_arvalid && aes_arready) begin
                aes_ar_total = aes_ar_total + 1;
                read_addr_q = aes_araddr;
                if (aes_araddr == 32'h40000024)
                    status_reads_total = status_reads_total + 1;
            end

            if (aes_rvalid && aes_rready && message_active &&
                (read_addr_q == 32'h4000003c) &&
                (first_ct_cycle[repeat_number-1] == 0))
                first_ct_cycle[repeat_number-1] = cycle_counter;

            if (message_active && reset_0)
                reset_between_blocks = 1;

            if (start_pulse && message_active) begin
                if (block_start_count < BLOCK_COUNT) begin
                    if (block_start_count == 0)
                        observed_state_first = state_in_reg;
                    if (block_start_count == BLOCK_COUNT-1)
                        observed_state_last = state_in_reg;
                    if (key_reg !== EXPECTED_KEY) errors_this_repeat = errors_this_repeat + 1;
                    if (data_in_reg !== expected_plaintext[block_start_count])
                        errors_this_repeat = errors_this_repeat + 1;
                    if (mode_reg !== EXPECTED_MODE) errors_this_repeat = errors_this_repeat + 1;
                    if (state_in_reg !== expected_state[block_start_count])
                        errors_this_repeat = errors_this_repeat + 1;
                    $fdisplay(state_file, "CBC_256B,CBC,%0d,%0d,%032x,%032x,%0s",
                      repeat_number, block_start_count+1,
                      expected_state[block_start_count], state_in_reg,
                      (state_in_reg === expected_state[block_start_count]) ? "PASS" : "FAIL");
                    block_start_count = block_start_count + 1;
                    core_start_cycle = cycle_counter;
                end else begin
                    errors_this_repeat = errors_this_repeat + 1;
                end
            end

            if (core_done_tick && message_active) begin
                block_done_count = block_done_count + 1;
                observed_core_cycles = observed_core_cycles + (cycle_counter-core_start_cycle);
            end

            if (bram_awvalid && bram_awready)
                bram_aw_total = bram_aw_total + 1;

            if (bram_wvalid && bram_wready) begin
                bram_w_total = bram_w_total + 1;
                if (message_active) begin
                    if (bram_wdata !== expected_ct_word[bram_word_count])
                        errors_this_repeat = errors_this_repeat + 1;
                    bram_word_count = bram_word_count + 1;
                    if (bram_word_count == WORDS_PER_MESSAGE)
                        finish_repeat;
                end
            end

            if (cycle_counter == 64'd600000) begin
                $display("[EXP C] CBC_256B TIMEOUT repeat=%0d blocks=%0d words=%0d",
                  repeat_number, block_start_count, bram_word_count);
                $fclose(result_file);
                $fclose(state_file);
                $finish;
            end
        end
    end
endmodule
