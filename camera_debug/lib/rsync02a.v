`ifndef __INCLUDED_RSYNC02A__
`define __INCLUDED_RSYNC02A__
`timescale 1ns/1ns

`define D 1

module rsync02a (clk, reset_in, reset_out);
input  clk;
input  reset_in;
output reset_out;

reg reset1_reg;
reg reset2_reg;

assign reset_out = reset2_reg;

always @ (posedge clk or negedge reset_in) begin
	if(~reset_in) begin
		reset1_reg <= #`D 1'b0;
		reset2_reg <= #`D 1'b0;
	end else begin
		reset1_reg <= #`D 1'b1;
		reset2_reg <= #`D reset1_reg;
	end
end

endmodule
`endif

