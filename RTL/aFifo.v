//==========================================
// Function : Asynchronous FIFO (w/ 2 asynchronous clocks).
// Notes    : Versao convencional (Clifford E. Cummings, SNUG 2002)
//            com sincronizacao dos ponteiros Gray:
//              - ponteiros binarios e Gray com ADDRESS_WIDTH+1 bits;
//              - dois flip-flops de sincronizacao para cada ponteiro
//                que cruza dominio (double flop resynchronization);
//              - Full_out gerado somente no dominio de WClk;
//              - Empty_out gerado somente no dominio de RClk;
//              - nenhum latch inferido (toda logica de status e
//                registrada em flip-flops com reset assincrono).
//            A interface externa e identica a da FIFO original.
//=========================================

`timescale 1ns/1ps

module aFifo
  #(parameter    DATA_WIDTH    = 8,
                 ADDRESS_WIDTH = 4,
                 FIFO_DEPTH    = (1 << ADDRESS_WIDTH))
     //Reading port
    (output reg  [DATA_WIDTH-1:0]        Data_out,
     output reg                          Empty_out,
     input wire                          ReadEn_in,
     input wire                          RClk,
     //Writing port.
     input wire  [DATA_WIDTH-1:0]        Data_in,
     output reg                          Full_out,
     input wire                          WriteEn_in,
     input wire                          WClk,

     input wire                          Clear_in);

    /////Internal connections & variables//////
    localparam                          PTR_WIDTH = ADDRESS_WIDTH + 1;

    reg   [DATA_WIDTH-1:0]              Mem [FIFO_DEPTH-1:0];

    //Ponteiro de escrita (dominio WClk):
    wire  [PTR_WIDTH-1:0]               wGrayPtr, wBinPtr, wGrayNext, wBinNext;
    //Ponteiro de leitura (dominio RClk):
    wire  [PTR_WIDTH-1:0]               rGrayPtr, rBinPtr, rGrayNext, rBinNext;
    //Ponteiros apos o cruzamento de dominio (saida do 2o flip-flop):
    wire  [PTR_WIDTH-1:0]               rGrayPtr_wSync;  //rGrayPtr sincronizado em WClk.
    wire  [PTR_WIDTH-1:0]               wGrayPtr_rSync;  //wGrayPtr sincronizado em RClk.

    wire                                NextWriteAddressEn, NextReadAddressEn;
    wire                                FullNext, EmptyNext;

    //////////////Code///////////////
    //Fifo addresses support logic:
    //'Next Addresses' enable logic:
    assign NextWriteAddressEn = WriteEn_in & ~Full_out;
    assign NextReadAddressEn  = ReadEn_in  & ~Empty_out;

    //Data ports logic:
    //(Uses a dual-port RAM).
    //'Data_in' logic (dominio de WClk):
    always @ (posedge WClk)
        if (NextWriteAddressEn)
            Mem[wBinPtr[ADDRESS_WIDTH-1:0]] <= Data_in;

    //'Data_out' logic (dominio de RClk):
    always @ (posedge RClk)
        if (NextReadAddressEn)
            Data_out <= Mem[rBinPtr[ADDRESS_WIDTH-1:0]];

    //Addreses (Gray counters) logic - ADDRESS_WIDTH+1 bits:
    GrayCounter #(.COUNTER_WIDTH(PTR_WIDTH)) GrayCounter_pWr
       (.GrayCount_out(wGrayPtr),
        .BinaryCount_out(wBinPtr),
        .GrayNext_out(wGrayNext),
        .BinaryNext_out(wBinNext),
        .Enable_in(NextWriteAddressEn),
        .Clear_in(Clear_in),
        .clk(WClk)
       );

    GrayCounter #(.COUNTER_WIDTH(PTR_WIDTH)) GrayCounter_pRd
       (.GrayCount_out(rGrayPtr),
        .BinaryCount_out(rBinPtr),
        .GrayNext_out(rGrayNext),
        .BinaryNext_out(rBinNext),
        .Enable_in(NextReadAddressEn),
        .Clear_in(Clear_in),
        .clk(RClk)
       );

    //Cruzamento de dominio dos ponteiros Gray (dois flip-flops cada):
    //rGrayPtr (RClk) -> dominio de WClk:
    Synchronizer #(.SYNC_WIDTH(PTR_WIDTH)) Sync_rPtr_to_WClk
       (.Q_out(rGrayPtr_wSync),
        .D_in(rGrayPtr),
        .Clear_in(Clear_in),
        .clk(WClk)
       );

    //wGrayPtr (WClk) -> dominio de RClk:
    Synchronizer #(.SYNC_WIDTH(PTR_WIDTH)) Sync_wPtr_to_RClk
       (.Q_out(wGrayPtr_rSync),
        .D_in(wGrayPtr),
        .Clear_in(Clear_in),
        .clk(RClk)
       );

    //'Full_out' logic for the writing port (somente no dominio de WClk):
    //Cheia quando o proximo ponteiro Gray de escrita e igual ao ponteiro
    //Gray de leitura sincronizado com os dois MSBs invertidos.
    assign FullNext = (wGrayNext == {~rGrayPtr_wSync[PTR_WIDTH-1:PTR_WIDTH-2],
                                      rGrayPtr_wSync[PTR_WIDTH-3:0]});

    always @ (posedge WClk, posedge Clear_in)  //D Flip-Flop w/ Asynchronous Clear.
        if (Clear_in)
            Full_out <= 1'b0;
        else
            Full_out <= FullNext;

    //'Empty_out' logic for the reading port (somente no dominio de RClk):
    //Vazia quando o proximo ponteiro Gray de leitura alcanca o ponteiro
    //Gray de escrita sincronizado.
    assign EmptyNext = (rGrayNext == wGrayPtr_rSync);

    always @ (posedge RClk, posedge Clear_in)  //D Flip-Flop w/ Asynchronous Preset.
        if (Clear_in)
            Empty_out <= 1'b1;
        else
            Empty_out <= EmptyNext;

endmodule
