module cktTest_doubleFlopping(
	input clk1, clk2, In,
	output reg Out
);
reg Din, Dsync;

always @(posedge clk1)
	Din <= In;
always @(posedge clk2) begin
	Dsync <= Din;
	Out <= Dsync;
end
endmodule
