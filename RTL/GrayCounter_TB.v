`timescale 1ns/100ps
module GrayCounter_TB
   #(parameter   COUNTER_WIDTH = 4);
	 reg clk, clear_in, enable_in;
	 wire [COUNTER_WIDTH-1:0] grayCount_out;

	// Disponibilizando o DUT(Device-Under-Test)
	GrayCounter DUT (
		.clk(clk),
		.Clear_in(clear_in),
		.Enable_in(enable_in),
		.GrayCount_out(grayCount_out)
		);

	// Aplicando os estimulos
	initial begin
		clk <= 0;
		enable_in <= 0;
		clear_in <= 0;
		
		#50 enable_in <= 1;
		#410 clear_in <= 1;
		#15 clear_in <= 0;
	end
	

	always
		#10 clk = ~clk;
	
	initial
		#800 enable_in <= 0;
	
	initial 
		#1000	$stop;

endmodule

	