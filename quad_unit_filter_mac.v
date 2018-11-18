module quad_unit_filter_mac(
	clk,
	layer_reset,
	quad_data_bus_i,
	neuron_mac_i,
	quad_subunit_en_i,
	quad_filter_fetch_en_i,
	filter_sel_i,
	quad_mac_unit_en_i,
	iteration_i,
	byte_counter_filter_fetch_i,
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
	accumulator_15_o
	);

// port parameter
parameter DATA_BUS_BIT_WIDTH       = 32;
parameter INPUT_BIT_WIDTH          = 8;         // bit-width of neuron-input for each computation unit: 8-bit
parameter QUAD                     = 4;
parameter NUM_OF_FILTERS_BIT_WIDTH = 4;
parameter ITER_BIT_WIDTH           = 6;         // mac filter operand fetch: 36 register, need 6-bit to index them
parameter REG_POOL_BIT_WIDTH       = 6;         // filter fetch : index inside filter weight
parameter OUTPUT_BIT_WIDTH         = 16+6+2;    // each quad-unit's output bit width

// MAC operand fetch and MAC control signal
// case statement not use parameter
parameter NUM_OF_MAC_UNIT   = 16;
parameter UNABLE_MAC_UNIT   = 16'h0000;

// filter pool, MAC operand fetch unit and MAC part, each unit has the same verilog code
parameter ACCUMULATOR_BIT_WIDTH  = 16+6;      // bit-width of output register: sum of 36 number,increase bit-width with 6-bits, total 16+6


input                                clk;
input                                layer_reset;
input [DATA_BUS_BIT_WIDTH-1:0]       quad_data_bus_i;
input [INPUT_BIT_WIDTH-1:0]          neuron_mac_i;
input [QUAD-1:0]                     quad_subunit_en_i;
input [QUAD-1:0]                     quad_filter_fetch_en_i;        // filter fetch: subunit enable signal
input [NUM_OF_FILTERS_BIT_WIDTH-1:0] filter_sel_i;                  // filter fetch: index filter-weight's address
input [NUM_OF_MAC_UNIT-1:0]          quad_mac_unit_en_i;
input [ITER_BIT_WIDTH-1:0]           iteration_i;                   // filter operand fetch: index filter-weight's address
input [REG_POOL_BIT_WIDTH-1:0]       byte_counter_filter_fetch_i;   // filter fetch: index filter-weight's address
input                                stage_finish_pipeline_3_i;
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

reg unit0_filter_fetch_en;
reg unit1_filter_fetch_en;
reg unit2_filter_fetch_en;
reg unit3_filter_fetch_en;
always @(quad_filter_fetch_en_i) begin
	unit0_filter_fetch_en = quad_filter_fetch_en_i[0];
	unit1_filter_fetch_en = quad_filter_fetch_en_i[1];
	unit2_filter_fetch_en = quad_filter_fetch_en_i[2];
	unit3_filter_fetch_en = quad_filter_fetch_en_i[3];
end

reg quad_subunit0_en_i;
reg quad_subunit1_en_i;
reg quad_subunit2_en_i;
reg quad_subunit3_en_i;
always @(quad_subunit_en_i) begin
	quad_subunit0_en_i = quad_subunit_en_i[0];
	quad_subunit1_en_i = quad_subunit_en_i[1];
	quad_subunit2_en_i = quad_subunit_en_i[2];
	quad_subunit3_en_i = quad_subunit_en_i[3];
end

reg [NUM_OF_MAC_UNIT-1:0] unit0_mac_unit_en;
reg [NUM_OF_MAC_UNIT-1:0] unit1_mac_unit_en;
reg [NUM_OF_MAC_UNIT-1:0] unit2_mac_unit_en;
reg [NUM_OF_MAC_UNIT-1:0] unit3_mac_unit_en;
always @(quad_mac_unit_en_i or quad_subunit0_en_i) begin
	if (quad_subunit0_en_i) begin
		unit0_mac_unit_en = quad_mac_unit_en_i;
	end
	else begin
		unit0_mac_unit_en = UNABLE_MAC_UNIT; //16'h0000;
	end
end

always @(quad_mac_unit_en_i or quad_subunit1_en_i) begin
	if (quad_subunit1_en_i) begin
		unit1_mac_unit_en = quad_mac_unit_en_i;
	end
	else begin
		unit1_mac_unit_en = UNABLE_MAC_UNIT; //16'h0000;
	end
end

always @(quad_mac_unit_en_i or quad_subunit2_en_i) begin
	if (quad_subunit2_en_i) begin
		unit2_mac_unit_en = quad_mac_unit_en_i;
	end
	else begin
		unit2_mac_unit_en = UNABLE_MAC_UNIT; //16'h0000;
	end
end

always @(quad_mac_unit_en_i or quad_subunit3_en_i) begin
	if (quad_subunit3_en_i) begin
		unit3_mac_unit_en = quad_mac_unit_en_i;
	end
	else begin
		unit3_mac_unit_en = UNABLE_MAC_UNIT; //16'h0000;
	end
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
filter_operand_mac filter_operand_mac_0(
	.clk(clk),
	.layer_reset(layer_reset),
	.data_input_i(data_input_0),
	.neuron_mac_i(neuron_mac_i),
	.filter_fetch_en_i(unit0_filter_fetch_en),
	.filter_sel_i(filter_sel_i),
	.mac_unit_en_i(unit0_mac_unit_en),
	.iteration_i(iteration_i),
	.byte_counter_filter_fetch_i(byte_counter_filter_fetch_i),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3_i),
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
	.accumulator_15_o(unit0_accumulator_15)
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
filter_operand_mac filter_operand_mac_1(
	.clk(clk),
	.layer_reset(layer_reset),
	.data_input_i(data_input_1),
	.neuron_mac_i(neuron_mac_i),
	.filter_fetch_en_i(unit1_filter_fetch_en),
	.filter_sel_i(filter_sel_i),
	.mac_unit_en_i(unit1_mac_unit_en),
	.iteration_i(iteration_i),
	.byte_counter_filter_fetch_i(byte_counter_filter_fetch_i),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3_i),
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
	.accumulator_15_o(unit1_accumulator_15)
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
filter_operand_mac filter_operand_mac_2(
	.clk(clk),
	.layer_reset(layer_reset),
	.data_input_i(data_input_2),
	.neuron_mac_i(neuron_mac_i),
	.filter_fetch_en_i(unit2_filter_fetch_en),
	.filter_sel_i(filter_sel_i),
	.mac_unit_en_i(unit2_mac_unit_en),
	.iteration_i(iteration_i),
	.byte_counter_filter_fetch_i(byte_counter_filter_fetch_i),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3_i),
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
	.accumulator_15_o(unit2_accumulator_15)
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
filter_operand_mac filter_operand_mac_3(
	.clk(clk),
	.layer_reset(layer_reset),
	.data_input_i(data_input_3),
	.neuron_mac_i(neuron_mac_i),
	.filter_fetch_en_i(unit3_filter_fetch_en),
	.filter_sel_i(filter_sel_i),
	.mac_unit_en_i(unit3_mac_unit_en),
	.iteration_i(iteration_i),
	.byte_counter_filter_fetch_i(byte_counter_filter_fetch_i),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3_i),
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
	.accumulator_15_o(unit3_accumulator_15)
);

//===================================================================================================================================
// 4 subunit accumulator sum up together -> one accumulator
//===================================================================================================================================
quad_accumulator_adder accu_adder_0(
	.clk(clk),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3),
	.accumulator_0_i(unit0_accumulator_0),
	.accumulator_1_i(unit1_accumulator_0),
	.accumulator_2_i(unit2_accumulator_0),
	.accumulator_3_i(unit3_accumulator_0),
	.accumulator_o(accumulator_0_o)
	);

quad_accumulator_adder accu_adder_1(
	.clk(clk),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3),
	.accumulator_0_i(unit0_accumulator_1),
	.accumulator_1_i(unit1_accumulator_1),
	.accumulator_2_i(unit2_accumulator_1),
	.accumulator_3_i(unit3_accumulator_1),
	.accumulator_o(accumulator_1_o)
	);

quad_accumulator_adder accu_adder_2(
	.clk(clk),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3),
	.accumulator_0_i(unit0_accumulator_2),
	.accumulator_1_i(unit1_accumulator_2),
	.accumulator_2_i(unit2_accumulator_2),
	.accumulator_3_i(unit3_accumulator_2),
	.accumulator_o(accumulator_2_o)
	);

quad_accumulator_adder accu_adder_3(
	.clk(clk),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3),
	.accumulator_0_i(unit0_accumulator_3),
	.accumulator_1_i(unit1_accumulator_3),
	.accumulator_2_i(unit2_accumulator_3),
	.accumulator_3_i(unit3_accumulator_3),
	.accumulator_o(accumulator_3_o)
	);

quad_accumulator_adder accu_adder_4(
	.clk(clk),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3),
	.accumulator_0_i(unit0_accumulator_4),
	.accumulator_1_i(unit1_accumulator_4),
	.accumulator_2_i(unit2_accumulator_4),
	.accumulator_3_i(unit3_accumulator_4),
	.accumulator_o(accumulator_4_o)
	);

quad_accumulator_adder accu_adder_5(
	.clk(clk),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3),
	.accumulator_0_i(unit0_accumulator_5),
	.accumulator_1_i(unit1_accumulator_5),
	.accumulator_2_i(unit2_accumulator_5),
	.accumulator_3_i(unit3_accumulator_5),
	.accumulator_o(accumulator_5_o)
	);

quad_accumulator_adder accu_adder_6(
	.clk(clk),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3),
	.accumulator_0_i(unit0_accumulator_6),
	.accumulator_1_i(unit1_accumulator_6),
	.accumulator_2_i(unit2_accumulator_6),
	.accumulator_3_i(unit3_accumulator_6),
	.accumulator_o(accumulator_6_o)
	);

quad_accumulator_adder accu_adder_7(
	.clk(clk),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3),
	.accumulator_0_i(unit0_accumulator_7),
	.accumulator_1_i(unit1_accumulator_7),
	.accumulator_2_i(unit2_accumulator_7),
	.accumulator_3_i(unit3_accumulator_7),
	.accumulator_o(accumulator_7_o)
	);

quad_accumulator_adder accu_adder_8(
	.clk(clk),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3),
	.accumulator_0_i(unit0_accumulator_8),
	.accumulator_1_i(unit1_accumulator_8),
	.accumulator_2_i(unit2_accumulator_8),
	.accumulator_3_i(unit3_accumulator_8),
	.accumulator_o(accumulator_8_o)
	);

quad_accumulator_adder accu_adder_9(
	.clk(clk),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3),
	.accumulator_0_i(unit0_accumulator_9),
	.accumulator_1_i(unit1_accumulator_9),
	.accumulator_2_i(unit2_accumulator_9),
	.accumulator_3_i(unit3_accumulator_9),
	.accumulator_o(accumulator_9_o)
	);

quad_accumulator_adder accu_adder_10(
	.clk(clk),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3),
	.accumulator_0_i(unit0_accumulator_10),
	.accumulator_1_i(unit1_accumulator_10),
	.accumulator_2_i(unit2_accumulator_10),
	.accumulator_3_i(unit3_accumulator_10),
	.accumulator_o(accumulator_10_o)
	);

quad_accumulator_adder accu_adder_11(
	.clk(clk),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3),
	.accumulator_0_i(unit0_accumulator_11),
	.accumulator_1_i(unit1_accumulator_11),
	.accumulator_2_i(unit2_accumulator_11),
	.accumulator_3_i(unit3_accumulator_11),
	.accumulator_o(accumulator_11_o)
	);

quad_accumulator_adder accu_adder_12(
	.clk(clk),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3),
	.accumulator_0_i(unit0_accumulator_12),
	.accumulator_1_i(unit1_accumulator_12),
	.accumulator_2_i(unit2_accumulator_12),
	.accumulator_3_i(unit3_accumulator_12),
	.accumulator_o(accumulator_12_o)
	);

quad_accumulator_adder accu_adder_13(
	.clk(clk),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3),
	.accumulator_0_i(unit0_accumulator_13),
	.accumulator_1_i(unit1_accumulator_13),
	.accumulator_2_i(unit2_accumulator_13),
	.accumulator_3_i(unit3_accumulator_13),
	.accumulator_o(accumulator_13_o)
	);

quad_accumulator_adder accu_adder_14(
	.clk(clk),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3),
	.accumulator_0_i(unit0_accumulator_14),
	.accumulator_1_i(unit1_accumulator_14),
	.accumulator_2_i(unit2_accumulator_14),
	.accumulator_3_i(unit3_accumulator_14),
	.accumulator_o(accumulator_14_o)
	);

quad_accumulator_adder accu_adder_15(
	.clk(clk),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3),
	.accumulator_0_i(unit0_accumulator_15),
	.accumulator_1_i(unit1_accumulator_15),
	.accumulator_2_i(unit2_accumulator_15),
	.accumulator_3_i(unit3_accumulator_15),
	.accumulator_o(accumulator_15_o)
	);

endmodule