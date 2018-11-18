// Company           :   tud
// Author            :   binyiwu
// E-Mail            :   <$ICPRO_EMAIL not set - insert email address>
//
// Filename          :   neuron_fetch_unit.v
// Project Name      :   sa_wubinyi
// Subproject Name   :   cnn_accelerator
// Description       :   <short description>
//
// Create Date       :   Mon Oct 16 09:03:20 2017
// Last Change       :   $Date$
// by                :   $Author$
//------------------------------------------------------------
module neuron_fetch_unit(
	clk,
	layer_reset,
	fetch_data_i,
	addressing_en_i,
	channel_switch_en_i,
	store_data_en_i,
	output_neuron_ac_en_i,
	filter_width_i,
	neuron_activation_o
	);
// port parameter
parameter FETCH_DATA_BIT_WIDTH     = 56;  // 8 * 7
parameter REG_BIT_WIDTH            = 8;
parameter FILTER_WIDTH_BIT_WIDTH   = 3;

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
parameter CACHE_CHANNELS           = 7;
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
input      [FETCH_DATA_BIT_WIDTH-1:0]      fetch_data_i;
input                                      addressing_en_i;
input                                      channel_switch_en_i;
input                                      store_data_en_i;
input                                      output_neuron_ac_en_i;
input      [FILTER_WIDTH_BIT_WIDTH-1:0]    filter_width_i;
output reg [REG_BIT_WIDTH-1:0]             neuron_activation_o;

//======================================================================================================
// data fetching 
//======================================================================================================
// // when filter width = 0 (1), switching channel signal can not work properly
// // the "channel_switch_en_i" need to delay one clock
// reg channel_switch_en_temp_0;
// always @(posedge clk) begin
// 	channel_switch_en_temp_0 <= channel_switch_en_i;
// end
// // because pipeline itself delays two clock, so delay here two clock
// reg channel_switch_en_temp_1;
// always @(posedge clk) begin
// 	channel_switch_en_temp_1 <= channel_switch_en_temp_0;
// end
// reg channel_switch_en;
// always @(posedge clk) begin
// 	channel_switch_en <= channel_switch_en_temp_1;
// end

reg channel_switch_en;
always @(posedge clk) begin
	channel_switch_en <= channel_switch_en_i;
end

// wire channel_switch_en;
// assign channel_switch_en <= channel_switch_en_i;
// conputing begining channel

reg [CHANNEL_BIT_WIDTH-1:0] begining_channel;
always @(posedge clk or posedge layer_reset) begin
	if (layer_reset) begin
		begining_channel <= INI_BEGIN_CHANNAL;
	end
	else if (addressing_en_i) begin
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
	if (store_data_en_i) begin
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
	else if (output_neuron_ac_en_i) begin
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
	else if (output_neuron_ac_en_i) begin
		neuron_activation_o <= fetch_data[index];
	end
end

endmodule