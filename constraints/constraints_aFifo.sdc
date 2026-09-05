#==========================================================
# SDC da FIFO assincrona (aFifo) - corner Slow, analise de setup
# Baseado na especificacao externa do Lab 10.
#==========================================================

set_units -capacitance 1pF -time 1ns

#----------------------------------------------------------
# Clocks (assincronos entre si)
#----------------------------------------------------------
# WClk: 100 MHz (T = 10 ns)
create_clock -name WClk -period 10.0 -waveform {0 5.0} [get_ports WClk]
# RClk: 80 MHz (T = 12,5 ns)
create_clock -name RClk -period 12.5 -waveform {0 6.25} [get_ports RClk]

# Transicao dos clocks: 0,10 ns
set_clock_transition -rise 0.10 [get_clocks WClk]
set_clock_transition -fall 0.10 [get_clocks WClk]
set_clock_transition -rise 0.10 [get_clocks RClk]
set_clock_transition -fall 0.10 [get_clocks RClk]

# Uncertainty de setup: 0,20 ns
set_clock_uncertainty -setup 0.20 [get_clocks WClk]
set_clock_uncertainty -setup 0.20 [get_clocks RClk]

# WClk e RClk sao assincronos: nao ha analise de setup entre os dominios.
# Os caminhos entre dominios existem apenas nos sincronizadores de dois
# flip-flops (double flopping), que nao devem ser analisados para setup.
set_clock_groups -asynchronous -group [get_clocks WClk] -group [get_clocks RClk]

#----------------------------------------------------------
# Entradas
#----------------------------------------------------------
# Data_in e WriteEn_in: dominio de WClk
set_input_delay -max 1.20 -clock [get_clocks WClk] [get_ports {Data_in[*]}]
set_input_delay -max 1.20 -clock [get_clocks WClk] [get_ports WriteEn_in]
set_input_transition -max 0.20 [get_ports {Data_in[*]}]
set_input_transition -max 0.20 [get_ports WriteEn_in]

# ReadEn_in: dominio de RClk
set_input_delay -max 1.20 -clock [get_clocks RClk] [get_ports ReadEn_in]
set_input_transition -max 0.20 [get_ports ReadEn_in]

#----------------------------------------------------------
# Saidas
#----------------------------------------------------------
# Full_out: dominio de WClk
set_output_delay -max 1.00 -clock [get_clocks WClk] [get_ports Full_out]
set_load 0.020 [get_ports Full_out]

# Data_out e Empty_out: dominio de RClk
set_output_delay -max 1.00 -clock [get_clocks RClk] [get_ports {Data_out[*]}]
set_output_delay -max 1.00 -clock [get_clocks RClk] [get_ports Empty_out]
set_load 0.020 [get_ports {Data_out[*]}]
set_load 0.020 [get_ports Empty_out]

#----------------------------------------------------------
# Reset assincrono
#----------------------------------------------------------
# Clear_in e assincrono: excluido dos caminhos funcionais de setup.
set_false_path -from [get_ports Clear_in]
