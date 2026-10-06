set script_dir [file normalize [file dirname [info script]]]
set repo_root [file normalize [file join $script_dir ..]]
set build_dir [file join $repo_root build]
file delete -force $build_dir
file mkdir $build_dir
create_project RV32IMB_based_SoC [file join $build_dir RV32IMB_based_SoC] -part xc7z020clg484-2 -force
set_property target_language Verilog [current_project]
set ip_repositories [list \
    [file join $repo_root ip_repo rv32imb_ultra_1_0] \
    [file join $repo_root ip_repo AES_hardware_final_1_1]]
set_property ip_repo_paths $ip_repositories [current_project]
update_ip_catalog -rebuild
set hw_test_case ""
if {[info exists ::env(HW_TEST_CASE)]} {
    set hw_test_case $::env(HW_TEST_CASE)
}
set source_design_dir [file join $repo_root design design_1]
if {$hw_test_case ne ""} {
    set test_design_dir [file join $build_dir design_copy design_1]
    file delete -force $test_design_dir
    file mkdir [file dirname $test_design_dir]
    file copy -force $source_design_dir $test_design_dir
    set bd_file [file join $test_design_dir design_1.bd]
} else {
    set bd_file [file join $source_design_dir design_1.bd]
}
add_files -norecurse $bd_file
add_files -fileset constrs_1 -norecurse [file join $repo_root constraints zedboard.xdc]
update_compile_order -fileset sources_1
open_bd_design [get_files [file tail $bd_file]]
if {$hw_test_case ne ""} {
    set firmware_coe [file normalize [file join $repo_root firmware images "${hw_test_case}.coe"]]
    if {![file exists $firmware_coe]} {
        error "Unknown hardware test case '$hw_test_case': $firmware_coe does not exist"
    }
    set_property CONFIG.coefficient_file $firmware_coe [get_bd_cells dist_mem_gen_0]
    puts "HARDWARE_TEST_CASE=$hw_test_case"
    puts "FIRMWARE_COE=$firmware_coe"
}
validate_bd_design
save_bd_design
generate_target all [get_files [file tail $bd_file]]
set wrapper [make_wrapper -files [get_files [file tail $bd_file]] -top]
add_files -norecurse $wrapper
set simulation_files [glob -nocomplain [file join $repo_root sim *.v]]
if {[llength $simulation_files] > 0} {
    add_files -fileset sim_1 $simulation_files
}
set expected_files [glob -nocomplain [file join $repo_root expected *.hex]]
if {[llength $expected_files] > 0} {
    add_files -fileset sim_1 $expected_files
}
update_compile_order -fileset sources_1
if {$hw_test_case ne ""} {
    set_property top "tb_hw_rv32imb_${hw_test_case}" [get_filesets sim_1]
    update_compile_order -fileset sim_1
    puts "SIM_TOP=[get_property TOP [get_filesets sim_1]]"
}
puts "PORTABLE_PROJECT=[get_property DIRECTORY [current_project]]"
puts "PART=[get_property PART [current_project]]"
puts "CUSTOM_IPS=xilinx.com:user:rv32imb_ultra:1.0,xilinx.com:user:AES_hardware_final:1.1"
