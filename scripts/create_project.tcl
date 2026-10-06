set script_dir [file normalize [file dirname [info script]]]
set repo_root [file normalize [file join $script_dir ..]]
set build_dir [file join $repo_root build]
create_project RV32IMB_based_SoC [file join $build_dir RV32IMB_based_SoC] -part xc7z020clg484-2 -force
set_property target_language Verilog [current_project]
set ip_repositories [list \
    [file join $repo_root ip_repo rv32imb_ultra_1_0] \
    [file join $repo_root ip_repo AES_hardware_final_1_1]]
set_property ip_repo_paths $ip_repositories [current_project]
update_ip_catalog -rebuild
set bd_file [file join $repo_root design design_1 design_1.bd]
add_files -norecurse $bd_file
add_files -fileset constrs_1 -norecurse [file join $repo_root constraints zedboard.xdc]
update_compile_order -fileset sources_1
open_bd_design [get_files [file tail $bd_file]]
validate_bd_design
save_bd_design
generate_target all [get_files [file tail $bd_file]]
set wrapper [make_wrapper -files [get_files [file tail $bd_file]] -top]
add_files -norecurse $wrapper
update_compile_order -fileset sources_1
puts "PORTABLE_PROJECT=[get_property DIRECTORY [current_project]]"
puts "PART=[get_property PART [current_project]]"
puts "CUSTOM_IPS=xilinx.com:user:rv32imb_ultra:1.0,xilinx.com:user:AES_hardware_final:1.1"
