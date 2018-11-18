// Company           :   tud
// Author            :   binyiwu
// E-Mail            :   <$ICPRO_EMAIL not set - insert email address>
//
// Filename          :   cache.v
// Project Name      :   sa_wubinyi
// Subproject Name   :   cnn_accelerator
// Description       :   <short description>
//
// Create Date       :   Mon Oct 16 08:39:24 2017
// Last Change       :   $Date$
// by                :   $Author$
//------------------------------------------------------------
module cache(
	clk,
	rd_en_i,
	channel_rd_sel_i,
	address_rd_i,
	fetch_data_o,
	wr_en_i,
	channel_wr_sel_i,
	address_wr_i,
	cache_data_i
	);

parameter BIT_WIDTH          = 8;
parameter CHANNEL_DEPTH      = 32;
parameter CACHE_CHANNELS     = 7;
parameter FETCH_DATA_BIT_WIDTH = 56;  // 8 * 7
parameter CACHE_CHANNEL_BIT_WIDTH = 3;
parameter FIRST_CHANNEL      = 3'h0; 
parameter SECOND_CHANNEL     = 3'h1; 
parameter THIRD_CHANNEL      = 3'h2; 
parameter FOURTH_CHANNEL     = 3'h3; 
parameter FIFTH_CHANNEL      = 3'h4; 
parameter SIXTH_CHANNEL      = 3'h5; 
parameter SEVENTH_CHANNEL    = 3'h6;
parameter CACHE_ADDRESS_BIT_WIDTH = 5; // through 32
parameter TRUE               = 1'b1;
parameter FALSE              = 1'b0;
parameter INITFILE0          = "none";
parameter INITFILE1          = "none";
parameter INITFILE2          = "none";
parameter INITFILE3          = "none";
parameter INITFILE4          = "none";
parameter INITFILE5          = "none";
parameter INITFILE6          = "none";


input clk;
input rd_en_i;
input [CACHE_CHANNELS-1:0] channel_rd_sel_i;
input [CACHE_ADDRESS_BIT_WIDTH-1:0] address_rd_i;
output [FETCH_DATA_BIT_WIDTH-1:0] fetch_data_o;
input wr_en_i;
input [CACHE_CHANNEL_BIT_WIDTH-1:0] channel_wr_sel_i;
input [CACHE_ADDRESS_BIT_WIDTH-1:0] address_wr_i;
input [BIT_WIDTH-1:0] cache_data_i;

initial begin
	if (INITFILE0 != "none")
		$readmemh(INITFILE0, channel_0);
	if (INITFILE1 != "none")
		$readmemh(INITFILE1, channel_1);
	if (INITFILE2 != "none")
		$readmemh(INITFILE2, channel_2);
	if (INITFILE3 != "none")
		$readmemh(INITFILE3, channel_3);
	if (INITFILE4 != "none")
		$readmemh(INITFILE4, channel_4);
	if (INITFILE5 != "none")
		$readmemh(INITFILE5, channel_5);
	if (INITFILE6 != "none")
		$readmemh(INITFILE6, channel_6);
end

reg [BIT_WIDTH-1:0] channel_0 [0:CHANNEL_DEPTH-1];
reg [BIT_WIDTH-1:0] channel_1 [0:CHANNEL_DEPTH-1];
reg [BIT_WIDTH-1:0] channel_2 [0:CHANNEL_DEPTH-1];
reg [BIT_WIDTH-1:0] channel_3 [0:CHANNEL_DEPTH-1];
reg [BIT_WIDTH-1:0] channel_4 [0:CHANNEL_DEPTH-1];
reg [BIT_WIDTH-1:0] channel_5 [0:CHANNEL_DEPTH-1];
reg [BIT_WIDTH-1:0] channel_6 [0:CHANNEL_DEPTH-1];

// memory write
always @(posedge clk) begin
	if (wr_en_i) begin
		case(channel_wr_sel_i)
			FIRST_CHANNEL:    channel_0[address_wr_i] <= cache_data_i;
			SECOND_CHANNEL:   channel_1[address_wr_i] <= cache_data_i;
			THIRD_CHANNEL:    channel_2[address_wr_i] <= cache_data_i;
			FOURTH_CHANNEL:   channel_3[address_wr_i] <= cache_data_i;
			FIFTH_CHANNEL:    channel_4[address_wr_i] <= cache_data_i;
			SIXTH_CHANNEL:    channel_5[address_wr_i] <= cache_data_i;
			SEVENTH_CHANNEL:  channel_6[address_wr_i] <= cache_data_i;
		endcase
	end
end

// memory read
reg [BIT_WIDTH-1:0] data_0;
reg [BIT_WIDTH-1:0] data_1;
reg [BIT_WIDTH-1:0] data_2;
reg [BIT_WIDTH-1:0] data_3;
reg [BIT_WIDTH-1:0] data_4;
reg [BIT_WIDTH-1:0] data_5;
reg [BIT_WIDTH-1:0] data_6;
always @(posedge clk) begin
	if (rd_en_i) begin
		case(channel_rd_sel_i[6])
			1'b0: data_0 <= 8'h00;
			1'b1: data_0 <= channel_0[address_rd_i];
		endcase
		case(channel_rd_sel_i[5])
			1'b0: data_1 <= 8'h00;
			1'b1: data_1 <= channel_1[address_rd_i];
		endcase
		case(channel_rd_sel_i[4])
			1'b0: data_2 <= 8'h00;
			1'b1: data_2 <= channel_2[address_rd_i];
		endcase
		case(channel_rd_sel_i[3])
			1'b0: data_3 <= 8'h00;
			1'b1: data_3 <= channel_3[address_rd_i];
		endcase
		case(channel_rd_sel_i[2])
			1'b0: data_4 <= 8'h00;
			1'b1: data_4 <= channel_4[address_rd_i];
		endcase
		case(channel_rd_sel_i[1])
			1'b0: data_5 <= 8'h00;
			1'b1: data_5 <= channel_5[address_rd_i];
		endcase
		case(channel_rd_sel_i[0])
			1'b0: data_6 <= 8'h00;
			1'b1: data_6 <= channel_6[address_rd_i];
		endcase
	end
end

assign fetch_data_o = {data_6, data_5, data_4, data_3, data_2, data_1, data_0};

endmodule
