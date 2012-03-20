`timescale 1ns/1ps
`define    D  1

module pixel_buffer (
	writeClk,
	writeRst_n,
	VSYNC,
	HREF,
	DATA,
	readClk,
	readRst_n,
	readData,
	txStatus,
	txStart
);
input         writeClk;
input         writeRst_n;
input         VSYNC;
input         HREF;
input   [7:0] DATA;
input         readClk;
input         readRst_n;
output  [7:0] readData;
input         txStatus;
output        txStart;

// latch Video inputs to FF 
reg           r_VSYNC;
reg           r_HREF;
reg     [7:0] r_DATA;
always @ (posedge writeClk or negedge writeRst_n)
	if(~writeRst_n) begin
		r_VSYNC <= #`D 1'b0;
		r_HREF  <= #`D 1'b0;
		r_DATA  <= #`D 8'h00;
	end else begin
		r_VSYNC <= #`D VSYNC;
		r_HREF  <= #`D HREF;
		r_DATA  <= #`D DATA;
	end

// state machine for handling FIFO lock access
// FIFO : 16 bit word, 19200 words (15bit address)
parameter P_ST_INIT      = 2'b00;
parameter P_ST_HREF_ODD  = 2'b01;
parameter P_ST_HREF_EVEN = 2'b10;
parameter P_ST_READ_WAIT = 2'b11;
reg    [1:0]  r_state;
reg           r_SRAMClkSel; // 0: write, 1: read
reg   [15:0]  r_writeBuffer;
reg           r_writeEn;
wire          w_trig_VSYNC;
wire          w_readDone_sync;
wire          w_fifo_full;
wire          w_fifo_empty;

trigp01a VSYNC_trigger(.clk(writeClk), .reset_n(writeRst_n), .in(r_VSYNC), .trigger(w_trig_VSYNC));
syncd01a sync_readdone(.clk(writeClk), .reset_n(writeRst_n), .d(r_readDone), .q(w_readDone_sync));

always @ (posedge writeClk or negedge writeRst_n)
	if(~writeRst_n) begin
		r_state       <= #`D P_ST_INIT;
		r_SRAMClkSel  <= #`D 1'b0;
		r_writeBuffer <= #`D 16'h0000;
		r_writeEn     <= #`D 1'b0;
		r_writeAddr   <= #`D 15'h0000;
	end else begin
		case(r_state)
			P_ST_INIT: begin
				r_state      <= #`D (w_trig_VSYNC & ~w_fifo_full) ? P_ST_HREF_ODD : r_state;
				r_SRAMClkSel <= #`D 1'b0:
				r_writeAddr  <= #`D 15'h0000;
			end
			P_ST_HREF_ODD: begin
				r_state       <= #`D w_trig_VSYNC ? P_ST_WAIT_READ : r_HREF ? P_ST_HREF_EVEN : r_state;
				r_writeBuffer <= #`D r_HREF ? {r_writeBuffer[15:8],r_DATA} : r_writeBuffer;
				r_writeEn     <= #`D 1'b0;
			end
			P_ST_HREF_EVEN: begin
				r_state       <= #`D r_HREF ? P_ST_HREF_ODD : r_state;
				r_writeBuffer <= #`D r_HREF ? {r_DATA,r_writeBuffer[7:0]} : r_writeBuffer;
				r_writeEn     <= #`D r_HREF ? 1'b1 : 1'b0;
				r_writeAddr   <= #`D r_HREF ? r_writeAddr + 15'h1 : r_writeAddr;
			end
			P_ST_WAIT_READ: begin
				r_state       <= #`D w_readDone_sync ? P_ST_INIT : r_state;
				r_SRAMClkSel  <= #`D 1'b1;
			end
			default : r_state <= #`D P_ST_INIT;
		endcase
	end

endmodule

