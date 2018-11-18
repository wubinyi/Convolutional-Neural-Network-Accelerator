module quad_unit_tb();

parameter DATA_BUS_BIT_WIDTH = 32;
parameter FUNCTION_BIT_WIDTH = 4;
parameter OUTPUT_BIT_WIDTH  = 16+6+2;


reg                               clk;
reg                               reset;
reg                               layer_reset;
reg  [DATA_BUS_BIT_WIDTH-1:0]     data_bus;
reg  [FUNCTION_BIT_WIDTH-1:0]     function_sel;
wire [OUTPUT_BIT_WIDTH-1:0]   	  accumulator_0;
wire [OUTPUT_BIT_WIDTH-1:0]   	  accumulator_1;
wire [OUTPUT_BIT_WIDTH-1:0]   	  accumulator_2;
wire [OUTPUT_BIT_WIDTH-1:0]   	  accumulator_3;
wire [OUTPUT_BIT_WIDTH-1:0]   	  accumulator_4;
wire [OUTPUT_BIT_WIDTH-1:0]   	  accumulator_5;
wire [OUTPUT_BIT_WIDTH-1:0]   	  accumulator_6;
wire [OUTPUT_BIT_WIDTH-1:0]   	  accumulator_7;
wire [OUTPUT_BIT_WIDTH-1:0]   	  accumulator_8;
wire [OUTPUT_BIT_WIDTH-1:0]   	  accumulator_9;
wire [OUTPUT_BIT_WIDTH-1:0]   	  accumulator_10;
wire [OUTPUT_BIT_WIDTH-1:0]   	  accumulator_11;
wire [OUTPUT_BIT_WIDTH-1:0]   	  accumulator_12;
wire [OUTPUT_BIT_WIDTH-1:0]   	  accumulator_13;
wire [OUTPUT_BIT_WIDTH-1:0]   	  accumulator_14;
wire [OUTPUT_BIT_WIDTH-1:0]   	  accumulator_15;

computation_quad_unit quad_unit_0(
	.clk(clk),
	.reset(reset),
	.layer_reset(layer_reset),
	.data_bus(data_bus),
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
	forever #20 clk = ~clk;
end

initial begin
	reset = 1'b0;
	# 35 reset = 1'b1;
	# 10 reset = 1'b0;
end

// function
parameter NO_FUNCTION                    = 0;
parameter FETCH_FILTER_WIDTH             = 1;
parameter FETCH_FILTER_SIZE              = 2;
parameter FETCH_PICTURE_WIDTH            = 3;
parameter FETCH_PICTURE_HEIGHT           = 4;
parameter FETCH_NUM_OF_FILTERS           = 5;
parameter FETCH_NUM_OF_CHANNELS          = 6;
parameter FETCH_FILTER_WEIGHT            = 7;
parameter CACHE_LOADING                  = 8;
parameter NEURON_FETCH                   = 9; 
parameter NEURON_FETCH_AND_OPERAND_FETCH = 10;
parameter OPERAND_FETCH                  = 11;
initial begin
	layer_reset = 1'b0;
	data_bus = 32'h0000_0000;
	function_sel = NO_FUNCTION;
	# 4  // signal delay
	# 60 // filter width: 3
	data_bus = 32'h0000_0002;
	function_sel = FETCH_FILTER_WIDTH;
	# 40 // filter size: 9
	data_bus = 32'h0000_0008;
	function_sel = FETCH_FILTER_SIZE;
	# 40 // picture width: 4
	data_bus = 32'h0000_0004;
	function_sel = FETCH_PICTURE_WIDTH;
	# 40 // picture height: 4
	data_bus = 32'h0000_0004;
	function_sel = FETCH_PICTURE_HEIGHT;
	# 40 // number of filters: 3
	data_bus = 32'h0000_0003;
	function_sel = FETCH_NUM_OF_FILTERS;
	# 40 // number of channels: 2
	data_bus = 32'h0000_0002;
	function_sel = FETCH_NUM_OF_CHANNELS;
	# 40 // layer reset
	layer_reset = 1'b1;
	# 40 // fetch first filter
	layer_reset = 1'b0;
	data_bus = 32'h0000_2111;
	function_sel = FETCH_FILTER_WEIGHT;
	# 360 // fetch second filter
	data_bus = 32'h0000_2212;
	function_sel = FETCH_FILTER_WEIGHT;
	# 360 // fetch third filter
	data_bus = 32'h0000_2213;
	function_sel = FETCH_FILTER_WEIGHT;
	# 360 // neuron fetch
	data_bus = 32'hffff_ffff;
	function_sel = NEURON_FETCH;
	# 120
	data_bus = 32'hffff_ffff;
	function_sel = NEURON_FETCH_AND_OPERAND_FETCH;	
	# 3200  // 3x3x3x3
	data_bus = 32'hffff_ffff;
	function_sel = OPERAND_FETCH;
	# 80 // nothing
	data_bus = 32'hffff_ffff;
	function_sel = NO_FUNCTION;	
end

endmodule