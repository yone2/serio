`ifndef __INCLUDED_RSCLK01A__
`define __INCLUDED_RSCLK01A__
`timescale 1ns/1ns

`define D 1

module rsclk01a ( F25Clk, reset_n, BitRateSel, gatedClk );
input       F25Clk;
input       reset_n;
input [3:0] BitRateSel;
output      gatedClk;

reg       clken;
reg [3:0] r_bitRateSel;

always @ (posedge F25Clk or negedge reset_n) 
	if(~reset_n) r_bitRateSel <= #`D 4'h3;
	else       r_bitRateSel <= #`D BitRateSel;

reg  [14:0] r_periodCounter;
wire [14:0] w_enablePeriod;
wire        w_clkEn;
wire [14:0] w_periodCounter;
wire       w_errorExpired;

assign w_clkEn = (r_periodCounter == w_enablePeriod);
assign w_periodCounter = (w_errorExpired | w_clkEn) ? 15'd0 : r_periodCounter + 15'd1;

function [14:0] EnablePeriod;
	input [3:0] br_sel;
	//EnablePeriod = 15'd2603;  //   9600 bps
	case(br_sel) 
		4'h0 : EnablePeriod = 15'd20832; //   1200 bps
		4'h1 : EnablePeriod = 15'd10415; //   2400 bps
		4'h2 : EnablePeriod = 15'd5207;  //   4800 bps
		4'h3 : EnablePeriod = 15'd2603;  //   9600 bps
		4'h4 : EnablePeriod = 15'd1301;  //  19200 bps
		4'h5 : EnablePeriod = 15'd650;   //  38400 bps
		4'h6 : EnablePeriod = 15'd433;   //  57600 bps
		4'h7 : EnablePeriod = 15'd216;   // 115000 bps
		4'h8 : EnablePeriod = 15'd107;   // 230000 bps
		4'h9 : EnablePeriod = 15'd53;    // 460000 bps
		4'ha : EnablePeriod = 15'd26;    // 921000 bps
		default : EnablePeriod = 15'd2603;
	endcase
endfunction

assign w_enablePeriod = EnablePeriod(r_bitRateSel);

always @ (posedge F25Clk or negedge reset_n)
	if(~reset_n) r_periodCounter <= #`D 15'd0;
	else       r_periodCounter <= #`D w_periodCounter;

always @ (posedge F25Clk or negedge reset_n)
	if(~reset_n) clken <= #`D 1'b0;
	else       clken <= #`D w_clkEn;

reg  [6:0] r_accumulatedError;
wire [6:0] w_accumulatedError;
wire [4:0] w_periodError;

assign w_errorExpired = (r_accumulatedError > 7'd39);
assign w_accumulatedError = w_errorExpired ? r_accumulatedError - 7'd39: 
	                        w_clkEn ? r_accumulatedError + {2'b00, w_periodError} : 
							r_accumulatedError;

function [4:0] PeriodError;
	input [3:0] br_sel;
	case(br_sel) 
		4'h0 : PeriodError = 5'd12;  //   1200 bps
		4'h1 : PeriodError = 5'd24;  //   2400 bps
		4'h2 : PeriodError = 5'd12;  //   4800 bps
		4'h3 : PeriodError = 5'd6;   //   9600 bps
		4'h4 : PeriodError = 5'd3;   //  19200 bps
		4'h5 : PeriodError = 5'd2;   //  38400 bps
		4'h6 : PeriodError = 5'd1;   //  57600 bps
		4'h7 : PeriodError = 5'd14;  // 115000 bps
		4'h8 : PeriodError = 5'd25;  // 230000 bps
		4'h9 : PeriodError = 5'd13;  // 460000 bps
		4'ha : PeriodError = 5'd5;   // 921000 bps
		default : PeriodError = 5'd6;
	endcase
endfunction

assign w_periodError = PeriodError(r_bitRateSel);

always @ (posedge F25Clk or negedge reset_n)
	if(~reset_n) r_accumulatedError <= #`D 7'd0;
	else       r_accumulatedError <= #`D w_accumulatedError;

cgate01a  cgate01a (
	.en(clken),      // 1 bit input 
	.test(1'b0),     // 1 bit input 
	.clk(F25Clk),    // 1 bit input 
	.gclk(gatedClk)  // 1 bit output
);

endmodule

`endif
