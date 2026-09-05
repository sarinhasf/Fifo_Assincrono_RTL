module analog_interface(
    ...
output reg Dout,
input Din;
reg Dsync;

always @(posedge clk) begin
    Dsyn <= Din;
    Dout <= Dsync; //double flop
end
...
