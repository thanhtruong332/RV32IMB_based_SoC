# ==============================================================
# 1. CẤU HÌNH CHÂN XUNG NHỊP (CLOCK) VÀ RESET
# ==============================================================
set_property PACKAGE_PIN Y9 [get_ports clk_in1_0]
set_property IOSTANDARD LVCMOS33 [get_ports clk_in1_0]

set_property PACKAGE_PIN N15 [get_ports reset_0]
set_property IOSTANDARD LVCMOS25 [get_ports reset_0]

# ==============================================================
# 2. CẤU HÌNH CHÂN UART (PMOD)
# ==============================================================
set_property PACKAGE_PIN Y11 [get_ports rx_0]
set_property IOSTANDARD LVCMOS33 [get_ports rx_0]

set_property PACKAGE_PIN AA11 [get_ports tx_0]
set_property IOSTANDARD LVCMOS33 [get_ports tx_0]

# ==============================================================
# 3. IGNORE TIMING TRÊN CHÂN RESET (Để tránh cảnh báo)
# ==============================================================
set_false_path -from [get_ports reset_0]

# ==============================================================
# 4. MULTICYCLE PATH - AES key_reg → state_reg
# ==============================================================
set _xlnx_shared_i0 [get_cells {design_1_i/AES_hardware_final_0/inst/aes_inst/key_reg_reg[*]}]
set _xlnx_shared_i1 [get_cells {design_1_i/AES_hardware_final_0/inst/aes_inst/aes_core_inst/state_reg_reg[*]}]
set_multicycle_path -setup -from $_xlnx_shared_i0 -to $_xlnx_shared_i1 2
set_multicycle_path -hold -from $_xlnx_shared_i0 -to $_xlnx_shared_i1 1

set_operating_conditions -grade extended