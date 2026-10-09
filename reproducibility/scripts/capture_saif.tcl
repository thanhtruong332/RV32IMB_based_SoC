# Run inside an elaborated XSim session.
# Usage: source capture_saif.tcl; capture_saif output.saif /tb/uut/* 4250 1094050
proc capture_saif {output_path scope warmup_ns duration_ns} {
  run ${warmup_ns}ns
  open_saif $output_path
  log_saif [get_objects -r $scope]
  run ${duration_ns}ns
  close_saif
  puts "SAIF_CAPTURE_DONE path=$output_path warmup_ns=$warmup_ns duration_ns=$duration_ns"
}
