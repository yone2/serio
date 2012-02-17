`ifndef __INCLUDED_SYNCD01A__
`define __INCLUDED_SYNCD01A__
`timescale 1ns/1ns

`define D 1

module syncd01a (clk, reset_n, d, q);

parameter width = 1;

input  clk;
input  reset_n;
input  [width-1:0] d;
output [width-1:0] q;

reg [width-1:0] ff1, ff2;
assign q = ff2;

always @ (posedge clk or negedge reset_n) 
	if(~reset_n) begin
		ff1 <= #`D 0;
		ff2 <= #`D 0;
	end else begin
		ff1 <= #`D d;
		ff2 <= #`D ff1;
	end

endmodule
`endif

