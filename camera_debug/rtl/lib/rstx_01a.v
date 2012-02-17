`ifndef __INCLUDED_RSTX_01A__
`define __INCLUDED_RSTX_01A__
`timescale 1ns/1ns

`define D 1

module rstx_01a (F25Clk, tx_clk, reset_n, txSerialData, txParallelData, txTrigger, txStatus);
input        F25Clk;
input        tx_clk;
input        reset_n;
output       txSerialData;
input  [7:0] txParallelData;
input        txTrigger;
output       txStatus;

parameter P_STATE_IDLE    = 1'b0;
parameter P_STATE_SENDING = 1'b1;

reg  [9:0]  r_shiftReg;
wire [9:0]  w_shiftReg;
reg         r_state;
wire        w_state;
reg         r_HoldTrigger;
wire        w_HoldTrigger;

assign w_HoldTrigger = txTrigger ? 1'b1 : (r_HoldTrigger & (r_state == P_STATE_SENDING)) ? 
	                   1'b0 : r_HoldTrigger;

assign txStatus     = (r_state != P_STATE_IDLE);
assign w_shiftReg   = (r_state == P_STATE_IDLE) & r_HoldTrigger ? 
	                  {1'b1, txParallelData, 1'b0} : {1'b0, r_shiftReg[9:1]};
assign txSerialData = (r_state == P_STATE_IDLE) ? 1'b1 : r_shiftReg[0];
assign w_state      = (r_state == P_STATE_IDLE) ? 
	                  (r_HoldTrigger ? P_STATE_SENDING : P_STATE_IDLE) :
	                  (|w_shiftReg) ? P_STATE_SENDING : P_STATE_IDLE;

always @ (posedge F25Clk or negedge reset_n)
	if(~reset_n) r_HoldTrigger <= #`D 1'b0;
	else         r_HoldTrigger <= #`D w_HoldTrigger;

always @ (posedge tx_clk or negedge reset_n)
	if(~reset_n) r_state <= #`D P_STATE_IDLE;
	else         r_state <= #`D w_state;

always @ (posedge tx_clk or negedge reset_n)
	if(~reset_n) r_shiftReg <= #`D 10'b0;
	else         r_shiftReg <= #`D w_shiftReg;

endmodule

`endif

