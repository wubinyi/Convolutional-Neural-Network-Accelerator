// Company           :   tud
// Author            :   binyiwu
// E-Mail            :   <$ICPRO_EMAIL not set - insert email address>
//
// Filename          :   quad_accumulator_adder.v
// Project Name      :   sa_wubinyi
// Subproject Name   :   cnn_accelerator
// Description       :   <short description>
//
// Create Date       :   Mon Oct 16 09:11:41 2017
// Last Change       :   $Date$
// by                :   $Author$
//------------------------------------------------------------
module quad_accumulator_adder(
	clk,
	adders_flag_i,
	stage_finish_pipeline_3_i,
	accumulator_0_i,
	accumulator_1_i,
	accumulator_2_i,
	accumulator_3_i,
	accumulator_o
	);

parameter ACCUMULATOR_BIT_WIDTH  = 16+6+2;      // bit-width of output register: sum of 36 number,increase bit-width with 6-bits, total 16+6; 22-->24
parameter TEMP_BIT_WIDTH     = 16+6+2;  // 23-->24
parameter OUTPUT_BIT_WIDTH  = 16+6+6;  // 24-->28
parameter INI_OUTPUT        = 28'h0000000;
parameter ADDERS_FLAG_BIT_WIDTH = 2;

input                             clk;
input [ADDERS_FLAG_BIT_WIDTH-1:0] adders_flag_i;
input                             stage_finish_pipeline_3_i;
input [ACCUMULATOR_BIT_WIDTH-1:0] accumulator_0_i;
input [ACCUMULATOR_BIT_WIDTH-1:0] accumulator_1_i;
input [ACCUMULATOR_BIT_WIDTH-1:0] accumulator_2_i;
input [ACCUMULATOR_BIT_WIDTH-1:0] accumulator_3_i;
output reg [OUTPUT_BIT_WIDTH-1:0] accumulator_o;

reg adder_0_flag;
reg adder_1_flag;
reg adder_2_flag;
always @(adders_flag_i) begin
	case(adders_flag_i)
		2'b00: begin
			adder_0_flag = 1'b0;
			adder_1_flag = 1'b0;
			adder_2_flag = 1'b0;
		end
		2'b01: begin
			adder_0_flag = 1'b1;
			adder_1_flag = 1'b0;
			adder_2_flag = 1'b0;
		end
		2'b10: begin
			adder_0_flag = 1'b1;
			adder_1_flag = 1'b0;
			adder_2_flag = 1'b1;		
		end
		2'b11: begin
			adder_0_flag = 1'b1;
			adder_1_flag = 1'b1;
			adder_2_flag = 1'b1;		
		end
	endcase
end

reg [TEMP_BIT_WIDTH-1:0] accumulator_temp_0;
always @(posedge clk) begin
	if (stage_finish_pipeline_3_i) begin
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
	if (stage_finish_pipeline_3_i) begin
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
	pipeline_finish <= stage_finish_pipeline_3_i;
end
always @(posedge clk) begin
	if (pipeline_finish) begin
		if (adder_2_flag) begin
			accumulator_o <= {{4{accumulator_temp_0[TEMP_BIT_WIDTH-1]}}, accumulator_temp_0} + 
								{{4{accumulator_temp_1[TEMP_BIT_WIDTH-1]}}, accumulator_temp_1};
		end
		else begin
			accumulator_o <= {{4{accumulator_temp_0[TEMP_BIT_WIDTH-1]}}, accumulator_temp_0};
		end		
	end
end

endmodule