# Usage: vivado -mode batch -source report_power_from_saif.tcl \
#          -tclargs routed.dcp activity.saif output_directory report_stem strip_path
if {$argc != 5} {
  error "Expected: <routed.dcp> <activity.saif> <output_directory> <report_stem> <strip_path>"
}
lassign $argv dcp saif out_dir stem strip_path
file mkdir $out_dir
open_checkpoint $dcp
report_power -file [file join $out_dir ${stem}_power_vectorless.rpt]
read_saif -strip_path $strip_path $saif
report_power -advisory -file [file join $out_dir ${stem}_power_saif.rpt]
report_switching_activity -file [file join $out_dir ${stem}_switching_activity.rpt] [get_nets -hier]
report_timing_summary -file [file join $out_dir ${stem}_timing_summary.rpt]
report_utilization -file [file join $out_dir ${stem}_utilization.rpt]
exit
