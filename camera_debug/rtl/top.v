module top (
	xipMCLK,
	xipRESET,
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
input       xipMCLK;
input       xipRESET;

// Camera IO
output      xopCAM_PWDN;
input       xipCAM_VSYNC;
input       xipCAM_HREF;
input       xipCAM_PCLK;
input       xipCAM_STROBE;
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
output      xopTXD;
input       xipRXD;

wire w_RSClk;
wire w_RSReset_n;
wire w_SCCBClk;
wire w_SCCBReset_n;
wire w_CamClk;
wire w_CamReset_n;

clk_reset clk_reset(
	.mclk         (xipMCLK),
	.reset_n      (~xipRESET),
	.rs_clk       (w_RSClk),
	.rs_reset_n   (w_RSReset_n),
	.sccb_clk     (w_SCCBClk),
	.sccb_reset_n (w_SCCBReset_n),
	.cam_clk      (w_CamClk),
	.cam_reset_n  (w_CamReset_n)
);

wire       w_frameStart;
wire       w_frameEnd;
wire       w_writeEn;
wire [7:0] w_writeData;
wire       w_readStart;
wire [7:0] w_readData;
wire       w_txStatus;

assign xonCAM_RESET = w_CamReset_n;

//dump_ctrl dump_ctrl(
//	.frameStart(w_frameStart),
//	.frameEnd  (w_frameEnd),
//	.writeClk  (xipCAM_PCLK),
//	.writeEn   (w_writeEn),
//	.writeData (w_writeData),
//	.readClk   (w_RSClk),
//	.readStart (w_readStart),
//	.readData  (w_readData),
//	.txStatus  (w_txStatus)
//);

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

