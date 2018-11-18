// Company           :   tud
// Author            :   binyiwu
// E-Mail            :   <$ICPRO_EMAIL not set - insert email address>
//
// Filename          :   neuron_fetch_control.v
// Project Name      :   sa_wubinyi
// Subproject Name   :   cnn_accelerator
// Description       :   <short description>
//
// Create Date       :   Mon Oct 16 08:57:38 2017
// Last Change       :   $Date$
// by                :   $Author$
//------------------------------------------------------------
// cache size: 32 x 7 x 16 = 3584 = 3.5 KBytes
// 32: support max. picture size's width
// 7 : support max. 6 x 6 filter
// 16: support max. 16 channels

module neuron_fetch_control(
	clk,
	layer_reset,
	neuron_fetch_en_i,
	filter_width_i,
	picture_height_i,
	// 2018-2-18 begin
	filter_height_i,
	fully_connect_en_i,
	// 2018-2-18 end
	cache_rd_o,
	address_o,
	channel_sel_o,
	addressing_en_o,
	next_stage_en_o,
	channel_switch_en_o,
	store_data_en_o,
	output_neuron_ac_en_o
	);

// port parameter
parameter FILTER_WIDTH_BIT_WIDTH   = 3;
parameter PICTURE_HEIGHT_BIT_WIDTH = 5;
parameter FETCH_DATA_BIT_WIDTH     = 56;  // 8 * 7
parameter CACHE_DEPTH_BIT_WIDTH    = 5;  // through 32
parameter CACHE_CHANNELS           = 7;

// control signal
parameter TRUE                     = 1'b1;
parameter FALSE                    = 1'b0;
parameter DEEPEST_ADDRESS          = 5'd31;
parameter ADDRESS_ZERO             = 5'd0;

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


input                                      clk;
input                                      layer_reset;
input                                      neuron_fetch_en_i;
input      [FILTER_WIDTH_BIT_WIDTH-1:0]    filter_width_i;
input      [PICTURE_HEIGHT_BIT_WIDTH-1:0]  picture_height_i;
// 2018-2-18 begin
input      [PICTURE_HEIGHT_BIT_WIDTH-1:0]  filter_height_i;
input 									   fully_connect_en_i;
// 2018-2-18 end
output                                     cache_rd_o;
output reg [CACHE_DEPTH_BIT_WIDTH-1:0]     address_o;
output reg [CACHE_CHANNELS-1:0]            channel_sel_o;
output                                     addressing_en_o;
output                                     next_stage_en_o;
output                                     channel_switch_en_o;
output                                     store_data_en_o;
output                                     output_neuron_ac_en_o;

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
// for cnn_accelerator's control logic
reg next_stage_en_0;
always @(posedge clk) begin
	next_stage_en_0 <= next_stage_en;
end
reg next_stage_en_1;
always @(posedge clk) begin
	next_stage_en_1 <= next_stage_en_0;
end
reg next_stage_en_2;
always @(posedge clk) begin
	next_stage_en_2 <= next_stage_en_1;
end
reg next_stage_en_3;
always @(posedge clk) begin
	next_stage_en_3 <= next_stage_en_2;
end
reg next_stage_en_4;
always @(posedge clk) begin
	next_stage_en_4 <= next_stage_en_3;
end
reg next_stage_en_5;
always @(posedge clk) begin
	next_stage_en_5 <= next_stage_en_4;
end
reg next_stage_en_out;
always @* begin
	case(filter_width_i)
		FILTER_WIDTH_1: next_stage_en_out = next_stage_en_0;
		FILTER_WIDTH_2: next_stage_en_out = next_stage_en_1;
		FILTER_WIDTH_3: next_stage_en_out = next_stage_en_2;
		FILTER_WIDTH_4: next_stage_en_out = next_stage_en_3;
		FILTER_WIDTH_5: next_stage_en_out = next_stage_en_4;
		FILTER_WIDTH_6: next_stage_en_out = next_stage_en_5;
		default: next_stage_en_out = next_stage_en_0;
	endcase
end


// channel switch signal
wire channel_switch_en;
//assign channel_switch_en = (address_o == DEEPEST_ADDRESS) ? TRUE : FALSE;
assign channel_switch_en = (address_o == picture_height_i) || (address_o == DEEPEST_ADDRESS) ? TRUE : FALSE;

// use for module-"neuron fetch unit"
reg channel_switch_en_0;
always @(channel_switch_en) begin
	channel_switch_en_0 = channel_switch_en;
end
reg channel_switch_en_1;
always @(posedge clk) begin
	channel_switch_en_1 <= channel_switch_en_0;
end
reg channel_switch_en_2;
always @(posedge clk) begin
	channel_switch_en_2 <= channel_switch_en_1;
end
reg channel_switch_en_3;
always @(posedge clk) begin
	channel_switch_en_3 <= channel_switch_en_2;
end
reg channel_switch_en_4;
always @(posedge clk) begin
	channel_switch_en_4 <= channel_switch_en_3;
end
reg channel_switch_en_5;
always @(posedge clk) begin
	channel_switch_en_5 <= channel_switch_en_4;
end
reg channel_switch_en_out;
always @* begin
	case(filter_width_i)
		FILTER_WIDTH_1: channel_switch_en_out = channel_switch_en_0;
		FILTER_WIDTH_2: channel_switch_en_out = channel_switch_en_1;
		FILTER_WIDTH_3: channel_switch_en_out = channel_switch_en_2;
		FILTER_WIDTH_4: channel_switch_en_out = channel_switch_en_3;
		FILTER_WIDTH_5: channel_switch_en_out = channel_switch_en_4;
		FILTER_WIDTH_6: channel_switch_en_out = channel_switch_en_5;
		default: channel_switch_en_out = channel_switch_en_0;
	endcase
end

neuron_fetch_pipeline neuron_fetch_pipeline_0(
	.clk(clk),
	.layer_reset(layer_reset),
	.filter_width_i(filter_width_i),
	.neuron_fetch_en_i(neuron_fetch_en_i),
	.addressing_en_o(addressing_en),
	.cache_rd_o(cache_rd_o),
	.store_data_en_o(store_data_en),
	.output_neuron_ac_en_o(output_neuron_ac_en)
	);

//wire addressing_en_o;
assign addressing_en_o = addressing_en;
//wire next_stage_en_o;  // for cnn_accelerator's control logic
assign next_stage_en_o = next_stage_en_out;
//wire channel_switch_en_o;
assign channel_switch_en_o = channel_switch_en_out; //channel_switch_en;
//wire store_data_en_o;
assign store_data_en_o = store_data_en;
//wire output_neuron_ac_en_o;
assign output_neuron_ac_en_o = output_neuron_ac_en;
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
// 2018-2-18 modify not adding
always @* begin
	if (fully_connect_en_i) begin
		ending_address = begining_address + filter_height_i;
	end
	else begin
		ending_address = begining_address + filter_width_i;
	end
end
// 2018-2-18

// fetch data: address output
// output reg [CACHE_DEPTH_BIT_WIDTH-1:0] address_o;
always @* begin
	address_plus_one = address_o + ADDRESS_OFFSET_ONE;
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

endmodule