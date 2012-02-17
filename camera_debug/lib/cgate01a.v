`ifndef __INCLUDED_CGATE01A__
`define __INCLUDED_CGATE01A__
`timescale 1ns/1ns

`define D 1

module cgate01a (clk, en, test, gclk);
input  clk;
input  en;
input  test;
output gclk;

wire w_open;
assign w_open = en | test;

reg  latched;

// Low Through Latch
always @ (clk) 
	if(~clk) latched <= #`D w_open;

assign gclk = latched & clk;

endmodule

`endif
