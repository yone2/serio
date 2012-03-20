`timescale 1ns/1ps

module top (
	xipMCLK,
	xipRESET,
//	xonOE, xonWE, xopAddr,
//	xonCE1, xonUB1, xonLB1, xbpDATA1,
//	xonCE2, xonUB2, xonLB2, xbpDATA2,
	xopCAM_PWDN,
	xipCAM_VSYNC,
	xipCAM_HREF,
	xipCAM_PCLK,
	xipCAM_STROBE,
	xopCAM_XCLK,
	xonCAM_RESET,
	xopCAM_SIO_C,
	xbpCAM_SIO_D,
	xipCAM_D,
	xopTXD,
	xipRXD,
	xopLD7, xopLD6, xopLD5, xopLD4, xopLD3, xopLD2, xopLD1, xopLD0,
);
// System IO
input       xipMCLK;     // T9
input       xipRESET;    // L14

//// SRAM interface
//output        xonOE;     // K4
//output        xonWE;     // G3
//output [17:0] xopAddr;   // {L3,K5,K3,J3,J4,H4,H3,G5,E4,E3,F4,F3,G4,L4,M3,M4,N3,L5}
//output        xonCE1;    // P7
//output        xonUB1;    // T4
//output        xonLB1;    // P6
//inout  [15:0] xbpDATA1;  // {R1,P1,L2,J2,H1,F2,P8,D3,B1,C1,C2,R5,T5,R6,T8,N7}
//output        xonCE2;    // N5
//output        xonUB2;    // R4
//output        xonLB2;    // P5
//inout  [15:0] xbpDATA2;  // {N1,M1,K2,C3,F5,G1,E2,D2,D1,E1,G2,J1,K1,M2,N2,P2}

// Camera IO
output      xopCAM_PWDN;
input       xipCAM_VSYNC;
input       xipCAM_HREF;
input       xipCAM_PCLK;
input       xipCAM_STROBE; // open input (no use)
output      xopCAM_XCLK;
output      xonCAM_RESET;
output      xopCAM_SIO_C;
inout       xbpCAM_SIO_D;
input [7:0] xipCAM_D;

// LEDs
output      xopLD7;    // P11
output      xopLD6;    // P12
output      xopLD5;    // N12
output      xopLD4;    // P13
output      xopLD3;    // N14
output      xopLD2;    // L12
output      xopLD1;    // P14
output      xopLD0;    // K12

// RS232C
output      xopTXD;    // R13
input       xipRXD;    // T13

wire w_RSClk;
wire w_RSReset_n;
wire w_SCCBClk;
wire w_SCCBReset_n;
wire w_CamClk;
wire w_CamReset_n;
wire w_PReset_n;

clk_reset clk_reset(
	.mclk         (xipMCLK),
	.reset_n      (~xipRESET),
	.rs_clk       (w_RSClk),
	.rs_reset_n   (w_RSReset_n),
	.sccb_clk     (w_SCCBClk),
	.sccb_reset_n (w_SCCBReset_n),
	.cam_clk      (w_CamClk),
	.cam_reset_n  (w_CamReset_n),
	.pclk         (xipCAM_PCLK),
	.preset_n     (w_PReset_n)
);

wire       w_frameStart;
wire       w_frameEnd;
wire       w_writeEn;
wire [7:0] w_writeData;
wire       w_readStart;
wire [7:0] w_readData;
wire       w_txStatus;

assign xopCAM_XCLK  = w_CamClk;
assign xonCAM_RESET = w_CamReset_n;

//assign xipUB1 = 1'b0;
//assign xipLB1 = 1'b0;
//assign xipUB2 = 1'b0;
//assign xipLB2 = 1'b0;
pixel_buffer pixel_buffer(
	.writeClk  (xipCAM_PCLK),
	.writeRst_n(w_PReset_n),
	.VSYNC     (xipCAM_VSYNC),
	.HREF      (xipCAM_HREF),
	.DATA      (xipCAM_D),
	.readClk   (w_RSClk),
	.readRst_n (w_RSReset_n),
	.readData  (w_readData),
	.txStatus  (w_txStatus),
	.txStart   (w_readStart)
//	.SRADDR    (xopAddr),
//	.SROE_N    (xonOE),
//	.SRWE_N    (xonWE),
//	.SRCE1_N   (xonCE1),
//	.SRCE2_N   (xonCE2),
//	.SRDATA1   (xbpDATA1),
//	.SRDATA2   (xbpDATA2)
);

rsio_01a rsio_01a(
	.pavsv01a2rsio_01aRSClk    (w_RSClk),
	.pavsv01a2rsio_01aReset_n  (w_RSReset_n),
	.swdec01a2rsio_01aTestMode (4'b0000), // tie 0
	.dbgif01a2rsio_01aTxBitRate(4'h7),    // tie const
	.dbgif01a2rsio_01aTxStart  (w_readStart),
	.dbgif01a2rsio_01aTxData   (w_readData),
	.rsio_01a2dbgif01aTxStatus (w_txStatus),
	.dbgif01a2rsio_01aRxBitRate(4'h7),    // tie const
	.dbgif01a2rsio_01aRxFetch  (1'b0),    // tie 0
	.rsio_01a2dbgif01aRxData   (),        // open
	.rsio_01a2dbgif01aRxStatus (),        // open
	.xipRXD1(xipRXD),
	.xopTXD1(xopTXD),
	.xipRXD2(1'b0),                       // tie 0
	.xopTXD2(1'b0)                        // tie 0
);

wire  [7:0] w_sccb_div;
wire  [2:0] w_mcmd;
wire [14:0] w_maddr;
wire  [7:0] w_mdata;
wire        w_scmdaccept;
wire  [1:0] w_sresp;
wire  [7:0] w_sdata;
wire  [7:0] w_debug_out;
assign {xopLD7,xopLD6,xopLD5,xopLD4,xopLD3,xopLD2,xopLD1,xopLD0} = w_debug_out;

sccb_bridge sccb_bridge(
	.sccb_clk(w_SCCBClk),
	.sccb_reset_n(w_SCCBReset_n),
	.sccb_div(w_sccb_div),
	.sio_c(xopCAM_SIO_C),
	.sio_d(xbpCAM_SIO_D),
	.pwdn(xopCAM_PWDN),
	.mcmd(w_mcmd),
	.maddr(w_maddr),
	.mdata(w_mdata),
	.scmdaccept(w_scmdaccept),
	.sresp(w_sresp),
	.sdata(w_sdata),
	.debug_out(w_debug_out)
);

sccb_config sccb_config(
	.config_clk(w_SCCBClk), 
	.config_reset_n(w_SCCBReset_n), 
	.sccb_div(w_sccb_div), 
	.mcmd(w_mcmd),
	.maddr(w_maddr),
	.mdata(w_mdata),
	.scmdaccept(w_scmdaccept),
	.sresp(w_sresp),
	.sdata(w_sdata)
);
endmodule

