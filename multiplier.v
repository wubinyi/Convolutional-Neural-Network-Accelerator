// Company           :   tud
// Author            :   binyiwu
// E-Mail            :   <$ICPRO_EMAIL not set - insert email address>
//
// Filename          :   multiplier.v
// Project Name      :   sa_wubinyi
// Subproject Name   :   cnn_accelerator
// Description       :   <short description>
//
// Create Date       :   Mon Oct 16 08:24:07 2017
// Last Change       :   $Date$
// by                :   $Author$
//------------------------------------------------------------
module multiplier(
	clk,
	//layer_reset,
	multi_en,
	multiplicator,
	multiplicand,
	product
	);

parameter INPUT_BIT_WIDTH   = 8;         // bit-width of neuron-input: 8-bit
parameter PRODUCT_BIT_WIDTH = 16+4;        // bit-width of product
parameter INI_PRODUCT       = 20'h0000;  // initial product

input                              clk;
//input                              layer_reset;
input                              multi_en;
input      [INPUT_BIT_WIDTH-1:0]   multiplicator;
input      [INPUT_BIT_WIDTH-1:0]   multiplicand;
output reg [PRODUCT_BIT_WIDTH-1:0] product;

always @(posedge clk) begin   // or posedge layer_reset
	// if (layer_reset) begin
	// 	product <= INI_PRODUCT;
	// end
	// else if (multi_en) begin
	if (multi_en) begin
		product <= multiplicator * multiplicand;
	end
	else begin
		product <= INI_PRODUCT;
	end
end

endmodule