if {$argc != 1} {
    error "Usage: vivado -mode batch -source scripts/run_test.tcl -tclargs <MODE_PAYLOAD>"
}
set ::env(HW_TEST_CASE) [lindex $argv 0]
source [file join [file dirname [info script]] create_project.tcl]
launch_simulation
run all
close_sim
