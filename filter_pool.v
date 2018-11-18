// Company           :   tud
// Author            :   binyiwu
// E-Mail            :   <$ICPRO_EMAIL not set - insert email address>
//
// Filename          :   filter_pool.v
// Project Name      :   sa_wubinyi
// Subproject Name   :   cnn_accelerator
// Description       :   <short description>
//
// Create Date       :   Mon Oct 16 09:05:19 2017
// Last Change       :   $Date$
// by                :   $Author$
//------------------------------------------------------------
module filter_pool(
	clk,
	data_input_i,
	filter_fetch_en_i,
	filter_sel_i,
	mac_unit_en_i,
	iteration_i,
	byte_counter_filter_fetch_i,
	filter_0_mac_o,
	filter_1_mac_o,
	filter_2_mac_o,
	filter_3_mac_o,
	filter_4_mac_o,
	filter_5_mac_o,
	filter_6_mac_o,
	filter_7_mac_o,
	filter_8_mac_o,
	filter_9_mac_o,
	filter_10_mac_o,
	filter_11_mac_o,
	filter_12_mac_o,
	filter_13_mac_o,
	filter_14_mac_o,
	filter_15_mac_o
	);

// port parameter
parameter INPUT_BIT_WIDTH   = 8;         // bit-width of neuron-input: 8-bit
parameter NUM_OF_FILTERS_BIT_WIDTH = 4;
parameter NUM_OF_MAC_UNIT  = 16;
parameter ITER_BIT_WIDTH    = 6;         // 36 register, need 6-bit to index them
parameter REG_POOL_BIT_WIDTH     = 6;

// filter weight writing/loading 
parameter BYTES_OF_REG      = 36;        // number of neuron-input: 36 --> max. filter size: 6 x 6
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


input                                 clk;
input [INPUT_BIT_WIDTH-1:0]           data_input_i;
input                                 filter_fetch_en_i;
input [NUM_OF_FILTERS_BIT_WIDTH-1:0]  filter_sel_i;            // index which filter
input [NUM_OF_MAC_UNIT-1:0]           mac_unit_en_i;
input [ITER_BIT_WIDTH-1:0]            iteration_i;
input [REG_POOL_BIT_WIDTH-1:0]        byte_counter_filter_fetch_i;   // index filter-weight's address
output reg [INPUT_BIT_WIDTH-1:0]      filter_0_mac_o;
output reg [INPUT_BIT_WIDTH-1:0]      filter_1_mac_o;
output reg [INPUT_BIT_WIDTH-1:0]      filter_2_mac_o;
output reg [INPUT_BIT_WIDTH-1:0]      filter_3_mac_o;
output reg [INPUT_BIT_WIDTH-1:0]      filter_4_mac_o;
output reg [INPUT_BIT_WIDTH-1:0]      filter_5_mac_o;
output reg [INPUT_BIT_WIDTH-1:0]      filter_6_mac_o;
output reg [INPUT_BIT_WIDTH-1:0]      filter_7_mac_o;
output reg [INPUT_BIT_WIDTH-1:0]      filter_8_mac_o;
output reg [INPUT_BIT_WIDTH-1:0]      filter_9_mac_o;
output reg [INPUT_BIT_WIDTH-1:0]      filter_10_mac_o;
output reg [INPUT_BIT_WIDTH-1:0]      filter_11_mac_o;
output reg [INPUT_BIT_WIDTH-1:0]      filter_12_mac_o;
output reg [INPUT_BIT_WIDTH-1:0]      filter_13_mac_o;
output reg [INPUT_BIT_WIDTH-1:0]      filter_14_mac_o;
output reg [INPUT_BIT_WIDTH-1:0]      filter_15_mac_o;


//===================================================================================================================================
// filter weight writing/loading 
//===================================================================================================================================
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
	if (filter_fetch_en_i) begin
		case(filter_sel_i)
			FETCH_1ST_FILTER: filter_weight_0[byte_counter_filter_fetch_i] <= data_input_i;
			FETCH_2ND_FILTER: filter_weight_1[byte_counter_filter_fetch_i] <= data_input_i;
			FETCH_3RD_FILTER: filter_weight_2[byte_counter_filter_fetch_i] <= data_input_i;
			FETCH_4TH_FILTER: filter_weight_3[byte_counter_filter_fetch_i] <= data_input_i;
			FETCH_5TH_FILTER: filter_weight_4[byte_counter_filter_fetch_i] <= data_input_i;
			FETCH_6TH_FILTER: filter_weight_5[byte_counter_filter_fetch_i] <= data_input_i;
			FETCH_7TH_FILTER: filter_weight_6[byte_counter_filter_fetch_i] <= data_input_i;
			FETCH_8TH_FILTER: filter_weight_7[byte_counter_filter_fetch_i] <= data_input_i;
			FETCH_9TH_FILTER: filter_weight_8[byte_counter_filter_fetch_i] <= data_input_i;
			FETCH_10TH_FILTER: filter_weight_9[byte_counter_filter_fetch_i] <= data_input_i;
			FETCH_11TH_FILTER: filter_weight_10[byte_counter_filter_fetch_i] <= data_input_i;
			FETCH_12TH_FILTER: filter_weight_11[byte_counter_filter_fetch_i] <= data_input_i;
			FETCH_13TH_FILTER: filter_weight_12[byte_counter_filter_fetch_i] <= data_input_i;
			FETCH_14TH_FILTER: filter_weight_13[byte_counter_filter_fetch_i] <= data_input_i;
			FETCH_15TH_FILTER: filter_weight_14[byte_counter_filter_fetch_i] <= data_input_i;
			FETCH_16TH_FILTER: filter_weight_15[byte_counter_filter_fetch_i] <= data_input_i;
		endcase		
	end
end


//===================================================================================================================================
// filter weight reading/fetching 
//===================================================================================================================================
always @(posedge clk) begin
	if (mac_unit_en_i[0]) begin
		filter_0_mac_o <= filter_weight_0[iteration_i];
	end
end
always @(posedge clk) begin
	if (mac_unit_en_i[1]) begin
		filter_1_mac_o <= filter_weight_1[iteration_i];
	end
end
always @(posedge clk) begin
	if (mac_unit_en_i[2]) begin
		filter_2_mac_o <= filter_weight_2[iteration_i];
	end
end
always @(posedge clk) begin
	if (mac_unit_en_i[3]) begin
		filter_3_mac_o <= filter_weight_3[iteration_i];
	end
end
always @(posedge clk) begin
	if (mac_unit_en_i[4]) begin
		filter_4_mac_o <= filter_weight_4[iteration_i];
	end
end
always @(posedge clk) begin
	if (mac_unit_en_i[5]) begin
		filter_5_mac_o <= filter_weight_5[iteration_i];
	end
end
always @(posedge clk) begin
	if (mac_unit_en_i[6]) begin
		filter_6_mac_o <= filter_weight_6[iteration_i];
	end
end
always @(posedge clk) begin
	if (mac_unit_en_i[7]) begin
		filter_7_mac_o <= filter_weight_7[iteration_i];
	end
end
always @(posedge clk) begin
	if (mac_unit_en_i[8]) begin
		filter_8_mac_o <= filter_weight_8[iteration_i];
	end
end
always @(posedge clk) begin
	if (mac_unit_en_i[9]) begin
		filter_9_mac_o <= filter_weight_9[iteration_i];
	end
end
always @(posedge clk) begin
	if (mac_unit_en_i[10]) begin
		filter_10_mac_o <= filter_weight_10[iteration_i];
	end
end
always @(posedge clk) begin
	if (mac_unit_en_i[11]) begin
		filter_11_mac_o <= filter_weight_11[iteration_i];
	end
end
always @(posedge clk) begin
	if (mac_unit_en_i[12]) begin
		filter_12_mac_o <= filter_weight_12[iteration_i];
	end
end
always @(posedge clk) begin
	if (mac_unit_en_i[13]) begin
		filter_13_mac_o <= filter_weight_13[iteration_i];
	end
end
always @(posedge clk) begin
	if (mac_unit_en_i[14]) begin
		filter_14_mac_o <= filter_weight_14[iteration_i];
	end
end
always @(posedge clk) begin
	if (mac_unit_en_i[15]) begin
		filter_15_mac_o <= filter_weight_15[iteration_i];
	end
end

endmodule