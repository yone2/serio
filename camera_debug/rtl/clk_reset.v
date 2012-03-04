`timescale 1ns/1ns
`define D 1

module clk_reset ( mclk, reset_n, rs_clk, rs_reset_n, sccb_clk, sccb_reset_n, cam_clk, cam_reset_n, pclk, preset_n);
input mclk;
input reset_n;
output rs_clk;
output rs_reset_n;
output sccb_clk;
output sccb_reset_n;
output cam_clk;
output cam_reset_n;
input  pclk;
output preset_n;

reg div2clk;
wire w_Reset_MCLKsync_n;

// clock division
always @ (posedge mclk or negedge w_Reset_MCLKsync_n) 
	if(~w_Reset_MCLKsync_n) div2clk <= #`D 1'b0;
	else                    div2clk <= #`D ~div2clk;

assign rs_clk    = div2clk;
assign sccb_clk  = div2clk;
assign cam_clk   = div2clk;

// Reset synchronization
syncd01a  i_reset_sync (
	.clk(mclk),            // 1 bit input 
	.reset_n(1'b1),        // 1 bit input 
	.d(reset_n),           // 1 bit input 
	.q(w_Reset_MCLKsync_n) // 1 bit output
);
rsync02a  i_reset_rs (
	.clk(rs_clk),                    // 1 bit input 
	.reset_in(w_Reset_MCLKsync_n),   // 1 bit input 
	.reset_out(rs_reset_n)           // 1 bit output
);
rsync02a  i_reset_sccb (
	.clk(sccb_clk),                  // 1 bit input 
	.reset_in(w_Reset_MCLKsync_n),   // 1 bit input 
	.reset_out(sccb_reset_n)         // 1 bit output
);
rsync02a  i_reset_cam (
	.clk(cam_clk),                   // 1 bit input 
	.reset_in(w_Reset_MCLKsync_n),   // 1 bit input 
	.reset_out(cam_reset_n)          // 1 bit output
);
rsync02a  i_reset_p (
	.clk(pclk),                      // 1 bit input 
	.reset_in(w_Reset_MCLKsync_n),   // 1 bit input 
	.reset_out(preset_n)             // 1 bit output
);

endmodule

