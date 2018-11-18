module computation_quad_unit(
	clk,
	reset,
	layer_reset,
	data_bus,
	function_sel,
	accumulator_0,
	accumulator_1,
	accumulator_2,
	accumulator_3,
	accumulator_4,
	accumulator_5,
	accumulator_6,
	accumulator_7,
	accumulator_8,
	accumulator_9,
	accumulator_10,
	accumulator_11,
	accumulator_12,
	accumulator_13,
	accumulator_14,
	accumulator_15
	);

// port parameter
parameter INPUT_BIT_WIDTH   = 8;         // bit-width of neuron-input for each computation unit: 8-bit
parameter OUTPUT_BIT_WIDTH  = 16+6+2;    // each quad-unit's output bit width
parameter DATA_BUS_BIT_WIDTH = 32;
parameter FUNCTION_BIT_WIDTH = 4;

// control logic
parameter TRUE                   = 1'b1;
parameter FALSE                  = 1'b0;

// configuration register parameter
parameter FILTER_WIDTH_BIT_WIDTH = 3;
parameter INI_FILTER_WIDTH       = 3'h0;
parameter FILTER_SIZE_BIT_WIDTH  = 6;
parameter INI_FILTER_SIZE        = 6'h00;
parameter PICTURE_WIDTH_BIT_WIDTH = 5;
parameter INI_PICTURE_WIDTH       = 5'h00;
parameter PICTURE_HEIGHT_BIT_WIDTH = 5;
parameter INI_PICTURE_HEIGHT       = 5'h00;
parameter PICTURE_SIZE_BIT_WIDTH  = 10;
parameter NUM_OF_FILTERS_BIT_WIDTH = 4;
parameter INI_NUM_OF_FILTERS       = 4'h0;
parameter NUM_OF_CHANNELS_BIT_WIDTH = 2;
parameter INI_NUM_OF_CHANNELS = 2'b00;

// filter fetch parameter
parameter REG_POOL_BIT_WIDTH     = 6;         // index inside filter weight
parameter INI_REG_POOL_INDEX     = 6'h00;
parameter REG_POOL_OFFSET_ONE    = 6'h01;
parameter INI_FILTER_SEL           = 4'h0;    // index which filter
parameter FILTER_SEL_OFFSET_ONE    = 4'h1;

// cache operation
// cache loading / writing
parameter CACHE_DEPTH_BIT_WIDTH   = 5;         // index inside channel through 32
parameter INI_ADDRESS_WR          = 5'h00;
parameter ADDRESS_WR_OFFSET_ONE   = 5'h01;
parameter CACHE_CHANNEL_BIT_WIDTH = 3;         // select channels
parameter INI_WR_CACHE_CHANNEL    = 3'h0; 
parameter CHANNEL_OFFSET_ONE      = 3'h1;
parameter LARGEST_WR_CHANNEL      = 3'h6;
// cache fetching
parameter CACHE_CHANNELS          = 7;
parameter CACHE_OUTPUT_BIT_WIDTH  = 56;

// MAC operand fetch and MAC control signal
// case statement not use parameter
parameter NUM_OF_SUBUNIT    = 4;
// case statement not use parameter
parameter NUM_OF_MAC_UNIT   = 16;
parameter UNABLE_MAC_UNIT   = 16'h0000;
parameter ITER_BIT_WIDTH    = 6;         // 36 register, need 6-bit to index them
parameter INI_6_BITS        = 6'h00;
parameter ITER_OFFSET_ONE   = 6'h01;

// filter pool, MAC operand fetch unit and MAC part, each unit has the same verilog code
parameter ACCUMULATOR_BIT_WIDTH  = 16+6;      // bit-width of output register: sum of 36 number,increase bit-width with 6-bits, total 16+6

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


input                               clk;
input                               reset;
input                               layer_reset;
input  [DATA_BUS_BIT_WIDTH-1:0]     data_bus;
input  [FUNCTION_BIT_WIDTH-1:0]     function_sel;
output [OUTPUT_BIT_WIDTH-1:0]       accumulator_0;
output [OUTPUT_BIT_WIDTH-1:0]       accumulator_1;
output [OUTPUT_BIT_WIDTH-1:0]       accumulator_2;
output [OUTPUT_BIT_WIDTH-1:0]       accumulator_3;
output [OUTPUT_BIT_WIDTH-1:0]       accumulator_4;
output [OUTPUT_BIT_WIDTH-1:0]       accumulator_5;
output [OUTPUT_BIT_WIDTH-1:0]       accumulator_6;
output [OUTPUT_BIT_WIDTH-1:0]       accumulator_7;
output [OUTPUT_BIT_WIDTH-1:0]       accumulator_8;
output [OUTPUT_BIT_WIDTH-1:0]       accumulator_9;
output [OUTPUT_BIT_WIDTH-1:0]       accumulator_10;
output [OUTPUT_BIT_WIDTH-1:0]       accumulator_11;
output [OUTPUT_BIT_WIDTH-1:0]       accumulator_12;
output [OUTPUT_BIT_WIDTH-1:0]       accumulator_13;
output [OUTPUT_BIT_WIDTH-1:0]       accumulator_14;
output [OUTPUT_BIT_WIDTH-1:0]       accumulator_15;

reg [INPUT_BIT_WIDTH-1:0] data_input_0;
reg [INPUT_BIT_WIDTH-1:0] data_input_1;
reg [INPUT_BIT_WIDTH-1:0] data_input_2;
reg [INPUT_BIT_WIDTH-1:0] data_input_3;
always @(data_bus) begin
	data_input_0 = data_bus[7:0];
	data_input_1 = data_bus[15:8];
	data_input_2 = data_bus[23:16];
	data_input_3 = data_bus[31:24];
end

//===================================================================================================================================
// control logic
//===================================================================================================================================
// configuration register
wire filter_width_confi_en;
assign filter_width_confi_en = function_sel == FETCH_FILTER_WIDTH ? TRUE : FALSE;
wire filter_size_confi_en;
assign filter_size_confi_en = function_sel == FETCH_FILTER_SIZE ? TRUE : FALSE;
wire picture_width_confi_en;
assign picture_width_confi_en = function_sel == FETCH_PICTURE_WIDTH ? TRUE : FALSE;
wire picture_height_confi_en;
assign picture_height_confi_en = function_sel == FETCH_PICTURE_HEIGHT ? TRUE : FALSE;
wire num_of_filters_confi_en;
assign num_of_filters_confi_en = function_sel == FETCH_NUM_OF_FILTERS ? TRUE : FALSE;
wire num_of_channels_confi_en;
assign num_of_channels_confi_en = function_sel == FETCH_NUM_OF_CHANNELS ? TRUE : FALSE;
// filter weight load
wire filter_fetch_en;
assign filter_fetch_en = (function_sel == FETCH_FILTER_WEIGHT) ? TRUE : FALSE; 
// cache load(write) and fetch(read)
wire cache_loading_en;
assign cache_wr_en = function_sel == CACHE_LOADING ? TRUE : FALSE;
wire neuron_fetch_en;
assign neuron_fetch_en = function_sel == NEURON_FETCH | function_sel == NEURON_FETCH_AND_OPERAND_FETCH  ? TRUE : FALSE;
// operand fetch
wire operand_fetch_en;
assign operand_fetch_en = function_sel == NEURON_FETCH_AND_OPERAND_FETCH | function_sel == OPERAND_FETCH ? TRUE : FALSE;
//===================================================================================================================================
// register configuration
// all the register's value is smaller than actual value 1
//===================================================================================================================================
// wire config_reg_reset;
// assign config_reg_reset = layer_reset | reset;
// config filter width
reg [FILTER_WIDTH_BIT_WIDTH-1:0] filter_width;
always @(posedge clk or posedge reset) begin
	if (reset) begin
		filter_width <= INI_FILTER_WIDTH;
	end
	else if (filter_width_confi_en) begin
		filter_width <= data_input_0;
	end
end
// config filter size
reg [FILTER_SIZE_BIT_WIDTH-1:0] filter_size;
always @(posedge clk or posedge reset) begin
	if (reset) begin
		filter_size <= INI_FILTER_SIZE;
	end
	else if (filter_size_confi_en) begin
		filter_size <= data_input_0;
	end
end
// config picture width
reg [PICTURE_WIDTH_BIT_WIDTH-1:0] picture_width;
always @(posedge clk or posedge reset) begin
	if (reset) begin
		picture_width <= INI_PICTURE_WIDTH;
	end
	else if (picture_width_confi_en) begin
		picture_width <= data_input_0;
	end
end
// config picture height
reg [PICTURE_HEIGHT_BIT_WIDTH-1:0] picture_height;
always @(posedge clk or posedge reset) begin
	if (reset) begin
		picture_height <= INI_PICTURE_HEIGHT;
	end
	else if (picture_height_confi_en) begin
		picture_height <= data_input_0;
	end
end
// config picture size
reg [PICTURE_SIZE_BIT_WIDTH-1:0] picture_size;
always @(picture_width or picture_height) begin
	picture_size = picture_width * picture_height;
end
// config number of filters
reg [NUM_OF_FILTERS_BIT_WIDTH-1:0] num_of_filters;
always @(posedge clk or posedge reset) begin
	if (reset) begin
		num_of_filters <= INI_NUM_OF_FILTERS;
	end
	else if (num_of_filters_confi_en) begin
		num_of_filters <= data_input_0;
	end
end
// config number of channels
reg [NUM_OF_CHANNELS_BIT_WIDTH-1:0] num_of_channels;
always @(posedge clk or posedge reset) begin
	if (reset) begin
		num_of_channels <= INI_NUM_OF_CHANNELS;
	end
	else if (num_of_channels_confi_en) begin
		num_of_channels <= data_input_0;
	end
end

//===================================================================================================================================
// filter fetch/load
// seperate fetch and allocation process to fully utilizate the hardware and memory bandwidth
// when computing, fetch process is also excuted. 
//===================================================================================================================================
// filter fetch: each filter is a unit, after fetching a filter, fetch another
reg [REG_POOL_BIT_WIDTH-1:0] byte_counter_filter_fetch;   // index filter-weight's address
reg [NUM_OF_FILTERS_BIT_WIDTH-1:0] filter_sel;            // index which filter

wire switch_loading_filter_en;                            // enable signal to switch filter
assign switch_loading_filter_en = byte_counter_filter_fetch == filter_size;

always @(posedge clk or posedge layer_reset) begin
	if (layer_reset) begin
		byte_counter_filter_fetch <= INI_REG_POOL_INDEX;
	end
	else if (filter_fetch_en) begin
		if (switch_loading_filter_en) begin
			byte_counter_filter_fetch <= INI_REG_POOL_INDEX;
		end
		else begin
			byte_counter_filter_fetch <= byte_counter_filter_fetch + REG_POOL_OFFSET_ONE;
		end
	end
end

always @(posedge clk or posedge layer_reset) begin
	if (layer_reset) begin
		filter_sel <= INI_FILTER_SEL;
	end
	else if (filter_fetch_en) begin
		if (switch_loading_filter_en) begin
			filter_sel <= filter_sel + FILTER_SEL_OFFSET_ONE;
		end		
	end
end

//===================================================================================================================================
// neuron activation cache and fetch
//===================================================================================================================================
reg [CACHE_DEPTH_BIT_WIDTH-1:0] address_wr;
reg [CACHE_CHANNEL_BIT_WIDTH-1:0] channel_sel_wr;
// write neuron activation cache 
wire address_wr_reset_en;
assign address_wr_reset_en = address_wr == picture_width ? TRUE : FALSE;
always @(posedge clk or posedge layer_reset) begin
	if (layer_reset) begin
		channel_sel_wr <= INI_WR_CACHE_CHANNEL;
	end
	else if (address_wr_reset_en) begin
		channel_sel_wr <= channel_sel_wr + CHANNEL_OFFSET_ONE;
	end
end
always @(posedge clk or posedge layer_reset) begin
	if (layer_reset) begin
		address_wr <= INI_ADDRESS_WR;
	end
	else if (cache_loading_en) begin
		if (address_wr_reset_en) begin
			address_wr <= INI_ADDRESS_WR;
		end
		else begin
			address_wr <= address_wr + ADDRESS_WR_OFFSET_ONE;			
		end
	end
end
// 
wire                              cache_rd_en;
wire [CACHE_DEPTH_BIT_WIDTH-1:0]  address_rd;
wire [CACHE_CHANNELS-1:0]         channel_sel_rd;
wire                              channel_switch_en;
wire                              store_data_en;
wire                              output_neuron_ac_en;
neuron_fetch_control neuron_fetch_control_0(
	.clk(clk),
	.layer_reset(layer_reset),
	.neuron_fetch_en_i(neuron_fetch_en),
	.filter_width_i(filter_width),
	.picture_height_i(picture_height),
	//.fetch_data_i(fetch_data),
	.cache_rd_o(cache_rd_en),
	.address_o(address_rd),
	.channel_sel_o(channel_sel_rd),
	//.neuron_activation_o(neuron_activation)
	.channel_switch_en_o(channel_switch_en),
	.store_data_en_o(store_data_en),
	.output_neuron_ac_en_o(output_neuron_ac_en)
	);

//===================================================================================================================================
// MAC operand fetch and MAC control signal
//===================================================================================================================================

// 16 mac enable signal
reg [NUM_OF_MAC_UNIT-1:0] mac_unit_en_temp;
always @(num_of_filters) begin
	case(num_of_filters)
		4'h0: mac_unit_en_temp = 16'h0001;
		4'h1: mac_unit_en_temp = 16'h0003;
		4'h2: mac_unit_en_temp = 16'h0007;
		4'h3: mac_unit_en_temp = 16'h000f;
		4'h4: mac_unit_en_temp = 16'h001f;
		4'h5: mac_unit_en_temp = 16'h003f;
		4'h6: mac_unit_en_temp = 16'h007f;
		4'h7: mac_unit_en_temp = 16'h00ff;
		4'h8: mac_unit_en_temp = 16'h01ff;
		4'h9: mac_unit_en_temp = 16'h03ff;
		4'ha: mac_unit_en_temp = 16'h07ff;
		4'hb: mac_unit_en_temp = 16'h0fff;
		4'hc: mac_unit_en_temp = 16'h1fff;
		4'hd: mac_unit_en_temp = 16'h3fff;
		4'he: mac_unit_en_temp = 16'h7fff;
		4'hf: mac_unit_en_temp = 16'hffff;
		//default: mac_unit_en_temp = 16'h0000;
	endcase
end  
// 4 subunit enable signal
reg [NUM_OF_SUBUNIT-1:0] subunit_en;
always @(num_of_channels) begin
	case(num_of_channels)
		2'h0: subunit_en = 4'b0001;
		2'h1: subunit_en = 4'b0011;
		2'h2: subunit_en = 4'b0111;
		2'h3: subunit_en = 4'b1111;
		default: subunit_en = 4'b0000;
	endcase
end
// MAC operand fetch iteration
reg [ITER_BIT_WIDTH-1:0] iteration;
reg                      stage_finish;
always @(posedge clk or posedge layer_reset) begin
	if (layer_reset) begin
		iteration <= INI_6_BITS;
		stage_finish <= FALSE;
	end
	else if (operand_fetch_en) begin
		if (iteration == filter_size) begin
			iteration <= INI_6_BITS;
			stage_finish <= TRUE;
		end
		else begin
			iteration <= iteration + ITER_OFFSET_ONE;
			stage_finish <= FALSE;
		end
	end
end
// MAC unit has 2 stage, operand fetch is one stage, 
// so the signal "stage_finish" should delay 3 clock
// here use 3 register to pipeline
reg stage_finish_pipeline_1;
always @(posedge clk) begin
	stage_finish_pipeline_1 <= stage_finish;
end
reg stage_finish_pipeline_2;
always @(posedge clk) begin
	stage_finish_pipeline_2 <= stage_finish_pipeline_1;
end
reg stage_finish_pipeline_3;
always @(posedge clk) begin
	stage_finish_pipeline_3 <= stage_finish_pipeline_2;
end
// 4 subunit control signal
reg [NUM_OF_MAC_UNIT-1:0] unit0_mac_unit_en;
always @(none_zero_operand_fetch_en or mac_unit_en_temp) begin
	if (none_zero_operand_fetch_en & subunit_en[0]) begin
		unit0_mac_unit_en = mac_unit_en_temp;
	end
	else begin
		unit0_mac_unit_en = UNABLE_MAC_UNIT; //16'h0000;
	end
end
reg [NUM_OF_MAC_UNIT-1:0] unit1_mac_unit_en;
always @(none_zero_operand_fetch_en or mac_unit_en_temp) begin
	if (none_zero_operand_fetch_en & subunit_en[1]) begin
		unit1_mac_unit_en = mac_unit_en_temp;
	end
	else begin
		unit1_mac_unit_en = UNABLE_MAC_UNIT; //16'h0000;
	end
end
reg [NUM_OF_MAC_UNIT-1:0] unit2_mac_unit_en;
always @(none_zero_operand_fetch_en or mac_unit_en_temp) begin
	if (none_zero_operand_fetch_en & subunit_en[2]) begin
		unit2_mac_unit_en = mac_unit_en_temp;
	end
	else begin
		unit2_mac_unit_en = UNABLE_MAC_UNIT; //16'h0000;
	end
end
reg [NUM_OF_MAC_UNIT-1:0] unit3_mac_unit_en;
always @(none_zero_operand_fetch_en or mac_unit_en_temp) begin
	if (none_zero_operand_fetch_en & subunit_en[3]) begin
		unit3_mac_unit_en = mac_unit_en_temp;
	end
	else begin
		unit3_mac_unit_en = UNABLE_MAC_UNIT; //16'h0000;
	end
end
wire unit0_filter_fetch_en;
assign unit0_filter_fetch_en = filter_fetch_en & subunit_en[0];
wire unit1_filter_fetch_en;
assign unit1_filter_fetch_en = filter_fetch_en & subunit_en[1];
wire unit2_filter_fetch_en;
assign unit2_filter_fetch_en = filter_fetch_en & subunit_en[2];
wire unit3_filter_fetch_en;
assign unit3_filter_fetch_en = filter_fetch_en & subunit_en[3];
//===================================================================================================================================
// filter pool, MAC operand fetch unit and MAC part, each unit has the same verilog code
//===================================================================================================================================
// neuron broadcast
reg [INPUT_BIT_WIDTH-1:0] neuron_mac;
//assign neuron_mac = neuron_activation;
always @(posedge clk) begin
	if (none_zero_operand_fetch_en) begin
		neuron_mac <= neuron_activation;
	end
end

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
	.neuron_mac_i(neuron_mac),
	.filter_fetch_en_i(unit0_filter_fetch_en),
	.filter_sel_i(filter_sel),
	.mac_unit_en_i(unit0_mac_unit_en),
	.iteration_i(iteration),
	.byte_counter_filter_fetch_i(byte_counter_filter_fetch),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3),
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
	.neuron_mac_i(neuron_mac),
	.filter_fetch_en_i(unit1_filter_fetch_en),
	.filter_sel_i(filter_sel),
	.mac_unit_en_i(unit1_mac_unit_en),
	.iteration_i(iteration),
	.byte_counter_filter_fetch_i(byte_counter_filter_fetch),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3),
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
	.neuron_mac_i(neuron_mac),
	.filter_fetch_en_i(unit2_filter_fetch_en),
	.filter_sel_i(filter_sel),
	.mac_unit_en_i(unit2_mac_unit_en),
	.iteration_i(iteration),
	.byte_counter_filter_fetch_i(byte_counter_filter_fetch),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3),
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
	.neuron_mac_i(neuron_mac),
	.filter_fetch_en_i(unit3_filter_fetch_en),
	.filter_sel_i(filter_sel),
	.mac_unit_en_i(unit3_mac_unit_en),
	.iteration_i(iteration),
	.byte_counter_filter_fetch_i(byte_counter_filter_fetch),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3),
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
accumulator_adder accu_adder_0(
	.clk(clk),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3),
	.accumulator_0_i(unit0_accumulator_0),
	.accumulator_1_i(unit1_accumulator_0),
	.accumulator_2_i(unit2_accumulator_0),
	.accumulator_3_i(unit3_accumulator_0),
	.accumulator_o(accumulator_0)
	);

accumulator_adder accu_adder_1(
	.clk(clk),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3),
	.accumulator_0_i(unit0_accumulator_1),
	.accumulator_1_i(unit1_accumulator_1),
	.accumulator_2_i(unit2_accumulator_1),
	.accumulator_3_i(unit3_accumulator_1),
	.accumulator_o(accumulator_1)
	);

accumulator_adder accu_adder_2(
	.clk(clk),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3),
	.accumulator_0_i(unit0_accumulator_2),
	.accumulator_1_i(unit1_accumulator_2),
	.accumulator_2_i(unit2_accumulator_2),
	.accumulator_3_i(unit3_accumulator_2),
	.accumulator_o(accumulator_2)
	);

accumulator_adder accu_adder_3(
	.clk(clk),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3),
	.accumulator_0_i(unit0_accumulator_3),
	.accumulator_1_i(unit1_accumulator_3),
	.accumulator_2_i(unit2_accumulator_3),
	.accumulator_3_i(unit3_accumulator_3),
	.accumulator_o(accumulator_3)
	);

accumulator_adder accu_adder_4(
	.clk(clk),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3),
	.accumulator_0_i(unit0_accumulator_4),
	.accumulator_1_i(unit1_accumulator_4),
	.accumulator_2_i(unit2_accumulator_4),
	.accumulator_3_i(unit3_accumulator_4),
	.accumulator_o(accumulator_4)
	);

accumulator_adder accu_adder_5(
	.clk(clk),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3),
	.accumulator_0_i(unit0_accumulator_5),
	.accumulator_1_i(unit1_accumulator_5),
	.accumulator_2_i(unit2_accumulator_5),
	.accumulator_3_i(unit3_accumulator_5),
	.accumulator_o(accumulator_5)
	);

accumulator_adder accu_adder_6(
	.clk(clk),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3),
	.accumulator_0_i(unit0_accumulator_6),
	.accumulator_1_i(unit1_accumulator_6),
	.accumulator_2_i(unit2_accumulator_6),
	.accumulator_3_i(unit3_accumulator_6),
	.accumulator_o(accumulator_6)
	);

accumulator_adder accu_adder_7(
	.clk(clk),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3),
	.accumulator_0_i(unit0_accumulator_7),
	.accumulator_1_i(unit1_accumulator_7),
	.accumulator_2_i(unit2_accumulator_7),
	.accumulator_3_i(unit3_accumulator_7),
	.accumulator_o(accumulator_7)
	);

accumulator_adder accu_adder_8(
	.clk(clk),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3),
	.accumulator_0_i(unit0_accumulator_8),
	.accumulator_1_i(unit1_accumulator_8),
	.accumulator_2_i(unit2_accumulator_8),
	.accumulator_3_i(unit3_accumulator_8),
	.accumulator_o(accumulator_8)
	);

accumulator_adder accu_adder_9(
	.clk(clk),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3),
	.accumulator_0_i(unit0_accumulator_9),
	.accumulator_1_i(unit1_accumulator_9),
	.accumulator_2_i(unit2_accumulator_9),
	.accumulator_3_i(unit3_accumulator_9),
	.accumulator_o(accumulator_9)
	);

accumulator_adder accu_adder_10(
	.clk(clk),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3),
	.accumulator_0_i(unit0_accumulator_10),
	.accumulator_1_i(unit1_accumulator_10),
	.accumulator_2_i(unit2_accumulator_10),
	.accumulator_3_i(unit3_accumulator_10),
	.accumulator_o(accumulator_10)
	);

accumulator_adder accu_adder_11(
	.clk(clk),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3),
	.accumulator_0_i(unit0_accumulator_11),
	.accumulator_1_i(unit1_accumulator_11),
	.accumulator_2_i(unit2_accumulator_11),
	.accumulator_3_i(unit3_accumulator_11),
	.accumulator_o(accumulator_11)
	);

accumulator_adder accu_adder_12(
	.clk(clk),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3),
	.accumulator_0_i(unit0_accumulator_12),
	.accumulator_1_i(unit1_accumulator_12),
	.accumulator_2_i(unit2_accumulator_12),
	.accumulator_3_i(unit3_accumulator_12),
	.accumulator_o(accumulator_12)
	);

accumulator_adder accu_adder_13(
	.clk(clk),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3),
	.accumulator_0_i(unit0_accumulator_13),
	.accumulator_1_i(unit1_accumulator_13),
	.accumulator_2_i(unit2_accumulator_13),
	.accumulator_3_i(unit3_accumulator_13),
	.accumulator_o(accumulator_13)
	);

accumulator_adder accu_adder_14(
	.clk(clk),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3),
	.accumulator_0_i(unit0_accumulator_14),
	.accumulator_1_i(unit1_accumulator_14),
	.accumulator_2_i(unit2_accumulator_14),
	.accumulator_3_i(unit3_accumulator_14),
	.accumulator_o(accumulator_14)
	);

accumulator_adder accu_adder_15(
	.clk(clk),
	.stage_finish_pipeline_3_i(stage_finish_pipeline_3),
	.accumulator_0_i(unit0_accumulator_15),
	.accumulator_1_i(unit1_accumulator_15),
	.accumulator_2_i(unit2_accumulator_15),
	.accumulator_3_i(unit3_accumulator_15),
	.accumulator_o(accumulator_15)
	);

endmodule