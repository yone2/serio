`ifndef __INCLUDED_RSRX_01A__
`define __INCLUDED_RSRX_01A__
`timescale 1ns/1ns

`define D 1

module rsrx_01a (sample_clk, rx_clk, reset_n, 
	rxSerialData, rxParallelData, rxTrigger, rxStatus, rxClkReset_n);
input        sample_clk;
input        rx_clk;
input        reset_n;
input        rxSerialData;
output [7:0] rxParallelData;
input        rxTrigger;
output [1:0] rxStatus;
output       rxClkReset_n;

// RXD synchronization
reg          r_rxdSync0;
reg          r_rxdSync1;
always @ (posedge sample_clk or negedge reset_n) 
	if(~reset_n) begin
		r_rxdSync0 <= #`D 1'b1;
		r_rxdSync1 <= #`D 1'b1;
	end else begin
		r_rxdSync0 <= #`D rxSerialData;
		r_rxdSync1 <= #`D r_rxdSync0;
	end

// positive & negative edge detect
wire w_startEdge;
wire w_stopEdge;

trigp01a  stop_trigger (
	.trigger(w_stopEdge),  // 1 bit output
	.clk(sample_clk),      // 1 bit input 
	.in(r_rxdSync1),       // 1 bit input 
	.reset_n(reset_n)      // 1 bit input 
);

trign01a  start_trigger (
	.trigger(w_startEdge), // 1 bit output
	.clk(sample_clk),      // 1 bit input 
	.in(r_rxdSync1),       // 1 bit input 
	.reset_n(reset_n)      // 1 bit input 
);

// RS Clk Synchronization
reg [1:0] rxStatus;
wire w_init_n;
assign w_init_n = ~(~rxStatus[0] & w_startEdge);
wire w_internalReset_n;
assign w_internalReset_n = w_init_n & reset_n;

rsync02a  internal_reset (
	.reset_out(rxClkReset_n),    // 1 bit output
	.clk(sample_clk),            // 1 bit input 
	.reset_in(w_internalReset_n) // 1 bit input 
);

// shift register
reg [7:0] r_shiftInData;
reg [7:0] r_rxCount;
always @ (posedge rx_clk or negedge reset_n)
	if(~reset_n) r_shiftInData <= #`D 8'h00;
	else         r_shiftInData <= #`D {r_rxdSync1, r_shiftInData[7:1]};

always @ (posedge rx_clk or negedge reset_n) 
	if(~reset_n)           r_rxCount <= #`D 8'b00000000;
	else if(~rxClkReset_n) r_rxCount <= #`D 8'b00000000;
	else                   r_rxCount <= #`D rxStatus[0] ? 
		                                {1'b1, r_rxCount[7:1]} : 8'b00000000;

wire w_RxComplete;
assign w_RxComplete = &r_rxCount;
wire w_RxCompleteTrigger;

trigp01a  RxCompleteTrigger (
	.trigger(w_RxCompleteTrigger), // 1 bit output
	.clk(sample_clk),              // 1 bit input 
	.in(w_RxComplete),             // 1 bit input 
	.reset_n(reset_n)              // 1 bit input 
);

reg [7:0] rxParallelData;
always @ (posedge sample_clk or negedge reset_n)
	if(~reset_n) rxParallelData <= #`D 8'h00;
	else         rxParallelData <= #`D (w_RxComplete) ? r_shiftInData : rxParallelData;


wire w_RxDataExist;
wire w_RxBusy;
assign w_RxDataExist = w_RxCompleteTrigger ? 1'b1 : rxTrigger ? 1'b0 : rxStatus[1];
assign w_RxBusy = w_startEdge ? 1'b1 : w_RxCompleteTrigger ? 1'b0 : rxStatus[0];

always @ (posedge sample_clk or negedge reset_n)
	if(~reset_n) rxStatus <= #`D 2'b00;
	else         rxStatus <= #`D {w_RxDataExist, w_RxBusy};

endmodule
`endif
