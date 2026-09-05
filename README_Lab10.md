# Lab 10 - FIFO Assincrona (arquitetura convencional)

## Arquivos modificados/criados

| Arquivo | Descricao |
|---|---|
| `RTL/aFifo.v` | FIFO reescrita na arquitetura convencional (Cummings). Interface externa inalterada. |
| `RTL/GrayCounter.v` | Contador Gray/binario com saidas do proximo valor (permite Full/Empty registrados). |
| `RTL/Synchronizer.v` | Sincronizador de dois flip-flops (double flopping), um por ponteiro que cruza dominio. |
| `RTL/aFifo_TB.v` | Testbench com clocks assincronos e placar de referencia auto-verificavel. |
| `constraints/constraints_aFifo.sdc` | SDC conforme a especificacao externa (corner Slow, setup). |
| `genus_fifo_script.tcl` | Script de sintese Genus + relatorios de area, timing e timing lint. |
| `backup_original/` | Copia dos arquivos originais. |

## O que a nova arquitetura implementa

- Ponteiros binario e Gray de **ADDRESS_WIDTH+1 = 5 bits** (bit extra distingue cheia de vazia).
- **Dois flip-flops de sincronizacao** para cada ponteiro que cruza dominio
  (`Sync_rPtr_to_WClk` e `Sync_wPtr_to_RClk`), 5 FFs por estagio = 20 FFs de sincronizacao.
- `Full_out` gerado **somente no dominio de WClk**:
  `wGrayNext == {~rGrayPtr_wSync[4:3], rGrayPtr_wSync[2:0]}`, registrado em FF.
- `Empty_out` gerado **somente no dominio de RClk**: `rGrayNext == wGrayPtr_rSync`, registrado em FF.
- **Nenhum latch**: o latch de `Status` da versao original foi eliminado; toda a logica de
  status esta em flip-flops com reset assincrono (`Clear_in`).
- Escrita aceita apenas com `WriteEn_in && !Full_out`; leitura apenas com `ReadEn_in && !Empty_out`.

## Simulacao RTL (resultado obtido com Icarus Verilog)

| Teste | Resultado |
|---|---|
| Preencher ate `Full_out=1` | 16 escritas aceitas (= profundidade) |
| Esvaziar ate `Empty_out=1` | 16 leituras, dados na ordem correta |
| Concorrente WClk=10 ns / RClk=13 ns | 213 escritas / 213 leituras, 0 erro |
| Concorrente WClk=13 ns / RClk=10 ns | 202 escritas / 202 leituras, 0 erro |
| **Total** | **431 leituras verificadas, 0 erro** - sem perda, duplicacao ou reordenacao |

Comando usado: `iverilog -g2012 -o fifo.out aFifo.v GrayCounter.v Synchronizer.v aFifo_TB.v && vvp fifo.out`
(no Xcelium/ModelSim, compilar os mesmos 4 arquivos; a forma de onda sai em `aFifo_TB.vcd`).

## Sintese

Rodar `genus -f genus_fifo_script.tcl` a partir da pasta do projeto (as pastas `outputs/` e
`reports/` ja existem). O script segue o mesmo padrao do `genus_script_nodft.tcl`.

Saidas em `outputs/`: `aFifo_netlist.v`, `aFifo_sdc.sdc`, `aFifo_delays.sdf`.
Reports em `reports/`: `report_timing.rpt`, `report_power.rpt`, `report_area.rpt`, `report_qor.rpt`.

Para as respostas do item 4:

1. **Latches e sincronizadores** - `set_db hdl_error_on_latch true` faz a sintese falhar caso
   algum latch seja inferido; os registradores dos sincronizadores aparecem no netlist e no
   `report_area.rpt`: `Sync_rPtr_to_WClk` e `Sync_wPtr_to_RClk` (5 FF metaestavel + 5 FF sync cada).
2. **WNS / TNS por dominio** - `report_qor.rpt` traz WNS/TNS por grupo de caminho; o pior caminho
   detalhado esta em `report_timing.rpt` (as linhas comentadas no fim do TCL geram um report por
   dominio, WClk e RClk, se precisar separar).
3. **Classificacao do pior caminho** (in2reg / reg2reg / reg2out) - ver o inicio e o fim do caminho
   em `report_timing.rpt` (porta de entrada, registrador ou porta de saida).
4. **Clocks assincronos** - `set_clock_groups -asynchronous` no SDC garante que nao ha analise de
   setup entre WClk e RClk; o `check_timing_intent` no inicio do script e o timing lint e nao deve
   apontar caminhos funcionais sem constraint.
