// Company           :   tud
// Author            :   binyiwu
// E-Mail            :   <$ICPRO_EMAIL not set - insert email address>
//
// Filename          :   mac.v
// Project Name      :   sa_wubinyi
// Subproject Name   :   cnn_accelerator
// Description       :   <short description>
//
// Create Date       :   Mon Oct 16 08:31:02 2017
// Last Change       :   $Date$
// by                :   $Author$
//------------------------------------------------------------
module mac(
	clk,
	layer_reset,
	stage_finish,
	mac_en,
	neuron,
	weight,
	accumulator
	);

parameter INPUT_BIT_WIDTH   = 8;         // bit-width of neuron-input: 8-bit
parameter PRODUCT_BIT_WIDTH = 16+4;        // bit-width of product
parameter OUTPUT_BIT_WIDTH  = 16+6+2;      // bit-width of output register: sum of 36 number,increase bit-width with 6-bits, total 16+6
parameter INI_ACCUMULATOR   = 24'h000000; 

input                             clk;
input                             layer_reset;
input                             stage_finish;
input                             mac_en;
input      [INPUT_BIT_WIDTH-1:0]  neuron;
input      [INPUT_BIT_WIDTH-1:0]  weight;
output     [OUTPUT_BIT_WIDTH-1:0] accumulator;

wire [PRODUCT_BIT_WIDTH-1:0] product;
wire [OUTPUT_BIT_WIDTH-1:0]  sum;
multiplier inst_multiplier(
	.clk(clk),
	//.layer_reset(layer_reset),
	.multi_en(mac_en),
	.multiplicator(neuron),
	.multiplicand(weight),
	.product(product)
	);

// pipelline
reg adder_en;
always @(posedge clk) begin
	adder_en <= mac_en;
end
adder inst_adder(
	.clk(clk),
	.layer_reset(layer_reset),
	.stage_finish(stage_finish),
	.adder_en(adder_en),
	.addend(product),
	.sum(sum)
	);

assign accumulator = sum;
// always @(posedge clk or posedge layer_reset) begin
// 	if (layer_reset) begin
// 		accumulator <= INI_ACCUMULATOR;
// 	end
// 	else if(mac_en) begin
// 		accumulator <= sum;
// 	end
// end

endmodule