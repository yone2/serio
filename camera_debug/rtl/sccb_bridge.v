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
wire      w_sccb_wclken;
wire      w_sccb_gwclk;
assign w_sccb_clken  = (r_divcount == 8'h00) ? 1 : 0;
assign w_sccb_wclken = (r_divcount == {1'b0,sccb_div[7:1]}) | w_sccb_clken;

reg r_sccb_clken;
reg r_sccb_wclken;
always @ (posedge sccb_clk or negedge sccb_reset_n)
	if(~sccb_reset_n) r_sccb_clken <= #`D 1'b0;
	else              r_sccb_clken <= #`D w_sccb_clken;
always @ (posedge sccb_clk or negedge sccb_reset_n)
	if(~sccb_reset_n) r_sccb_wclken <= #`D 1'b0;
	else              r_sccb_wclken <= #`D w_sccb_wclken;	

cgate01a cgate_sccb1(.clk(sccb_clk), .en(r_sccb_clken),  .test(1'b0), .gclk(w_sccb_gclk));
cgate01a cgate_sccb2(.clk(sccb_clk), .en(r_sccb_wclken), .test(1'b0), .gclk(w_sccb_gwclk));

always @ (posedge sccb_clk or negedge sccb_reset_n)
	if(~sccb_reset_n) r_divcount <= #`D 8'h01;
	else              r_divcount <= #`D (r_divcount == sccb_div) ? 8'h00 : r_divcount + 1;

// SCCB transmission control
parameter P_SCCB_IDLE          = 3'b000;
parameter P_SCCB_SENDING_START = 3'b001;
parameter P_SCCB_SENDING_IDW   = 3'b010;
parameter P_SCCB_SENDING_ADDR  = 3'b011;
parameter P_SCCB_SENDING_DATA  = 3'b100;
parameter P_SCCB_SENDING_STOP  = 3'b101;
parameter P_SCCB_SENDING_IDR   = 3'b110;
parameter P_SCCB_RECEIVING_DAT = 3'b111;

reg [2:0]    r_sccb_state;
wire         w_sccb_idle;
assign w_sccb_idle = (r_sccb_state == 3'b000);
reg          r_sio_c;
reg          r_sio_c_pre;
reg          r_sio_d;
reg          r_sio_d_oe;
reg [17:0]   r_seq_sio_c;
reg [17:0]   r_seq_sio_d;
reg [17:0]   r_seq_sio_d_oe;
wire [17:0]  w_seq_sio_c;
wire [17:0]  w_seq_sio_d;
wire [17:0]  w_seq_sio_d_oe;
wire         w_sio_din;
assign sio_c = r_sio_c;
assign sio_d = r_sio_d_oe ? r_sio_d : 1'bz;
assign w_sio_din = !r_sio_d_oe & sio_d;
assign pwdn  = 1'b0; // tie down
reg [2:0]    r_mcmd;
reg [14:0]   r_maddr;
reg [7:0]    r_mdata;
reg [7:0]    r_sresp;
reg [7:0]    r_sdata;
assign scmdaccept  = w_sccb_idle;
assign sresp       = r_sresp;
assign sdata       = r_sdata;

// Sequence Pattern
parameter P_SEQ_CD_IDLE  = 18'b11_1111_1111_1111_1111;
parameter P_SEQ_CD_START = 18'b11_1111_1111_1111_1110;
parameter P_SEQ_OE_START = 18'b11_1111_1111_1111_1111;
parameter P_SEQ_CD_END   = 18'b01_1111_1111_1111_1111;
parameter P_SEQ_OE_END   = 18'b11_1111_1111_1111_1111;
parameter P_SEQ_RUN_CLK  = 18'b10_1010_1010_1010_1010;
parameter P_SEQ_RUN_WOE  = 18'b11_1111_1111_1111_1100;
parameter P_SEQ_RUN_ROE  = 18'b00_0000_0000_0000_0000;
wire [17:0] w_seq_dat_wrid;
wire [17:0] w_seq_dat_rdid;
wire [17:0] w_seq_dat_addr;
wire [17:0] w_seq_dat_data;
assign w_seq_dat_wrid = {r_maddr[14],r_maddr[14],
	r_maddr[13],r_maddr[13],r_maddr[12],r_maddr[12],r_maddr[11],r_maddr[11],
	r_maddr[10],r_maddr[10],r_maddr[9],r_maddr[9],r_maddr[8],r_maddr[8],2'b00,2'b00};
assign w_seq_dat_rdid = {r_maddr[14],r_maddr[14],
	r_maddr[13],r_maddr[13],r_maddr[12],r_maddr[12],r_maddr[11],r_maddr[11],
	r_maddr[10],r_maddr[10],r_maddr[9],r_maddr[9],r_maddr[8],r_maddr[8],2'b11,2'b00};
assign w_seq_dat_addr = {r_maddr[7],r_maddr[7],
	r_maddr[6],r_maddr[6],r_maddr[5],r_maddr[5],r_maddr[4],r_maddr[4],r_maddr[3],r_maddr[3],
	r_maddr[2],r_maddr[2],r_maddr[1],r_maddr[1],r_maddr[0],r_maddr[0],2'b11};
assign w_seq_dat_data = {r_mdata[7],r_mdata[7],
	r_mdata[6],r_mdata[6],r_mdata[5],r_mdata[5],r_mdata[4],r_mdata[4],r_mdata[3],r_mdata[3],
	r_mdata[2],r_mdata[2],r_mdata[1],r_mdata[1],r_mdata[0],r_mdata[0],2'b11};

function [17:0] seq_select_clk;
	input [2:0] next_state;
	case(next_state) 
		P_SCCB_IDLE          : seq_select_clk = P_SEQ_CD_IDLE;
		P_SCCB_SENDING_START : seq_select_clk = P_SEQ_CD_START;
		P_SCCB_SENDING_IDW   : seq_select_clk = P_SEQ_RUN_CLK;
		P_SCCB_SENDING_ADDR  : seq_select_clk = P_SEQ_RUN_CLK;
		P_SCCB_SENDING_DATA  : seq_select_clk = P_SEQ_RUN_CLK;
		P_SCCB_SENDING_IDR   : seq_select_clk = P_SEQ_RUN_CLK;
		P_SCCB_RECEIVING_DAT : seq_select_clk = P_SEQ_RUN_CLK;
		P_SCCB_SENDING_STOP  : seq_select_clk = P_SEQ_CD_END;
		default              : seq_select_clk = P_SEQ_CD_IDLE;
	endcase
endfunction

function [17:0] seq_select_dat;
	input [2:0] next_state;
	input [17:0] wrid;
	input [17:0] rdid;
	input [17:0] addr;
	input [17:0] data;
	case(next_state) 
		P_SCCB_IDLE          : seq_select_dat = P_SEQ_CD_IDLE;
		P_SCCB_SENDING_START : seq_select_dat = P_SEQ_CD_START;
		P_SCCB_SENDING_IDW   : seq_select_dat = wrid;
		P_SCCB_SENDING_ADDR  : seq_select_dat = addr;
		P_SCCB_SENDING_DATA  : seq_select_dat = data;
		P_SCCB_SENDING_IDR   : seq_select_dat = rdid;
		P_SCCB_RECEIVING_DAT : seq_select_dat = P_SEQ_CD_IDLE;
		P_SCCB_SENDING_STOP  : seq_select_dat = P_SEQ_CD_END;
		default              : seq_select_dat = P_SEQ_CD_IDLE;
	endcase
endfunction

function [17:0] seq_select_oe;
	input [2:0] next_state;
	case(next_state) 
		P_SCCB_IDLE          : seq_select_oe  = P_SEQ_OE_START;
		P_SCCB_SENDING_START : seq_select_oe  = P_SEQ_OE_START;
		P_SCCB_SENDING_IDW   : seq_select_oe  = P_SEQ_RUN_WOE;
		P_SCCB_SENDING_ADDR  : seq_select_oe  = P_SEQ_RUN_WOE;
		P_SCCB_SENDING_DATA  : seq_select_oe  = P_SEQ_RUN_WOE;
		P_SCCB_SENDING_IDR   : seq_select_oe  = P_SEQ_RUN_WOE;
		P_SCCB_RECEIVING_DAT : seq_select_oe  = P_SEQ_RUN_ROE;
		P_SCCB_SENDING_STOP  : seq_select_oe  = P_SEQ_OE_END;
		default              : seq_select_oe  = P_SEQ_OE_START;
	endcase
endfunction


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

reg  [2:0] r_sccb_next;
reg        r_update_seq;
reg  [4:0] r_seq_cnt;
reg  [8:0] r_read_data;
wire       w_seq_cnt_done;
assign w_seq_cnt_done = (r_seq_cnt == 5'd17);

assign w_seq_sio_c = seq_select_clk(r_sccb_next);
assign w_seq_sio_d = seq_select_dat(r_sccb_next, w_seq_dat_wrid, w_seq_dat_rdid, w_seq_dat_addr, w_seq_dat_data);
assign w_seq_sio_d_oe = seq_select_oe(r_sccb_next);

always @ (posedge w_sccb_gclk or negedge sccb_reset_n)
	if(~sccb_reset_n) begin
		r_sccb_state <= #`D P_SCCB_IDLE;
		r_sccb_next  <= #`D P_SCCB_IDLE;
		r_update_seq <= #`D 1'b0;
		r_seq_cnt    <= #`D 5'd0;
		r_sdata      <= #`D 8'h00;
		r_sresp      <= #`D 2'b00;
	end else begin
		r_seq_cnt    <= #`D w_sccb_idle ? 5'd0 : w_seq_cnt_done ? 5'd0 : r_seq_cnt + 5'd1;
		r_update_seq <= #`D w_sccb_idle ? (w_mcmd_valid ? 1'b1 : 1'b0) : w_seq_cnt_done ? 1'b1 : 1'b0;
		if(r_sccb_state == P_SCCB_IDLE) begin
			r_sccb_next  <= #`D P_SCCB_SENDING_START;
			r_sccb_state <= #`D w_mcmd_valid   ? P_SCCB_SENDING_START : r_sccb_state;
			r_sresp      <= #`D w_mcmd_valid & w_wr_en ? 2'b01 : 2'b00; // No response or DVA
			r_sdata      <= #`D 8'h00;
		end else if(r_sccb_state == P_SCCB_SENDING_START) begin
			r_sccb_next  <= #`D P_SCCB_SENDING_IDW;
			r_sccb_state <= #`D w_seq_cnt_done ? P_SCCB_SENDING_IDW : r_sccb_state;
			r_sresp      <= #`D 2'b00; // No response
		end else if(r_sccb_state == P_SCCB_SENDING_IDW) begin
			r_sccb_next  <= #`D P_SCCB_SENDING_ADDR;
			r_sccb_state <= #`D w_seq_cnt_done ? P_SCCB_SENDING_ADDR : r_sccb_state;
		end else if(r_sccb_state == P_SCCB_SENDING_ADDR) begin
			r_sccb_next  <= #`D (w_wr_en?P_SCCB_SENDING_DATA:P_SCCB_SENDING_IDR);
			r_sccb_state <= #`D w_seq_cnt_done ? (w_wr_en?P_SCCB_SENDING_DATA:P_SCCB_SENDING_IDR) : r_sccb_state;
		end else if(r_sccb_state == P_SCCB_SENDING_DATA) begin
			r_sccb_next  <= #`D P_SCCB_SENDING_STOP;
			r_sccb_state <= #`D w_seq_cnt_done ? P_SCCB_SENDING_STOP  : r_sccb_state;
		end else if(r_sccb_state == P_SCCB_SENDING_IDR) begin
			r_sccb_next  <= #`D P_SCCB_RECEIVING_DAT;
			r_sccb_state <= #`D w_seq_cnt_done ? P_SCCB_RECEIVING_DAT : r_sccb_state;
		end else if(r_sccb_state == P_SCCB_RECEIVING_DAT) begin
			r_sccb_next  <= #`D P_SCCB_SENDING_STOP;
			r_sccb_state <= #`D w_seq_cnt_done ? P_SCCB_SENDING_STOP  : r_sccb_state;
			r_sresp      <= #`D w_seq_cnt_done ? 2'b01 : 2'b00; // DVA
			r_sdata      <= #`D w_seq_cnt_done ? r_read_data[8:1] : r_sdata;
		end else if(r_sccb_state == P_SCCB_SENDING_STOP) begin
			r_sccb_next  <= #`D P_SCCB_IDLE;
			r_sccb_state <= #`D w_seq_cnt_done ? P_SCCB_IDLE          : r_sccb_state;
			r_sresp      <= #`D 2'b00; // No response
			r_sdata      <= #`D 8'h00;
		end
	end

always @ (posedge w_sccb_gclk or negedge sccb_reset_n) 
	if(~sccb_reset_n) begin
		r_sio_c_pre    <= #`D 1'b1;
		r_sio_d        <= #`D 1'b1;
		r_sio_d_oe     <= #`D 1'b0;
		r_seq_sio_c    <= #`D 18'h3ffff;
		r_seq_sio_d    <= #`D 18'h3ffff;
		r_seq_sio_d_oe <= #`D 18'h3ffff;
		r_read_data    <= #`D 9'h000;
	end else begin
		r_sio_c_pre    <= #`D r_seq_sio_c[17];
		r_sio_d        <= #`D r_seq_sio_d[17];
		r_sio_d_oe     <= #`D r_seq_sio_d_oe[17];
		r_seq_sio_c    <= #`D r_update_seq ? w_seq_sio_c   : {r_seq_sio_c[16:0], 1'b1};
		r_seq_sio_d    <= #`D r_update_seq ? w_seq_sio_d   : {r_seq_sio_d[16:0], 1'b1};
		r_seq_sio_d_oe <= #`D r_update_seq ? w_seq_sio_d_oe: {r_seq_sio_d_oe[16:0], 1'b1} ;
		r_read_data    <= #`D (!r_sio_d_oe & r_sio_c_pre & !r_seq_sio_c[17]) ? {r_read_data[7:0], w_sio_din} : r_read_data;
	end

always @ (posedge w_sccb_gwclk or negedge sccb_reset_n) 
	if(~sccb_reset_n) r_sio_c <= #`D 1'b1;
	else              r_sio_c <= #`D r_sio_c_pre;


assign debug_out = {r_sio_c, r_sio_d, r_sio_d_oe, scmdaccept, 2'b00, r_sccb_state};

endmodule

