// cache size: 32 x 7 x 16 = 3584 = 3.5 KBytes
// 32: support max. picture size's width
// 7 : support max. 6 x 6 filter
// 16: support max. 16 channels

module neuron_fetch(
	clk,
	layer_reset,
	neuron_fetch_en_i,
	filter_width_i,
	picture_height_i,
	fetch_data_i,
	cache_rd_o,
	address_o,
	channel_sel_o,
	neuron_activation_o
	);

// port parameter
parameter FILTER_WIDTH_BIT_WIDTH   = 3;
parameter PICTURE_HEIGHT_BIT_WIDTH = 5;
parameter FETCH_DATA_BIT_WIDTH     = 56;  // 8 * 7
parameter CACHE_DEPTH_BIT_WIDTH    = 5;  // through 32
parameter CACHE_CHANNELS           = 7;
parameter REG_BIT_WIDTH            = 8;

// control signal
parameter TRUE                     = 1'b1;
parameter FALSE                    = 1'b0;
parameter DEEPEST_ADDRESS          = 5'd31;

// addressing restriction and address generator
parameter INI_ADDRESS              = 5'h00; 
parameter ADDRESS_OFFSET_ONE       = 5'h01;
parameter CHANNEL_SEL_NONE         = 7'b0000000;
parameter FILTER_WIDTH_1           = 3'h0;
parameter CHANNEL_SEL_1            = 7'b1000000;        
parameter FILTER_WIDTH_2           = 3'h1;
parameter CHANNEL_SEL_2            = 7'b1100000;  
parameter FILTER_WIDTH_3           = 3'h2;
parameter CHANNEL_SEL_3            = 7'b1110000;
parameter FILTER_WIDTH_4           = 3'h3;
parameter CHANNEL_SEL_4            = 7'b1111000;
parameter FILTER_WIDTH_5           = 3'h4;
parameter CHANNEL_SEL_5            = 7'b1111100;
parameter FILTER_WIDTH_6           = 3'h5;
parameter CHANNEL_SEL_6            = 7'b1111110;

// data fetch
parameter CHANNEL_BIT_WIDTH        = 3;
parameter INI_BEGIN_CHANNAL        = 3'h0;
parameter FIRST_CHANNEL            = 3'h0;
parameter SECOND_CHANNEL           = 3'h1;
parameter THIRD_CHANNEL            = 3'h2;
parameter FOURTH_CHANNEL           = 3'h3;
parameter FIFTH_CHANNEL            = 3'h4;
parameter SIXTH_CHANNEL            = 3'h5;
parameter SEVENTH_CHANNEL          = 3'h6;
parameter INDEX_BIT_WIDTH          = 3;
parameter INI_INDEX                = 3'h0;
parameter INDEX_ZERO               = 3'h0;
parameter INDEX_ONE                = 3'h1;
parameter INDEX_TWO                = 3'h2;
parameter INDEX_THREE              = 3'h3;
parameter INDEX_FOURTH             = 3'h4;
parameter INDEX_FIFTH              = 3'h5;
parameter INI_OUPUT                = 8'h00;


input                                      clk;
input                                      layer_reset;
input                                      neuron_fetch_en_i;
input      [FILTER_WIDTH_BIT_WIDTH-1:0]    filter_width_i;
input      [PICTURE_HEIGHT_BIT_WIDTH-1:0]  picture_height_i;
input      [FETCH_DATA_BIT_WIDTH-1:0]      fetch_data_i;
output                                     cache_rd_o;
output reg [CACHE_DEPTH_BIT_WIDTH-1:0]     address_o;
output reg [CACHE_CHANNELS-1:0]            channel_sel_o;
output reg [REG_BIT_WIDTH-1:0]             neuron_activation_o;

//======================================================================================================
// internal register
//======================================================================================================
// addressing
reg [CACHE_DEPTH_BIT_WIDTH-1:0] begining_address;
reg [CACHE_DEPTH_BIT_WIDTH-1:0] ending_address;
reg [CACHE_DEPTH_BIT_WIDTH-1:0] address_plus_one;
reg [CACHE_DEPTH_BIT_WIDTH-1:0] next_begining_address;

// addressing controlling signal
wire addressing_en;

// cache read/write signal / output signal
// wire cache_rd_o;

// store/load fetch data
wire store_data_en;

// output neuron activation enable signal
wire output_neuron_ac_en;

//======================================================================================================
// control signal 
//======================================================================================================
// next stage signal
wire next_stage_en;
assign next_stage_en = (address_o == ending_address) ? TRUE : FALSE;

// channel switch signal
wire channel_switch_en;
//assign channel_switch_en = (address_o == DEEPEST_ADDRESS) ? TRUE : FALSE;
assign channel_switch_en = (address_o == picture_height_i) | (address_o == DEEPEST_ADDRESS) ? TRUE : FALSE;

// filter width
//wire [FILTER_WIDTH_BIT_WIDTH-1:0] filter_width;
//assign filter_width = filter_width_i - 3'h1;

neuron_fetch_pipelline neuron_fetch_pipelline_0(
	.clk(clk),
	.layer_reset(layer_reset),
	.filter_width_i(filter_width_i),
	.neuron_fetch_en_i(neuron_fetch_en_i),
	.addressing_en_o(addressing_en),
	.cache_rd_o(cache_rd_o),
	.store_data_en_o(store_data_en),
	.output_neuron_ac_en_o(output_neuron_ac_en)
	);


//======================================================================================================
// addressing restriction and address generator
//======================================================================================================
// fetch restriction: begining address
always @(posedge clk or posedge layer_reset) begin
	if (layer_reset) begin
		begining_address <= INI_ADDRESS;
	end
	else if (addressing_en) begin
		if (channel_switch_en) begin
			begining_address <= INI_ADDRESS;
		end
		else if (next_stage_en) begin
			begining_address <= next_begining_address;
		end
	end
end
always @* begin
	next_begining_address = begining_address + ADDRESS_OFFSET_ONE;
end

// fetch restriction: ending address
always @* begin
	ending_address <= begining_address + filter_width_i;
end

// fetch data: address output
// output reg [CACHE_DEPTH_BIT_WIDTH-1:0] address_o;
always @* begin
	address_plus_one <= address_o + ADDRESS_OFFSET_ONE;
end
always @(posedge clk or posedge layer_reset) begin
	if (layer_reset) begin
		address_o <= INI_ADDRESS;
	end
	else if (addressing_en) begin
		if (channel_switch_en) begin
			address_o <= INI_ADDRESS;
		end
		else if (next_stage_en) begin
			address_o <= next_begining_address;
		end 
		else begin
			address_o <= address_plus_one;
		end		
	end
end

// initial cache channel select
reg [CACHE_CHANNELS-1:0] channel_val;
always @(filter_width_i) begin
	case(filter_width_i)
		FILTER_WIDTH_1: channel_val = CHANNEL_SEL_1; //7'b1000000;
		FILTER_WIDTH_2: channel_val = CHANNEL_SEL_2; //7'b1100000;
		FILTER_WIDTH_3: channel_val = CHANNEL_SEL_3; //7'b1110000;
		FILTER_WIDTH_4: channel_val = CHANNEL_SEL_4; //7'b1111000;
		FILTER_WIDTH_5: channel_val = CHANNEL_SEL_5; //7'b1111100;
		FILTER_WIDTH_6: channel_val = CHANNEL_SEL_6; //7'b1111110;
		default: channel_val = CHANNEL_SEL_NONE; // 7'b0000000;
	endcase
end
// channel select and switch channel
// reg [CACHE_CHANNELS-1:0] channel_sel_o;
always @(posedge clk) begin
	if (layer_reset) begin
		channel_sel_o <= channel_val;   // channel_val is not a constant, can not use signal "layer_reset" as trigger signal
	end
	else if (addressing_en) begin
		if (channel_switch_en) begin
			channel_sel_o <= {channel_sel_o[0], channel_sel_o[CACHE_CHANNELS-1:1]};
		end		
	end 
end

//======================================================================================================
// data fetching 
//======================================================================================================
// conputing begining channel
reg [CHANNEL_BIT_WIDTH-1:0] begining_channel;
always @(posedge clk or posedge layer_reset) begin
	if (layer_reset) begin
		begining_channel <= INI_BEGIN_CHANNAL;
	end
	else if (addressing_en) begin
		if (channel_switch_en) begin
			case(begining_channel)
				FIRST_CHANNEL:  begining_channel <= SECOND_CHANNEL;
				SECOND_CHANNEL: begining_channel <= THIRD_CHANNEL;
				THIRD_CHANNEL:  begining_channel <= FOURTH_CHANNEL;
				FOURTH_CHANNEL: begining_channel <= FIFTH_CHANNEL;
				FIFTH_CHANNEL:  begining_channel <= SIXTH_CHANNEL;
				SIXTH_CHANNEL:  begining_channel <= SEVENTH_CHANNEL;
				default:        begining_channel <= FIRST_CHANNEL;
			endcase
		end		
	end

end

// fetch data: fetched data transfer(sort fetched data)
reg [FETCH_DATA_BIT_WIDTH-8-1:0] fetch_data_temp;
always @* begin
	case(begining_channel)
		FIRST_CHANNEL:    fetch_data_temp = fetch_data_i[FETCH_DATA_BIT_WIDTH-8-1:0];
		SECOND_CHANNEL:   fetch_data_temp = fetch_data_i[FETCH_DATA_BIT_WIDTH-1:8];
		THIRD_CHANNEL:    fetch_data_temp = {fetch_data_i[7:0], fetch_data_i[FETCH_DATA_BIT_WIDTH-1:16]};
		FOURTH_CHANNEL:   fetch_data_temp = {fetch_data_i[15:0], fetch_data_i[FETCH_DATA_BIT_WIDTH-1:24]};
		FIFTH_CHANNEL:    fetch_data_temp = {fetch_data_i[23:0], fetch_data_i[FETCH_DATA_BIT_WIDTH-1:32]};
		SIXTH_CHANNEL:    fetch_data_temp = {fetch_data_i[31:0], fetch_data_i[FETCH_DATA_BIT_WIDTH-1:40]};
		SEVENTH_CHANNEL:  fetch_data_temp = {fetch_data_i[39:0], fetch_data_i[FETCH_DATA_BIT_WIDTH-1:48]};
		default:          fetch_data_temp = fetch_data_i[FETCH_DATA_BIT_WIDTH-8-1:0];
	endcase
end


// store fetched data
reg [REG_BIT_WIDTH-1:0] fetch_data [0:CACHE_CHANNELS-2];
always @(posedge clk) begin
	if (store_data_en) begin
		fetch_data[0] <= fetch_data_temp[7:0];
		fetch_data[1] <= fetch_data_temp[15:8];
		fetch_data[2] <= fetch_data_temp[23:16];
		fetch_data[3] <= fetch_data_temp[31:24];
		fetch_data[4] <= fetch_data_temp[39:32];
		fetch_data[5] <= fetch_data_temp[47:40];
	end
end

// index of fetch_data
reg [INDEX_BIT_WIDTH-1:0] index;
reg [INDEX_BIT_WIDTH-1:0] next_index;
always @(posedge clk or posedge layer_reset) begin
	if (layer_reset) begin
		index <= INI_INDEX;
	end
	else if (output_neuron_ac_en) begin
		if (index == filter_width_i) begin
			index <= INI_INDEX;
		end
		else begin
			index <= next_index;
		end
	end
end
always @* begin
	case(index)
		INDEX_ZERO:   next_index = INDEX_ONE;
		INDEX_ONE:    next_index = INDEX_TWO;
		INDEX_TWO:    next_index = INDEX_THREE;
		INDEX_THREE:  next_index = INDEX_FOURTH;
		INDEX_FOURTH: next_index = INDEX_FIFTH;
		default:      next_index = INDEX_ZERO;
	endcase
end

// output neuron activation
always @(posedge clk or posedge layer_reset) begin
	if (layer_reset) begin
		neuron_activation_o <= INI_OUPUT;
	end
	else if (output_neuron_ac_en) begin
		neuron_activation_o <= fetch_data[index];
	end
end

endmodule