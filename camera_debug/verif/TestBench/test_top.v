`timescale 1ns/1ns

module test_top;
`define MCLK_HCYCLE 10
`define SIM_TIME    40000000

reg xipMCLK;
reg xipRESET;
wire xopCAM_SIO_C;
wire xbpCAM_SIO_D;
wire xopTXD;
reg  xipRXD;
wire xopLD0;
wire xopLD1;
wire xopLD2;
wire xopLD3;
wire xopLD4;
wire xopLD5;
wire xopLD6;
wire xopLD7;

top top(
	.xipMCLK(xipMCLK),
	.xipRESET(xipRESET),
	.xopCAM_PWDN(),
	.xipCAM_VSYNC(1'b0),
	.xipCAM_HREF(1'b0),
	.xipCAM_PCLK(1'b0),
	.xipCAM_STROBE(1'b0),
	.xopCAM_XCLK(),
	.xonCAM_RESET(),
	.xopCAM_SIO_C(xopCAM_SIO_C),
	.xbpCAM_SIO_D(xbpCAM_SIO_D),
	.xipCAM_D(8'h00),
	.xopTXD(),
	.xipRXD(xipRXD),
	.xopLD7(xopLD7), 
	.xopLD6(xopLD6), 
	.xopLD5(xopLD5), 
	.xopLD4(xopLD4), 
	.xopLD3(xopLD3), 
	.xopLD2(xopLD2), 
	.xopLD1(xopLD1), 
	.xopLD0(xopLD0)
);

/***** Main Sequence *****/
initial begin
	xipRXD = 1'b0;
	#`SIM_TIME $finish;
end

/***** Clock & Reset *****/
always begin
	xipMCLK = 0; #`MCLK_HCYCLE;
	xipMCLK = 1; #`MCLK_HCYCLE;
end

initial begin
	xipRESET = 1'b0; #100
	xipRESET = 1'b1; #100000
	xipRESET = 1'b0;
end

/***** Dump waveform *****/
initial begin
	$dumpfile("test_top.vcd");
	$dumpvars(0, top);
end

endmodule
