module top (
	xipMCLK,
	xinRESET,
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
	xipRXD
);
// System IO
input       xipMCLK;
input       xinRESET;

// Camera IO
output      xopCAM_PWDN;
input       xipCAM_VSYNC;
input       xipCAM_HREF;
input       xipCAM_PCLK;
input       xipCAM_STROBE;
output      xopCAM_XCLK;
output      xonCAM_RESET_N;
output      xopCAM_SIO_C;
inout       xbpCAM_SIO_D;
input [7:0] xipCAM_D;

// RS232C
output      xopTXD;
input       xipRXD;

wire w_RSClk;
wire w_RSReset_n;
wire w_CamClk;
wire w_CamReset_n;

clk_reset clk_reset(
	.mclk       (xipMCLK),
	.reset_n    (xinRESET),
	.rs_clk     (w_RSClk),
	.rs_reset_n (w_RSReset_n),
	.cam_clk    (w_CamClk),
	.cam_reset_n(w_CamReset_n)
);

wire       w_frameStart;
wire       w_frameEnd;
wire       w_writeEn;
wire [7:0] w_writeData;
wire       w_readStart;
wire [7:0] w_readData;
wire       w_txStatus;

dump_ctrl dump_ctrl(
	.frameStart(w_frameStart),
	.frameEnd  (w_frameEnd),
	.writeClk  (xipCAM_PCLK),
	.writeEn   (w_writeEn),
	.writeData (w_writeData),
	.readClk   (w_RSClk),
	.readStart (w_readStart),
	.readData  (w_readData),
	.txStatus  (w_txStatus)
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

endmodule

