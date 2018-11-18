// Company           :   tud
// Author            :   binyiwu
// E-Mail            :   <$ICPRO_EMAIL not set - insert email address>
//
// Filename          :   cache_filter_operand_mac.v
// Project Name      :   sa_wubinyi
// Subproject Name   :   cnn_accelerator
// Description       :   <short description>
//
// Create Date       :   Mon Oct 16 09:07:14 2017
// Last Change       :   $Date$
// by                :   $Author$
//------------------------------------------------------------

module cache_filter_operand_mac(
	clk,
	layer_reset,
	subunit_en_i,
	cache_rd_en_i,
	channel_sel_rd_i,
	address_rd_i,
	cache_wr_en_i,
	channel_sel_wr_i,
	address_wr_i,
	data_input_i,
	channel_switch_en_i,
	addressing_en_i,
	store_data_en_i,
	output_neuron_ac_en_i,
	filter_width_i,
	operand_fetch_en_i,
	filter_fetch_en_i,
	filter_sel_i,
	mac_unit_en_i,
	iteration_i,
	byte_counter_filter_fetch_i,
	stage_finish_i,
	stage_finish_pipeline_i,
	accumulator_0_o,
	accumulator_1_o,
	accumulator_2_o,
	accumulator_3_o,
	accumulator_4_o,
	accumulator_5_o,
	accumulator_6_o,
	accumulator_7_o,
	accumulator_8_o,
	accumulator_9_o,
	accumulator_10_o,
	accumulator_11_o,
	accumulator_12_o,
	accumulator_13_o,
	accumulator_14_o,
	accumulator_15_o,
	tf_quantization_en_i,
	quan_weight_zero_i
	);

parameter INPUT_BIT_WIDTH   = 8;         // bit-width of neuron-input: 8-bit
parameter NUM_OF_FILTERS_BIT_WIDTH = 4;
parameter NUM_OF_MAC_UNIT  = 16;
parameter ITER_BIT_WIDTH    = 6;         // 36 register, need 6-bit to index them
parameter REG_POOL_BIT_WIDTH     = 6;
parameter OUTPUT_BIT_WIDTH  = 16+6+2;      // bit-width of output register: sum of 36 number,increase bit-width with 6-bits, total 16+6

parameter FILTER_WIDTH_BIT_WIDTH   = 3;
parameter FETCH_DATA_BIT_WIDTH     = 56;  // 8 * 7
parameter CACHE_DEPTH_BIT_WIDTH    = 5;  // through 32
parameter CACHE_CHANNELS           = 7;
parameter CACHE_CHANNEL_BIT_WIDTH = 3;         // select channels

// tf quantization
parameter QUAN_SCALE_BIT_WIDTH = 24;
parameter QUAN_WEIGHT_ZERO_BIT_WIDTH = 8;


parameter FALSE                   = 1'b0;
parameter MAC_UNABLE              = 16'h0000;

input                                 clk;
input                                 layer_reset;
input                                 subunit_en_i;
// cache control signal
input                               cache_rd_en_i;
input [CACHE_CHANNELS-1:0]          channel_sel_rd_i;
input [CACHE_DEPTH_BIT_WIDTH-1:0]   address_rd_i;
input                               cache_wr_en_i;
input [CACHE_CHANNEL_BIT_WIDTH-1:0] channel_sel_wr_i;
input [CACHE_DEPTH_BIT_WIDTH-1:0]   address_wr_i;
input [INPUT_BIT_WIDTH-1:0]         data_input_i;
// neuron fetch control signal
input                               channel_switch_en_i;
input                               addressing_en_i;
input                               store_data_en_i;
input                               output_neuron_ac_en_i;
input [FILTER_WIDTH_BIT_WIDTH-1:0]  filter_width_i;
// mac operand fetch control signal
input                               operand_fetch_en_i;
// filter fetch
input                                 filter_fetch_en_i;
input [NUM_OF_FILTERS_BIT_WIDTH-1:0]  filter_sel_i;            // index which filter
input [NUM_OF_MAC_UNIT-1:0]           mac_unit_en_i;
input [ITER_BIT_WIDTH-1:0]            iteration_i;
input [REG_POOL_BIT_WIDTH-1:0]        byte_counter_filter_fetch_i;   // index filter-weight's address
// tf quantization
input                                 stage_finish_pipeline_i;
output reg [OUTPUT_BIT_WIDTH-1:0]         accumulator_0_o;
output reg [OUTPUT_BIT_WIDTH-1:0]         accumulator_1_o;
output reg [OUTPUT_BIT_WIDTH-1:0]         accumulator_2_o;
output reg [OUTPUT_BIT_WIDTH-1:0]         accumulator_3_o;
output reg [OUTPUT_BIT_WIDTH-1:0]         accumulator_4_o;
output reg [OUTPUT_BIT_WIDTH-1:0]         accumulator_5_o;
output reg [OUTPUT_BIT_WIDTH-1:0]         accumulator_6_o;
output reg [OUTPUT_BIT_WIDTH-1:0]         accumulator_7_o;
output reg [OUTPUT_BIT_WIDTH-1:0]         accumulator_8_o;
output reg [OUTPUT_BIT_WIDTH-1:0]         accumulator_9_o;
output reg [OUTPUT_BIT_WIDTH-1:0]         accumulator_10_o;
output reg [OUTPUT_BIT_WIDTH-1:0]         accumulator_11_o;
output reg [OUTPUT_BIT_WIDTH-1:0]         accumulator_12_o;
output reg [OUTPUT_BIT_WIDTH-1:0]         accumulator_13_o;
output reg [OUTPUT_BIT_WIDTH-1:0]         accumulator_14_o;
output reg [OUTPUT_BIT_WIDTH-1:0]         accumulator_15_o;
// quantization: sum
input                                 stage_finish_i;
input 								  tf_quantization_en_i;
input [QUAN_WEIGHT_ZERO_BIT_WIDTH-1:0] quan_weight_zero_i;

//===================================================================================================================================
// control signal part 1 (There are two part)
//===================================================================================================================================
// cache control signal
reg                               cache_rd_en;
//reg [CACHE_CHANNELS-1:0]          channel_sel_rd;
//reg [CACHE_DEPTH_BIT_WIDTH-1:0]   address_rd;
reg                               cache_wr_en;
//reg [CACHE_CHANNEL_BIT_WIDTH-1:0] channel_sel_wr;
//reg [CACHE_DEPTH_BIT_WIDTH-1:0]   address_wr;
//reg [INPUT_BIT_WIDTH-1:0]         data_input;
// neuron fetch control signal
reg                               channel_switch_en;
reg                               addressing_en;
reg                               store_data_en;
reg                               output_neuron_ac_en;
//reg [FILTER_WIDTH_BIT_WIDTH-1:0]  filter_width;
// mac operand fetch control signal
reg                               operand_fetch_en;
// filter fetch
reg                               filter_fetch_en;
//reg [NUM_OF_FILTERS_BIT_WIDTH-1:0]  filter_sel;            // index which filter
//reg [NUM_OF_MAC_UNIT-1:0]           mac_unit_en;
//reg [ITER_BIT_WIDTH-1:0]            iteration;
//reg [REG_POOL_BIT_WIDTH-1:0]        byte_counter_filter_fetch;   // index filter-weight's address
// tf quantization
reg                               tf_quantization_en;

always @* begin
	if (subunit_en_i) begin
		cache_rd_en = cache_rd_en_i;
		cache_wr_en = cache_wr_en_i;
		channel_switch_en = channel_switch_en_i;
		addressing_en = addressing_en_i;
		store_data_en = store_data_en_i;
		output_neuron_ac_en = output_neuron_ac_en_i;
		operand_fetch_en = operand_fetch_en_i;
		filter_fetch_en = filter_fetch_en_i;
		tf_quantization_en = tf_quantization_en_i;
	end
	else begin
		cache_rd_en = FALSE;
		cache_wr_en = FALSE;
		channel_switch_en = FALSE;
		addressing_en = FALSE;
		store_data_en = FALSE;
		output_neuron_ac_en = FALSE;
		operand_fetch_en = FALSE;
		filter_fetch_en = FALSE;
		tf_quantization_en = FALSE;		
	end
end


//===================================================================================================================================
// cache and fetch unit
//===================================================================================================================================

wire [FETCH_DATA_BIT_WIDTH-1:0] fetch_data;
wire [INPUT_BIT_WIDTH-1:0]        neuron_activation;
// cache #(.INITFILE0("INITFILE0"), .INITFILE1("INITFILE1"), .INITFILE2("INITFILE2"), .INITFILE3("INITFILE3"), 
// 		.INITFILE4("INITFILE4"), .INITFILE5("INITFILE5"), .INITFILE6("INITFILE6")) cache_0(
cache cache_0(
	.clk(clk),
	.rd_en_i(cache_rd_en),
	.channel_rd_sel_i(channel_sel_rd_i),
	.address_rd_i(address_rd_i),
	.fetch_data_o(fetch_data),
	.wr_en_i(cache_wr_en),
	.channel_wr_sel_i(channel_sel_wr_i),
	.address_wr_i(address_wr_i),
	.cache_data_i(data_input_i)
	);


neuron_fetch_unit neuron_fetch_unit_0(
	.clk(clk),
	.layer_reset(layer_reset),
	.fetch_data_i(fetch_data),
	.channel_switch_en_i(channel_switch_en),
	.addressing_en_i(addressing_en),
	.store_data_en_i(store_data_en),
	.output_neuron_ac_en_i(output_neuron_ac_en),
	.filter_width_i(filter_width_i),
	.neuron_activation_o(neuron_activation)
	);
//===================================================================================================================================
// control signal part 2 (There are two part)
//===================================================================================================================================
// neuron activation zero judgement
wire none_zero_neuron_activation;
assign none_zero_neuron_activation = |neuron_activation;
wire none_zero_operand_fetch_en;
assign none_zero_operand_fetch_en = operand_fetch_en & none_zero_neuron_activation;

reg [NUM_OF_MAC_UNIT-1:0]           mac_unit_en;
always @* begin
	if (none_zero_operand_fetch_en) begin
		mac_unit_en = mac_unit_en_i;
	end
	else begin
		mac_unit_en = MAC_UNABLE;
	end
end
//===================================================================================================================================
// accumulate the neuron activation, capable with tensorflow's quantization
//===================================================================================================================================
// wire tf_quantization_en;
// assign tf_quantization_en = subunit_en_i & tf_quantization_en_i;
// wire [SUM_QUAN_OFFSET-1:0] sum_quan_offset;
// tf_quantization tf_quantization_0(
// 	.clk(clk),
// 	.layer_reset(layer_reset),
// 	.stage_finish_i(stage_finish_i),
// 	.tf_quantization_en_i(tf_quantization_en),
// 	.neuron_activation_i(neuron_activation),
// 	.sum_quan_offset_o(sum_quan_offset)
// 	);
// assign sum_quan_offset_o = sum_quan_offset;
reg operand_fetch_en_pipeline;
always @(posedge clk) begin
	operand_fetch_en_pipeline <= operand_fetch_en;
end
wire [QUAN_SCALE_BIT_WIDTH-1:0] quan_scale;
wire tf_quantization_en_and;
assign tf_quantization_en_and = tf_quantization_en & operand_fetch_en_pipeline;
tf_quantization tf_quantization_0(
	.clk(clk),
	.layer_reset(layer_reset),
	.stage_finish_i(stage_finish_i),
	.quan_weight_zero_i(quan_weight_zero_i),
	.tf_quantization_en_i(tf_quantization_en_and),
	.neuron_activation_i(neuron_activation),
	.quan_scale_o(quan_scale)
	);
//===================================================================================================================================
// MAC operand fetch 
//===================================================================================================================================
// neuron broadcast
reg [INPUT_BIT_WIDTH-1:0] neuron_mac;
always @(posedge clk) begin
	if (none_zero_operand_fetch_en) begin
		neuron_mac <= neuron_activation;
	end
end

// filter weight operand fetch
wire [INPUT_BIT_WIDTH-1:0] filter_0_mac;
wire [INPUT_BIT_WIDTH-1:0] filter_1_mac;
wire [INPUT_BIT_WIDTH-1:0] filter_2_mac;
wire [INPUT_BIT_WIDTH-1:0] filter_3_mac;
wire [INPUT_BIT_WIDTH-1:0] filter_4_mac;
wire [INPUT_BIT_WIDTH-1:0] filter_5_mac;
wire [INPUT_BIT_WIDTH-1:0] filter_6_mac;
wire [INPUT_BIT_WIDTH-1:0] filter_7_mac;
wire [INPUT_BIT_WIDTH-1:0] filter_8_mac;
wire [INPUT_BIT_WIDTH-1:0] filter_9_mac;
wire [INPUT_BIT_WIDTH-1:0] filter_10_mac;
wire [INPUT_BIT_WIDTH-1:0] filter_11_mac;
wire [INPUT_BIT_WIDTH-1:0] filter_12_mac;
wire [INPUT_BIT_WIDTH-1:0] filter_13_mac;
wire [INPUT_BIT_WIDTH-1:0] filter_14_mac;
wire [INPUT_BIT_WIDTH-1:0] filter_15_mac;
filter_pool filter_pool_0(
	.clk(clk),
	.data_input_i(data_input_i),
	.filter_fetch_en_i(filter_fetch_en),
	.filter_sel_i(filter_sel_i),
	.mac_unit_en_i(mac_unit_en),
	.iteration_i(iteration_i),
	.byte_counter_filter_fetch_i(byte_counter_filter_fetch_i),
	.filter_0_mac_o(filter_0_mac),
	.filter_1_mac_o(filter_1_mac),
	.filter_2_mac_o(filter_2_mac),
	.filter_3_mac_o(filter_3_mac),
	.filter_4_mac_o(filter_4_mac),
	.filter_5_mac_o(filter_5_mac),
	.filter_6_mac_o(filter_6_mac),
	.filter_7_mac_o(filter_7_mac),
	.filter_8_mac_o(filter_8_mac),
	.filter_9_mac_o(filter_9_mac),
	.filter_10_mac_o(filter_10_mac),
	.filter_11_mac_o(filter_11_mac),
	.filter_12_mac_o(filter_12_mac),
	.filter_13_mac_o(filter_13_mac),
	.filter_14_mac_o(filter_14_mac),
	.filter_15_mac_o(filter_15_mac)
	);

//===================================================================================================================================
// MAC - control signal pipeline
//===================================================================================================================================
// delay mac unit enable signal one clock using register
// because 'filter_xx_mac' delay one clock
reg [NUM_OF_MAC_UNIT-1:0] mac_unit_en_delay;
always @(posedge clk) begin
	mac_unit_en_delay <= mac_unit_en;
end

//===================================================================================================================================
// MAC - computing part
//===================================================================================================================================
wire [OUTPUT_BIT_WIDTH-1:0]         accumulator_0;
wire [OUTPUT_BIT_WIDTH-1:0]         accumulator_1;
wire [OUTPUT_BIT_WIDTH-1:0]         accumulator_2;
wire [OUTPUT_BIT_WIDTH-1:0]         accumulator_3;
wire [OUTPUT_BIT_WIDTH-1:0]         accumulator_4;
wire [OUTPUT_BIT_WIDTH-1:0]         accumulator_5;
wire [OUTPUT_BIT_WIDTH-1:0]         accumulator_6;
wire [OUTPUT_BIT_WIDTH-1:0]         accumulator_7;
wire [OUTPUT_BIT_WIDTH-1:0]         accumulator_8;
wire [OUTPUT_BIT_WIDTH-1:0]         accumulator_9;
wire [OUTPUT_BIT_WIDTH-1:0]         accumulator_10;
wire [OUTPUT_BIT_WIDTH-1:0]         accumulator_11;
wire [OUTPUT_BIT_WIDTH-1:0]         accumulator_12;
wire [OUTPUT_BIT_WIDTH-1:0]         accumulator_13;
wire [OUTPUT_BIT_WIDTH-1:0]         accumulator_14;
wire [OUTPUT_BIT_WIDTH-1:0]         accumulator_15;
mac mac_0(
	.clk(clk),
	.layer_reset(layer_reset),
	.stage_finish(stage_finish_pipeline_i),
	.mac_en(mac_unit_en_delay[0]),
	.neuron(neuron_mac),
	.weight(filter_0_mac),
	.accumulator(accumulator_0)
	);
mac mac_1(
	.clk(clk),
	.layer_reset(layer_reset),
	.stage_finish(stage_finish_pipeline_i),
	.mac_en(mac_unit_en_delay[1]),
	.neuron(neuron_mac),
	.weight(filter_1_mac),
	.accumulator(accumulator_1)
	);
mac mac_2(
	.clk(clk),
	.layer_reset(layer_reset),
	.stage_finish(stage_finish_pipeline_i),
	.mac_en(mac_unit_en_delay[2]),
	.neuron(neuron_mac),
	.weight(filter_2_mac),
	.accumulator(accumulator_2)
	);
mac mac_3(
	.clk(clk),
	.layer_reset(layer_reset),
	.stage_finish(stage_finish_pipeline_i),
	.mac_en(mac_unit_en_delay[3]),
	.neuron(neuron_mac),
	.weight(filter_3_mac),
	.accumulator(accumulator_3)
	);
mac mac_4(
	.clk(clk),
	.layer_reset(layer_reset),
	.stage_finish(stage_finish_pipeline_i),
	.mac_en(mac_unit_en_delay[4]),
	.neuron(neuron_mac),
	.weight(filter_4_mac),
	.accumulator(accumulator_4)
	);
mac mac_5(
	.clk(clk),
	.layer_reset(layer_reset),
	.stage_finish(stage_finish_pipeline_i),
	.mac_en(mac_unit_en_delay[5]),
	.neuron(neuron_mac),
	.weight(filter_5_mac),
	.accumulator(accumulator_5)
	);
mac mac_6(
	.clk(clk),
	.layer_reset(layer_reset),
	.stage_finish(stage_finish_pipeline_i),
	.mac_en(mac_unit_en_delay[6]),
	.neuron(neuron_mac),
	.weight(filter_6_mac),
	.accumulator(accumulator_6)
	);
mac mac_7(
	.clk(clk),
	.layer_reset(layer_reset),
	.stage_finish(stage_finish_pipeline_i),
	.mac_en(mac_unit_en_delay[7]),
	.neuron(neuron_mac),
	.weight(filter_7_mac),
	.accumulator(accumulator_7)
	);
mac mac_8(
	.clk(clk),
	.layer_reset(layer_reset),
	.stage_finish(stage_finish_pipeline_i),
	.mac_en(mac_unit_en_delay[8]),
	.neuron(neuron_mac),
	.weight(filter_8_mac),
	.accumulator(accumulator_8)
	);
mac mac_9(
	.clk(clk),
	.layer_reset(layer_reset),
	.stage_finish(stage_finish_pipeline_i),
	.mac_en(mac_unit_en_delay[9]),
	.neuron(neuron_mac),
	.weight(filter_9_mac),
	.accumulator(accumulator_9)
	);
mac mac_10(
	.clk(clk),
	.layer_reset(layer_reset),
	.stage_finish(stage_finish_pipeline_i),
	.mac_en(mac_unit_en_delay[10]),
	.neuron(neuron_mac),
	.weight(filter_10_mac),
	.accumulator(accumulator_10)
	);
mac mac_11(
	.clk(clk),
	.layer_reset(layer_reset),
	.stage_finish(stage_finish_pipeline_i),
	.mac_en(mac_unit_en_delay[11]),
	.neuron(neuron_mac),
	.weight(filter_11_mac),
	.accumulator(accumulator_11)
	);
mac mac_12(
	.clk(clk),
	.layer_reset(layer_reset),
	.stage_finish(stage_finish_pipeline_i),
	.mac_en(mac_unit_en_delay[12]),
	.neuron(neuron_mac),
	.weight(filter_12_mac),
	.accumulator(accumulator_12)
	);
mac mac_13(
	.clk(clk),
	.layer_reset(layer_reset),
	.stage_finish(stage_finish_pipeline_i),
	.mac_en(mac_unit_en_delay[13]),
	.neuron(neuron_mac),
	.weight(filter_13_mac),
	.accumulator(accumulator_13)
	);
mac mac_14(
	.clk(clk),
	.layer_reset(layer_reset),
	.stage_finish(stage_finish_pipeline_i),
	.mac_en(mac_unit_en_delay[14]),
	.neuron(neuron_mac),
	.weight(filter_14_mac),
	.accumulator(accumulator_14)
	);
mac mac_15(
	.clk(clk),
	.layer_reset(layer_reset),
	.stage_finish(stage_finish_pipeline_i),
	.mac_en(mac_unit_en_delay[15]),
	.neuron(neuron_mac),
	.weight(filter_15_mac),
	.accumulator(accumulator_15)
	);

//===================================================================================================================================
// tensorflow quantization computation
//===================================================================================================================================
reg tf_quan_en_and_pipeline_1;
always @(posedge clk) begin
	tf_quan_en_and_pipeline_1 <= tf_quantization_en_and;
end
reg tf_quan_en_and_pipeline_2;
always @(posedge clk) begin
	tf_quan_en_and_pipeline_2 <= tf_quan_en_and_pipeline_1;
end
always @(posedge clk) begin
	if (tf_quan_en_and_pipeline_2) begin
		if (stage_finish_pipeline_i) begin
			if (mac_unit_en_i[0]) begin
				accumulator_0_o <= accumulator_0 - quan_scale;
			end
			if (mac_unit_en_i[1]) begin
				accumulator_1_o <= accumulator_1 - quan_scale;
			end
			if (mac_unit_en_i[2]) begin
				accumulator_2_o <= accumulator_2 - quan_scale;
			end
			if (mac_unit_en_i[3]) begin
				accumulator_3_o <= accumulator_3 - quan_scale;
			end
			if (mac_unit_en_i[4]) begin
				accumulator_4_o <= accumulator_4 - quan_scale;
			end
			if (mac_unit_en_i[5]) begin
				accumulator_5_o <= accumulator_5 - quan_scale;
			end
			if (mac_unit_en_i[6]) begin
				accumulator_6_o <= accumulator_6 - quan_scale;
			end
			if (mac_unit_en_i[7]) begin
				accumulator_7_o <= accumulator_7 - quan_scale;
			end
			if (mac_unit_en_i[8]) begin
				accumulator_8_o <= accumulator_8 - quan_scale;
			end
			if (mac_unit_en_i[9]) begin
				accumulator_9_o <= accumulator_9 - quan_scale;
			end
			if (mac_unit_en_i[10]) begin
				accumulator_10_o <= accumulator_10 - quan_scale;
			end
			if (mac_unit_en_i[11]) begin
				accumulator_11_o <= accumulator_11 - quan_scale;
			end
			if (mac_unit_en_i[12]) begin
				accumulator_12_o <= accumulator_12 - quan_scale;
			end
			if (mac_unit_en_i[13]) begin
				accumulator_13_o <= accumulator_13 - quan_scale;
			end
			if (mac_unit_en_i[14]) begin
				accumulator_14_o <= accumulator_14 - quan_scale;
			end
			if (mac_unit_en_i[15]) begin
				accumulator_15_o <= accumulator_15 - quan_scale;
			end
			// accumulator_0_o <= accumulator_0 - quan_scale;
			// accumulator_1_o <= accumulator_1 - quan_scale;
			// accumulator_2_o <= accumulator_2 - quan_scale;
			// accumulator_3_o <= accumulator_3 - quan_scale;
			// accumulator_4_o <= accumulator_4 - quan_scale;
			// accumulator_5_o <= accumulator_5 - quan_scale;
			// accumulator_6_o <= accumulator_6 - quan_scale;
			// accumulator_7_o <= accumulator_7 - quan_scale;
			// accumulator_8_o <= accumulator_8 - quan_scale;
			// accumulator_9_o <= accumulator_9 - quan_scale;
			// accumulator_10_o <= accumulator_10 - quan_scale;
			// accumulator_11_o <= accumulator_11 - quan_scale;
			// accumulator_12_o <= accumulator_12 - quan_scale;
			// accumulator_13_o <= accumulator_13 - quan_scale;
			// accumulator_14_o <= accumulator_14 - quan_scale;
			// accumulator_15_o <= accumulator_15 - quan_scale;			
		end
	end
	else begin
		accumulator_0_o <= accumulator_0;
		accumulator_1_o <= accumulator_1;
		accumulator_2_o <= accumulator_2;
		accumulator_3_o <= accumulator_3;
		accumulator_4_o <= accumulator_4;
		accumulator_5_o <= accumulator_5;
		accumulator_6_o <= accumulator_6;
		accumulator_7_o <= accumulator_7;
		accumulator_8_o <= accumulator_8;
		accumulator_9_o <= accumulator_9;
		accumulator_10_o <= accumulator_10;
		accumulator_11_o <= accumulator_11;
		accumulator_12_o <= accumulator_12;
		accumulator_13_o <= accumulator_13;
		accumulator_14_o <= accumulator_14;
		accumulator_15_o <= accumulator_15;
	end
end

endmodule