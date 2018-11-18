// Company           :   tud
// Author            :   binyiwu
// E-Mail            :   <$ICPRO_EMAIL not set - insert email address>
//
// Filename          :   sram.v
// Project Name      :   p_eval
// Subproject Name   :   s_deepl
// Description       :   <short description>
//
// Create Date       :   Tue Dec  5 11:10:55 2017
// Last Change       :   $Date: 2017-12-05 12:11:14 +0100 (Tue, 05 Dec 2017) $
// by                :   $Author: binyiwu $
//------------------------------------------------------------
module sram(
	clk,
	cnna_mem_read_en_i,
	cnna_mem_write_en_i,
	cnna_mem_address_i,
	data_from_cnna_i,
	data_to_cnna_o,

	udp_mem_read_en_i,
	udp_mem_write_en_i,	
	udp_mem_address_i,
	data_from_udp_i,
	data_to_udp_o	
	);

parameter MEM_ADDR_BIT_WIDTH = 8;
parameter CNNA_INPUT_DATA_BIT_WIDTH = 8*16;
parameter CNNA_OUTPUT_DATA_BIT_WIDTH = 32*16;

input 										clk;
input                                       cnna_mem_read_en_i;
input                                       cnna_mem_write_en_i;
input      [MEM_ADDR_BIT_WIDTH-1:0]         cnna_mem_address_i;
input      [CNNA_OUTPUT_DATA_BIT_WIDTH-1:0] data_from_cnna_i;
output reg [CNNA_INPUT_DATA_BIT_WIDTH-1:0]  data_to_cnna_o;

input 										udp_mem_read_en_i;
input 										udp_mem_write_en_i;
input      [MEM_ADDR_BIT_WIDTH-1:0] 		udp_mem_address_i;
input      [CNNA_INPUT_DATA_BIT_WIDTH-1:0]  data_from_udp_i;
output reg [CNNA_OUTPUT_DATA_BIT_WIDTH-1:0] data_to_udp_o;

// sram for data to CNNA
reg [CNNA_INPUT_DATA_BIT_WIDTH-1:0] data_to_cnna [255:0];
always @(posedge clk) begin
	if (cnna_mem_read_en_i) begin
		data_to_cnna_o <= data_to_cnna[cnna_mem_address_i];
	end
	else if(udp_mem_write_en_i) begin
		data_to_cnna[udp_mem_address_i] <= data_from_udp_i;
	end
end

// sram for storing data from CNNA
reg [CNNA_OUTPUT_DATA_BIT_WIDTH-1:0] data_from_cnna [255:0];
always @(posedge clk) begin
	if (cnna_mem_write_en_i) begin
		data_from_cnna[cnna_mem_address_i] <= data_from_cnna_i;
	end
	else if (udp_mem_read_en_i) begin
		data_to_udp_o <= data_from_cnna[udp_mem_address_i];
	end
end

endmodule