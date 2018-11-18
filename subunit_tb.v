module subunit_tb();


parameter INPUT_BIT_WIDTH   = 8;         // bit-width of neuron-input: 8-bit
parameter OUTPUT_BIT_WIDTH  = 16+6;      // bit-width of output register: sum of 36 number,increase bit-width with 6-bits, total 16+6
parameter NO_FUNCTION                    = 0;
parameter FETCH_FILTER_WIDTH             = 1;
parameter FETCH_FILTER_SIZE              = 2;
parameter FETCH_PICTURE_WIDTH            = 3;
parameter FETCH_PICTURE_HEIGHT           = 4;
parameter FETCH_NUM_OF_FILTERS           = 5;
parameter FETCH_FILTER_WEIGHT            = 6;
parameter CACHE_LOADING                  = 7;
parameter NEURON_FETCH                   = 8; 
parameter NEURON_FETCH_AND_OPERAND_FETCH = 9;
parameter OPERAND_FETCH                  = 10;

reg                           clk;
reg                           reset;
reg                           layer_reset;
reg  [INPUT_BIT_WIDTH-1:0]    data_input;
reg  [3:0]                    function_sel;
wire [OUTPUT_BIT_WIDTH-1:0]   accumulator_0;
wire [OUTPUT_BIT_WIDTH-1:0]   accumulator_1;
wire [OUTPUT_BIT_WIDTH-1:0]   accumulator_2;
wire [OUTPUT_BIT_WIDTH-1:0]   accumulator_3;
wire [OUTPUT_BIT_WIDTH-1:0]   accumulator_4;
wire [OUTPUT_BIT_WIDTH-1:0]   accumulator_5;
wire [OUTPUT_BIT_WIDTH-1:0]   accumulator_6;
wire [OUTPUT_BIT_WIDTH-1:0]   accumulator_7;
wire [OUTPUT_BIT_WIDTH-1:0]   accumulator_8;
wire [OUTPUT_BIT_WIDTH-1:0]   accumulator_9;
wire [OUTPUT_BIT_WIDTH-1:0]   accumulator_10;
wire [OUTPUT_BIT_WIDTH-1:0]   accumulator_11;
wire [OUTPUT_BIT_WIDTH-1:0]   accumulator_12;
wire [OUTPUT_BIT_WIDTH-1:0]   accumulator_13;
wire [OUTPUT_BIT_WIDTH-1:0]   accumulator_14;
wire [OUTPUT_BIT_WIDTH-1:0]   accumulator_15;

computation_subunit subunit_0(
	.clk(clk),
	.reset(reset),
	.layer_reset(layer_reset),
	.data_input(data_input),
	.function_sel(function_sel),
	.accumulator_0(accumulator_0),
	.accumulator_1(accumulator_1),
	.accumulator_2(accumulator_2),
	.accumulator_3(accumulator_3),
	.accumulator_4(accumulator_4),
	.accumulator_5(accumulator_5),
	.accumulator_6(accumulator_6),
	.accumulator_7(accumulator_7),
	.accumulator_8(accumulator_8),
	.accumulator_9(accumulator_9),
	.accumulator_10(accumulator_10),
	.accumulator_11(accumulator_11),
	.accumulator_12(accumulator_12),
	.accumulator_13(accumulator_13),
	.accumulator_14(accumulator_14),
	.accumulator_15(accumulator_15)
	);

initial begin
	clk = 1'b0;
	forever # 20 clk = ~ clk;
end

initial begin
	reset = 1'b0;
	# 10 reset = 1'b1;
	# 10 reset = 1'b0;
end

initial begin
	// nothing
	layer_reset = 1'b0;
	data_input = 8'h00;
	function_sel = NO_FUNCTION;
	# 1
	# 60 // filter width: 3
	data_input = 8'h02;
	function_sel = FETCH_FILTER_WIDTH;
	# 40 // filter width: 9
	data_input = 8'h08;
	function_sel = FETCH_FILTER_SIZE;
	# 40 // picture width: 5
	data_input = 8'h04;  // restrict channel select
	function_sel = FETCH_PICTURE_WIDTH;
	# 40 // picture height: 5
	data_input = 8'h04; 
	function_sel = FETCH_PICTURE_HEIGHT;
	# 40 // number of filter: 3
	data_input = 8'h02;  // restrict MAC
	function_sel = FETCH_NUM_OF_FILTERS;
	# 40 // nothing
	data_input = 8'h00;
	function_sel = NO_FUNCTION;
	layer_reset = 1'b1;
	# 40
	layer_reset = 1'b0;
	# 40
	data_input = 8'h01;
	function_sel = FETCH_FILTER_WEIGHT;
	# 360
	data_input = 8'h02;
	function_sel = FETCH_FILTER_WEIGHT;
	# 360
	data_input = 8'h03;
	function_sel = FETCH_FILTER_WEIGHT;
	# 360 // nothing
	data_input = 8'h00;
	function_sel = NO_FUNCTION;
	# 40
	data_input = 8'h00;
	function_sel = NEURON_FETCH;
	# 120
	data_input = 8'h00;
	function_sel = NEURON_FETCH_AND_OPERAND_FETCH;	
	# 3200  // 3x3x3x3
	data_input = 8'h00;
	function_sel = OPERAND_FETCH;
	# 80 // nothing
	data_input = 8'h00;
	function_sel = NO_FUNCTION;	
end

endmodule