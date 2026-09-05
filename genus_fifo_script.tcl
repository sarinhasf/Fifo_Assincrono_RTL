#==========================================================
# Sintese da FIFO assincrona (aFifo) - Cadence Genus
# Corner Slow, analise de setup.
#==========================================================

set_db init_lib_search_path ../LIB/
set_db init_hdl_search_path ../RTL/

read_libs slow_vdd1v0_basicCells.lib

# Erro caso algum latch seja inferido (requisito do laboratorio).
set_db hdl_error_on_latch true

read_hdl { GrayCounter.v Synchronizer.v aFifo.v }
elaborate aFifo

read_sdc ../constraints/constraints_aFifo.sdc

# Timing lint: confirma que nao ha caminhos funcionais de setup sem constraint.
check_timing_intent > outputs/aFifo_timing_lint_pre.rpt

set_db syn_generic_effort medium
syn_generic
set_db syn_map_effort medium
syn_map
set_db syn_opt_effort medium
syn_opt

#----------------------------------------------------------
# Relatorios
#----------------------------------------------------------
check_timing_intent            > outputs/aFifo_timing_lint.rpt
report_area                    > outputs/aFifo_area.rpt
report_gates                   > outputs/aFifo_gates.rpt
report_power                   > outputs/aFifo_power.rpt
report_qor                     > outputs/aFifo_qor.rpt

# WNS/TNS e pior caminho por dominio de clock (somente setup).
report_timing -late -to [all_registers] -max_paths 10   > outputs/aFifo_timing_all.rpt
report_timing -late -group WClk -max_paths 10           > outputs/aFifo_timing_WClk.rpt
report_timing -late -group RClk -max_paths 10           > outputs/aFifo_timing_RClk.rpt
report_timing -late -summary                            > outputs/aFifo_timing_summary.rpt

# Classificacao in2reg / reg2reg / reg2out.
report_timing -late -from [all_inputs]  -to [all_registers] -max_paths 5 > outputs/aFifo_in2reg.rpt
report_timing -late -from [all_registers] -to [all_registers] -max_paths 5 > outputs/aFifo_reg2reg.rpt
report_timing -late -from [all_registers] -to [all_outputs] -max_paths 5 > outputs/aFifo_reg2out.rpt

# Registradores dos dois sincronizadores de ponteiro Gray.
report_instance -hierarchical  > outputs/aFifo_instances.rpt

#----------------------------------------------------------
# Saidas
#----------------------------------------------------------
write_hdl > outputs/aFifo_netlist.v
write_sdc > outputs/aFifo_sdc.sdc
write_sdf -nonegchecks -edges check_edge -timescale ns -recrem split -setuphold split > outputs/aFifo_delays.sdf
