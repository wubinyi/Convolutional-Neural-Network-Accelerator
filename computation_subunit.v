module computation_subunit(
	clk,
	reset,
	layer_reset,
	data_input,
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

parameter INPUT_BIT_WIDTH   = 8;         // bit-width of neuron-input: 8-bit
parameter OUTPUT_BIT_WIDTH  = 16+6;      // bit-width of output register: sum of 36 number,increase bit-width with 6-bits, total 16+6
parameter BYTES_OF_REG      = 36;        // number of neuron-input: 36 --> max. filter size: 6 x 6
parameter NUM_OF_FILTERS    = 16;        // number of output: 16, because of 16 filters
parameter ITER_BIT_WIDTH    = 6;         // 36 register, need 6-bit to index them
parameter INI_8_BITS        = 8'h00;
parameter INI_6_BITS        = 6'h00;
parameter FILTER_WIDTH_BIT_WIDTH = 3;
parameter INI_FILTER_WIDTH       = 3'h0;
parameter FILTER_SIZE_BIT_WIDTH  = 6;
parameter INI_FILTER_SIZE        = 6'h00;
parameter FILTER_SIZE_OFFSET_ONE = 6'h01;
parameter REG_POOL_BIT_WIDTH     = 6;
parameter INI_REG_POOL_INDEX     = 6'h00;
parameter REG_POOL_OFFSET_ONE    = 6'h01;
parameter TRUE                   = 1'b1;
parameter FALSE                  = 1'b0;
parameter CACHE_CHANNELS         = 7;
parameter CACHE_CHANNEL_BIT_WIDTH = 3;
parameter INI_WR_CACHE_CHANNEL    = 3'h0; 
parameter LARGEST_WR_CHANNEL         = 3'h6;
parameter CHANNEL_OFFSET_ONE      = 3'h1;
parameter CACHE_DEPTH_BIT_WIDTH    = 5;  // through 32
parameter INI_ADDRESS_WR          = 5'h00;
parameter ADDRESS_WR_OFFSET_ONE   = 5'h01;
parameter PICTURE_WIDTH_BIT_WIDTH = 5;
parameter PICTURE_HEIGHT_BIT_WIDTH = 5;
parameter INI_PICTURE_WIDTH       = 5'h00;
parameter PICTURE_SIZE_BIT_WIDTH  = 10;
parameter NUM_OF_FILTERS_BIT_WIDTH = 4;
parameter INI_NUM_OF_FILTERS       = 4'h0;
parameter INI_FILTER_SEL           = 4'h0;
parameter FILTER_SEL_OFFSET_ONE    = 4'h1;
parameter FETCH_1ST_FILTER = 0;
parameter FETCH_2ND_FILTER = 1;
parameter FETCH_3RD_FILTER = 2;
parameter FETCH_4TH_FILTER = 3;
parameter FETCH_5TH_FILTER = 4;
parameter FETCH_6TH_FILTER = 5;
parameter FETCH_7TH_FILTER = 6;
parameter FETCH_8TH_FILTER = 7;
parameter FETCH_9TH_FILTER = 8;
parameter FETCH_10TH_FILTER = 9;
parameter FETCH_11TH_FILTER = 10;
parameter FETCH_12TH_FILTER = 11;
parameter FETCH_13TH_FILTER = 12;
parameter FETCH_14TH_FILTER = 13;
parameter FETCH_15TH_FILTER = 14;
parameter FETCH_16TH_FILTER = 15;
parameter CACHE_OUTPUT_BIT_WIDTH   = 56;
parameter NUM_OF_MAC_UNIT  = 16;
parameter ZERO_NEURON_ACTI  = 8'h00;
// function
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


input                               clk;
input                               reset;
input                               layer_reset;
input  [INPUT_BIT_WIDTH-1:0]        data_input;
input  [3:0]                        function_sel;
output reg [OUTPUT_BIT_WIDTH-1:0]   accumulator_0;
output reg [OUTPUT_BIT_WIDTH-1:0]   accumulator_1;
output reg [OUTPUT_BIT_WIDTH-1:0]   accumulator_2;
output reg [OUTPUT_BIT_WIDTH-1:0]   accumulator_3;
output reg [OUTPUT_BIT_WIDTH-1:0]   accumulator_4;
output reg [OUTPUT_BIT_WIDTH-1:0]   accumulator_5;
output reg [OUTPUT_BIT_WIDTH-1:0]   accumulator_6;
output reg [OUTPUT_BIT_WIDTH-1:0]   accumulator_7;
output reg [OUTPUT_BIT_WIDTH-1:0]   accumulator_8;
output reg [OUTPUT_BIT_WIDTH-1:0]   accumulator_9;
output reg [OUTPUT_BIT_WIDTH-1:0]   accumulator_10;
output reg [OUTPUT_BIT_WIDTH-1:0]   accumulator_11;
output reg [OUTPUT_BIT_WIDTH-1:0]   accumulator_12;
output reg [OUTPUT_BIT_WIDTH-1:0]   accumulator_13;
output reg [OUTPUT_BIT_WIDTH-1:0]   accumulator_14;
output reg [OUTPUT_BIT_WIDTH-1:0]   accumulator_15;

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
// config filter width
reg [FILTER_WIDTH_BIT_WIDTH-1:0] filter_width;
always @(posedge clk or posedge reset) begin
	if (reset) begin
		filter_width <= INI_FILTER_WIDTH;
	end
	else if (filter_width_confi_en) begin
		filter_width <= data_input;
	end
end
// config filter size
reg [FILTER_SIZE_BIT_WIDTH-1:0] filter_size;
always @(posedge clk or posedge reset) begin
	if (reset) begin
		filter_size <= INI_FILTER_SIZE;
	end
	else if (filter_size_confi_en) begin
		filter_size <= data_input;
	end
end
// config picture width
reg [PICTURE_WIDTH_BIT_WIDTH-1:0] picture_width;
always @(posedge clk or posedge reset) begin
	if (reset) begin
		picture_width <= INI_PICTURE_WIDTH;
	end
	else if (picture_width_confi_en) begin
		picture_width <= data_input;
	end
end
// config picture height
reg [PICTURE_HEIGHT_BIT_WIDTH-1:0] picture_height;
always @(posedge clk or posedge reset) begin
	if (reset) begin
		picture_height <= INI_PICTURE_WIDTH;
	end
	else if (picture_height_confi_en) begin
		picture_height <= data_input;
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
		num_of_filters <= data_input;
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
reg [INPUT_BIT_WIDTH-1:0] filter_weight_0 [BYTES_OF_REG-1:0];
reg [INPUT_BIT_WIDTH-1:0] filter_weight_1 [BYTES_OF_REG-1:0];
reg [INPUT_BIT_WIDTH-1:0] filter_weight_2 [BYTES_OF_REG-1:0];
reg [INPUT_BIT_WIDTH-1:0] filter_weight_3 [BYTES_OF_REG-1:0];
reg [INPUT_BIT_WIDTH-1:0] filter_weight_4 [BYTES_OF_REG-1:0];
reg [INPUT_BIT_WIDTH-1:0] filter_weight_5 [BYTES_OF_REG-1:0];
reg [INPUT_BIT_WIDTH-1:0] filter_weight_6 [BYTES_OF_REG-1:0];
reg [INPUT_BIT_WIDTH-1:0] filter_weight_7 [BYTES_OF_REG-1:0];
reg [INPUT_BIT_WIDTH-1:0] filter_weight_8 [BYTES_OF_REG-1:0];
reg [INPUT_BIT_WIDTH-1:0] filter_weight_9 [BYTES_OF_REG-1:0];
reg [INPUT_BIT_WIDTH-1:0] filter_weight_10 [BYTES_OF_REG-1:0];
reg [INPUT_BIT_WIDTH-1:0] filter_weight_11 [BYTES_OF_REG-1:0];
reg [INPUT_BIT_WIDTH-1:0] filter_weight_12 [BYTES_OF_REG-1:0];
reg [INPUT_BIT_WIDTH-1:0] filter_weight_13 [BYTES_OF_REG-1:0];
reg [INPUT_BIT_WIDTH-1:0] filter_weight_14 [BYTES_OF_REG-1:0];
reg [INPUT_BIT_WIDTH-1:0] filter_weight_15 [BYTES_OF_REG-1:0];
always @(posedge clk) begin
	if (filter_fetch_en) begin
		case(filter_sel)
			FETCH_1ST_FILTER: filter_weight_0[byte_counter_filter_fetch] <= data_input;
			FETCH_2ND_FILTER: filter_weight_1[byte_counter_filter_fetch] <= data_input;
			FETCH_3RD_FILTER: filter_weight_2[byte_counter_filter_fetch] <= data_input;
			FETCH_4TH_FILTER: filter_weight_3[byte_counter_filter_fetch] <= data_input;
			FETCH_5TH_FILTER: filter_weight_4[byte_counter_filter_fetch] <= data_input;
			FETCH_6TH_FILTER: filter_weight_5[byte_counter_filter_fetch] <= data_input;
			FETCH_7TH_FILTER: filter_weight_6[byte_counter_filter_fetch] <= data_input;
			FETCH_8TH_FILTER: filter_weight_7[byte_counter_filter_fetch] <= data_input;
			FETCH_9TH_FILTER: filter_weight_8[byte_counter_filter_fetch] <= data_input;
			FETCH_10TH_FILTER: filter_weight_9[byte_counter_filter_fetch] <= data_input;
			FETCH_11TH_FILTER: filter_weight_10[byte_counter_filter_fetch] <= data_input;
			FETCH_12TH_FILTER: filter_weight_11[byte_counter_filter_fetch] <= data_input;
			FETCH_13TH_FILTER: filter_weight_12[byte_counter_filter_fetch] <= data_input;
			FETCH_14TH_FILTER: filter_weight_13[byte_counter_filter_fetch] <= data_input;
			FETCH_15TH_FILTER: filter_weight_14[byte_counter_filter_fetch] <= data_input;
			FETCH_16TH_FILTER: filter_weight_15[byte_counter_filter_fetch] <= data_input;
		endcase		
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
wire [CACHE_OUTPUT_BIT_WIDTH-1:0] fetch_data;
wire                              cache_rd_en;
wire [CACHE_DEPTH_BIT_WIDTH-1:0]  address_rd;
wire [CACHE_CHANNELS-1:0]         channel_sel_rd;
wire [INPUT_BIT_WIDTH-1:0]        neuron_activation;
neuron_fetch neuron_fetch_0(
	.clk(clk),
	.layer_reset(layer_reset),
	.neuron_fetch_en_i(neuron_fetch_en),
	.filter_width_i(filter_width),
	.picture_height_i(picture_height),
	.fetch_data_i(fetch_data),
	.cache_rd_o(cache_rd_en),
	.address_o(address_rd),
	.channel_sel_o(channel_sel_rd),
	.neuron_activation_o(neuron_activation)
	);
cache #(.INITFILE0("INITFILE0"), .INITFILE1("INITFILE1"), .INITFILE2("INITFILE2"), .INITFILE3("INITFILE3"), 
		.INITFILE4("INITFILE4"), .INITFILE5("INITFILE5"), .INITFILE6("INITFILE6")) cache_0(
	.clk(clk),
	.rd_en_i(cache_rd_en),
	.channel_rd_sel_i(channel_sel_rd),
	.address_rd_i(address_rd),
	.fetch_data_o(fetch_data),
	.wr_en_i(write),
	.channel_wr_sel_i(channel_sel_wr),
	.address_wr_i(address_wr),
	.cache_data_i(data_input)
	);

//===================================================================================================================================
// MAC operand fetch and MAC control signal
//===================================================================================================================================
// neuron activation zero judgement
wire none_zero_neuron_activation;
assign none_zero_neuron_activation = |neuron_activation;
wire none_zero_operand_fetch_en;
assign none_zero_operand_fetch_en = operand_fetch_en & none_zero_neuron_activation;
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
	endcase
end  
reg [NUM_OF_MAC_UNIT-1:0] mac_unit_en;
always @(none_zero_operand_fetch_en or mac_unit_en_temp) begin
	if (none_zero_operand_fetch_en) begin
		mac_unit_en = mac_unit_en_temp;
	end
	else begin
		mac_unit_en = 16'h0000;
	end
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
			iteration <= iteration + 6'd1;
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

//===================================================================================================================================
// MAC operand fetch 
//===================================================================================================================================
// neuron broadcast
reg [INPUT_BIT_WIDTH-1:0] neuron_mac;
//assign neuron_mac = neuron_activation;
always @(posedge clk) begin
	if (none_zero_operand_fetch_en) begin
		neuron_mac <= neuron_activation;
	end
end

// filter weight operand fetch
reg [INPUT_BIT_WIDTH-1:0] filter_0_mac;
reg [INPUT_BIT_WIDTH-1:0] filter_1_mac;
reg [INPUT_BIT_WIDTH-1:0] filter_2_mac;
reg [INPUT_BIT_WIDTH-1:0] filter_3_mac;
reg [INPUT_BIT_WIDTH-1:0] filter_4_mac;
reg [INPUT_BIT_WIDTH-1:0] filter_5_mac;
reg [INPUT_BIT_WIDTH-1:0] filter_6_mac;
reg [INPUT_BIT_WIDTH-1:0] filter_7_mac;
reg [INPUT_BIT_WIDTH-1:0] filter_8_mac;
reg [INPUT_BIT_WIDTH-1:0] filter_9_mac;
reg [INPUT_BIT_WIDTH-1:0] filter_10_mac;
reg [INPUT_BIT_WIDTH-1:0] filter_11_mac;
reg [INPUT_BIT_WIDTH-1:0] filter_12_mac;
reg [INPUT_BIT_WIDTH-1:0] filter_13_mac;
reg [INPUT_BIT_WIDTH-1:0] filter_14_mac;
reg [INPUT_BIT_WIDTH-1:0] filter_15_mac;
always @(posedge clk) begin
	if (mac_unit_en[0]) begin
		filter_0_mac <= filter_weight_0[iteration];
	end
end
always @(posedge clk) begin
	if (mac_unit_en[1]) begin
		filter_1_mac <= filter_weight_1[iteration];
	end
end
always @(posedge clk) begin
	if (mac_unit_en[2]) begin
		filter_2_mac <= filter_weight_2[iteration];
	end
end
always @(posedge clk) begin
	if (mac_unit_en[3]) begin
		filter_3_mac <= filter_weight_3[iteration];
	end
end
always @(posedge clk) begin
	if (mac_unit_en[4]) begin
		filter_4_mac <= filter_weight_4[iteration];
	end
end
always @(posedge clk) begin
	if (mac_unit_en[5]) begin
		filter_5_mac <= filter_weight_5[iteration];
	end
end
always @(posedge clk) begin
	if (mac_unit_en[6]) begin
		filter_6_mac <= filter_weight_6[iteration];
	end
end
always @(posedge clk) begin
	if (mac_unit_en[7]) begin
		filter_7_mac <= filter_weight_7[iteration];
	end
end
always @(posedge clk) begin
	if (mac_unit_en[8]) begin
		filter_8_mac <= filter_weight_8[iteration];
	end
end
always @(posedge clk) begin
	if (mac_unit_en[9]) begin
		filter_9_mac <= filter_weight_9[iteration];
	end
end
always @(posedge clk) begin
	if (mac_unit_en[10]) begin
		filter_10_mac <= filter_weight_10[iteration];
	end
end
always @(posedge clk) begin
	if (mac_unit_en[11]) begin
		filter_11_mac <= filter_weight_11[iteration];
	end
end
always @(posedge clk) begin
	if (mac_unit_en[12]) begin
		filter_12_mac <= filter_weight_12[iteration];
	end
end
always @(posedge clk) begin
	if (mac_unit_en[13]) begin
		filter_13_mac <= filter_weight_13[iteration];
	end
end
always @(posedge clk) begin
	if (mac_unit_en[14]) begin
		filter_14_mac <= filter_weight_14[iteration];
	end
end
always @(posedge clk) begin
	if (mac_unit_en[15]) begin
		filter_15_mac <= filter_weight_15[iteration];
	end
end

// delay mac unit enable signal one clock using register
// because filter_xx_mac delay one clock
reg [NUM_OF_MAC_UNIT-1:0] mac_unit_en_delay;
always @(posedge clk) begin
	mac_unit_en_delay <= mac_unit_en;
end

//===================================================================================================================================
// MAC - computing part
//===================================================================================================================================
// 16 MAC units
wire [OUTPUT_BIT_WIDTH-1:0] accumulator_0_temp;
wire [OUTPUT_BIT_WIDTH-1:0] accumulator_1_temp;
wire [OUTPUT_BIT_WIDTH-1:0] accumulator_2_temp;
wire [OUTPUT_BIT_WIDTH-1:0] accumulator_3_temp;
wire [OUTPUT_BIT_WIDTH-1:0] accumulator_4_temp;
wire [OUTPUT_BIT_WIDTH-1:0] accumulator_5_temp;
wire [OUTPUT_BIT_WIDTH-1:0] accumulator_6_temp;
wire [OUTPUT_BIT_WIDTH-1:0] accumulator_7_temp;
wire [OUTPUT_BIT_WIDTH-1:0] accumulator_8_temp;
wire [OUTPUT_BIT_WIDTH-1:0] accumulator_9_temp;
wire [OUTPUT_BIT_WIDTH-1:0] accumulator_10_temp;
wire [OUTPUT_BIT_WIDTH-1:0] accumulator_11_temp;
wire [OUTPUT_BIT_WIDTH-1:0] accumulator_12_temp;
wire [OUTPUT_BIT_WIDTH-1:0] accumulator_13_temp;
wire [OUTPUT_BIT_WIDTH-1:0] accumulator_14_temp;
wire [OUTPUT_BIT_WIDTH-1:0] accumulator_15_temp;
mac mac_0(clk, layer_reset, stage_finish_pipeline_3, mac_unit_en_delay[0], neuron_mac, filter_0_mac, accumulator_0_temp);
mac mac_1(clk, layer_reset, stage_finish_pipeline_3, mac_unit_en_delay[1], neuron_mac, filter_1_mac, accumulator_1_temp);
mac mac_2(clk, layer_reset, stage_finish_pipeline_3, mac_unit_en_delay[2], neuron_mac, filter_2_mac, accumulator_2_temp);
mac mac_3(clk, layer_reset, stage_finish_pipeline_3, mac_unit_en_delay[3], neuron_mac, filter_3_mac, accumulator_3_temp);
mac mac_4(clk, layer_reset, stage_finish_pipeline_3, mac_unit_en_delay[4], neuron_mac, filter_4_mac, accumulator_4_temp);
mac mac_5(clk, layer_reset, stage_finish_pipeline_3, mac_unit_en_delay[5], neuron_mac, filter_5_mac, accumulator_5_temp);
mac mac_6(clk, layer_reset, stage_finish_pipeline_3, mac_unit_en_delay[6], neuron_mac, filter_6_mac, accumulator_6_temp);
mac mac_7(clk, layer_reset, stage_finish_pipeline_3, mac_unit_en_delay[7], neuron_mac, filter_7_mac, accumulator_7_temp);
mac mac_8(clk, layer_reset, stage_finish_pipeline_3, mac_unit_en_delay[8], neuron_mac, filter_8_mac, accumulator_8_temp);
mac mac_9(clk, layer_reset, stage_finish_pipeline_3, mac_unit_en_delay[9], neuron_mac, filter_9_mac, accumulator_9_temp);
mac mac_10(clk, layer_reset, stage_finish_pipeline_3, mac_unit_en_delay[10], neuron_mac, filter_10_mac, accumulator_10_temp);
mac mac_11(clk, layer_reset, stage_finish_pipeline_3, mac_unit_en_delay[11], neuron_mac, filter_11_mac, accumulator_11_temp);
mac mac_12(clk, layer_reset, stage_finish_pipeline_3, mac_unit_en_delay[12], neuron_mac, filter_12_mac, accumulator_12_temp);
mac mac_13(clk, layer_reset, stage_finish_pipeline_3, mac_unit_en_delay[13], neuron_mac, filter_13_mac, accumulator_13_temp);
mac mac_14(clk, layer_reset, stage_finish_pipeline_3, mac_unit_en_delay[14], neuron_mac, filter_14_mac, accumulator_14_temp);
mac mac_15(clk, layer_reset, stage_finish_pipeline_3, mac_unit_en_delay[15], neuron_mac, filter_15_mac, accumulator_15_temp);

// after one filter mac oprations, output accumulator
always @(posedge clk) begin
	if (stage_finish_pipeline_3) begin
		accumulator_0  <= accumulator_0_temp;
		accumulator_1  <= accumulator_1_temp;
		accumulator_2  <= accumulator_2_temp;
		accumulator_3  <= accumulator_3_temp;
		accumulator_4  <= accumulator_4_temp;
		accumulator_5  <= accumulator_5_temp;
		accumulator_6  <= accumulator_6_temp;
		accumulator_7  <= accumulator_7_temp;
		accumulator_8  <= accumulator_8_temp;
		accumulator_9  <= accumulator_9_temp;
		accumulator_10 <= accumulator_10_temp;
		accumulator_11 <= accumulator_11_temp;
		accumulator_12 <= accumulator_12_temp;
		accumulator_13 <= accumulator_13_temp;
		accumulator_14 <= accumulator_14_temp;
		accumulator_15 <= accumulator_15_temp;
	end
end

endmodule