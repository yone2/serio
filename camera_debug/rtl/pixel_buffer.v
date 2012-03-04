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
	txStart,
	SRADDR,
	SROE_N,
	SRWE_N,
	SRCE1_N,
	SRCE2_N,
	SRDATA1,
	SRDATA2
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
output [17:0] SRADDR;
output        SROE_N;
output        SRWE_N;
output        SRCE1_N;
output        SRCE2_N;
inout  [15:0] SRDATA1;
inout  [15:0] SRDATA2;

// use SRAM 1 only
assign SRCE1_N = 1'b0;
assign SRDATA2 = SROE_N ? r_writeData : 16'hz;
assign SRCE2_N = 1'b1;
assign SRDATA2 = 16'hz;

reg    [17:0] r_writeAddr;
reg           r_validWrite;

always @ (posedge writeClk or negedge writeRst_n) 
	if(~writeRst_n) r_writeAddr <= #`D 18'h00000;
	else            r_writeAddr <= #`D r_validWrite ? r_writeAddr+18'h1 : r_writeAddr;


endmodule

