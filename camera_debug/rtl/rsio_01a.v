`define D 1
`timescale 1ns/1ns

module rsio_01a (
	pavsv01a2rsio_01aRSClk,
	pavsv01a2rsio_01aReset_n,
	swdec01a2rsio_01aTestMode,
	dbgif01a2rsio_01aTxBitRate,
	dbgif01a2rsio_01aTxStart,
	dbgif01a2rsio_01aTxData,
	rsio_01a2dbgif01aTxStatus,
	dbgif01a2rsio_01aRxBitRate,
	dbgif01a2rsio_01aRxFetch,
	rsio_01a2dbgif01aRxData,
	rsio_01a2dbgif01aRxStatus,
	xipRXD1,
	xopTXD1,
	xipRXD2,
	xopTXD2
);

input         pavsv01a2rsio_01aRSClk;
input         pavsv01a2rsio_01aReset_n;
input  [3:0]  swdec01a2rsio_01aTestMode;

input  [3:0]  dbgif01a2rsio_01aTxBitRate;
input         dbgif01a2rsio_01aTxStart;
input  [7:0]  dbgif01a2rsio_01aTxData;
output        rsio_01a2dbgif01aTxStatus;

input  [3:0]  dbgif01a2rsio_01aRxBitRate;
input         dbgif01a2rsio_01aRxFetch;
output [7:0]  rsio_01a2dbgif01aRxData;
output [1:0]  rsio_01a2dbgif01aRxStatus;

input         xipRXD1;
output        xopTXD1;
input         xipRXD2;
input         xopTXD2;

wire          w_TXD;
wire          w_TxData;

assign        xopTXD1 = w_TXD;
reg           r_divTxClk;

// TestMode Override
//   TestMode definition
//     4'b0000 : Normal   mode
//     4'b0001 : Loopback mode (xipRXD1 -> xopTXD1)
//     4'b0010 : Bypass   mode (xipRXD2 -> xopTXD1)
//     4'b0100 : Copy     mode (xopTXD2 -> xopTXD1)
//     4'b1000 : RS Clock mode
assign        w_TXD = swdec01a2rsio_01aTestMode[3] ? r_divTxClk : 
                      swdec01a2rsio_01aTestMode[2] ? xopTXD2 :
                      swdec01a2rsio_01aTestMode[1] ? xipRXD2 :
                      swdec01a2rsio_01aTestMode[0] ? xipRXD1 : w_TxData;

wire w_TxClk;
wire w_RxClk;
wire w_RxReset_n;

always @ (posedge w_TxClk or negedge pavsv01a2rsio_01aReset_n)
	if(~pavsv01a2rsio_01aReset_n) r_divTxClk <= #`D 1'b0;
	else                          r_divTxClk <= #`D ~r_divTxClk;
	
/******************************************************************
*                       RS232-C Tx interface                      *
******************************************************************/
rsclk01a  i_TxClk (
	.gatedClk(w_TxClk),                      // 1 bit output
	.BitRateSel(dbgif01a2rsio_01aTxBitRate), // 4 bit input 
	.reset_n(pavsv01a2rsio_01aReset_n),      // 1 bit input 
	.F25Clk(pavsv01a2rsio_01aRSClk)          // 1 bit input 
);

rstx_01a  rxtx_01a (
	.F25Clk(pavsv01a2rsio_01aRSClk),
	.txParallelData(dbgif01a2rsio_01aTxData),  // 8 bit input 
	.reset_n(pavsv01a2rsio_01aReset_n),        // 1 bit input 
	.txSerialData(w_TxData),                   // 1 bit output
	.txTrigger(dbgif01a2rsio_01aTxStart),      // 1 bit input 
	.tx_clk(w_TxClk),                          // 1 bit input 
	.txStatus(rsio_01a2dbgif01aTxStatus)       // 1 bit output
);

/******************************************************************
*                       RS232-C Rx interface                      *
******************************************************************/
rsclk01a  i_RxClk (
	.gatedClk(w_RxClk),                      // 1 bit output
	.BitRateSel(dbgif01a2rsio_01aRxBitRate), // 4 bit input 
	.reset_n(w_RxReset_n),                   // 1 bit input 
	.F25Clk(pavsv01a2rsio_01aRSClk)          // 1 bit input 
);

rsrx_01a  rxrx_01a (
	.rxParallelData(rsio_01a2dbgif01aRxData), // 8 bit output
	.rxStatus(rsio_01a2dbgif01aRxStatus),     // 2 bit output
	.rx_clk(w_RxClk),                         // 1 bit input 
	.rxSerialData(xipRXD1),                   // 1 bit input 
	.reset_n(pavsv01a2rsio_01aReset_n),       // 1 bit input 
	.rxTrigger(dbgif01a2rsio_01aRxFetch),     // 1 bit input 
	.sample_clk(pavsv01a2rsio_01aRSClk),      // 1 bit input 
	.rxClkReset_n(w_RxReset_n)                // 1 bit output
);

endmodule

