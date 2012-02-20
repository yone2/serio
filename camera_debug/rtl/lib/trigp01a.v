`ifndef __INCLUDED_TRIGP01A__
`define __INCLUDED_TRIGP01A__
`timescale 1ns/1ns

`define D 1

module trigp01a (clk, reset_n, in, trigger);
input  clk;
input  reset_n;
input  in;
output trigger;

reg    r_trigger;
reg    r_stage1;
reg    r_stage2;
wire   w_trigger_pos;

assign trigger = r_trigger;
assign w_trigger_pos = r_stage1 & ~r_stage2;

always @ (posedge clk or negedge reset_n)
	if(~reset_n) begin
		r_trigger <= #`D 1'b0;
		r_stage1  <= #`D 1'b0;
		r_stage2  <= #`D 1'b0;
	end else begin
		r_trigger <= #`D w_trigger_pos;
		r_stage1  <= #`D in;
		r_stage2  <= #`D r_stage1;
	end
endmodule

`endif

