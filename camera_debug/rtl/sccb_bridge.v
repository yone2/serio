`define D 1
`timescale 1ps/1ns

module sccb_bridge(
	sccb_clk,
	sccb_reset_n,
	sccb_div,
	sio_c,
	sio_d,
	pwdn,
	mcmd,
	maddr,
	mdata,
	scmdaccept,
	sresp,
	sdata,
	debug_out
);
// Bus clock
input        sccb_clk;
input        sccb_reset_n;

// Clock ratio (Bus:SCCB)
input  [7:0] sccb_div;

// SCCB I/F
output       sio_c;
inout        sio_d;
output       pwdn;

// Bus I/F
input  [2:0] mcmd;
input [14:0] maddr;
input  [7:0] mdata;
output       scmdaccept;
output [1:0] sresp;
output [7:0] sdata;

// debug LED
output [7:0] debug_out;

// clock divide (gated pulse)
reg [7:0] r_divcount;
wire      w_sccb_clken;
wire      w_sccb_gclk;
assign w_sccb_clken = (r_divcount == 8'h00) ? 1 : 0;
cgate01a cgate_sccb(.clk(sccb_clk), .en(w_sccb_clken), .test(1'b0), .gclk(w_sccb_gclk));

always @ (posedge sccb_clk or negedge sccb_reset_n)
	if(~sccb_reset_n) r_divcount <= #`D 8'h01;
	else              r_divcount <= #`D (r_divcount == sccb_div) ? 8'h00 : r_divcount + 1;

// SCCB transmission control
/* 
* State definition 
* 3'b000 : idle
* 3'b001 : sending ID/Address
* 3'b010 : sending write data
* 3'b100 : receiving read data
* else   : error state
*/
parameter P_SCCB_IDLE  = 3'b000;
parameter P_SCCB_DEVID = 3'b001;
parameter P_SCCB_ADDR  = 3'b010;
parameter P_SCCB_WRITE = 3'b100;
parameter P_SCCB_READ  = 3'b101;

reg          r_sio_c;
reg          r_sio_d;
reg          r_sio_d_oe;
assign sio_c = r_sio_c;
assign sio_d = r_sio_d_oe ? r_sio_d : 1'bz;
assign pwdn  = 1'b0; // tie down
reg [2:0]    r_sccb_state;
reg [8:0]    r_sccb_data;
reg [2:0]    r_mcmd;
reg [14:0]   r_maddr;
reg [7:0]    r_mdata;
reg [7:0]    r_sresp;
reg [7:0]    r_sdata;
wire         w_sccb_idle;
assign w_sccb_idle = (r_sccb_state == 3'b000);
assign scmdaccept  = w_sccb_idle;
assign sresp       = r_sresp;
assign sdata       = r_sdata;

always @ (posedge sccb_clk or negedge sccb_reset_n)
	if(~sccb_reset_n) begin
		r_mcmd  <= #`D 3'b000;
		r_maddr <= #`D 15'h0000;
		r_mdata <= #`D 8'h00;
	end else begin
		r_mcmd  <= #`D w_sccb_idle ? mcmd  : r_mcmd;
		r_maddr <= #`D w_sccb_idle ? maddr : r_maddr;
		r_mdata <= #`D w_sccb_idle ? mdata : r_mdata;
	end

wire w_mcmd_valid;
wire w_wr_en;
wire w_rd_en;
assign w_mcmd_valid = ~r_mcmd[2] & (r_mcmd[1] ^ r_mcmd[0]);
assign w_wr_en = w_mcmd_valid & r_mcmd[0];
assign w_rd_en = w_mcmd_valid & r_mcmd[1];

always @ (posedge sccb_clk or negedge sccb_reset_n)
	if(~sccb_reset_n) begin
		r_sccb_state <= #`D P_SCCB_IDLE;
		r_sccb_data  <= #`D 9'b0000_0000_0;
	end else begin
		if(r_sccb_state == P_SCCB_IDLE) begin
			r_sccb_state <= #`D w_mcmd_valid ? P_SCCB_DEVID : P_SCCB_IDLE;
			r_sccb_data  <= #`D w_mcmd_valid ? {r_maddr[14:8], 1'b0} : r_sccb_data;
		end else if(r_sccb_state == P_SCCB_DEVID) begin
			r_sccb_state <= #`D w_transmit_end ? P_SCCB_ADDR : P_SCCB_DEVID;
			r_sccb_data  <= #`D w_transmit_end ? {r_maddr[7:0], 1'b0};
		end else if(r_sccb_state == P_SCCB_ADDR) begin
			r_sccb_state <= #`D w_transmit_end ? (w_wr_en ? P_SCCB_WRITE) : P_SCCB_ADDR;
			r_sccb_data  <= #`D w_transmit_end ? {r_maddr[7:0], 1'b0};
		end else if(r_sccb_state == P_SCCB_WRITE) begin
		end else if(r_sccb_state == P_SCCB_READ) begin
		end // else hang up
	end

assign debug_out = {r_sio_c, r_sio_d, r_sio_d_oe, scmdaccept, 1'b0, r_sccb_state};

endmodule

