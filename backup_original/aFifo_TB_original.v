`timescale 1ns/100ps
module aFifo_TB
   #(parameter   DATA_WIDTH    = 8,
                 ADDRESS_WIDTH = 4,
                 FIFO_DEPTH    = (1 << ADDRESS_WIDTH));
					  
	  wire[DATA_WIDTH-1:0]         Data_out;
     wire                         Empty_out;
     reg                          ReadEn_in;
     reg                          RClk;        
     //Writing port.	 
     reg  [DATA_WIDTH-1:0]        Data_in;  
     wire                         Full_out;
     reg                          WriteEn_in;
     reg                          WClk;
	 
     reg                          Clear_in;

	integer k;
					  
	// Disponibilizando o DUT(Device-Under-Test)
	aFifo DUT (
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

	// Aplicando os estimulos
	always 
		#23 RClk = ~RClk;
		
	always 
		#29 WClk = ~WClk;
	
	initial begin
		WClk <= 0;
		RClk <= 0;
		ReadEn_in <= 0;
		WriteEn_in <= 0;
		Clear_in <= 0;
		
		#100 WriteEn_in <= 1;
		#1000 WriteEn_in <= 0;
		ReadEn_in <= 1;
		#1000 ReadEn_in <= 0;
	end
	
	initial begin
		Clear_in <= 0;
		#20 Clear_in <= 1;
		#40 Clear_in <= 0;
	end
	
	initial begin
		#65 Data_in <= 0;
		for (k=0; k < 32; k = k + 1)
			#58 Data_in <= k;
	end

	initial 
		#2300	$stop;
		
endmodule

	