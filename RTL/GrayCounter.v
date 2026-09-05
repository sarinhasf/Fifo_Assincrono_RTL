//==========================================
// Function : Contador Gray/Binario para ponteiros de FIFO assincrona.
// Notes    : Versao convencional (Cummings). Mantem o contador binario
//            visivel (endereco da RAM) e disponibiliza o proximo valor
//            Gray de forma combinacional, permitindo que Full_out e
//            Empty_out sejam gerados em flip-flops (sem latches).
//            Clear_in e um reset assincrono.
//=========================================

`timescale 1ns/1ps

module GrayCounter
   #(parameter   COUNTER_WIDTH = 4)
    (output reg  [COUNTER_WIDTH-1:0]    GrayCount_out,    //Ponteiro em codigo Gray (registrado).
     output reg  [COUNTER_WIDTH-1:0]    BinaryCount_out,  //Ponteiro binario (endereco da RAM).
     output wire [COUNTER_WIDTH-1:0]    GrayNext_out,     //Proximo valor Gray (combinacional).
     output wire [COUNTER_WIDTH-1:0]    BinaryNext_out,   //Proximo valor binario (combinacional).
     input wire                         Enable_in,        //Habilita a contagem.
     input wire                         Clear_in,         //Reset assincrono.
     input wire                         clk);

    /////////Internal connections & variables///////
    wire   [COUNTER_WIDTH-1:0]         BinaryNext;

    /////////Code///////////////////////
    //Proximo ponteiro binario e sua conversao para Gray:
    assign BinaryNext     = BinaryCount_out + {{(COUNTER_WIDTH-1){1'b0}}, (Enable_in & ~Clear_in)};
    assign BinaryNext_out = BinaryNext;
    assign GrayNext_out   = BinaryNext ^ (BinaryNext >> 1);

    //Registradores dos ponteiros (reset assincrono, sem latches):
    always @ (posedge clk, posedge Clear_in)
        if (Clear_in) begin
            BinaryCount_out <= {COUNTER_WIDTH{1'b0}};
            GrayCount_out   <= {COUNTER_WIDTH{1'b0}};
        end
        else begin
            BinaryCount_out <= BinaryNext;
            GrayCount_out   <= GrayNext_out;
        end

endmodule
