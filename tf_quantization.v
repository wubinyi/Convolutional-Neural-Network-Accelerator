// Company           :   tud
// Author            :   binyiwu
// E-Mail            :   <$ICPRO_EMAIL not set - insert email address>
//
// Filename          :   tf_quantization.v
// Project Name      :   p_eval
// Subproject Name   :   s_deepl
// Description       :   <short description>
//
// Create Date       :   Tue Nov 28 11:37:09 2017
// Last Change       :   $Date$
// by                :   $Author$
//------------------------------------------------------------
module tf_quantization(
	clk,
	layer_reset,
	stage_finish_i,
	quan_weight_zero_i,
	tf_quantization_en_i,
	neuron_activation_i,
	quan_scale_o
	);


parameter NEURON_ACTIV_BIT_WIDTH = 8;
parameter SUM_QUAN_OFFSET_BIT_WIDTH = 16;
parameter INIT_SUM_QUAN_OFFSET = 16'd0;
parameter QUAN_SCALE_BIT_WIDTH = 24;
parameter INI_QUAN_SCALE = 24'h0;
parameter QUAN_WEIGHT_ZERO_BIT_WIDTH = 8;

input 									clk;
input 									layer_reset;
input 									stage_finish_i;
input [QUAN_WEIGHT_ZERO_BIT_WIDTH-1:0] 	quan_weight_zero_i;
input 									tf_quantization_en_i;
input  [NEURON_ACTIV_BIT_WIDTH-1:0] 	neuron_activation_i;
output reg [QUAN_SCALE_BIT_WIDTH-1:0] 		quan_scale_o;

// sum of neuron activation
reg [SUM_QUAN_OFFSET_BIT_WIDTH-1:0] sum_quan_offset;
always @(posedge clk or posedge layer_reset) begin
	if (layer_reset) begin
		sum_quan_offset <= INIT_SUM_QUAN_OFFSET;
	end
	else if (tf_quantization_en_i) begin
		if (stage_finish_i) begin
			sum_quan_offset <= neuron_activation_i;
		end
		else begin
			sum_quan_offset <= sum_quan_offset + neuron_activation_i;
		end
	end
	// if (stage_finish_i) begin
	// 	sum_quan_offset <= neuron_activation_i;
	// end 
	// else if (tf_quantization_en_i) begin
	// 	sum_quan_offset <= sum_quan_offset + neuron_activation_i;
	// end
end

always @(posedge clk) begin
	if (tf_quantization_en_i) begin
		if (stage_finish_i) begin
			quan_scale_o <= sum_quan_offset * quan_weight_zero_i;
		end
	end
	// else begin
	// 	quan_scale_o <= INI_QUAN_SCALE;
	// end
end

endmodule