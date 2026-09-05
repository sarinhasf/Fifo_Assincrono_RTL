set_db init_lib_search_path ../LIB/
set_db init_hdl_search_path ../RTL/
read_libs slow_vdd1v0_basicCells.lib

# Erro caso algum latch seja inferido (requisito do laboratorio).
set_db hdl_error_on_latch true

read_hdl {aFifo.v GrayCounter.v Synchronizer.v}
elaborate aFifo
read_sdc ../constraints/constraints_aFifo.sdc

# Timing lint: confirma que nao ha caminho funcional de setup sem constraint.
check_timing_intent

set_db syn_generic_effort medium
syn_generic
set_db syn_map_effort medium
syn_map
set_db syn_opt_effort medium
syn_opt

syn_opt -incremental

write_hdl > outputs/aFifo_netlist.v
write_sdc > outputs/aFifo_sdc.sdc
write_sdf -nonegchecks -edges check_edge -timescale ns -recrem split  -setuphold split > outputs/aFifo_delays.sdf

#################################
### Reports
#################################
report_timing > reports/report_timing.rpt
report_power  > reports/report_power.rpt
report_area   > reports/report_area.rpt
report_qor    > reports/report_qor.rpt

### Opcionais para as respostas do item 4 (WNS/TNS por dominio de clock):
#report_timing -group WClk -max_paths 10 > reports/report_timing_WClk.rpt
#report_timing -group RClk -max_paths 10 > reports/report_timing_RClk.rpt
