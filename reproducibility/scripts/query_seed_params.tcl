puts "EXP_E_SEED_PARAMS_BEGIN"
foreach p [lsort [list_param]] {
  if {[regexp -nocase {seed|random} $p]} {
    set value ""
    catch {set value [get_param $p]}
    puts "$p=$value"
  }
}
puts "EXP_E_SEED_PARAMS_END"
puts "EXP_E_PLACE_ARGS_BEGIN"
help place_design -args
puts "EXP_E_PLACE_ARGS_END"
puts "EXP_E_ROUTE_ARGS_BEGIN"
help route_design -args
puts "EXP_E_ROUTE_ARGS_END"
exit
