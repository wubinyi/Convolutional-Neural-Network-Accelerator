// Company           :   tud
// Author            :   binyiwu
// E-Mail            :   <$ICPRO_EMAIL not set - insert email address>
//
// Filename          :   accumulator_adder.v
// Project Name      :   sa_wubinyi
// Subproject Name   :   cnn_accelerator
// Description       :   <short description>
//
// Create Date       :   Mon Oct 16 09:18:43 2017
// Last Change       :   $Date$
// by                :   $Author$
//------------------------------------------------------------
module accumulator_adder(
	clk,
	adders_flag_i,
	stage_finish_pipeline_5_i,
	accumulator_0_i,
	accumulator_1_i,
	accumulator_2_i,
	accumulator_3_i,
	accumulator_o
	);

parameter ACCUMULATOR_BIT_WIDTH  = 16+6+2+4;      // 16+6+2=24 --> 28
parameter TEMP_BIT_WIDTH     = 16+6+2+1+3;        // 25 --> 28 
parameter OUTPUT_BIT_WIDTH  = 16+6+2+2+6;         // 26 --> 32
parameter ADDER_FLAG_BIT_WIDTH = 3;

input                             clk;
input [ADDER_FLAG_BIT_WIDTH-1:0]  adders_flag_i;
input                             stage_finish_pipeline_5_i;
input [ACCUMULATOR_BIT_WIDTH-1:0] accumulator_0_i;
input [ACCUMULATOR_BIT_WIDTH-1:0] accumulator_1_i;
input [ACCUMULATOR_BIT_WIDTH-1:0] accumulator_2_i;
input [ACCUMULATOR_BIT_WIDTH-1:0] accumulator_3_i;
output reg [OUTPUT_BIT_WIDTH-1:0] accumulator_o;

wire adder_0_flag;
wire adder_1_flag;
wire adder_2_flag;
assign {adder_0_flag, adder_1_flag, adder_2_flag} = adders_flag_i;

reg [TEMP_BIT_WIDTH-1:0] accumulator_temp_0;
always @(posedge clk) begin
	if (stage_finish_pipeline_5_i) begin
		if (adder_0_flag) begin
			accumulator_temp_0 <= accumulator_0_i + accumulator_1_i;
		end
		else begin
			accumulator_temp_0 <= accumulator_0_i;		
		end		
	end
end

reg [TEMP_BIT_WIDTH-1:0] accumulator_temp_1;
always @(posedge clk) begin
	if (stage_finish_pipeline_5_i) begin
		if (adder_1_flag) begin
			accumulator_temp_1 <= accumulator_2_i + accumulator_3_i;
		end
		else begin
			accumulator_temp_1 <= accumulator_2_i;
		end
	end
end
reg pipeline_finish;
always @(posedge clk) begin
	pipeline_finish <= stage_finish_pipeline_5_i;
end

always @(posedge clk) begin
	if (pipeline_finish) begin
		if (adder_2_flag) begin
			accumulator_o <= {{4{accumulator_temp_0[TEMP_BIT_WIDTH-1]}}, accumulator_temp_0} + 
								{{4{accumulator_temp_1[TEMP_BIT_WIDTH-1]}},accumulator_temp_1};
		end
		else begin
			accumulator_o <= {{4{accumulator_temp_0[TEMP_BIT_WIDTH-1]}}, accumulator_temp_0};
		end
	end
end

endmodule