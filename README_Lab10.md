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

Rodar `genus -f genus_fifo_script.tcl` a partir da pasta do projeto (a pasta `outputs/` ja existe).
Os relatorios necessarios para as respostas do item 4 saem em `outputs/`:

1. **Latches e sincronizadores** - `aFifo_instances.rpt` + log de elaboracao
   (`set_db hdl_error_on_latch true` faz a sintese falhar caso algum latch seja inferido).
   Registradores dos sincronizadores: `Sync_rPtr_to_WClk` (5 FF meta + 5 FF sync) e
   `Sync_wPtr_to_RClk` (5 FF meta + 5 FF sync).
2. **WNS / TNS por dominio** - `aFifo_timing_WClk.rpt`, `aFifo_timing_RClk.rpt`, `aFifo_qor.rpt`.
3. **Classificacao do pior caminho** - `aFifo_in2reg.rpt`, `aFifo_reg2reg.rpt`, `aFifo_reg2out.rpt`.
4. **Clocks assincronos** - `set_clock_groups -asynchronous` no SDC garante que nao ha analise de
   setup entre WClk e RClk; `aFifo_timing_lint.rpt` (check_timing_intent) confirma que nao restam
   caminhos funcionais sem constraint.
