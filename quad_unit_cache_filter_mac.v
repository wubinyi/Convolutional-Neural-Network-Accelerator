// Company           :   tud
// Author            :   binyiwu
// E-Mail            :   <$ICPRO_EMAIL not set - insert email address>
//
// Filename          :   quad_unit_cache_filter_mac.v
// Project Name      :   sa_wubinyi
// Subproject Name   :   cnn_accelerator
// Description       :   <short description>
//
// Create Date       :   Mon Oct 16 09:13:49 2017
// Last Change       :   $Date$
// by                :   $Author$
//------------------------------------------------------------
module quad_unit_cache_filter_mac(
	clk,
	layer_reset,
	quad_subunit_en_i,
	quad_data_bus_i,
	cache_rd_en_i,
	channel_sel_rd_i,
	address_rd_i,
	cache_wr_en_i,
	channel_sel_wr_i,
	address_wr_i,
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
	stage_finish_pipeline_i,  // --> stage_finish_pipeline_2_i
	stage_finish_pipeline_3_i,
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

// port parameter
parameter QUAD                     = 4;
parameter QUAD_DATA_BUS_BIT_WIDTH  = 32;

parameter INPUT_BIT_WIDTH          = 8;         // bit-width of neuron-input for each computation unit: 8-bit
parameter NUM_OF_FILTERS_BIT_WIDTH = 4;
parameter ITER_BIT_WIDTH           = 6;         // mac filter operand fetch: 36 register, need 6-bit to index them
parameter REG_POOL_BIT_WIDTH       = 6;         // filter fetch : index inside filter weight
parameter OUTPUT_BIT_WIDTH         = 16+6+6;    // each quad-unit's output bit width // 24-->28

// MAC operand fetch and MAC control signal
// case statement not use parameter
parameter NUM_OF_MAC_UNIT   = 16;
parameter UNABLE_MAC_UNIT   = 16'h0000;

// filter pool, MAC operand fetch unit and MAC part, each unit has the same verilog code
parameter ACCUMULATOR_BIT_WIDTH  = 16+6+2;      // bit-width of output register: sum of 36 number,increase bit-width with 6-bits, total 16+6 // 22->24
parameter ADDERS_FLAG_BIT_WIDTH  = 2;


parameter FILTER_WIDTH_BIT_WIDTH   = 3;
parameter FETCH_DATA_BIT_WIDTH     = 56;  // 8 * 7
parameter CACHE_DEPTH_BIT_WIDTH    = 5;  // through 32
parameter CACHE_CHANNELS           = 7;
parameter CACHE_CHANNEL_BIT_WIDTH = 3;         // select channels

// tf quantization
parameter QUAN_WEIGHT_ZERO_BIT_WIDTH = 8;


input                                clk;
input                                layer_reset;
input [QUAD-1:0]                     quad_subunit_en_i;
input [QUAD_DATA_BUS_BIT_WIDTH-1:0]  quad_data_bus_i;
// cache control signal
input                               cache_rd_en_i;
input [CACHE_CHANNELS-1:0]          channel_sel_rd_i;
input [CACHE_DEPTH_BIT_WIDTH-1:0]   address_rd_i;
input                               cache_wr_en_i;
input [CACHE_CHANNEL_BIT_WIDTH-1:0] channel_sel_wr_i;
input [CACHE_DEPTH_BIT_WIDTH-1:0]   address_wr_i;
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
// MAC
input                                 stage_finish_pipeline_i; // --> stage_finish_pipeline_2_i
input                                 stage_finish_pipeline_3_i;
output [OUTPUT_BIT_WIDTH-1:0]        accumulator_0_o;
output [OUTPUT_BIT_WIDTH-1:0]        accumulator_1_o;
output [OUTPUT_BIT_WIDTH-1:0]        accumulator_2_o;
output [OUTPUT_BIT_WIDTH-1:0]        accumulator_3_o;
output [OUTPUT_BIT_WIDTH-1:0]        accumulator_4_o;
output [OUTPUT_BIT_WIDTH-1:0]        accumulator_5_o;
output [OUTPUT_BIT_WIDTH-1:0]        accumulator_6_o;
output [OUTPUT_BIT_WIDTH-1:0]        accumulator_7_o;
output [OUTPUT_BIT_WIDTH-1:0]        accumulator_8_o;
output [OUTPUT_BIT_WIDTH-1:0]        accumulator_9_o;
output [OUTPUT_BIT_WIDTH-1:0]        accumulator_10_o;
output [OUTPUT_BIT_WIDTH-1:0]        accumulator_11_o;
output [OUTPUT_BIT_WIDTH-1:0]        accumulator_12_o;
output [OUTPUT_BIT_WIDTH-1:0]        accumulator_13_o;
output [OUTPUT_BIT_WIDTH-1:0]        accumulator_14_o;
output [OUTPUT_BIT_WIDTH-1:0]        accumulator_15_o;
// quantization: sum
input                              stage_finish_i;
input                              tf_quantization_en_i;
input [QUAN_WEIGHT_ZERO_BIT_WIDTH-1:0] quan_weight_zero_i;
//===================================================================================================================================
// control signal distributer
//===================================================================================================================================
reg [INPUT_BIT_WIDTH-1:0] data_input_0;
reg [INPUT_BIT_WIDTH-1:0] data_input_1;
reg [INPUT_BIT_WIDTH-1:0] data_input_2;
reg [INPUT_BIT_WIDTH-1:0] data_input_3;
always @(quad_data_bus_i) begin
	data_input_0 = quad_data_bus_i[7:0];
	data_input_1 = quad_data_bus_i[15:8];
	data_input_2 = quad_data_bus_i[23:16];
	data_input_3 = quad_data_bus_i[31:24];
end


reg unit0_subunit_en;
reg unit1_subunit_en;
reg unit2_subunit_en;
reg unit3_subunit_en;
always @(quad_subunit_en_i) begin
	unit0_subunit_en = quad_subunit_en_i[0];
	unit1_subunit_en = quad_subunit_en_i[1];
	unit2_subunit_en = quad_subunit_en_i[2];
	unit3_subunit_en = quad_subunit_en_i[3];
end


//===================================================================================================================================
// filter pool, MAC operand fetch unit and MAC part, each unit has the same verilog code
//===================================================================================================================================

// computation unit 0
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit0_accumulator_0;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit0_accumulator_1;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit0_accumulator_2;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit0_accumulator_3;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit0_accumulator_4;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit0_accumulator_5;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit0_accumulator_6;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit0_accumulator_7;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit0_accumulator_8;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit0_accumulator_9;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit0_accumulator_10;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit0_accumulator_11;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit0_accumulator_12;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit0_accumulator_13;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit0_accumulator_14;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit0_accumulator_15;
cache_filter_operand_mac cache_filter_operand_mac_0(
	.clk(clk),
	.layer_reset(layer_reset),
	.subunit_en_i(unit0_subunit_en),
	.cache_rd_en_i(cache_rd_en_i),
	.channel_sel_rd_i(channel_sel_rd_i),
	.address_rd_i(address_rd_i),
	.cache_wr_en_i(cache_wr_en_i),
	.channel_sel_wr_i(channel_sel_wr_i),
	.address_wr_i(address_wr_i),
	.data_input_i(data_input_0),
	.channel_switch_en_i(channel_switch_en_i),
	.addressing_en_i(addressing_en_i),
	.store_data_en_i(store_data_en_i),
	.output_neuron_ac_en_i(output_neuron_ac_en_i),
	.filter_width_i(filter_width_i),
	.operand_fetch_en_i(operand_fetch_en_i),
	.filter_fetch_en_i(filter_fetch_en_i),
	.filter_sel_i(filter_sel_i),
	.mac_unit_en_i(mac_unit_en_i),
	.iteration_i(iteration_i),
	.byte_counter_filter_fetch_i(byte_counter_filter_fetch_i),
	.stage_finish_i(stage_finish_i),
	.stage_finish_pipeline_i(stage_finish_pipeline_i),
	.accumulator_0_o(unit0_accumulator_0),
	.accumulator_1_o(unit0_accumulator_1),
	.accumulator_2_o(unit0_accumulator_2),
	.accumulator_3_o(unit0_accumulator_3),
	.accumulator_4_o(unit0_accumulator_4),
	.accumulator_5_o(unit0_accumulator_5),
	.accumulator_6_o(unit0_accumulator_6),
	.accumulator_7_o(unit0_accumulator_7),
	.accumulator_8_o(unit0_accumulator_8),
	.accumulator_9_o(unit0_accumulator_9),
	.accumulator_10_o(unit0_accumulator_10),
	.accumulator_11_o(unit0_accumulator_11),
	.accumulator_12_o(unit0_accumulator_12),
	.accumulator_13_o(unit0_accumulator_13),
	.accumulator_14_o(unit0_accumulator_14),
	.accumulator_15_o(unit0_accumulator_15),
	.tf_quantization_en_i(tf_quantization_en_i),
	.quan_weight_zero_i(quan_weight_zero_i)
);

// computation unit 1
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit1_accumulator_0;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit1_accumulator_1;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit1_accumulator_2;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit1_accumulator_3;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit1_accumulator_4;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit1_accumulator_5;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit1_accumulator_6;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit1_accumulator_7;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit1_accumulator_8;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit1_accumulator_9;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit1_accumulator_10;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit1_accumulator_11;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit1_accumulator_12;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit1_accumulator_13;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit1_accumulator_14;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit1_accumulator_15;
cache_filter_operand_mac cache_filter_operand_mac_1(
	.clk(clk),
	.layer_reset(layer_reset),
	.subunit_en_i(unit1_subunit_en),
	.cache_rd_en_i(cache_rd_en_i),
	.channel_sel_rd_i(channel_sel_rd_i),
	.address_rd_i(address_rd_i),
	.cache_wr_en_i(cache_wr_en_i),
	.channel_sel_wr_i(channel_sel_wr_i),
	.address_wr_i(address_wr_i),
	.data_input_i(data_input_1),
	.channel_switch_en_i(channel_switch_en_i),
	.addressing_en_i(addressing_en_i),
	.store_data_en_i(store_data_en_i),
	.output_neuron_ac_en_i(output_neuron_ac_en_i),
	.filter_width_i(filter_width_i),
	.operand_fetch_en_i(operand_fetch_en_i),
	.filter_fetch_en_i(filter_fetch_en_i),
	.filter_sel_i(filter_sel_i),
	.mac_unit_en_i(mac_unit_en_i),
	.iteration_i(iteration_i),
	.byte_counter_filter_fetch_i(byte_counter_filter_fetch_i),
	.stage_finish_i(stage_finish_i),
	.stage_finish_pipeline_i(stage_finish_pipeline_i),
	.accumulator_0_o(unit1_accumulator_0),
	.accumulator_1_o(unit1_accumulator_1),
	.accumulator_2_o(unit1_accumulator_2),
	.accumulator_3_o(unit1_accumulator_3),
	.accumulator_4_o(unit1_accumulator_4),
	.accumulator_5_o(unit1_accumulator_5),
	.accumulator_6_o(unit1_accumulator_6),
	.accumulator_7_o(unit1_accumulator_7),
	.accumulator_8_o(unit1_accumulator_8),
	.accumulator_9_o(unit1_accumulator_9),
	.accumulator_10_o(unit1_accumulator_10),
	.accumulator_11_o(unit1_accumulator_11),
	.accumulator_12_o(unit1_accumulator_12),
	.accumulator_13_o(unit1_accumulator_13),
	.accumulator_14_o(unit1_accumulator_14),
	.accumulator_15_o(unit1_accumulator_15),
	.tf_quantization_en_i(tf_quantization_en_i),
	.quan_weight_zero_i(quan_weight_zero_i)
);

// computation unit 2
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit2_accumulator_0;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit2_accumulator_1;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit2_accumulator_2;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit2_accumulator_3;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit2_accumulator_4;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit2_accumulator_5;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit2_accumulator_6;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit2_accumulator_7;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit2_accumulator_8;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit2_accumulator_9;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit2_accumulator_10;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit2_accumulator_11;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit2_accumulator_12;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit2_accumulator_13;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit2_accumulator_14;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit2_accumulator_15;
cache_filter_operand_mac cache_filter_operand_mac_2(
	.clk(clk),
	.layer_reset(layer_reset),
	.subunit_en_i(unit2_subunit_en),
	.cache_rd_en_i(cache_rd_en_i),
	.channel_sel_rd_i(channel_sel_rd_i),
	.address_rd_i(address_rd_i),
	.cache_wr_en_i(cache_wr_en_i),
	.channel_sel_wr_i(channel_sel_wr_i),
	.address_wr_i(address_wr_i),
	.data_input_i(data_input_2),
	.channel_switch_en_i(channel_switch_en_i),
	.addressing_en_i(addressing_en_i),
	.store_data_en_i(store_data_en_i),
	.output_neuron_ac_en_i(output_neuron_ac_en_i),
	.filter_width_i(filter_width_i),
	.operand_fetch_en_i(operand_fetch_en_i),
	.filter_fetch_en_i(filter_fetch_en_i),
	.filter_sel_i(filter_sel_i),
	.mac_unit_en_i(mac_unit_en_i),
	.iteration_i(iteration_i),
	.byte_counter_filter_fetch_i(byte_counter_filter_fetch_i),
	.stage_finish_i(stage_finish_i),
	.stage_finish_pipeline_i(stage_finish_pipeline_i),
	.accumulator_0_o(unit2_accumulator_0),
	.accumulator_1_o(unit2_accumulator_1),
	.accumulator_2_o(unit2_accumulator_2),
	.accumulator_3_o(unit2_accumulator_3),
	.accumulator_4_o(unit2_accumulator_4),
	.accumulator_5_o(unit2_accumulator_5),
	.accumulator_6_o(unit2_accumulator_6),
	.accumulator_7_o(unit2_accumulator_7),
	.accumulator_8_o(unit2_accumulator_8),
	.accumulator_9_o(unit2_accumulator_9),
	.accumulator_10_o(unit2_accumulator_10),
	.accumulator_11_o(unit2_accumulator_11),
	.accumulator_12_o(unit2_accumulator_12),
	.accumulator_13_o(unit2_accumulator_13),
	.accumulator_14_o(unit2_accumulator_14),
	.accumulator_15_o(unit2_accumulator_15),
	.tf_quantization_en_i(tf_quantization_en_i),
	.quan_weight_zero_i(quan_weight_zero_i)
);

// computation unit 3
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit3_accumulator_0;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit3_accumulator_1;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit3_accumulator_2;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit3_accumulator_3;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit3_accumulator_4;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit3_accumulator_5;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit3_accumulator_6;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit3_accumulator_7;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit3_accumulator_8;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit3_accumulator_9;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit3_accumulator_10;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit3_accumulator_11;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit3_accumulator_12;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit3_accumulator_13;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit3_accumulator_14;
wire [ACCUMULATOR_BIT_WIDTH-1:0] unit3_accumulator_15;
cache_filter_operand_mac cache_filter_operand_mac_3(
	.clk(clk),
	.layer_reset(layer_reset),
	.subunit_en_i(unit3_subunit_en),
	.cache_rd_en_i(cache_rd_en_i),
	.channel_sel_rd_i(channel_sel_rd_i),
	.address_rd_i(address_rd_i),
	.cache_wr_en_i(cache_wr_en_i),
	.channel_sel_wr_i(channel_sel_wr_i),
	.address_wr_i(address_wr_i),
	.data_input_i(data_input_3),
	.channel_switch_en_i(channel_switch_en_i),
	.addressing_en_i(addressing_en_i),
	.store_data_en_i(store_data_en_i),
	.output_neuron_ac_en_i(output_neuron_ac_en_i),
	.filter_width_i(filter_width_i),
	.operand_fetch_en_i(operand_fetch_en_i),
	.filter_fetch_en_i(filter_fetch_en_i),
	.filter_sel_i(filter_sel_i),
	.mac_unit_en_i(mac_unit_en_i),
	.iteration_i(iteration_i),
	.byte_counter_filter_fetch_i(byte_counter_filter_fetch_i),
	.stage_finish_i(stage_finish_i),
	.stage_finish_pipeline_i(stage_finish_pipeline_i),
	.accumulator_0_o(unit3_accumulator_0),
	.accumulator_1_o(unit3_accumulator_1),
	.accumulator_2_o(unit3_accumulator_2),
	.accumulator_3_o(unit3_accumulator_3),
	.accumulator_4_o(unit3_accumulator_4),
	.accumulator_5_o(unit3_accumulator_5),
	.accumulator_6_o(unit3_accumulator_6),
	.accumulator_7_o(unit3_accumulator_7),
	.accumulator_8_o(unit3_accumulator_8),
	.accumulator_9_o(unit3_accumulator_9),
	.accumulator_10_o(unit3_accumulator_10),
	.accumulator_11_o(unit3_accumulator_11),
	.accumulator_12_o(unit3_accumulator_12),
	.accumulator_13_o(unit3_accumulator_13),
	.accumulator_14_o(unit3_accumulator_14),
	.accumulator_15_o(unit3_accumulator_15),
	.tf_quantization_en_i(tf_quantization_en_i),
	.quan_weight_zero_i(quan_weight_zero_i)
);

//===================================================================================================================================
// 4 subunit accumulator sum up together -> one accumulator
//===================================================================================================================================
// quad accumulator control logic
reg [ADDERS_FLAG_BIT_WIDTH-1:0] adders_flag;
always @(quad_subunit_en_i) begin
	case(quad_subunit_en_i)
		4'b0001: adders_flag = 2'b00;
		4'b0011: adders_flag = 2'b01;
		4'b0111: adders_flag = 2'b10;
		4'b1111: adders_flag = 2'b11;
		default: adders_flag = 2'b00;
	endcase
end

wire [ADDERS_FLAG_BIT_WIDTH-1:0] adders_flag_0;
assign adders_flag_0 = adders_flag & {2{mac_unit_en_i[0]}};
quad_accumulator_adder quad_accu_adder_0(
	.clk(clk),
	.adders_flag_i(adders_flag_0),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3_i),
	.accumulator_0_i(unit0_accumulator_0),
	.accumulator_1_i(unit1_accumulator_0),
	.accumulator_2_i(unit2_accumulator_0),
	.accumulator_3_i(unit3_accumulator_0),
	.accumulator_o(accumulator_0_o)
	);

wire [ADDERS_FLAG_BIT_WIDTH-1:0] adders_flag_1;
assign adders_flag_1 = adders_flag & {2{mac_unit_en_i[1]}};
quad_accumulator_adder quad_accu_adder_1(
	.clk(clk),
	.adders_flag_i(adders_flag_1),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3_i),
	.accumulator_0_i(unit0_accumulator_1),
	.accumulator_1_i(unit1_accumulator_1),
	.accumulator_2_i(unit2_accumulator_1),
	.accumulator_3_i(unit3_accumulator_1),
	.accumulator_o(accumulator_1_o)
	);

wire [ADDERS_FLAG_BIT_WIDTH-1:0] adders_flag_2;
assign adders_flag_2 = adders_flag & {2{mac_unit_en_i[2]}};
quad_accumulator_adder quad_accu_adder_2(
	.clk(clk),
	.adders_flag_i(adders_flag_2),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3_i),
	.accumulator_0_i(unit0_accumulator_2),
	.accumulator_1_i(unit1_accumulator_2),
	.accumulator_2_i(unit2_accumulator_2),
	.accumulator_3_i(unit3_accumulator_2),
	.accumulator_o(accumulator_2_o)
	);

wire [ADDERS_FLAG_BIT_WIDTH-1:0] adders_flag_3;
assign adders_flag_3 = adders_flag & {2{mac_unit_en_i[3]}};
quad_accumulator_adder quad_accu_adder_3(
	.clk(clk),
	.adders_flag_i(adders_flag_3),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3_i),
	.accumulator_0_i(unit0_accumulator_3),
	.accumulator_1_i(unit1_accumulator_3),
	.accumulator_2_i(unit2_accumulator_3),
	.accumulator_3_i(unit3_accumulator_3),
	.accumulator_o(accumulator_3_o)
	);

wire [ADDERS_FLAG_BIT_WIDTH-1:0] adders_flag_4;
assign adders_flag_4 = adders_flag & {2{mac_unit_en_i[4]}};
quad_accumulator_adder quad_accu_adder_4(
	.clk(clk),
	.adders_flag_i(adders_flag_4),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3_i),
	.accumulator_0_i(unit0_accumulator_4),
	.accumulator_1_i(unit1_accumulator_4),
	.accumulator_2_i(unit2_accumulator_4),
	.accumulator_3_i(unit3_accumulator_4),
	.accumulator_o(accumulator_4_o)
	);

wire [ADDERS_FLAG_BIT_WIDTH-1:0] adders_flag_5;
assign adders_flag_5 = adders_flag & {2{mac_unit_en_i[5]}};
quad_accumulator_adder quad_accu_adder_5(
	.clk(clk),
	.adders_flag_i(adders_flag_5),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3_i),
	.accumulator_0_i(unit0_accumulator_5),
	.accumulator_1_i(unit1_accumulator_5),
	.accumulator_2_i(unit2_accumulator_5),
	.accumulator_3_i(unit3_accumulator_5),
	.accumulator_o(accumulator_5_o)
	);

wire [ADDERS_FLAG_BIT_WIDTH-1:0] adders_flag_6;
assign adders_flag_6 = adders_flag & {2{mac_unit_en_i[6]}};
quad_accumulator_adder quad_accu_adder_6(
	.clk(clk),
	.adders_flag_i(adders_flag_6),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3_i),
	.accumulator_0_i(unit0_accumulator_6),
	.accumulator_1_i(unit1_accumulator_6),
	.accumulator_2_i(unit2_accumulator_6),
	.accumulator_3_i(unit3_accumulator_6),
	.accumulator_o(accumulator_6_o)
	);

wire [ADDERS_FLAG_BIT_WIDTH-1:0] adders_flag_7;
assign adders_flag_7 = adders_flag & {2{mac_unit_en_i[7]}};
quad_accumulator_adder quad_accu_adder_7(
	.clk(clk),
	.adders_flag_i(adders_flag_7),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3_i),
	.accumulator_0_i(unit0_accumulator_7),
	.accumulator_1_i(unit1_accumulator_7),
	.accumulator_2_i(unit2_accumulator_7),
	.accumulator_3_i(unit3_accumulator_7),
	.accumulator_o(accumulator_7_o)
	);

wire [ADDERS_FLAG_BIT_WIDTH-1:0] adders_flag_8;
assign adders_flag_8 = adders_flag & {2{mac_unit_en_i[8]}};
quad_accumulator_adder quad_accu_adder_8(
	.clk(clk),
	.adders_flag_i(adders_flag_8),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3_i),
	.accumulator_0_i(unit0_accumulator_8),
	.accumulator_1_i(unit1_accumulator_8),
	.accumulator_2_i(unit2_accumulator_8),
	.accumulator_3_i(unit3_accumulator_8),
	.accumulator_o(accumulator_8_o)
	);

wire [ADDERS_FLAG_BIT_WIDTH-1:0] adders_flag_9;
assign adders_flag_9 = adders_flag & {2{mac_unit_en_i[9]}};
quad_accumulator_adder quad_accu_adder_9(
	.clk(clk),
	.adders_flag_i(adders_flag_9),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3_i),
	.accumulator_0_i(unit0_accumulator_9),
	.accumulator_1_i(unit1_accumulator_9),
	.accumulator_2_i(unit2_accumulator_9),
	.accumulator_3_i(unit3_accumulator_9),
	.accumulator_o(accumulator_9_o)
	);

wire [ADDERS_FLAG_BIT_WIDTH-1:0] adders_flag_10;
assign adders_flag_10 = adders_flag & {2{mac_unit_en_i[10]}};
quad_accumulator_adder quad_accu_adder_10(
	.clk(clk),
	.adders_flag_i(adders_flag_10),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3_i),
	.accumulator_0_i(unit0_accumulator_10),
	.accumulator_1_i(unit1_accumulator_10),
	.accumulator_2_i(unit2_accumulator_10),
	.accumulator_3_i(unit3_accumulator_10),
	.accumulator_o(accumulator_10_o)
	);

wire [ADDERS_FLAG_BIT_WIDTH-1:0] adders_flag_11;
assign adders_flag_11 = adders_flag & {2{mac_unit_en_i[11]}};
quad_accumulator_adder quad_accu_adder_11(
	.clk(clk),
	.adders_flag_i(adders_flag_11),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3_i),
	.accumulator_0_i(unit0_accumulator_11),
	.accumulator_1_i(unit1_accumulator_11),
	.accumulator_2_i(unit2_accumulator_11),
	.accumulator_3_i(unit3_accumulator_11),
	.accumulator_o(accumulator_11_o)
	);

wire [ADDERS_FLAG_BIT_WIDTH-1:0] adders_flag_12;
assign adders_flag_12 = adders_flag & {2{mac_unit_en_i[12]}};
quad_accumulator_adder quad_accu_adder_12(
	.clk(clk),
	.adders_flag_i(adders_flag_12),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3_i),
	.accumulator_0_i(unit0_accumulator_12),
	.accumulator_1_i(unit1_accumulator_12),
	.accumulator_2_i(unit2_accumulator_12),
	.accumulator_3_i(unit3_accumulator_12),
	.accumulator_o(accumulator_12_o)
	);

wire [ADDERS_FLAG_BIT_WIDTH-1:0] adders_flag_13;
assign adders_flag_13 = adders_flag & {2{mac_unit_en_i[13]}};
quad_accumulator_adder quad_accu_adder_13(
	.clk(clk),
	.adders_flag_i(adders_flag_13),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3_i),
	.accumulator_0_i(unit0_accumulator_13),
	.accumulator_1_i(unit1_accumulator_13),
	.accumulator_2_i(unit2_accumulator_13),
	.accumulator_3_i(unit3_accumulator_13),
	.accumulator_o(accumulator_13_o)
	);

wire [ADDERS_FLAG_BIT_WIDTH-1:0] adders_flag_14;
assign adders_flag_14 = adders_flag & {2{mac_unit_en_i[14]}};
quad_accumulator_adder quad_accu_adder_14(
	.clk(clk),
	.adders_flag_i(adders_flag_14),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3_i),
	.accumulator_0_i(unit0_accumulator_14),
	.accumulator_1_i(unit1_accumulator_14),
	.accumulator_2_i(unit2_accumulator_14),
	.accumulator_3_i(unit3_accumulator_14),
	.accumulator_o(accumulator_14_o)
	);

wire [ADDERS_FLAG_BIT_WIDTH-1:0] adders_flag_15;
assign adders_flag_15 = adders_flag & {2{mac_unit_en_i[15]}};
quad_accumulator_adder quad_accu_adder_15(
	.clk(clk),
	.adders_flag_i(adders_flag_15),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3_i),
	.accumulator_0_i(unit0_accumulator_15),
	.accumulator_1_i(unit1_accumulator_15),
	.accumulator_2_i(unit2_accumulator_15),
	.accumulator_3_i(unit3_accumulator_15),
	.accumulator_o(accumulator_15_o)
	);

endmodule