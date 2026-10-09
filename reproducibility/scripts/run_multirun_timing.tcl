# Usage: vivado -mode batch -source run_multirun_timing.tcl \
#          -tclargs project.xpr output_directory design_name parent_synthesis_run
if {$argc != 4} {
  error "Expected: <project.xpr> <output_directory> <design_name> <parent_synthesis_run>"
}
lassign $argv xpr out_root stem parent
file mkdir $out_root
open_project $xpr
if {[get_property PART [current_project]] ne {xc7z020clg484-2}} {
  error "$stem part mismatch: [get_property PART [current_project]]"
}
if {![llength [get_runs -quiet $parent]]} {
  error "Required synthesis run '$parent' is missing"
}
if {[get_property PROGRESS [get_runs $parent]] ne {100%}} {
  launch_runs $parent -jobs 4
  wait_on_run $parent
}
set impl_flow [get_property FLOW [get_runs impl_1]]
set constrset [get_property CONSTRSET [get_runs impl_1]]
set configs [list \
  [list expE_r1 {Vivado Implementation Defaults}] \
  [list expE_r2 {Performance_Explore}] \
  [list expE_r3 {Performance_ExplorePostRoutePhysOpt}] \
  [list expE_r4 {Performance_NetDelay_high}] \
  [list expE_r5 {Performance_RefinePlacement}]]
set run_names {}
foreach cfg $configs {
  lassign $cfg run_name strategy
  if {[llength [get_runs -quiet $run_name]]} { delete_runs [get_runs $run_name] }
  create_run $run_name -parent_run $parent -flow $impl_flow -strategy $strategy -constrset $constrset
  lappend run_names $run_name
}
set manifest [open [file join $out_root run_manifest.csv] w]
puts $manifest {design,run,strategy,part,parent_synthesis,constraint_set,clock_mhz}
foreach cfg $configs {
  lassign $cfg run_name strategy
  puts $manifest "$stem,$run_name,$strategy,[get_property PART [current_project]],$parent,$constrset,40"
}
close $manifest
launch_runs [get_runs [list expE_r1 expE_r2 expE_r4 expE_r5]] -to_step route_design -jobs 2
launch_runs [get_runs expE_r3] -to_step {phys_opt_design (Post-Route)} -jobs 2
foreach run_name $run_names {
  wait_on_run $run_name
  if {[get_property PROGRESS [get_runs $run_name]] ne {100%}} { continue }
  open_run $run_name
  set out [file join $out_root $run_name]
  file mkdir $out
  report_timing_summary -delay_type min_max -max_paths 10 -input_pins -file [file join $out timing_summary.rpt]
  report_utilization -file [file join $out utilization.rpt]
}
exit
