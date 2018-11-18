// Company           :   tud
// Author            :   binyiwu
// E-Mail            :   <$ICPRO_EMAIL not set - insert email address>
//
// Filename          :   neuron_fetch_pipeline.v
// Project Name      :   sa_wubinyi
// Subproject Name   :   cnn_accelerator
// Description       :   <short description>
//
// Create Date       :   Mon Oct 16 08:44:24 2017
// Last Change       :   $Date$
// by                :   $Author$
//------------------------------------------------------------
module neuron_fetch_pipeline(
	clk,
	layer_reset,
	filter_width_i,
	neuron_fetch_en_i,
	addressing_en_o,
	cache_rd_o,
	store_data_en_o,
	output_neuron_ac_en_o
	);

// port parameter
parameter FILTER_WIDTH_BIT_WIDTH   = 3;

// thread activator
parameter FILTER_WIDTH_OFFSET_ONE  = 3'h1;
parameter FILTER_WIDTH_ZERO        = 3'h0;
parameter FILTER_WIDTH_ONE         = 3'h1;
parameter FILTER_WIDTH_TWO         = 3'h2;
parameter FILTER_WIDTH_THREE       = 3'h3;
parameter FILTER_WIDTH_FOUR        = 3'h4;
parameter FILTER_WIDTH_FIVE        = 3'h5;
parameter COUNTER_BIT_WIDTH        = 5;
parameter INI_COUNTER              = 5'h00;
parameter COUNTER_OFFSET_ONE       = 5'h01;
parameter COUNTER_ONE              = 5'h01;
parameter COUNTER_ZERO             = 5'h00;
parameter PIPELLINE_STAGE          = 5'h03;
parameter TRUE                     = 1'b1;
parameter FALSE                    = 1'b0;

// thread
parameter STATE_BIT_WIDTH          = 4;
parameter IDLE                     = 4'h0;
parameter PLACE_ADDRESS            = 4'h1;
parameter READ_CACHE               = 4'h2;
parameter STORE_FETCH_DATA         = 4'h3;
parameter OUPUT_NEURON_ACTI_1      = 4'h4;
parameter OUPUT_NEURON_ACTI_2      = 4'h5;
parameter OUPUT_NEURON_ACTI_3      = 4'h6;
parameter OUPUT_NEURON_ACTI_4      = 4'h7;
parameter OUPUT_NEURON_ACTI_5      = 4'h8;
parameter OUPUT_NEURON_ACTI_6      = 4'h9;

input clk;
input layer_reset;
input [FILTER_WIDTH_BIT_WIDTH-1:0] filter_width_i;
input neuron_fetch_en_i;
output addressing_en_o;
output cache_rd_o;
output store_data_en_o;
output output_neuron_ac_en_o;

task pipelline_thread;
	//input thread_en;
	input [STATE_BIT_WIDTH-1:0] neuron_fetch_state;
	input [FILTER_WIDTH_BIT_WIDTH-1:0] filter_width;
	output addressing_en;
	output cache_rd;
	output store_data_en;
	output output_neuron_ac_en;
	output [STATE_BIT_WIDTH-1:0] next_neuron_fetch_state;
	reg addressing_en_inter;
	reg cache_rd_inter;
	reg store_data_en_inter;
	reg output_neuron_ac_en_inter;
	begin
		addressing_en_inter = FALSE;
		cache_rd_inter = FALSE;
		store_data_en_inter = FALSE;
		output_neuron_ac_en_inter = FALSE;
		case(neuron_fetch_state)
			IDLE:begin
				next_neuron_fetch_state = PLACE_ADDRESS;
			end
			PLACE_ADDRESS:begin  // address already placed
				next_neuron_fetch_state = READ_CACHE;
				//addressing_en_inter = 1'b1;
				cache_rd_inter = TRUE;
			end
			READ_CACHE:begin
				next_neuron_fetch_state = STORE_FETCH_DATA;
				addressing_en_inter = TRUE;
				//cache_rd_inter = 1'b1;
			end
			STORE_FETCH_DATA:begin
				next_neuron_fetch_state = OUPUT_NEURON_ACTI_1;
				//addressing_en_inter = TRUE; // update address, the updated value is the next address
				store_data_en_inter = TRUE;
			end
			OUPUT_NEURON_ACTI_1:begin
				if (filter_width == FILTER_WIDTH_ZERO) begin
					next_neuron_fetch_state = PLACE_ADDRESS;
				end
				else begin
					next_neuron_fetch_state = OUPUT_NEURON_ACTI_2;
				end
				output_neuron_ac_en_inter = TRUE;
			end
			OUPUT_NEURON_ACTI_2:begin
				if (filter_width == FILTER_WIDTH_ONE) begin
					next_neuron_fetch_state = PLACE_ADDRESS;
				end
				else begin
					next_neuron_fetch_state = OUPUT_NEURON_ACTI_3;
				end
				output_neuron_ac_en_inter = TRUE;
			end
			OUPUT_NEURON_ACTI_3:begin
				if (filter_width == FILTER_WIDTH_TWO) begin
					next_neuron_fetch_state = PLACE_ADDRESS;
				end
				else begin
					next_neuron_fetch_state = OUPUT_NEURON_ACTI_4;
				end
				output_neuron_ac_en_inter = TRUE;
			end
			OUPUT_NEURON_ACTI_4:begin
				if (filter_width == FILTER_WIDTH_THREE) begin
					next_neuron_fetch_state = PLACE_ADDRESS;
				end
				else begin
					next_neuron_fetch_state = OUPUT_NEURON_ACTI_5;
				end
				output_neuron_ac_en_inter = TRUE;
			end
			OUPUT_NEURON_ACTI_5:begin
				if (filter_width == FILTER_WIDTH_FOUR) begin
					next_neuron_fetch_state = PLACE_ADDRESS;
				end
				else begin
					next_neuron_fetch_state = OUPUT_NEURON_ACTI_6;
				end
				output_neuron_ac_en_inter = TRUE;
			end
			OUPUT_NEURON_ACTI_6:begin
				if (filter_width == FILTER_WIDTH_FIVE) begin
					next_neuron_fetch_state = PLACE_ADDRESS;
				end
				else begin
					next_neuron_fetch_state = PLACE_ADDRESS;
				end
				output_neuron_ac_en_inter = TRUE;
			end
			default:begin
				next_neuron_fetch_state = PLACE_ADDRESS;
			end
		endcase
		addressing_en = addressing_en_inter; // & thread_en;
		cache_rd = cache_rd_inter; // & thread_en;
		store_data_en = store_data_en_inter; // & thread_en;
		output_neuron_ac_en = output_neuron_ac_en_inter; // & thread_en;					
	end
endtask

wire [FILTER_WIDTH_BIT_WIDTH-1:0] filter_width_actual;
assign filter_width_actual = filter_width_i + FILTER_WIDTH_OFFSET_ONE;
wire [COUNTER_BIT_WIDTH-1:0] total_clock;
assign total_clock = {filter_width_actual, 2'b00};

wire [COUNTER_BIT_WIDTH-1:0] thread_set_begin;
assign thread_set_begin = COUNTER_ZERO;
wire [COUNTER_BIT_WIDTH-1:0] thread_set_end;
assign thread_set_end = PIPELLINE_STAGE + {2'b00, filter_width_i};

wire [COUNTER_BIT_WIDTH-1:0] thread_0_counter;
assign thread_0_counter = COUNTER_ZERO;
wire [COUNTER_BIT_WIDTH-1:0] thread_1_counter;
assign thread_1_counter = {2'b00, filter_width_actual};
wire [COUNTER_BIT_WIDTH-1:0] thread_2_counter;
assign thread_2_counter = {2'b00, filter_width_actual} + {2'b00, filter_width_actual};
wire [COUNTER_BIT_WIDTH-1:0] thread_3_counter;
assign thread_3_counter = {2'b00, filter_width_actual} + {2'b00, filter_width_actual} + {2'b00, filter_width_actual};


reg [COUNTER_BIT_WIDTH-1:0] counter;
reg [COUNTER_BIT_WIDTH-1:0] counter_plus_one;
reg thread_0_counter_en;
reg thread_1_counter_en;
reg thread_2_counter_en;
reg thread_3_counter_en;

always @(posedge clk or posedge layer_reset) begin
	if (layer_reset) begin
		counter <= INI_COUNTER;
		thread_0_counter_en <= FALSE;
		thread_1_counter_en <= FALSE;
		thread_2_counter_en <= FALSE;
		thread_3_counter_en <= FALSE;
	end
	else if (neuron_fetch_en_i) begin
		if (counter == total_clock) begin
			counter <= total_clock;
		end
		else begin
			counter <= counter_plus_one;
		end
		if (counter == thread_0_counter) begin
			thread_0_counter_en <= TRUE;
		end
		if (counter == thread_1_counter) begin
			thread_1_counter_en <= TRUE;
		end
		if (counter == thread_2_counter) begin
			thread_2_counter_en <= TRUE;
		end
		if (counter == thread_3_counter) begin
			thread_3_counter_en <= TRUE;
		end
	end
	else begin
		counter <= INI_COUNTER;
		thread_0_counter_en <= FALSE;
		thread_1_counter_en <= FALSE;
		thread_2_counter_en <= FALSE;
		thread_3_counter_en <= FALSE;		
	end
end
always @(counter) begin
	counter_plus_one = counter + COUNTER_OFFSET_ONE;
end

// thread 0
reg [COUNTER_BIT_WIDTH-1:0] counter_0;
reg [COUNTER_BIT_WIDTH-1:0] counter_0_plus_one;
always @(posedge clk or posedge layer_reset) begin
	if (layer_reset) begin
		counter_0 <= INI_COUNTER;
	end
	else begin
		if (thread_0_counter_en) begin
			if (counter_0_plus_one == total_clock) begin
				counter_0 <= INI_COUNTER;
			end
			else begin
				counter_0 <= counter_0_plus_one;
			end
		end
		else begin
			counter_0 <= INI_COUNTER;		
		end		
	end
end
always @(counter_0) begin
	counter_0_plus_one = counter_0 + COUNTER_OFFSET_ONE;
end
reg thread_0_en;
wire thread_0_set_begin_flag;
wire thread_0_set_end_flag;
wire thread_0_set;
//wire counter_0_reset_en;
assign thread_0_set_begin_flag = counter_0 >= thread_set_begin;
assign thread_0_set_end_flag = counter_0 <= thread_set_end;
assign thread_0_set = thread_0_set_begin_flag & thread_0_set_end_flag;
//assign counter_0_reset_en = counter_0 == total_clock;
always @* begin
	if (thread_0_counter_en) begin
		if (thread_0_set) begin
			thread_0_en = TRUE;
		end
		else begin
			thread_0_en = FALSE;
		end		
	end
	else begin
		thread_0_en = FALSE;
	end
end

// // thread 0
// reg [COUNTER_BIT_WIDTH-1:0] counter_0;
// always @(posedge clk) begin
// 	if (thread_0_counter_en) begin
// 		if (counter_0 == total_clock) begin
// 			counter_0 <= COUNTER_ONE;
// 		end
// 		else begin
// 			counter_0 <= counter_0 + COUNTER_OFFSET_ONE;
// 		end
// 	end
// 	else begin
// 		counter_0 <= INI_COUNTER;
// 	end
// end

// reg thread_0_en;
// wire thread_0_set_begin_flag;
// wire thread_0_set_end_flag;
// wire thread_0_set;
// assign thread_0_set_begin_flag = counter_0 >= thread_set_begin;
// assign thread_0_set_end_flag = counter_0 <= thread_set_end;
// assign thread_0_set = thread_0_set_begin_flag & thread_0_set_end_flag;
// always @(thread_0_set) begin
// 	if (thread_0_set) begin
// 		thread_0_en = TRUE;
// 	end
// 	else begin
// 		thread_0_en = FALSE;
// 	end		
// end



// thread 1
reg [COUNTER_BIT_WIDTH-1:0] counter_1;
reg [COUNTER_BIT_WIDTH-1:0] counter_1_plus_one;
always @(posedge clk or posedge layer_reset) begin
	if (layer_reset) begin
		counter_1 <= INI_COUNTER;
	end
	else begin
		if (thread_1_counter_en) begin
			if (counter_1_plus_one == total_clock) begin
				counter_1 <= INI_COUNTER;
			end
			else begin
				counter_1 <= counter_1_plus_one;
			end
		end
		else begin
			counter_1 <= INI_COUNTER;		
		end		
	end
end
always @(counter_1) begin
	counter_1_plus_one = counter_1 + COUNTER_OFFSET_ONE;
end
reg thread_1_en;
wire thread_1_set_begin_flag;
wire thread_1_set_end_flag;
wire thread_1_set;
//wire counter_1_reset_en;
assign thread_1_set_begin_flag = counter_1 >= thread_set_begin;
assign thread_1_set_end_flag = counter_1 <= thread_set_end;
assign thread_1_set = thread_1_set_begin_flag & thread_1_set_end_flag;
//assign counter_1_reset_en = counter_1 == total_clock;
always @* begin
	if (thread_1_counter_en) begin
		if (thread_1_set) begin
			thread_1_en = TRUE;
		end
		else begin
			thread_1_en = FALSE;
		end		
	end
	else begin
		thread_1_en = FALSE;
	end
end

// // thread 1
// reg [COUNTER_BIT_WIDTH-1:0] counter_1;
// always @(posedge clk) begin
// 	if (thread_1_counter_en) begin
// 		if (counter_1 == total_clock) begin
// 			counter_1 <= COUNTER_ONE;
// 		end
// 		else begin
// 			counter_1 <= counter_1 + COUNTER_OFFSET_ONE;
// 		end
// 	end
// 	else begin
// 		counter_1 <= INI_COUNTER;
// 	end
// end
// reg thread_1_en;
// wire thread_1_set_begin_flag;
// wire thread_1_set_end_flag;
// wire thread_1_set;
// assign thread_1_set_begin_flag = counter_1 >= thread_set_begin;
// assign thread_1_set_end_flag = counter_1 <= thread_set_end;
// assign thread_1_set = thread_1_set_begin_flag & thread_1_set_end_flag;
// always @(thread_1_set) begin
// 	if (thread_1_set) begin
// 		thread_1_en = TRUE;
// 	end
// 	else begin
// 		thread_1_en = FALSE;
// 	end
// end


// thread 2
reg [COUNTER_BIT_WIDTH-1:0] counter_2;
reg [COUNTER_BIT_WIDTH-1:0] counter_2_plus_one;
always @(posedge clk or posedge layer_reset) begin
	if (layer_reset) begin
		counter_2 <= INI_COUNTER;
	end
	else begin
		if (thread_2_counter_en) begin
			if (counter_2_plus_one == total_clock) begin
				counter_2 <= INI_COUNTER;
			end
			else begin
				counter_2 <= counter_2_plus_one;
			end
		end
		else begin
			counter_2 <= INI_COUNTER;		
		end		
	end
end
always @(counter_2) begin
	counter_2_plus_one = counter_2 + COUNTER_OFFSET_ONE;
end
reg thread_2_en;
wire thread_2_set_begin_flag;
wire thread_2_set_end_flag;
wire thread_2_set;
//wire counter_2_reset_en;
assign thread_2_set_begin_flag = counter_2 >= thread_set_begin;
assign thread_2_set_end_flag = counter_2 <= thread_set_end;
assign thread_2_set = thread_2_set_begin_flag & thread_2_set_end_flag;
//assign counter_2_reset_en = counter_2 == total_clock;
always @* begin
	if (thread_2_counter_en) begin
		if (thread_2_set) begin
			thread_2_en = TRUE;
		end
		else begin
			thread_2_en = FALSE;
		end		
	end
	else begin
		thread_2_en = FALSE;
	end
end
// // thread 2
// reg [COUNTER_BIT_WIDTH-1:0] counter_2;
// always @(posedge clk) begin
// 	if (thread_2_counter_en) begin
// 		if (counter_2 == total_clock) begin
// 			counter_2 <= COUNTER_ONE;
// 		end
// 		else begin
// 			counter_2 <= counter_2 + COUNTER_OFFSET_ONE;
// 		end
// 	end
// 	else begin
// 		counter_2 <= INI_COUNTER;
// 	end
// end
// reg  thread_2_en;
// wire thread_2_set_begin_flag;
// wire thread_2_set_end_flag;
// wire thread_2_set;
// assign thread_2_set_begin_flag = counter_2 >= thread_set_begin;
// assign thread_2_set_end_flag = counter_2 <= thread_set_end;
// assign thread_2_set = thread_2_set_begin_flag & thread_2_set_end_flag;
// always @(thread_2_set) begin
// 	if (thread_2_set) begin
// 		thread_2_en = TRUE;
// 	end
// 	else begin
// 		thread_2_en = FALSE;
// 	end
// end


// thread 3
reg [COUNTER_BIT_WIDTH-1:0] counter_3;
reg [COUNTER_BIT_WIDTH-1:0] counter_3_plus_one;
always @(posedge clk or posedge layer_reset) begin
	if (layer_reset) begin
		counter_3 <= INI_COUNTER;
	end
	else begin
		if (thread_3_counter_en) begin
			if (counter_3_plus_one == total_clock) begin
				counter_3 <= INI_COUNTER;
			end
			else begin
				counter_3 <= counter_3_plus_one;
			end
		end
		else begin
			counter_3 <= INI_COUNTER;		
		end		
	end
end
always @(counter_3) begin
	counter_3_plus_one = counter_3 + COUNTER_OFFSET_ONE;
end
reg thread_3_en;
wire thread_3_set_begin_flag;
wire thread_3_set_end_flag;
wire thread_3_set;
//wire counter_3_reset_en;
assign thread_3_set_begin_flag = counter_3 >= thread_set_begin;
assign thread_3_set_end_flag = counter_3 <= thread_set_end;
assign thread_3_set = thread_3_set_begin_flag & thread_3_set_end_flag;
//assign counter_3_reset_en = counter_3 == total_clock;
always @* begin
	if (thread_3_counter_en) begin
		if (thread_3_set) begin
			thread_3_en = TRUE;
		end
		else begin
			thread_3_en = FALSE;
		end		
	end
	else begin
		thread_3_en = FALSE;
	end
end
// // thread 3
// reg [COUNTER_BIT_WIDTH-1:0] counter_3;
// always @(posedge clk) begin
// 	if (thread_3_counter_en) begin
// 		if (counter_3 == total_clock) begin
// 			counter_3 <= COUNTER_ONE;
// 		end
// 		else begin
// 			counter_3 <= counter_3 + COUNTER_OFFSET_ONE;
// 		end
// 	end
// 	else begin
// 		counter_3 <= INI_COUNTER;
// 	end
// end
// reg  thread_3_en;
// wire thread_3_set_begin_flag;
// wire thread_3_set_end_flag;
// wire thread_3_set;
// assign thread_3_set_begin_flag = counter_3 >= thread_set_begin;
// assign thread_3_set_end_flag = counter_3 <= thread_set_end;
// assign thread_3_set = thread_3_set_begin_flag & thread_3_set_end_flag;
// always @(thread_3_set) begin
// 	if (thread_3_set) begin
// 		thread_3_en = TRUE;
// 	end
// 	else begin
// 		thread_3_en = FALSE;
// 	end
// end


// first thread
reg [STATE_BIT_WIDTH-1:0] neuron_fetch_state_f;
reg [STATE_BIT_WIDTH-1:0] next_neuron_fetch_state_f;
reg addressing_en_f;
reg cache_rd_o_f;
reg store_data_en_f;
reg output_neuron_ac_en_f;
always @(posedge clk or posedge layer_reset) begin
	if (layer_reset) begin
		neuron_fetch_state_f <= IDLE;
	end
	else if (thread_0_en) begin
		neuron_fetch_state_f <= next_neuron_fetch_state_f;
	end
	else if(!neuron_fetch_en_i) begin
		neuron_fetch_state_f <= IDLE;
	end
end
always @(neuron_fetch_state_f or filter_width_i) begin
	pipelline_thread(neuron_fetch_state_f, filter_width_i, addressing_en_f, cache_rd_o_f, store_data_en_f, output_neuron_ac_en_f, next_neuron_fetch_state_f);
end

// second thread
reg [STATE_BIT_WIDTH-1:0] neuron_fetch_state_s;
reg [STATE_BIT_WIDTH-1:0] next_neuron_fetch_state_s;
reg addressing_en_s;
reg cache_rd_o_s;
reg store_data_en_s;
reg output_neuron_ac_en_s;
always @(posedge clk or posedge layer_reset) begin
	if (layer_reset) begin
		neuron_fetch_state_s <= IDLE;
	end
	else if (thread_1_en) begin
		neuron_fetch_state_s <= next_neuron_fetch_state_s;
	end
	else if(!neuron_fetch_en_i) begin
		neuron_fetch_state_s <= IDLE;
	end
end
always @(neuron_fetch_state_s or filter_width_i) begin
	pipelline_thread(neuron_fetch_state_s, filter_width_i, addressing_en_s, cache_rd_o_s, store_data_en_s, output_neuron_ac_en_s, next_neuron_fetch_state_s);
end

// third thread
reg [STATE_BIT_WIDTH-1:0] neuron_fetch_state_t;
reg [STATE_BIT_WIDTH-1:0] next_neuron_fetch_state_t;
reg addressing_en_t;
reg cache_rd_o_t;
reg store_data_en_t;
reg output_neuron_ac_en_t;
always @(posedge clk or posedge layer_reset) begin
	if (layer_reset) begin
		neuron_fetch_state_t <= IDLE;
	end
	else if (thread_2_en) begin
		neuron_fetch_state_t <= next_neuron_fetch_state_t;
	end
	else if(!neuron_fetch_en_i) begin
		neuron_fetch_state_t <= IDLE;
	end
end
always @(neuron_fetch_state_t or filter_width_i) begin
	pipelline_thread(neuron_fetch_state_t, filter_width_i, addressing_en_t, cache_rd_o_t, store_data_en_t, output_neuron_ac_en_t, next_neuron_fetch_state_t);
end

// fourth thread
reg [STATE_BIT_WIDTH-1:0] neuron_fetch_state_fo;
reg [STATE_BIT_WIDTH-1:0] next_neuron_fetch_state_fo;
reg addressing_en_fo;
reg cache_rd_o_fo;
reg store_data_en_fo;
reg output_neuron_ac_en_fo;
always @(posedge clk or posedge layer_reset) begin
	if (layer_reset) begin
		neuron_fetch_state_fo <= IDLE;
	end
	else if (thread_3_en) begin
		neuron_fetch_state_fo <= next_neuron_fetch_state_fo;
	end
	else if(!neuron_fetch_en_i) begin
		neuron_fetch_state_fo <= IDLE;
	end
end
always @(neuron_fetch_state_fo or filter_width_i) begin
	pipelline_thread(neuron_fetch_state_fo, filter_width_i, addressing_en_fo, cache_rd_o_fo, store_data_en_fo, output_neuron_ac_en_fo, next_neuron_fetch_state_fo);
end

assign addressing_en_o = addressing_en_f | addressing_en_s | addressing_en_t | addressing_en_fo;
assign cache_rd_o = cache_rd_o_f | cache_rd_o_s | cache_rd_o_t | cache_rd_o_fo;
assign store_data_en_o = store_data_en_f | store_data_en_s | store_data_en_t | store_data_en_fo;
assign output_neuron_ac_en_o = output_neuron_ac_en_f | output_neuron_ac_en_s | output_neuron_ac_en_t | output_neuron_ac_en_fo;

endmodule




// module neuron_fetch_pipelline_backup(
// 	clk,
// 	layer_reset,
// 	filter_width_i,
// 	neuron_fetch_en_i,
// 	addressing_en_o,
// 	cache_rd_o,
// 	store_data_en_o,
// 	output_neuron_ac_en_o
// 	);

// parameter PIPELLINE_STAGE                          = 3;

// parameter IDLE                                     = 4'h0;
// parameter PLACE_ADDRESS                            = 4'h1;
// parameter READ_CACHE                               = 4'h2;
// parameter STORE_FETCH_DATA                         = 4'h3;
// parameter OUPUT_NEURON_ACTI_1                      = 4'h4;
// parameter OUPUT_NEURON_ACTI_2                      = 4'h5;
// parameter OUPUT_NEURON_ACTI_3                      = 4'h6;
// parameter OUPUT_NEURON_ACTI_4                      = 4'h7;
// parameter OUPUT_NEURON_ACTI_5                      = 4'h8;
// parameter OUPUT_NEURON_ACTI_6                      = 4'h9;

// input clk;
// input layer_reset;
// input [2:0] filter_width_i;
// input neuron_fetch_en_i;
// output addressing_en_o;
// output cache_rd_o;
// output store_data_en_o;
// output output_neuron_ac_en_o;

// task pipelline_thread;
// 	//input thread_en;
// 	input [3:0] neuron_fetch_state;
// 	input [2:0] filter_width;
// 	output addressing_en;
// 	output cache_rd;
// 	output store_data_en;
// 	output output_neuron_ac_en;
// 	output [3:0] next_neuron_fetch_state;
// 	reg addressing_en_inter;
// 	reg cache_rd_inter;
// 	reg store_data_en_inter;
// 	reg output_neuron_ac_en_inter;
// 	begin
// 		addressing_en_inter = 1'b0;
// 		cache_rd_inter = 1'b0;
// 		store_data_en_inter = 1'b0;
// 		output_neuron_ac_en_inter = 1'b0;
// 		case(neuron_fetch_state)
// 			IDLE:begin
// 				next_neuron_fetch_state = PLACE_ADDRESS;
// 			end
// 			PLACE_ADDRESS:begin  // address already placed
// 				next_neuron_fetch_state = READ_CACHE;
// 				//addressing_en_inter = 1'b1;
// 				cache_rd_inter = 1'b1;
// 			end
// 			READ_CACHE:begin
// 				next_neuron_fetch_state = STORE_FETCH_DATA;
// 				//addressing_en_inter = 1'b1;
// 				//cache_rd_inter = 1'b1;
// 			end
// 			STORE_FETCH_DATA:begin
// 				next_neuron_fetch_state = OUPUT_NEURON_ACTI_1;
// 				addressing_en_inter = 1'b1; // update address, the updated value is the next address
// 				store_data_en_inter = 1'b1;
// 			end
// 			OUPUT_NEURON_ACTI_1:begin
// 				if (filter_width == 3'h0) begin
// 					next_neuron_fetch_state = PLACE_ADDRESS;
// 				end
// 				else begin
// 					next_neuron_fetch_state = OUPUT_NEURON_ACTI_2;
// 				end
// 				output_neuron_ac_en_inter = 1'b1;
// 			end
// 			OUPUT_NEURON_ACTI_2:begin
// 				if (filter_width == 3'h1) begin
// 					next_neuron_fetch_state = PLACE_ADDRESS;
// 				end
// 				else begin
// 					next_neuron_fetch_state = OUPUT_NEURON_ACTI_3;
// 				end
// 				output_neuron_ac_en_inter = 1'b1;
// 			end
// 			OUPUT_NEURON_ACTI_3:begin
// 				if (filter_width == 3'h2) begin
// 					next_neuron_fetch_state = PLACE_ADDRESS;
// 				end
// 				else begin
// 					next_neuron_fetch_state = OUPUT_NEURON_ACTI_4;
// 				end
// 				output_neuron_ac_en_inter = 1'b1;
// 			end
// 			OUPUT_NEURON_ACTI_4:begin
// 				if (filter_width == 3'h3) begin
// 					next_neuron_fetch_state = PLACE_ADDRESS;
// 				end
// 				else begin
// 					next_neuron_fetch_state = OUPUT_NEURON_ACTI_5;
// 				end
// 				output_neuron_ac_en_inter = 1'b1;
// 			end
// 			OUPUT_NEURON_ACTI_5:begin
// 				if (filter_width == 3'h4) begin
// 					next_neuron_fetch_state = PLACE_ADDRESS;
// 				end
// 				else begin
// 					next_neuron_fetch_state = OUPUT_NEURON_ACTI_6;
// 				end
// 				output_neuron_ac_en_inter = 1'b1;
// 			end
// 			OUPUT_NEURON_ACTI_6:begin
// 				if (filter_width == 3'h5) begin
// 					next_neuron_fetch_state = PLACE_ADDRESS;
// 				end
// 				else begin
// 					next_neuron_fetch_state = PLACE_ADDRESS;
// 				end
// 				output_neuron_ac_en_inter = 1'b1;
// 			end
// 			default:begin
// 				next_neuron_fetch_state = PLACE_ADDRESS;
// 			end
// 		endcase
// 		addressing_en = addressing_en_inter; // & thread_en;
// 		cache_rd = cache_rd_inter; // & thread_en;
// 		store_data_en = store_data_en_inter; // & thread_en;
// 		output_neuron_ac_en = output_neuron_ac_en_inter; // & thread_en;					
// 	end
// endtask

// parameter COUNTER_BIT_WIDTH     = 5;
// parameter INI_COUNTER           = 5'h00;
// parameter COUNTER_OFFSET_ONE    = 5'h01;
// parameter COUNTER_ONE           = 5'h01;
// parameter TRUE                  = 1'b1;
// parameter FALSE                 = 1'b0;

// wire [2:0] filter_width_actual;
// assign filter_width_actual = filter_width_i + 3'h1;
// wire [4:0] total_clock;
// assign total_clock = 3'h4 * filter_width_actual - 5'h01;
// wire [4:0] thread_set_begin;

// assign thread_set_begin = 5'h00;
// wire [4:0] thread_set_end;
// assign thread_set_end = 5'h02 + {2'b00, filter_width_actual};

// wire [4:0] thread_0_counter;
// assign thread_0_counter = 5'h00;
// wire [4:0] thread_1_counter;
// assign thread_1_counter = {2'b00, filter_width_actual};
// wire [4:0] thread_2_counter;
// assign thread_2_counter = {2'b00, filter_width_actual} + {2'b00, filter_width_actual};
// wire [4:0] thread_3_counter;
// assign thread_3_counter = {2'b00, filter_width_actual} + {2'b00, filter_width_actual} + {2'b00, filter_width_actual};


// reg [COUNTER_BIT_WIDTH-1:0] counter;
// reg [COUNTER_BIT_WIDTH-1:0] counter_plus_one;
// reg thread_0_counter_en;
// reg thread_1_counter_en;
// reg thread_2_counter_en;
// reg thread_3_counter_en;

// always @(posedge clk or posedge layer_reset) begin
// 	if (layer_reset) begin
// 		counter_plus_one = INI_COUNTER;
// 	end
// 	else if (neuron_fetch_en_i) begin
// 		counter_plus_one = counter + COUNTER_OFFSET_ONE;
// 	end
// end
// always @* begin
// 	if (neuron_fetch_en_i) begin
// 		if (counter == total_clock) begin
// 			counter = total_clock;
// 		end
// 		else begin
// 			counter = counter_plus_one;
// 		end	
// 		if (counter >= thread_0_counter) begin
// 			thread_0_counter_en = TRUE;
// 		end
// 		else begin
// 			thread_0_counter_en = FALSE;
// 		end
// 		if (counter >= thread_1_counter) begin
// 			thread_1_counter_en = TRUE;
// 		end
// 		else begin
// 			thread_1_counter_en = FALSE;
// 		end
// 		if (counter >= thread_2_counter) begin
// 			thread_2_counter_en = TRUE;
// 		end
// 		else begin
// 			thread_2_counter_en = FALSE;
// 		end
// 		if (counter >= thread_3_counter) begin
// 			thread_3_counter_en = TRUE;
// 		end
// 		else begin
// 			thread_3_counter_en = FALSE;
// 		end
// 	end
// 	else begin
// 		counter = INI_COUNTER;
// 		thread_0_counter_en = FALSE;
// 		thread_1_counter_en = FALSE;
// 		thread_2_counter_en = FALSE;
// 		thread_3_counter_en = FALSE;		
// 	end
// end

// // always @(posedge clk or posedge layer_reset) begin
// // 	if (layer_reset) begin
// // 		counter <= INI_COUNTER;
// // 		thread_0_counter_en <= FALSE;
// // 		thread_1_counter_en <= FALSE;
// // 		thread_2_counter_en <= FALSE;
// // 		thread_3_counter_en <= FALSE;
// // 	end
// // 	else if (neuron_fetch_en_i) begin
// // 		if (counter == total_clock) begin
// // 			counter <= total_clock;
// // 		end
// // 		else begin
// // 			counter <= counter_plus_one;
// // 		end
// // 		if (counter == thread_0_counter) begin
// // 			thread_0_counter_en <= TRUE;
// // 		end
// // 		if (counter == thread_1_counter) begin
// // 			thread_1_counter_en <= TRUE;
// // 		end
// // 		if (counter == thread_2_counter) begin
// // 			thread_2_counter_en <= TRUE;
// // 		end
// // 		if (counter == thread_3_counter) begin
// // 			thread_3_counter_en <= TRUE;
// // 		end
// // 	end
// // 	else begin
// // 		counter <= INI_COUNTER;
// // 		thread_0_counter_en <= FALSE;
// // 		thread_1_counter_en <= FALSE;
// // 		thread_2_counter_en <= FALSE;
// // 		thread_3_counter_en <= FALSE;		
// // 	end
// // end
// // always @(counter) begin
// // 	counter_plus_one = counter + COUNTER_OFFSET_ONE;
// // end

// // thread 0
// reg [COUNTER_BIT_WIDTH-1:0] counter_0;
// always @(posedge clk) begin
// 	if (thread_0_counter_en) begin
// 		if (counter_0 == total_clock) begin
// 			counter_0 <= COUNTER_ONE;
// 		end
// 		else begin
// 			counter_0 <= counter_0 + COUNTER_OFFSET_ONE;
// 		end
// 	end
// 	else begin
// 		counter_0 <= INI_COUNTER;
// 	end
// end

// reg thread_0_en;
// wire thread_0_set_begin_flag;
// wire thread_0_set_end_flag;
// wire thread_0_set;
// assign thread_0_set_begin_flag = counter_0 >= thread_set_begin;
// assign thread_0_set_end_flag = counter_0 <= thread_set_end;
// assign thread_0_set = thread_0_set_begin_flag & thread_0_set_end_flag;
// always @(thread_0_set) begin
// 	if (thread_0_set) begin
// 		thread_0_en = TRUE;
// 	end
// 	else begin
// 		thread_0_en = FALSE;
// 	end		
// end

// // thread 1
// reg [COUNTER_BIT_WIDTH-1:0] counter_1;
// always @(posedge clk) begin
// 	if (thread_1_counter_en) begin
// 		if (counter_1 == total_clock) begin
// 			counter_1 <= COUNTER_ONE;
// 		end
// 		else begin
// 			counter_1 <= counter_1 + COUNTER_OFFSET_ONE;
// 		end
// 	end
// 	else begin
// 		counter_1 <= INI_COUNTER;
// 	end
// end
// reg thread_1_en;
// wire thread_1_set_begin_flag;
// wire thread_1_set_end_flag;
// wire thread_1_set;
// assign thread_1_set_begin_flag = counter_1 >= thread_set_begin;
// assign thread_1_set_end_flag = counter_1 <= thread_set_end;
// assign thread_1_set = thread_1_set_begin_flag & thread_1_set_end_flag;
// always @(thread_1_set) begin
// 	if (thread_1_set) begin
// 		thread_1_en = TRUE;
// 	end
// 	else begin
// 		thread_1_en = FALSE;
// 	end
// end

// // thread 2
// reg [COUNTER_BIT_WIDTH-1:0] counter_2;
// always @(posedge clk) begin
// 	if (thread_2_counter_en) begin
// 		if (counter_2 == total_clock) begin
// 			counter_2 <= COUNTER_ONE;
// 		end
// 		else begin
// 			counter_2 <= counter_2 + COUNTER_OFFSET_ONE;
// 		end
// 	end
// 	else begin
// 		counter_2 <= INI_COUNTER;
// 	end
// end
// reg  thread_2_en;
// wire thread_2_set_begin_flag;
// wire thread_2_set_end_flag;
// wire thread_2_set;
// assign thread_2_set_begin_flag = counter_2 >= thread_set_begin;
// assign thread_2_set_end_flag = counter_2 <= thread_set_end;
// assign thread_2_set = thread_2_set_begin_flag & thread_2_set_end_flag;
// always @(thread_2_set) begin
// 	if (thread_2_set) begin
// 		thread_2_en = TRUE;
// 	end
// 	else begin
// 		thread_2_en = FALSE;
// 	end
// end

// // thread 3
// reg [COUNTER_BIT_WIDTH-1:0] counter_3;
// always @(posedge clk) begin
// 	if (thread_3_counter_en) begin
// 		if (counter_3 == total_clock) begin
// 			counter_3 <= COUNTER_ONE;
// 		end
// 		else begin
// 			counter_3 <= counter_3 + COUNTER_OFFSET_ONE;
// 		end
// 	end
// 	else begin
// 		counter_3 <= INI_COUNTER;
// 	end
// end
// reg  thread_3_en;
// wire thread_3_set_begin_flag;
// wire thread_3_set_end_flag;
// wire thread_3_set;
// assign thread_3_set_begin_flag = counter_3 >= thread_set_begin;
// assign thread_3_set_end_flag = counter_3 <= thread_set_end;
// assign thread_3_set = thread_3_set_begin_flag & thread_3_set_end_flag;
// always @(thread_3_set) begin
// 	if (thread_3_set) begin
// 		thread_3_en = TRUE;
// 	end
// 	else begin
// 		thread_3_en = FALSE;
// 	end
// end


// // first thread
// reg [3:0] neuron_fetch_state_f;
// reg [3:0] next_neuron_fetch_state_f;
// reg addressing_en_f;
// reg cache_rd_o_f;
// reg store_data_en_f;
// reg output_neuron_ac_en_f;
// always @(posedge clk or posedge layer_reset) begin
// 	if (layer_reset) begin
// 		neuron_fetch_state_f <= IDLE;
// 	end
// 	else if (thread_0_en) begin
// 		neuron_fetch_state_f <= next_neuron_fetch_state_f;
// 	end
// 	else if(!neuron_fetch_en_i) begin
// 		neuron_fetch_state_f <= IDLE;
// 	end
// end
// always @(neuron_fetch_state_f or filter_width_i or thread_0_en) begin
// 	pipelline_thread(neuron_fetch_state_f, filter_width_i, addressing_en_f, cache_rd_o_f, store_data_en_f, output_neuron_ac_en_f, next_neuron_fetch_state_f);
// end

// // second thread
// reg [3:0] neuron_fetch_state_s;
// reg [3:0] next_neuron_fetch_state_s;
// reg addressing_en_s;
// reg cache_rd_o_s;
// reg store_data_en_s;
// reg output_neuron_ac_en_s;
// always @(posedge clk or posedge layer_reset) begin
// 	if (layer_reset) begin
// 		neuron_fetch_state_s <= IDLE;
// 	end
// 	else if (thread_1_en) begin
// 		neuron_fetch_state_s <= next_neuron_fetch_state_s;
// 	end
// 	else if(!neuron_fetch_en_i) begin
// 		neuron_fetch_state_s <= IDLE;
// 	end
// end
// always @(neuron_fetch_state_s or filter_width_i or thread_1_en) begin
// 	pipelline_thread(neuron_fetch_state_s, filter_width_i, addressing_en_s, cache_rd_o_s, store_data_en_s, output_neuron_ac_en_s, next_neuron_fetch_state_s);
// end

// // third thread
// reg [3:0] neuron_fetch_state_t;
// reg [3:0] next_neuron_fetch_state_t;
// reg addressing_en_t;
// reg cache_rd_o_t;
// reg store_data_en_t;
// reg output_neuron_ac_en_t;
// always @(posedge clk or posedge layer_reset) begin
// 	if (layer_reset) begin
// 		neuron_fetch_state_t <= IDLE;
// 	end
// 	else if (thread_2_en) begin
// 		neuron_fetch_state_t <= next_neuron_fetch_state_t;
// 	end
// 	else if(!neuron_fetch_en_i) begin
// 		neuron_fetch_state_t <= IDLE;
// 	end
// end
// always @(neuron_fetch_state_t or filter_width_i or thread_2_en) begin
// 	pipelline_thread(neuron_fetch_state_t, filter_width_i, addressing_en_t, cache_rd_o_t, store_data_en_t, output_neuron_ac_en_t, next_neuron_fetch_state_t);
// end

// // fourth thread
// reg [3:0] neuron_fetch_state_fo;
// reg [3:0] next_neuron_fetch_state_fo;
// reg addressing_en_fo;
// reg cache_rd_o_fo;
// reg store_data_en_fo;
// reg output_neuron_ac_en_fo;
// always @(posedge clk or posedge layer_reset) begin
// 	if (layer_reset) begin
// 		neuron_fetch_state_fo <= IDLE;
// 	end
// 	else if (thread_3_en) begin
// 		neuron_fetch_state_fo <= next_neuron_fetch_state_fo;
// 	end
// 	else if(!neuron_fetch_en_i) begin
// 		neuron_fetch_state_fo <= IDLE;
// 	end
// end
// always @(neuron_fetch_state_fo or filter_width_i or thread_3_en) begin
// 	pipelline_thread(neuron_fetch_state_fo, filter_width_i, addressing_en_fo, cache_rd_o_fo, store_data_en_fo, output_neuron_ac_en_fo, next_neuron_fetch_state_fo);
// end

// assign addressing_en_o = addressing_en_f | addressing_en_s | addressing_en_t | addressing_en_fo;
// assign cache_rd_o = cache_rd_o_f | cache_rd_o_s | cache_rd_o_t | cache_rd_o_fo;
// assign store_data_en_o = store_data_en_f | store_data_en_s | store_data_en_t | store_data_en_fo;
// assign output_neuron_ac_en_o = output_neuron_ac_en_f | output_neuron_ac_en_s | output_neuron_ac_en_t | output_neuron_ac_en_fo;

// endmodule