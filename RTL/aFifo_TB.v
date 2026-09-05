//==========================================
// Testbench da FIFO assincrona (versao convencional).
// - DATA_WIDTH = 8, ADDRESS_WIDTH = 4 (16 posicoes).
// - Teste 1: preenche ate Full_out=1 e esvazia ate Empty_out=1.
// - Teste 2: escritas e leituras concorrentes, WClk=10ns / RClk=13ns,
//            com pelo menos 200 operacoes aceitas de cada tipo.
// - Teste 3: repete o teste concorrente invertendo os periodos.
// A sequencia de dados e um contador incremental (sequencia conhecida) e
// um placar de referencia detecta perda, duplicacao ou reordenacao.
// Todos os estimulos sao aplicados na borda de descida do clock do
// respectivo dominio, evitando condicoes de corrida com o DUT.
//=========================================

`timescale 1ns/1ps

module aFifo_TB
   #(parameter   DATA_WIDTH    = 8,
                 ADDRESS_WIDTH = 4,
                 FIFO_DEPTH    = (1 << ADDRESS_WIDTH));

     wire [DATA_WIDTH-1:0]        Data_out;
     wire                         Empty_out;
     reg                          ReadEn_in;
     reg                          RClk;
     //Writing port.
     reg  [DATA_WIDTH-1:0]        Data_in;
     wire                         Full_out;
     reg                          WriteEn_in;
     reg                          WClk;

     reg                          Clear_in;

    //Meio periodo de cada clock (programavel por teste):
    real                          WHalf = 5.0;    //WClk = 10,0 ns
    real                          RHalf = 6.5;    //RClk = 13,0 ns

    //Placar de referencia (modelo da fila):
    reg  [DATA_WIDTH-1:0]         RefQueue [0:8191];
    integer                       wr_idx, rd_idx;
    integer                       writes_ok, reads_ok, errors;

    // Disponibilizando o DUT(Device-Under-Test)
    aFifo #(.DATA_WIDTH(DATA_WIDTH), .ADDRESS_WIDTH(ADDRESS_WIDTH)) DUT (
        .Data_out(Data_out),
        .Empty_out(Empty_out),
        .ReadEn_in(ReadEn_in),
        .RClk(RClk),
        .Data_in(Data_in),
        .Full_out(Full_out),
        .WriteEn_in(WriteEn_in),
        .WClk(WClk),
        .Clear_in(Clear_in)
        );

    // Geracao dos dois clocks assincronos
    always #(WHalf) WClk = ~WClk;
    always #(RHalf) RClk = ~RClk;

    //---------------------------------------------------------
    // Modelo de referencia
    //---------------------------------------------------------
    // Escrita aceita (WriteEn_in && !Full_out): guarda o dado escrito e
    // avanca a sequencia conhecida de dados.
    always @ (posedge WClk)
        if (!Clear_in && WriteEn_in && !Full_out) begin
            RefQueue[wr_idx] = Data_in;
            wr_idx    = wr_idx + 1;
            writes_ok = writes_ok + 1;
            Data_in  <= Data_in + 1'b1;
        end

    // Leitura aceita (ReadEn_in && !Empty_out): Data_out e atualizado na
    // mesma borda; a comparacao e feita logo apos a atualizacao.
    always @ (posedge RClk)
        if (!Clear_in && ReadEn_in && !Empty_out) begin
            #0.5;
            if (Data_out !== RefQueue[rd_idx]) begin
                errors = errors + 1;
                $display("[%0t] ERRO na leitura %0d: Data_out=%0d, esperado=%0d",
                          $time, rd_idx, Data_out, RefQueue[rd_idx]);
            end
            else
                reads_ok = reads_ok + 1;
            rd_idx = rd_idx + 1;
        end

    //---------------------------------------------------------
    // Tarefas de teste
    //---------------------------------------------------------
    task do_reset;
        begin
            @(negedge WClk) WriteEn_in = 0;
            @(negedge RClk) ReadEn_in  = 0;
            Clear_in = 1;
            #50;
            @(negedge WClk) Clear_in = 0;
            wr_idx = 0; rd_idx = 0;
            #50;
        end
    endtask

    // Teste 1: preenche ate Full_out=1, depois esvazia ate Empty_out=1.
    task test_fill_then_drain;
        integer w0, r0;
        begin
            $display("\n--- Teste 1: preencher ate Full_out=1 e esvaziar ate Empty_out=1 ---");
            w0 = writes_ok; r0 = reads_ok;
            @(negedge WClk) WriteEn_in = 1;
            wait (Full_out === 1'b1);
            @(negedge WClk) WriteEn_in = 0;
            $display("[%0t] Full_out=1 apos %0d escritas aceitas (profundidade = %0d)",
                      $time, writes_ok - w0, FIFO_DEPTH);
            if ((writes_ok - w0) !== FIFO_DEPTH) begin
                errors = errors + 1;
                $display("ERRO: numero de escritas aceitas diferente da profundidade.");
            end

            #100;
            @(negedge RClk) ReadEn_in = 1;
            wait (Empty_out === 1'b1);
            @(negedge RClk) ReadEn_in = 0;
            $display("[%0t] Empty_out=1 apos %0d leituras corretas (erros acumulados = %0d)",
                      $time, reads_ok - r0, errors);
            if ((reads_ok - r0) !== FIFO_DEPTH) begin
                errors = errors + 1;
                $display("ERRO: numero de leituras diferente da profundidade.");
            end
            #100;
        end
    endtask

    // Testes 2 e 3: escritas e leituras concorrentes.
    task test_concurrent;
        input real wper;
        input real rper;
        input integer n_ops;
        integer w0, r0;
        begin
            $display("\n--- Teste concorrente: WClk = %0.1f ns, RClk = %0.1f ns, %0d operacoes ---",
                      wper, rper, n_ops);
            WHalf = wper/2.0;
            RHalf = rper/2.0;
            w0 = writes_ok;
            r0 = reads_ok;
            @(negedge WClk) WriteEn_in = 1;
            @(negedge RClk) ReadEn_in  = 1;
            wait (((writes_ok - w0) >= n_ops) && ((reads_ok - r0) >= n_ops));
            @(negedge WClk) WriteEn_in = 0;
            #200;
            @(negedge RClk) ReadEn_in = 0;   //drena o que restou na FIFO.
            #200;
            $display("[%0t] escritas aceitas = %0d, leituras corretas = %0d, erros = %0d",
                      $time, writes_ok - w0, reads_ok - r0, errors);
        end
    endtask

    //---------------------------------------------------------
    // Sequencia principal
    //---------------------------------------------------------
    initial begin
        WClk  = 0;
        RClk  = 0;
        Data_in    = 8'h00;
        ReadEn_in  = 0;
        WriteEn_in = 0;
        Clear_in   = 0;
        wr_idx = 0; rd_idx = 0;
        writes_ok = 0; reads_ok = 0; errors = 0;

        do_reset;
        test_fill_then_drain;                //WClk = 10 ns, RClk = 13 ns

        do_reset;
        test_concurrent(10.0, 13.0, 200);    //WClk mais rapido que RClk.

        do_reset;
        test_concurrent(13.0, 10.0, 200);    //periodos invertidos.

        $display("\n===== RESULTADO FINAL: %0d leituras verificadas, %0d erro(s) =====",
                  reads_ok, errors);
        if (errors == 0)
            $display("OK: sem perda, duplicacao ou reordenacao de dados.\n");
        else
            $display("FALHA: verificar as formas de onda em aFifo_TB.vcd\n");
        $finish;
    end

    initial begin
        $dumpfile("aFifo_TB.vcd");
        $dumpvars(0, aFifo_TB);
        #500000;
        $display("TIMEOUT");
        $finish;
    end

endmodule
