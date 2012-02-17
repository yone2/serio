`define D 1
`timescale 1ns/1ps

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
parameter P_SCCB_IDLE     = 2'b00;
parameter P_SCCB_WAIT_SET = 2'b01;
parameter P_SCCB_RUNNING  = 2'b10;
parameter P_SCCB_WAIT_END = 2'b11;

reg          r_sio_c;
reg          r_sio_d;
reg          r_sio_d_oe;
assign sio_c = r_sio_c;
assign sio_d = r_sio_d_oe ? r_sio_d : 1'bz;
assign pwdn  = 1'b0; // tie down
reg [1:0]    r_sccb_state;
reg [149:0]  r_seq_sio_c;
reg [149:0]  r_seq_sio_d;
reg [149:0]  r_seq_sio_d_oe;
reg [2:0]    r_mcmd;
reg [14:0]   r_maddr;
reg [7:0]    r_mdata;
reg [7:0]    r_sresp;
reg [7:0]    r_sdata;
wire         w_sccb_idle;
assign w_sccb_idle = (r_sccb_state == 2'b00);
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

reg        r_update_seq;
reg        r_ack_seq;
reg        r_end_transmit;
reg  [7:0] r_seq_cnt;
wire [7:0] w_end_cnt;
assign w_end_cnt = w_wr_en ? 8'd113 : 8'd149;
reg  [7:0] r_read_data;

always @ (posedge sccb_clk or negedge sccb_reset_n)
	if(~sccb_reset_n) begin
		r_sccb_state <= #`D P_SCCB_IDLE;
		r_update_seq <= #`D 1'b0;
		r_sdata      <= #`D 8'h00;
		r_sresp      <= #`D 2'b00;
	end else begin
		if(r_sccb_state == P_SCCB_IDLE) begin
			r_sccb_state <= #`D w_mcmd_valid    ? P_SCCB_WAIT_SET : r_sccb_state;
			r_update_seq <= #`D w_mcmd_valid    ? 1'b1            : 1'b0;
			r_sresp      <= #`D w_mcmd_valid & w_wr_en ? 2'b01 : 2'b00; // No response or DVA
		end else if(r_sccb_state == P_SCCB_WAIT_SET) begin
			r_sccb_state <= #`D r_ack_seq       ? P_SCCB_RUNNING  : r_sccb_state;
			r_update_seq <= #`D r_ack_seq       ? 1'b0            : 1'b1;
			r_sresp      <= #`D 2'b00; // No response
		end else if(r_sccb_state == P_SCCB_RUNNING) begin
			r_sccb_state <= #`D r_end_transmit  ? P_SCCB_WAIT_END : r_sccb_state;
		end else if(r_sccb_state == P_SCCB_WAIT_END) begin
			r_sccb_state <= #`D ~r_end_transmit ? P_SCCB_IDLE     : r_sccb_state;
			r_sresp      <= #`D ~r_end_transmit ? (w_wr_en ? 2'b00 : 2'b01) : 2'b00; // DVA
			r_sdata      <= #`D ~r_end_transmit ? r_read_data : r_sdata;
		end
	end

always @ (posedge w_sccb_gclk or negedge sccb_reset_n) 
	if(~sccb_reset_n) begin
		r_sio_c        <= #`D 1'b1;
		r_sio_d        <= #`D 1'b1;
		r_sio_d_oe     <= #`D 1'b0;
		r_seq_sio_c    <= #`D 150'd0;
		r_seq_sio_d    <= #`D 150'd0;
		r_seq_sio_d_oe <= #`D 150'd0;
		r_ack_seq      <= #`D 1'b0;
		r_end_transmit <= #`D 1'b0;
		r_seq_cnt      <= #`D 8'h00;
		r_read_data    <= #`D 8'h00;
	end else begin
		r_sio_c        <= #`D r_update_seq ? 1'b1 : r_seq_sio_c[149];
		r_sio_d        <= #`D r_update_seq ? 1'b1 : r_seq_sio_d[149];
		r_sio_d_oe     <= #`D r_update_seq ? 1'b1 : r_seq_sio_d_oe[149];
		r_seq_sio_c    <= #`D r_update_seq ? 
			{3'b110, {9{4'b0110}}, {9{4'b0110}}, {9{4'b0110}}, (w_wr_en ? {9{4'b1111}} : {9{4'b0110}}), 3'b011}  : 
			{r_seq_sio_c[148:0], 1'b1};
		r_seq_sio_d    <= #`D r_update_seq ?
			{3'b100, {4{r_maddr[14]}}, {4{r_maddr[13]}}{9{4'b0110}}, {9{4'b0110}}, (w_wr_en ? {9{4'b1111}} : {9{4'b0110}}), 3'b011}  : 
			{r_seq_sio_d[148:0], 1'b1};
		r_seq_sio_d_oe <= #`D r_update_seq ? {3'b111, } : {r_seq_sio_d_oe[148:0], 1'b1};
		r_ack_seq      <= #`D r_update_seq ? 1'b1 : 1'b0;
		r_end_transmit <= #`D r_update_seq ? 1'b0 : (r_seq_cnt == w_end_cnt);
		r_seq_cnt      <= #`D r_update_seq ? 8'h0 : r_seq_cnt + 8'h1;
	end


assign debug_out = {r_sio_c, r_sio_d, r_sio_d_oe, scmdaccept, 2'b00, r_sccb_state};

endmodule

