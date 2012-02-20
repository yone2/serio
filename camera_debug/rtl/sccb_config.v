`define D 1
`timescale 1ns/1ps

module sccb_config(
	config_clk, config_reset_n, 
	sccb_div, mcmd, maddr, mdata, 
	scmdaccept, sresp, sdata
);
input         config_clk;
input         config_reset_n;
output  [7:0] sccb_div;
output  [2:0] mcmd;
output [14:0] maddr;
output  [7:0] mdata;
input         scmdaccept;
input   [1:0] sresp;
input   [7:0] sdata;

assign sccb_div = 8'd50;

reg [7:0] r_rom_addr;
reg [2:0] r_mcmd;
reg [7:0] r_maddr;
reg [7:0] r_mdata;
assign mcmd     = {1'b0, r_mcmd};
assign maddr    = {7'b0100001, r_maddr};
assign mdata    = r_mdata;

wire [1:0] w_cmd;
wire [7:0] w_addr;
wire [7:0] w_data;
case_rom case_rom(
	.romaddr(r_rom_addr), 
	.t_cmd(w_cmd),
	.t_addr(w_addr),
	.t_data(w_data)
);

always @ (posedge config_clk or negedge config_reset_n)
	if(~config_reset_n) begin
		r_mcmd     <= #`D 2'b00;
		r_maddr    <= #`D 8'h00;
		r_mdata    <= #`D 8'h00;
	end else begin
		r_mcmd     <= #`D w_cmd;
		r_maddr    <= #`D w_addr;
		r_mdata    <= #`D w_data;
	end

reg [1:0] r_handshake;

always @ (posedge config_clk or negedge config_reset_n)
	if(~config_reset_n) begin
		r_rom_addr  <= #`D 8'h00;
		r_handshake <= #`D 2'b11;
	end else begin
		if(r_handshake == 2'b00) begin // wait scmdaccept
			r_handshake <= #`D scmdaccept ? ((sresp == 2'b01) ? 2'b10 : 2'b01) : r_handshake;
		end else if(r_handshake == 2'b01) begin
			r_handshake <= #`D (sresp == 2'b01) ? 2'b10 : r_handshake;
		end else if(r_handshake == 2'b10) begin
			r_handshake <= #`D 2'b00;
			r_rom_addr  <= #`D (r_rom_addr == 8'hff) ? r_rom_addr : r_rom_addr + 8'h1;
		end else if(r_handshake == 2'b11) begin
			r_handshake <= #`D 2'b00;
		end
	end

endmodule

