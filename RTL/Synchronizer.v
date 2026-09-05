//==========================================
// Function : Sincronizador de dois flip-flops (double flopping).
// Notes    : Usado para cruzar os ponteiros Gray entre os dominios
//            de WClk e RClk. Um par de FFs por bit de ponteiro.
//=========================================

`timescale 1ns/1ps

module Synchronizer
   #(parameter   SYNC_WIDTH = 5)
    (output reg  [SYNC_WIDTH-1:0]       Q_out,      //Saida sincronizada (2o flip-flop).
     input wire  [SYNC_WIDTH-1:0]       D_in,       //Entrada do outro dominio de clock.
     input wire                         Clear_in,   //Reset assincrono.
     input wire                         clk);       //Clock do dominio de destino.

    /////////Internal connections & variables///////
    reg    [SYNC_WIDTH-1:0]            Q_meta;     //Saida do 1o flip-flop (metaestavel).

    /////////Code///////////////////////
    always @ (posedge clk, posedge Clear_in)
        if (Clear_in) begin
            Q_meta <= {SYNC_WIDTH{1'b0}};
            Q_out  <= {SYNC_WIDTH{1'b0}};
        end
        else begin
            Q_meta <= D_in;      //1o flip-flop.
            Q_out  <= Q_meta;    //2o flip-flop (double flop resynchronization).
        end

endmodule
