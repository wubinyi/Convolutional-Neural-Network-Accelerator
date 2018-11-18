// Company           :   tud
// Author            :   binyiwu
// E-Mail            :   <$ICPRO_EMAIL not set - insert email address>
//
// Filename          :   cnn_accelerator.v
// Project Name      :   p_eval
// Subproject Name   :   s_deepl
// Description       :   <short description>
//
// Create Date       :   Tue Nov 28 11:54:34 2017
// Last Change       :   $Date$
// by                :   $Author$
//------------------------------------------------------------

module cnn_accelerator(
	clk,
	reset,
	cpu_to_cnn,
	data_bus_i,
	data_bus_o,
	mem_read_en,
	mem_write_en,
	mem_address_o,
	cnn_to_cpu,
	cnna_clk_counter
	);

// port parameter
parameter INPUT_BIT_WIDTH           = 8;         // bit-width of neuron-input for each computation unit: 8-bit
parameter QUAD_DATA_BUS_BIT_WIDTH   = 32;
parameter OUTPUT_BIT_WIDTH          = 16+6+2+2+6;    // cnn accelerator's output;  26 --> 32
parameter DATA_BUS_BIT_WIDTH        = 128;
//parameter INI_DATA_BUS              = 128'h0;
parameter OUTPUT_DATA_BUS_BIT_WIDTH = 32*16;
parameter MEM_ADDRESS_BIT_WIDTH     = 8;
parameter INI_MEM_ADDRESS           = 8'h0;
parameter MEM_ADDRESS_ZERO          = 8'h0;
parameter MEM_ADDRESS_ONE           = 8'h1;
parameter MEM_ADDRESS_OFFSET_ONE    = 8'h1;

// control logic
parameter TRUE                      = 1'b1;
parameter FALSE                     = 1'b0;
parameter STATE_BIT_WIDTH           = 4;
parameter STAGE_COUNTER_BIT_WIDTH   = 16;
parameter INI_STAGE_COUNTER         = 16'h0000;
parameter STAGE_COUNTER_OFFSET_ONE  = 16'h0001;
parameter ONLY_NEURON_FETCH_TIME    = 16'd4;
parameter WAIT_TIME                 = 16'd7;
parameter ONLY_OPERAND_FETCH_TIME   = 16'd2;

// configuration register parameter
parameter BYTE_BIT_WIDTH              = 8;
parameter FILTER_WIDTH_BIT_WIDTH      = 3;
parameter INI_FILTER_WIDTH            = 3'h0;
parameter INI_NEXT_STAGE_CLK_COUNTER  = 3'h0;
parameter NEXT_STAGE_CLK_OFFSET_ONE   = 3'h1;
parameter FILTER_WIDTH_1           = 3'h0;       
parameter FILTER_WIDTH_2           = 3'h1; 
parameter FILTER_WIDTH_3           = 3'h2;
parameter FILTER_WIDTH_4           = 3'h3;
parameter FILTER_WIDTH_5           = 3'h4;
parameter FILTER_WIDTH_6           = 3'h5;
parameter FILTER_SIZE_BIT_WIDTH       = 6;
parameter INI_FILTER_SIZE             = 6'h00;
parameter PICTURE_WIDTH_BIT_WIDTH     = 5;
parameter INI_PICTURE_WIDTH           = 5'h00;
parameter CACHED_CHANNEL_OFFSET_ONE   = 5'h01;
parameter PICTURE_HEIGHT_BIT_WIDTH    = 5;
parameter INI_PICTURE_HEIGHT          = 5'h00;
parameter NEURON_FETCH_TIME_BIT_WIDTH = 16;
parameter INI_NEURON_FETCH_TIME       = 16'h0000;
parameter NUM_OF_FILTERS_BIT_WIDTH    = 4;
parameter INI_NUM_OF_FILTERS          = 4'h0;
parameter NUM_OF_CHANNELS_BIT_WIDTH   = 4;
parameter INI_NUM_OF_CHANNELS         = 4'h0;
parameter FILTER_FETCH_TIME_BIT_WIDTH = 10;
parameter INI_FILTER_FETCH_TIME       = 10'h000;
parameter LOAD_NEURON_TIME_BIT_WIDTH  = 8;
parameter INI_LOAD_NEURON_TIME        = 8'h00;
parameter PLATFORM_SUPPORT_BIT_WIDTH  = 8;
parameter INI_PLATFORM_SUPPORT        = 8'h00;
parameter QUAN_WEIGHT_ZERO_BIT_WIDTH  = 8;
parameter INI_QUAN_WEIGHT_ZERO        = 8'h00;

// filter fetch parameter
parameter REG_POOL_BIT_WIDTH       = 6;         // index inside filter weight
parameter INI_REG_POOL_INDEX       = 6'h00;
parameter REG_POOL_OFFSET_ONE      = 6'h01;
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
parameter NUM_OF_SUBUNIT    = 16;
// case statement not use parameter
parameter NUM_OF_MAC_UNIT   = 16;
parameter UNABLE_MAC_UNIT   = 16'h0000;
parameter ITER_BIT_WIDTH    = 6;         // 36 register, need 6-bit to index them
parameter INI_6_BITS        = 6'h00;
parameter ITER_OFFSET_ONE   = 6'h01;
parameter QUAD              = 4;
parameter INI_QUAD          = 4'h0;

// filter pool, MAC operand fetch unit and MAC part, each unit has the same verilog code
parameter ACCUMULATOR_BIT_WIDTH  = 16+6+2+4;      // each quad-unit's output bit width  // 24 --> 28
parameter ADDER_FLAG_BIT_WIDTH   = 3;

// state
parameter IDLE                           = 4'd0;
parameter FETCH_CONFIG_REG               = 4'd1;
parameter FETCH_CONFIG_REG_1             = 4'd2;
parameter FETCH_MEM_ADDR_REG             = 4'd3;
parameter FETCH_MEM_ADDR_REG_1           = 4'd4;
parameter LAYER_RESET_EN                 = 4'd5;
parameter FETCH_FILTER_WEIGHT            = 4'd6;
parameter FETCH_FILTER_WEIGHT_1          = 4'd7;
parameter CACHE_LOADING                  = 4'd8;
parameter CACHE_LOADING_1                = 4'd9;
parameter NEURON_FETCH                   = 4'd10;
parameter NEURON_FETCH_AND_OPERAND_FETCH = 4'd11;
parameter OPERAND_FETCH                  = 4'd12;
parameter WAITING                        = 4'd13;
parameter CNN_NOTI_CPU                   = 4'd14;

// quantization:sum & scale
parameter SUM_QUAN_OFFSET = 16+6+2;
parameter QUAD_SUM_QUAN_OFFSET = 4*SUM_QUAN_OFFSET;
parameter QUAN_SCALE_BIT_WIDTH = 32;


input                                   clk;
input                                   reset;
input                                   cpu_to_cnn;
input      [DATA_BUS_BIT_WIDTH-1:0]     data_bus_i;
output     [OUTPUT_DATA_BUS_BIT_WIDTH-1:0]     data_bus_o;
output reg                              mem_read_en;
output reg                              mem_write_en;
output reg [MEM_ADDRESS_BIT_WIDTH-1:0]  mem_address_o;
output reg                              cnn_to_cpu;
output reg [31:0]						cnna_clk_counter;

//===================================================================================================================================
// internal register
//===================================================================================================================================
// first 128-bit configuration
reg [FILTER_WIDTH_BIT_WIDTH-1:0] filter_width;
reg [FILTER_SIZE_BIT_WIDTH-1:0] filter_size;
reg [PICTURE_WIDTH_BIT_WIDTH-1:0] picture_width;
reg [PICTURE_HEIGHT_BIT_WIDTH-1:0] picture_height;
reg [NEURON_FETCH_TIME_BIT_WIDTH-1:0] neuron_fetch_time;
reg [NUM_OF_FILTERS_BIT_WIDTH-1:0] num_of_filters;
reg [NUM_OF_CHANNELS_BIT_WIDTH-1:0] num_of_channels;
reg [FILTER_FETCH_TIME_BIT_WIDTH-1:0] filter_fetch_time;
reg [LOAD_NEURON_TIME_BIT_WIDTH-1:0] load_neuron_time;
reg [PLATFORM_SUPPORT_BIT_WIDTH-1:0] platform_support;
reg [QUAN_WEIGHT_ZERO_BIT_WIDTH-1:0] quan_weight_zero;
// 2018-2-18
reg [PICTURE_HEIGHT_BIT_WIDTH-1:0] filter_height;
// second 128-bit configuraion
reg [MEM_ADDRESS_BIT_WIDTH-1:0] reading_address;
reg [MEM_ADDRESS_BIT_WIDTH-1:0] writing_address;

// control logic
reg [STAGE_COUNTER_BIT_WIDTH-1:0] stage_counter;

//===================================================================================================================================
// control logic
//===================================================================================================================================
// memory operation port
// reg mem_read_en;
// reg mem_write_en;
// memory write active signal from 'accumulator_adder'
reg mem_write_active_for_cl;
// memory read active signal from 'neuron_fetch_control'
// after each stage read one data from memory to cache
// But when 'channel_switch_en' comes, reads 'filter_width' data from memory to cache
// 2018-2-14
reg mem_read_active_for_cl_temp;
reg mem_read_active_for_cl_nstag;
reg mem_read_active_for_cl_chswit;
always @* begin
	mem_read_active_for_cl_temp = mem_read_active_for_cl_nstag | mem_read_active_for_cl_chswit;
end
// 2018-2-17
reg mem_read_active_for_cl_temp1;
always @(posedge clk) begin
	mem_read_active_for_cl_temp1 <= mem_read_active_for_cl_temp;
end
reg mem_read_active_for_cl;
always @(posedge clk) begin
	mem_read_active_for_cl <= mem_read_active_for_cl_temp1;
end
// configuration register-parameter of CNN
reg config_register_en;
// configuration register-reading and writing address
reg config_address_reg_en;
// layer reset
reg layer_reset;
// filter weight load
reg filter_fetch_en;
// cache load(write) and fetch(read)
reg cache_loading_en;
reg cache_loading_active_for_cl;
always @(posedge clk) begin
	cache_loading_active_for_cl <= mem_read_active_for_cl;
end
reg neuron_fetch_en;
// operand fetch
reg operand_fetch_en;
// clear stage_counter
reg clear_stage_counter_en;
// wait counter enable
reg wait_counter_en;
// for WAITING to write data to sram  // 2018-2-14 unuseful
reg waiting_iteration_en;

reg [STATE_BIT_WIDTH-1:0] current_state;
reg [STATE_BIT_WIDTH-1:0] next_state;
always @(posedge clk or posedge reset) begin
	if (reset) begin
		current_state <= IDLE;
	end
	else begin
		current_state <= next_state;
	end
end
// used for clock counter, just for benchmark
always @(posedge clk or posedge reset) begin
	if (reset) begin
		cnna_clk_counter <= 32'h0;
	end
	else begin
		if (cpu_to_cnn) begin
			cnna_clk_counter <= 32'h0;
		end
		else if (current_state != IDLE) begin
			cnna_clk_counter <= cnna_clk_counter + 32'h1;
		end
	end
end
always @(current_state or cpu_to_cnn or stage_counter or filter_fetch_time or neuron_fetch_time or mem_write_active_for_cl 
			or mem_read_active_for_cl or cache_loading_active_for_cl or load_neuron_time) begin
	mem_read_en = FALSE;
	mem_write_en = FALSE;
	config_register_en = FALSE;
	config_address_reg_en = FALSE;
	filter_fetch_en = FALSE;
	cache_loading_en = FALSE;
	neuron_fetch_en = FALSE;
	operand_fetch_en = FALSE;
	clear_stage_counter_en = FALSE;
	wait_counter_en = FALSE;
	waiting_iteration_en = FALSE;
	case(current_state)
		IDLE: begin
			if (cpu_to_cnn) begin
				next_state = FETCH_CONFIG_REG;
			end
			else begin
				next_state = IDLE;
			end
		end
		FETCH_CONFIG_REG:begin
			mem_read_en = TRUE;
			next_state = FETCH_CONFIG_REG_1;
		end
		FETCH_CONFIG_REG_1: begin
			config_register_en = TRUE;
			next_state = FETCH_MEM_ADDR_REG;
		end
		FETCH_MEM_ADDR_REG:begin
			mem_read_en = TRUE;
			next_state = FETCH_MEM_ADDR_REG_1;
		end
		FETCH_MEM_ADDR_REG_1:begin
			config_address_reg_en = TRUE;
			next_state = LAYER_RESET_EN;
		end
		LAYER_RESET_EN: begin
			next_state = FETCH_FILTER_WEIGHT;
		end
		FETCH_FILTER_WEIGHT: begin
			mem_read_en = TRUE;
			next_state = FETCH_FILTER_WEIGHT_1;
		end
		FETCH_FILTER_WEIGHT_1: begin
			filter_fetch_en = TRUE;
			if (stage_counter == filter_fetch_time) begin
				clear_stage_counter_en = TRUE;
				next_state = CACHE_LOADING;					
			end
			else begin
				next_state = FETCH_FILTER_WEIGHT;			
			end
		end
		CACHE_LOADING: begin
			mem_read_en = TRUE;
			next_state = CACHE_LOADING_1;			
		end
		CACHE_LOADING_1:begin
			cache_loading_en = TRUE;
			if (stage_counter == load_neuron_time) begin
				clear_stage_counter_en = TRUE;
				next_state = NEURON_FETCH;				
			end
			else begin
				next_state = CACHE_LOADING;
			end
		end
		NEURON_FETCH:begin
			neuron_fetch_en = TRUE;
			wait_counter_en = TRUE;
			if (stage_counter == ONLY_NEURON_FETCH_TIME) begin
				clear_stage_counter_en = TRUE;
				next_state = NEURON_FETCH_AND_OPERAND_FETCH;				
			end
			else begin
				next_state = NEURON_FETCH;
			end
			
		end
		NEURON_FETCH_AND_OPERAND_FETCH: begin
			neuron_fetch_en = TRUE;
			operand_fetch_en = TRUE;
			mem_write_en = mem_write_active_for_cl;
			mem_read_en = mem_read_active_for_cl;
			cache_loading_en = cache_loading_active_for_cl;
			if (stage_counter == neuron_fetch_time) begin
				clear_stage_counter_en = TRUE;
				next_state = OPERAND_FETCH;
			end
			else begin
				next_state = NEURON_FETCH_AND_OPERAND_FETCH;
			end
		end
		OPERAND_FETCH:begin
			operand_fetch_en = TRUE;
			wait_counter_en = TRUE;
			mem_write_en = mem_write_active_for_cl;
			mem_read_en = mem_read_active_for_cl;
			cache_loading_en = cache_loading_active_for_cl;
			if (stage_counter == ONLY_OPERAND_FETCH_TIME) begin
				clear_stage_counter_en = TRUE;
				next_state = WAITING;
			end
			else begin
				next_state = OPERAND_FETCH;
			end	
		end
		WAITING:begin
			waiting_iteration_en = TRUE;
			wait_counter_en = TRUE;
			mem_write_en = mem_write_active_for_cl;
			if (stage_counter == WAIT_TIME) begin
				clear_stage_counter_en = TRUE;
				next_state = CNN_NOTI_CPU;
			end
			else begin
				next_state = WAITING;
			end	
		end
		CNN_NOTI_CPU:begin
			next_state = IDLE;
		end
		default:begin
			next_state = IDLE;
		end
	endcase
end

//wire stage_counter_reset;
//assign stage_counter_reset = layer_reset | clear_stage_counter_en;
reg [STAGE_COUNTER_BIT_WIDTH-1:0] stage_counter_plus;
always @(posedge clk or posedge layer_reset) begin
	if (layer_reset) begin
		stage_counter <= INI_STAGE_COUNTER;
	end
	else if (clear_stage_counter_en) begin
		stage_counter <= INI_STAGE_COUNTER;
	end
	else if (filter_fetch_en || operand_fetch_en || wait_counter_en || cache_loading_en) begin
			stage_counter <= stage_counter_plus;
	end
end

always @(stage_counter) begin
	stage_counter_plus = stage_counter + STAGE_COUNTER_OFFSET_ONE;
end

// layer_reset signal
wire layer_reset_flag;
assign layer_reset_flag = next_state == LAYER_RESET_EN;
always @(posedge clk or posedge reset) begin
	if (reset) begin
		layer_reset <= FALSE;
	end
	else if(layer_reset_flag) begin
		layer_reset <= TRUE;
	end
	else begin
		layer_reset <= FALSE;
	end
end

// cnn notifies cpu
wire cnn_to_cpu_flag;
assign cnn_to_cpu_flag = next_state == CNN_NOTI_CPU;
always @(posedge clk or posedge reset) begin
	if (reset) begin
		cnn_to_cpu <= FALSE;	
	end
	else if (cnn_to_cpu_flag) begin
		cnn_to_cpu <= TRUE;
	end
	else begin
		cnn_to_cpu <= FALSE;
	end
end

//===================================================================================================================================
// memory operation
//===================================================================================================================================
// memory reading address
reg [MEM_ADDRESS_BIT_WIDTH-1:0] mem_read_addr;
//wire [MEM_ADDRESS_BIT_WIDTH-1:0] mem_read_addr_plus_one;
always @(posedge clk) begin
	if (layer_reset) begin
		mem_read_addr <= reading_address;
	end
	else if (mem_read_en) begin
		mem_read_addr <= mem_read_addr + MEM_ADDRESS_OFFSET_ONE;
	end
end
//assign mem_read_addr_plus_one = mem_read_addr + MEM_ADDRESS_OFFSET_ONE;

// memory writing address
reg [MEM_ADDRESS_BIT_WIDTH-1:0] mem_write_addr;
//wire [MEM_ADDRESS_BIT_WIDTH-1:0] mem_write_addr_plus_one;
always @(posedge clk) begin
	if (layer_reset) begin
		mem_write_addr <= writing_address;
	end
	else if (mem_write_en) begin
		mem_write_addr <= mem_write_addr + MEM_ADDRESS_OFFSET_ONE;
	end
end
//assign mem_write_addr_plus_one = mem_write_addr + MEM_ADDRESS_OFFSET_ONE;

// output address for memory
always @* begin
	if (mem_read_en) begin
		case(current_state)
			FETCH_CONFIG_REG: mem_address_o = MEM_ADDRESS_ZERO;
			FETCH_MEM_ADDR_REG: mem_address_o = MEM_ADDRESS_ONE;
			default: mem_address_o = mem_read_addr;
		endcase
	end
	else if (mem_write_en) begin
		mem_address_o = mem_write_addr;
	end
	else begin
		mem_address_o = INI_MEM_ADDRESS;
	end
end
//===================================================================================================================================
// register configuration
// all the register's value is smaller than actual value 1
//===================================================================================================================================
// wire config_reg_reset;
// assign config_reg_reset = layer_reset | reset;
// config filter width
always @(posedge clk or posedge reset) begin
	if (reset) begin
		filter_width <= INI_FILTER_WIDTH;
	end
	else if (config_register_en) begin
		filter_width <= data_bus_i[FILTER_WIDTH_BIT_WIDTH-1:0];
	end
end
// config filter size
always @(posedge clk or posedge reset) begin
	if (reset) begin
		filter_size <= INI_FILTER_SIZE;
	end
	else if (config_register_en) begin
		filter_size <= data_bus_i[BYTE_BIT_WIDTH+FILTER_SIZE_BIT_WIDTH-1:BYTE_BIT_WIDTH];
	end
end
// config picture width
always @(posedge clk or posedge reset) begin
	if (reset) begin
		picture_width <= INI_PICTURE_WIDTH;
	end
	else if (config_register_en) begin
		picture_width <= data_bus_i[BYTE_BIT_WIDTH*2+PICTURE_WIDTH_BIT_WIDTH-1:BYTE_BIT_WIDTH*2];
	end
end
// config picture height
always @(posedge clk or posedge reset) begin
	if (reset) begin
		picture_height <= INI_PICTURE_HEIGHT;
	end
	else if (config_register_en) begin
		picture_height <= data_bus_i[BYTE_BIT_WIDTH*3+PICTURE_HEIGHT_BIT_WIDTH-1:BYTE_BIT_WIDTH*3];
	end
end
// config neuron fetch time
// real value: filter_width * filter_width * (picture_width+1-filter_width) * (picture_height+1-filter_width) - 2
always @(posedge clk or posedge reset) begin
	if (reset) begin
		neuron_fetch_time <= INI_NEURON_FETCH_TIME;
	end
	else if (config_register_en) begin
		neuron_fetch_time <= data_bus_i[BYTE_BIT_WIDTH*6-1:BYTE_BIT_WIDTH*4];
	end
end
// config number of filters
always @(posedge clk or posedge reset) begin
	if (reset) begin
		num_of_filters <= INI_NUM_OF_FILTERS;
	end
	else if (config_register_en) begin
		num_of_filters <= data_bus_i[BYTE_BIT_WIDTH*6+NUM_OF_FILTERS_BIT_WIDTH-1:BYTE_BIT_WIDTH*6];
	end
end
// config number of channels
always @(posedge clk or posedge reset) begin
	if (reset) begin
		num_of_channels <= INI_NUM_OF_CHANNELS;
	end
	else if (config_register_en) begin
		num_of_channels <= data_bus_i[BYTE_BIT_WIDTH*7+NUM_OF_CHANNELS_BIT_WIDTH-1:BYTE_BIT_WIDTH*7];
	end
end
// config filter fetch time
// real value: filter_size * num_of_filters - 1
always @(posedge clk or posedge reset) begin
	if (reset) begin
		filter_fetch_time <= INI_FILTER_FETCH_TIME;
	end
	else if (config_register_en) begin
		filter_fetch_time <= data_bus_i[BYTE_BIT_WIDTH*8+FILTER_FETCH_TIME_BIT_WIDTH-1:BYTE_BIT_WIDTH*8];
	end
end

// config load_neuron_time
always @(posedge clk or posedge reset) begin
	if (reset) begin
		load_neuron_time <= INI_LOAD_NEURON_TIME;
	end
	else if (config_register_en) begin
		load_neuron_time <= data_bus_i[BYTE_BIT_WIDTH*10+LOAD_NEURON_TIME_BIT_WIDTH-1:BYTE_BIT_WIDTH*10];
	end
end

// config platform support
// 0x00 ---> pure convolution computation
// 0x01 ---> support tensorflow quantization computation
always @(posedge clk or posedge reset) begin
	if (reset) begin
		platform_support <= INI_PLATFORM_SUPPORT;
	end
	else if (config_register_en) begin
		platform_support <= data_bus_i[BYTE_BIT_WIDTH*11+PLATFORM_SUPPORT_BIT_WIDTH-1:BYTE_BIT_WIDTH*11];
	end
end

// config quantization weight zero 
always @(posedge clk or posedge reset) begin
	if (reset) begin
		quan_weight_zero <= INI_QUAN_WEIGHT_ZERO;
	end
	else if (config_register_en) begin
		quan_weight_zero <= data_bus_i[BYTE_BIT_WIDTH*12+QUAN_WEIGHT_ZERO_BIT_WIDTH-1:BYTE_BIT_WIDTH*12];
	end
end

// 2018-2-18
// filter height
always @(posedge clk or posedge reset) begin
	if (reset) begin
		filter_height <= 'h0;
	end
	else if (config_register_en) begin
		filter_height <= data_bus_i[BYTE_BIT_WIDTH*13+PICTURE_HEIGHT_BIT_WIDTH-1:BYTE_BIT_WIDTH*13];
	end
end
//========================================================================================
// config reading address
always @(posedge clk or posedge reset) begin
	if (reset) begin
		reading_address <= INI_MEM_ADDRESS;
	end
	else if (config_address_reg_en) begin
		reading_address <= data_bus_i[MEM_ADDRESS_BIT_WIDTH-1:0];
	end
end
// config writing address
always @(posedge clk or posedge reset) begin
	if (reset) begin
		writing_address <= INI_MEM_ADDRESS;
	end
	else if (config_address_reg_en) begin
		writing_address <= data_bus_i[MEM_ADDRESS_BIT_WIDTH*2-1: MEM_ADDRESS_BIT_WIDTH];
	end
end
//===================================================================================================================================
// parse supporting platform
//===================================================================================================================================
wire tf_quantization_en;
assign tf_quantization_en = platform_support == 8'h01 ? TRUE : FALSE;

// 2018-2-18
wire fully_connect_en;
assign fully_connect_en = platform_support == 8'h02 ? TRUE : FALSE;

//===================================================================================================================================
// filter writing/loading
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
// write neuron activation cache
// cache write enable signal 
reg cache_wr_en; 
always @* begin
	cache_wr_en = cache_loading_en;
end
// address
reg [CACHE_DEPTH_BIT_WIDTH-1:0] address_wr;
reg [CACHE_CHANNEL_BIT_WIDTH-1:0] channel_sel_wr;
wire address_wr_reset_en;
assign address_wr_reset_en = address_wr == picture_height ? TRUE : FALSE;
always @(posedge clk or posedge layer_reset) begin
	if (layer_reset) begin
		channel_sel_wr <= INI_WR_CACHE_CHANNEL;
	end
	else if (cache_loading_en) begin
		if (address_wr_reset_en) begin
			if (channel_sel_wr == LARGEST_WR_CHANNEL) begin
				channel_sel_wr <= INI_WR_CACHE_CHANNEL;
			end
			else begin
				channel_sel_wr <= channel_sel_wr + CHANNEL_OFFSET_ONE;
			end	
		end		
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

// cache reading control logic
wire                              cache_rd_en;
wire [CACHE_DEPTH_BIT_WIDTH-1:0]  address_rd;
wire [CACHE_CHANNELS-1:0]         channel_sel_rd;
wire                              addressing_en;
wire                              next_stage_en;
wire                              channel_switch_en;
wire                              store_data_en;
wire                              output_neuron_ac_en;
neuron_fetch_control neuron_fetch_control_0(
	.clk(clk),
	.layer_reset(layer_reset),
	.neuron_fetch_en_i(neuron_fetch_en),
	.filter_width_i(filter_width),
	.picture_height_i(picture_height),
	// 2018-2-18 begin
	.filter_height_i(filter_height),
	.fully_connect_en_i(fully_connect_en),
	// 2018-2-18 end
	.cache_rd_o(cache_rd_en),
	.address_o(address_rd),
	.channel_sel_o(channel_sel_rd),
	.addressing_en_o(addressing_en),
	.next_stage_en_o(next_stage_en),
	.channel_switch_en_o(channel_switch_en),
	.store_data_en_o(store_data_en),
	.output_neuron_ac_en_o(output_neuron_ac_en)
	);

// for cache writing during computation
// caching neurons into neuron_cache enable signal (during operand fetching)
reg [PICTURE_WIDTH_BIT_WIDTH-1:0] cached_channel_counter;
always @(posedge clk or posedge layer_reset) begin
	if (layer_reset) begin
		cached_channel_counter <= INI_PICTURE_WIDTH;
	end
	else if (cache_loading_en) begin
		if (address_wr_reset_en) begin
			cached_channel_counter <= cached_channel_counter + CACHED_CHANNEL_OFFSET_ONE;
		end
	end
end
wire cache_neuron_en;
assign cache_neuron_en = cached_channel_counter > picture_width ? FALSE : TRUE;
// the following part are using for control logic: read data from memory to cache
// use 'next_stage_en'
reg [FILTER_WIDTH_BIT_WIDTH-1:0] next_stage_clock_counter;
always @(posedge clk or posedge layer_reset) begin
	if (layer_reset) begin
		next_stage_clock_counter <= INI_NEXT_STAGE_CLK_COUNTER;
		mem_read_active_for_cl_nstag <= FALSE;
	end
	else if (next_stage_en && cache_neuron_en) begin
		if (next_stage_clock_counter == filter_width) begin
			next_stage_clock_counter <= INI_NEXT_STAGE_CLK_COUNTER;
			mem_read_active_for_cl_nstag <= TRUE;
		end
		else begin
			next_stage_clock_counter <= next_stage_clock_counter + NEXT_STAGE_CLK_OFFSET_ONE;
			mem_read_active_for_cl_nstag <= FALSE;			
		end
	end
	else begin
		next_stage_clock_counter <= INI_NEXT_STAGE_CLK_COUNTER;
		mem_read_active_for_cl_nstag <= FALSE;
	end
end
// use 'channel_switch_en'
reg mem_read_active_for_cl_0;
always @(posedge clk) begin
	mem_read_active_for_cl_0 <= channel_switch_en;
end
reg mem_read_active_for_cl_1;
always @(posedge clk) begin
	mem_read_active_for_cl_1 <= mem_read_active_for_cl_0;
end
reg mem_read_active_for_cl_2;
always @(posedge clk) begin
	mem_read_active_for_cl_2 <= mem_read_active_for_cl_1;
end
reg mem_read_active_for_cl_3;
always @(posedge clk) begin
	mem_read_active_for_cl_3 <= mem_read_active_for_cl_2;
end
reg mem_read_active_for_cl_4;
always @(posedge clk) begin
	mem_read_active_for_cl_4 <= mem_read_active_for_cl_3;
end
reg mem_read_active_for_cl_5;
always @(posedge clk) begin
	mem_read_active_for_cl_5 <= mem_read_active_for_cl_4;
end
always @(posedge clk) begin
	if (cache_neuron_en) begin
		case(filter_width)
			FILTER_WIDTH_1: mem_read_active_for_cl_chswit <= mem_read_active_for_cl_0;
			FILTER_WIDTH_2: mem_read_active_for_cl_chswit <= mem_read_active_for_cl_1;
			FILTER_WIDTH_3: mem_read_active_for_cl_chswit <= mem_read_active_for_cl_2;
			FILTER_WIDTH_4: mem_read_active_for_cl_chswit <= mem_read_active_for_cl_3;
			FILTER_WIDTH_5: mem_read_active_for_cl_chswit <= mem_read_active_for_cl_4;
			FILTER_WIDTH_6: mem_read_active_for_cl_chswit <= mem_read_active_for_cl_5;
			default: mem_read_active_for_cl_chswit <= mem_read_active_for_cl_0;
		endcase
		// mem_read_active_for_cl_chswit <= mem_read_active_for_cl_2;		
	end
end

//===================================================================================================================================
// MAC operand fetch and MAC control signal
//===================================================================================================================================
// 16 mac enable signal
reg [NUM_OF_MAC_UNIT-1:0] mac_unit_en;
always @(num_of_filters) begin
	case(num_of_filters)
		4'h0: mac_unit_en = 16'h0001;
		4'h1: mac_unit_en = 16'h0003;
		4'h2: mac_unit_en = 16'h0007;
		4'h3: mac_unit_en = 16'h000f;
		4'h4: mac_unit_en = 16'h001f;
		4'h5: mac_unit_en = 16'h003f;
		4'h6: mac_unit_en = 16'h007f;
		4'h7: mac_unit_en = 16'h00ff;
		4'h8: mac_unit_en = 16'h01ff;
		4'h9: mac_unit_en = 16'h03ff;
		4'ha: mac_unit_en = 16'h07ff;
		4'hb: mac_unit_en = 16'h0fff;
		4'hc: mac_unit_en = 16'h1fff;
		4'hd: mac_unit_en = 16'h3fff;
		4'he: mac_unit_en = 16'h7fff;
		4'hf: mac_unit_en = 16'hffff;
		//default: mac_unit_en = 16'h0000;
	endcase
end  
// 16 subunit enable signal
reg [NUM_OF_SUBUNIT-1:0] subunit_en;
always @(num_of_channels) begin
	case(num_of_channels)
		4'h0: subunit_en = 16'h0001;
		4'h1: subunit_en = 16'h0003;
		4'h2: subunit_en = 16'h0007;
		4'h3: subunit_en = 16'h000f;
		4'h4: subunit_en = 16'h001f;
		4'h5: subunit_en = 16'h003f;
		4'h6: subunit_en = 16'h007f;
		4'h7: subunit_en = 16'h00ff;
		4'h8: subunit_en = 16'h01ff;
		4'h9: subunit_en = 16'h03ff;
		4'ha: subunit_en = 16'h07ff;
		4'hb: subunit_en = 16'h0fff;
		4'hc: subunit_en = 16'h1fff;
		4'hd: subunit_en = 16'h3fff;
		4'he: subunit_en = 16'h7fff;
		4'hf: subunit_en = 16'hffff;
	endcase
end
// MAC operand fetch iteration
reg [ITER_BIT_WIDTH-1:0] iteration;
reg                      stage_finish;
reg 					 operand_fetch_en_pipeline;
always @(posedge clk) begin
	operand_fetch_en_pipeline <= operand_fetch_en;
end
always @(posedge clk or posedge layer_reset) begin
	if (layer_reset) begin
		iteration <= INI_6_BITS;
		stage_finish <= FALSE;
	end
	else if (operand_fetch_en_pipeline ) begin  //|| waiting_iteration_en
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
// operand fetch is one stage, but "stage_finish" comes from "iteration", "iteration" use "operand_fetch_en_pipeline"
// so just ignore operand fetch stage
// MAC unit has 2 stage
// so the signal "stage_finish" should delay 2 clock (impuls in 3th clock)
// here use 2 register to pipeline
reg stage_finish_pipeline_1;
always @(posedge clk) begin
	stage_finish_pipeline_1 <= stage_finish;
end
reg stage_finish_pipeline_2;
always @(posedge clk) begin
	stage_finish_pipeline_2 <= stage_finish_pipeline_1;
end
// for supporting tensorflow's quantization
reg stage_finish_pipeline_3;
always @(posedge clk) begin
	stage_finish_pipeline_3 <= stage_finish_pipeline_2;
end

// 4 quad control signal
// mac operand fetch signal
reg [QUAD-1:0] quad0_subunit_en;
reg [QUAD-1:0] quad1_subunit_en;
reg [QUAD-1:0] quad2_subunit_en;
reg [QUAD-1:0] quad3_subunit_en;
always @(subunit_en) begin
	quad0_subunit_en = subunit_en[3:0];
	quad1_subunit_en = subunit_en[7:4];
	quad2_subunit_en = subunit_en[11:8];
	quad3_subunit_en = subunit_en[15:12];
end

reg [QUAD_DATA_BUS_BIT_WIDTH-1:0] data_input_0;
reg [QUAD_DATA_BUS_BIT_WIDTH-1:0] data_input_1;
reg [QUAD_DATA_BUS_BIT_WIDTH-1:0] data_input_2;
reg [QUAD_DATA_BUS_BIT_WIDTH-1:0] data_input_3;
always @(data_bus_i) begin
	data_input_0 = data_bus_i[31:0];
	data_input_1 = data_bus_i[63:32];
	data_input_2 = data_bus_i[95:64];
	data_input_3 = data_bus_i[127:96];
end
//===================================================================================================================================
// filter pool, neuron cache, neuron fetch transfer unit, zero judgement, operand fetch, mac control, MAC
//===================================================================================================================================
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
quad_unit_cache_filter_mac quad_unit_cache_filter_mac_0(
	.clk(clk),
	.layer_reset(layer_reset),
	.quad_subunit_en_i(quad0_subunit_en),
	.quad_data_bus_i(data_input_0),
	.cache_rd_en_i(cache_rd_en),
	.channel_sel_rd_i(channel_sel_rd),
	.address_rd_i(address_rd),
	.cache_wr_en_i(cache_wr_en),
	.channel_sel_wr_i(channel_sel_wr),
	.address_wr_i(address_wr),
	.channel_switch_en_i(channel_switch_en),       // used for neuron fetch transfer 
	.addressing_en_i(addressing_en),
	.store_data_en_i(store_data_en),
	.output_neuron_ac_en_i(output_neuron_ac_en),
	.filter_width_i(filter_width),
	.operand_fetch_en_i(operand_fetch_en),
	.filter_fetch_en_i(filter_fetch_en),
	.filter_sel_i(filter_sel),
	.mac_unit_en_i(mac_unit_en),
	.iteration_i(iteration),
	.byte_counter_filter_fetch_i(byte_counter_filter_fetch),
	.stage_finish_i(stage_finish),
	.stage_finish_pipeline_i(stage_finish_pipeline_2),
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
	.accumulator_15_o(unit0_accumulator_15),
	.tf_quantization_en_i(tf_quantization_en),
	.quan_weight_zero_i(quan_weight_zero)
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
quad_unit_cache_filter_mac quad_unit_cache_filter_mac_1(
	.clk(clk),
	.layer_reset(layer_reset),
	.quad_subunit_en_i(quad1_subunit_en),
	.quad_data_bus_i(data_input_1),
	.cache_rd_en_i(cache_rd_en),
	.channel_sel_rd_i(channel_sel_rd),
	.address_rd_i(address_rd),
	.cache_wr_en_i(cache_wr_en),
	.channel_sel_wr_i(channel_sel_wr),
	.address_wr_i(address_wr),
	.channel_switch_en_i(channel_switch_en),       // used for neuron fetch transfer 
	.addressing_en_i(addressing_en),
	.store_data_en_i(store_data_en),
	.output_neuron_ac_en_i(output_neuron_ac_en),
	.filter_width_i(filter_width),
	.operand_fetch_en_i(operand_fetch_en),
	.filter_fetch_en_i(filter_fetch_en),
	.filter_sel_i(filter_sel),
	.mac_unit_en_i(mac_unit_en),
	.iteration_i(iteration),
	.byte_counter_filter_fetch_i(byte_counter_filter_fetch),
	.stage_finish_i(stage_finish),
	.stage_finish_pipeline_i(stage_finish_pipeline_2),
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
	.accumulator_15_o(unit1_accumulator_15),
	.tf_quantization_en_i(tf_quantization_en),
	.quan_weight_zero_i(quan_weight_zero)
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
quad_unit_cache_filter_mac quad_unit_cache_filter_mac_2(
	.clk(clk),
	.layer_reset(layer_reset),
	.quad_subunit_en_i(quad2_subunit_en),
	.quad_data_bus_i(data_input_2),
	.cache_rd_en_i(cache_rd_en),
	.channel_sel_rd_i(channel_sel_rd),
	.address_rd_i(address_rd),
	.cache_wr_en_i(cache_wr_en),
	.channel_sel_wr_i(channel_sel_wr),
	.address_wr_i(address_wr),
	.channel_switch_en_i(channel_switch_en),       // used for neuron fetch transfer 
	.addressing_en_i(addressing_en),
	.store_data_en_i(store_data_en),
	.output_neuron_ac_en_i(output_neuron_ac_en),
	.filter_width_i(filter_width),
	.operand_fetch_en_i(operand_fetch_en),
	.filter_fetch_en_i(filter_fetch_en),
	.filter_sel_i(filter_sel),
	.mac_unit_en_i(mac_unit_en),
	.iteration_i(iteration),
	.byte_counter_filter_fetch_i(byte_counter_filter_fetch),
	.stage_finish_i(stage_finish),
	.stage_finish_pipeline_i(stage_finish_pipeline_2),
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
	.accumulator_15_o(unit2_accumulator_15),
	.tf_quantization_en_i(tf_quantization_en),
	.quan_weight_zero_i(quan_weight_zero)
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
quad_unit_cache_filter_mac quad_unit_cache_filter_mac_3(
	.clk(clk),
	.layer_reset(layer_reset),
	.quad_subunit_en_i(quad3_subunit_en),
	.quad_data_bus_i(data_input_3),
	.cache_rd_en_i(cache_rd_en),
	.channel_sel_rd_i(channel_sel_rd),
	.address_rd_i(address_rd),
	.cache_wr_en_i(cache_wr_en),
	.channel_sel_wr_i(channel_sel_wr),
	.address_wr_i(address_wr),
	.channel_switch_en_i(channel_switch_en),       // used for neuron fetch transfer 
	.addressing_en_i(addressing_en),
	.store_data_en_i(store_data_en),
	.output_neuron_ac_en_i(output_neuron_ac_en),
	.filter_width_i(filter_width),
	.operand_fetch_en_i(operand_fetch_en),
	.filter_fetch_en_i(filter_fetch_en),
	.filter_sel_i(filter_sel),
	.mac_unit_en_i(mac_unit_en),
	.iteration_i(iteration),
	.byte_counter_filter_fetch_i(byte_counter_filter_fetch),
	.stage_finish_i(stage_finish),
	.stage_finish_pipeline_i(stage_finish_pipeline_2),
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
	.accumulator_15_o(unit3_accumulator_15),
	.tf_quantization_en_i(tf_quantization_en),
	.quan_weight_zero_i(quan_weight_zero)
);
//===================================================================================================================================
// tf quantization scale: 16 multipliers, enable signal according to number of channels
//===================================================================================================================================
// wire [QUAN_SCALE_BIT_WIDTH-1:0] quan_scale_0;
// wire [QUAN_SCALE_BIT_WIDTH-1:0] quan_scale_1;
// wire [QUAN_SCALE_BIT_WIDTH-1:0] quan_scale_2;
// wire [QUAN_SCALE_BIT_WIDTH-1:0] quan_scale_3;
// wire [QUAN_SCALE_BIT_WIDTH-1:0] quan_scale_4;
// wire [QUAN_SCALE_BIT_WIDTH-1:0] quan_scale_5;
// wire [QUAN_SCALE_BIT_WIDTH-1:0] quan_scale_6;
// wire [QUAN_SCALE_BIT_WIDTH-1:0] quan_scale_7;
// wire [QUAN_SCALE_BIT_WIDTH-1:0] quan_scale_8;
// wire [QUAN_SCALE_BIT_WIDTH-1:0] quan_scale_9;
// wire [QUAN_SCALE_BIT_WIDTH-1:0] quan_scale_10;
// wire [QUAN_SCALE_BIT_WIDTH-1:0] quan_scale_11;
// wire [QUAN_SCALE_BIT_WIDTH-1:0] quan_scale_12;
// wire [QUAN_SCALE_BIT_WIDTH-1:0] quan_scale_13;
// wire [QUAN_SCALE_BIT_WIDTH-1:0] quan_scale_14;
// wire [QUAN_SCALE_BIT_WIDTH-1:0] quan_scale_15;
// tf_quantization_scale tf_quantization_scale_0(
// 	.clk(clk),
// 	.sub_unit_en(subunit_en),
// 	.stage_finish_i(stage_finish),
// 	.quan_weight_zero_i(quan_weight_zero),
// 	.unit0_quan_sum_offset_i(unit0_sum_quan_offset),
// 	.unit1_quan_sum_offset_i(unit1_sum_quan_offset),
// 	.unit2_quan_sum_offset_i(unit2_sum_quan_offset),
// 	.unit3_quan_sum_offset_i(unit3_sum_quan_offset),
// 	.quan_scale_0(quan_scale_0),
// 	.quan_scale_1(quan_scale_1),
// 	.quan_scale_2(quan_scale_2),
// 	.quan_scale_3(quan_scale_3),
// 	.quan_scale_4(quan_scale_4),
// 	.quan_scale_5(quan_scale_5),
// 	.quan_scale_6(quan_scale_6),
// 	.quan_scale_7(quan_scale_7),
// 	.quan_scale_8(quan_scale_8),
// 	.quan_scale_9(quan_scale_9),
// 	.quan_scale_10(quan_scale_10),
// 	.quan_scale_11(quan_scale_11),
// 	.quan_scale_12(quan_scale_12),
// 	.quan_scale_13(quan_scale_13),
// 	.quan_scale_14(quan_scale_14),
// 	.quan_scale_15(quan_scale_15)
// 	);
//===================================================================================================================================
// 4 quad-unit accumulator sum up together -> one accumulator
//===================================================================================================================================
// accumulator_adder
wire [OUTPUT_BIT_WIDTH-1:0]       accumulator_0;
wire [OUTPUT_BIT_WIDTH-1:0]       accumulator_1;
wire [OUTPUT_BIT_WIDTH-1:0]       accumulator_2;
wire [OUTPUT_BIT_WIDTH-1:0]       accumulator_3;
wire [OUTPUT_BIT_WIDTH-1:0]       accumulator_4;
wire [OUTPUT_BIT_WIDTH-1:0]       accumulator_5;
wire [OUTPUT_BIT_WIDTH-1:0]       accumulator_6;
wire [OUTPUT_BIT_WIDTH-1:0]       accumulator_7;
wire [OUTPUT_BIT_WIDTH-1:0]       accumulator_8;
wire [OUTPUT_BIT_WIDTH-1:0]       accumulator_9;
wire [OUTPUT_BIT_WIDTH-1:0]       accumulator_10;
wire [OUTPUT_BIT_WIDTH-1:0]       accumulator_11;
wire [OUTPUT_BIT_WIDTH-1:0]       accumulator_12;
wire [OUTPUT_BIT_WIDTH-1:0]       accumulator_13;
wire [OUTPUT_BIT_WIDTH-1:0]       accumulator_14;
wire [OUTPUT_BIT_WIDTH-1:0]       accumulator_15;


reg stage_finish_pipeline_4;
always @(posedge clk) begin
	stage_finish_pipeline_4 <= stage_finish_pipeline_3;
end
reg stage_finish_pipeline_5;
always @(posedge clk) begin
	stage_finish_pipeline_5 <= stage_finish_pipeline_4;
end
// wire stage_finish_pipeline_5;
// assign stage_finish_pipeline_5 = stage_finish_pipeline_4;

// the following two registers are using for control logic
reg stage_finish_pipeline_6;
always @(posedge clk) begin
	stage_finish_pipeline_6 <= stage_finish_pipeline_5;
end
always @(posedge clk) begin
	mem_write_active_for_cl <= stage_finish_pipeline_6;
end
// 16 subunit enable signal
reg adder_0_flag;
reg adder_1_flag;
reg adder_2_flag;
always @(num_of_channels) begin
	case(num_of_channels)
		4'h0, 4'h1, 4'h2, 4'h3    : begin
			adder_0_flag = 1'b0;
			adder_1_flag = 1'b0;
			adder_2_flag = 1'b0;
		end
		4'h4, 4'h5, 4'h6, 4'h7    : begin
			adder_0_flag = 1'b1;
			adder_1_flag = 1'b0;
			adder_2_flag = 1'b0;			
		end
		4'h8, 4'h9, 4'ha, 4'hb  : begin
			adder_0_flag = 1'b1;
			adder_1_flag = 1'b0;
			adder_2_flag = 1'b1;			
		end
		4'hc, 4'hd, 4'he, 4'hf: begin
			adder_0_flag = 1'b1;
			adder_1_flag = 1'b1;
			adder_2_flag = 1'b1;			
		end
	endcase
end
wire [ADDER_FLAG_BIT_WIDTH-1:0] adders_flag;
assign adders_flag = {adder_0_flag, adder_1_flag, adder_2_flag};

wire [ADDER_FLAG_BIT_WIDTH-1:0] adders_flag_0;
assign adders_flag_0 = adders_flag & {3{mac_unit_en[0]}};
accumulator_adder accu_adder_0(
	.clk(clk),
	.adders_flag_i(adders_flag_0),
	.stage_finish_pipeline_5_i(stage_finish_pipeline_5),
	.accumulator_0_i(unit0_accumulator_0),
	.accumulator_1_i(unit1_accumulator_0),
	.accumulator_2_i(unit2_accumulator_0),
	.accumulator_3_i(unit3_accumulator_0),
	.accumulator_o(accumulator_0)
	);

wire [ADDER_FLAG_BIT_WIDTH-1:0] adders_flag_1;
assign adders_flag_1 = adders_flag & {3{mac_unit_en[1]}};
accumulator_adder accu_adder_1(
	.clk(clk),
	.adders_flag_i(adders_flag_1),
	.stage_finish_pipeline_5_i(stage_finish_pipeline_5),
	.accumulator_0_i(unit0_accumulator_1),
	.accumulator_1_i(unit1_accumulator_1),
	.accumulator_2_i(unit2_accumulator_1),
	.accumulator_3_i(unit3_accumulator_1),
	.accumulator_o(accumulator_1)
	);

wire [ADDER_FLAG_BIT_WIDTH-1:0] adders_flag_2;
assign adders_flag_2 = adders_flag & {3{mac_unit_en[2]}};
accumulator_adder accu_adder_2(
	.clk(clk),
	.adders_flag_i(adders_flag_2),
	.stage_finish_pipeline_5_i(stage_finish_pipeline_5),
	.accumulator_0_i(unit0_accumulator_2),
	.accumulator_1_i(unit1_accumulator_2),
	.accumulator_2_i(unit2_accumulator_2),
	.accumulator_3_i(unit3_accumulator_2),
	.accumulator_o(accumulator_2)
	);

wire [ADDER_FLAG_BIT_WIDTH-1:0] adders_flag_3;
assign adders_flag_3 = adders_flag & {3{mac_unit_en[3]}};
accumulator_adder accu_adder_3(
	.clk(clk),
	.adders_flag_i(adders_flag_3),
	.stage_finish_pipeline_5_i(stage_finish_pipeline_5),
	.accumulator_0_i(unit0_accumulator_3),
	.accumulator_1_i(unit1_accumulator_3),
	.accumulator_2_i(unit2_accumulator_3),
	.accumulator_3_i(unit3_accumulator_3),
	.accumulator_o(accumulator_3)
	);

wire [ADDER_FLAG_BIT_WIDTH-1:0] adders_flag_4;
assign adders_flag_4 = adders_flag & {3{mac_unit_en[4]}};
accumulator_adder accu_adder_4(
	.clk(clk),
	.adders_flag_i(adders_flag_4),
	.stage_finish_pipeline_5_i(stage_finish_pipeline_5),
	.accumulator_0_i(unit0_accumulator_4),
	.accumulator_1_i(unit1_accumulator_4),
	.accumulator_2_i(unit2_accumulator_4),
	.accumulator_3_i(unit3_accumulator_4),
	.accumulator_o(accumulator_4)
	);

wire [ADDER_FLAG_BIT_WIDTH-1:0] adders_flag_5;
assign adders_flag_5 = adders_flag & {3{mac_unit_en[5]}};
accumulator_adder accu_adder_5(
	.clk(clk),
	.adders_flag_i(adders_flag_5),
	.stage_finish_pipeline_5_i(stage_finish_pipeline_5),
	.accumulator_0_i(unit0_accumulator_5),
	.accumulator_1_i(unit1_accumulator_5),
	.accumulator_2_i(unit2_accumulator_5),
	.accumulator_3_i(unit3_accumulator_5),
	.accumulator_o(accumulator_5)
	);

wire [ADDER_FLAG_BIT_WIDTH-1:0] adders_flag_6;
assign adders_flag_6 = adders_flag & {3{mac_unit_en[6]}};
accumulator_adder accu_adder_6(
	.clk(clk),
	.adders_flag_i(adders_flag_6),
	.stage_finish_pipeline_5_i(stage_finish_pipeline_5),
	.accumulator_0_i(unit0_accumulator_6),
	.accumulator_1_i(unit1_accumulator_6),
	.accumulator_2_i(unit2_accumulator_6),
	.accumulator_3_i(unit3_accumulator_6),
	.accumulator_o(accumulator_6)
	);

wire [ADDER_FLAG_BIT_WIDTH-1:0] adders_flag_7;
assign adders_flag_7 = adders_flag & {3{mac_unit_en[7]}};
accumulator_adder accu_adder_7(
	.clk(clk),
	.adders_flag_i(adders_flag_7),
	.stage_finish_pipeline_5_i(stage_finish_pipeline_5),
	.accumulator_0_i(unit0_accumulator_7),
	.accumulator_1_i(unit1_accumulator_7),
	.accumulator_2_i(unit2_accumulator_7),
	.accumulator_3_i(unit3_accumulator_7),
	.accumulator_o(accumulator_7)
	);

wire [ADDER_FLAG_BIT_WIDTH-1:0] adders_flag_8;
assign adders_flag_8 = adders_flag & {3{mac_unit_en[8]}};
accumulator_adder accu_adder_8(
	.clk(clk),
	.adders_flag_i(adders_flag_8),
	.stage_finish_pipeline_5_i(stage_finish_pipeline_5),
	.accumulator_0_i(unit0_accumulator_8),
	.accumulator_1_i(unit1_accumulator_8),
	.accumulator_2_i(unit2_accumulator_8),
	.accumulator_3_i(unit3_accumulator_8),
	.accumulator_o(accumulator_8)
	);

wire [ADDER_FLAG_BIT_WIDTH-1:0] adders_flag_9;
assign adders_flag_9 = adders_flag & {3{mac_unit_en[9]}};
accumulator_adder accu_adder_9(
	.clk(clk),
	.adders_flag_i(adders_flag_9),
	.stage_finish_pipeline_5_i(stage_finish_pipeline_5),
	.accumulator_0_i(unit0_accumulator_9),
	.accumulator_1_i(unit1_accumulator_9),
	.accumulator_2_i(unit2_accumulator_9),
	.accumulator_3_i(unit3_accumulator_9),
	.accumulator_o(accumulator_9)
	);

wire [ADDER_FLAG_BIT_WIDTH-1:0] adders_flag_10;
assign adders_flag_10 = adders_flag & {3{mac_unit_en[10]}};
accumulator_adder accu_adder_10(
	.clk(clk),
	.adders_flag_i(adders_flag_10),
	.stage_finish_pipeline_5_i(stage_finish_pipeline_5),
	.accumulator_0_i(unit0_accumulator_10),
	.accumulator_1_i(unit1_accumulator_10),
	.accumulator_2_i(unit2_accumulator_10),
	.accumulator_3_i(unit3_accumulator_10),
	.accumulator_o(accumulator_10)
	);

wire [ADDER_FLAG_BIT_WIDTH-1:0] adders_flag_11;
assign adders_flag_11 = adders_flag & {3{mac_unit_en[11]}};
accumulator_adder accu_adder_11(
	.clk(clk),
	.adders_flag_i(adders_flag_11),
	.stage_finish_pipeline_5_i(stage_finish_pipeline_5),
	.accumulator_0_i(unit0_accumulator_11),
	.accumulator_1_i(unit1_accumulator_11),
	.accumulator_2_i(unit2_accumulator_11),
	.accumulator_3_i(unit3_accumulator_11),
	.accumulator_o(accumulator_11)
	);

wire [ADDER_FLAG_BIT_WIDTH-1:0] adders_flag_12;
assign adders_flag_12 = adders_flag & {3{mac_unit_en[12]}};
accumulator_adder accu_adder_12(
	.clk(clk),
	.adders_flag_i(adders_flag_12),
	.stage_finish_pipeline_5_i(stage_finish_pipeline_5),
	.accumulator_0_i(unit0_accumulator_12),
	.accumulator_1_i(unit1_accumulator_12),
	.accumulator_2_i(unit2_accumulator_12),
	.accumulator_3_i(unit3_accumulator_12),
	.accumulator_o(accumulator_12)
	);

wire [ADDER_FLAG_BIT_WIDTH-1:0] adders_flag_13;
assign adders_flag_13 = adders_flag & {3{mac_unit_en[13]}};
accumulator_adder accu_adder_13(
	.clk(clk),
	.adders_flag_i(adders_flag_13),
	.stage_finish_pipeline_5_i(stage_finish_pipeline_5),
	.accumulator_0_i(unit0_accumulator_13),
	.accumulator_1_i(unit1_accumulator_13),
	.accumulator_2_i(unit2_accumulator_13),
	.accumulator_3_i(unit3_accumulator_13),
	.accumulator_o(accumulator_13)
	);

wire [ADDER_FLAG_BIT_WIDTH-1:0] adders_flag_14;
assign adders_flag_14 = adders_flag & {3{mac_unit_en[14]}};
accumulator_adder accu_adder_14(
	.clk(clk),
	.adders_flag_i(adders_flag_14),
	.stage_finish_pipeline_5_i(stage_finish_pipeline_5),
	.accumulator_0_i(unit0_accumulator_14),
	.accumulator_1_i(unit1_accumulator_14),
	.accumulator_2_i(unit2_accumulator_14),
	.accumulator_3_i(unit3_accumulator_14),
	.accumulator_o(accumulator_14)
	);

wire [ADDER_FLAG_BIT_WIDTH-1:0] adders_flag_15;
assign adders_flag_15 = adders_flag & {3{mac_unit_en[15]}};
accumulator_adder accu_adder_15(
	.clk(clk),
	.adders_flag_i(adders_flag_15),
	.stage_finish_pipeline_5_i(stage_finish_pipeline_5),
	.accumulator_0_i(unit0_accumulator_15),
	.accumulator_1_i(unit1_accumulator_15),
	.accumulator_2_i(unit2_accumulator_15),
	.accumulator_3_i(unit3_accumulator_15),
	.accumulator_o(accumulator_15)
	);

// reg stage_finish_pipeline_6;
// always @(posedge clk) begin
// 	stage_finish_pipeline_6 <= stage_finish_pipeline_5;
// end
// always @(posedge clk or posedge layer_reset) begin
// 	if (layer_reset) begin
// 		data_bus_o <= INI_DATA_BUS;
// 	end
// 	else if (stage_finish_pipeline_6) begin
// 		data_bus_o <= {accumulator_0[7:0], accumulator_1[7:0], accumulator_2[7:0], accumulator_3[7:0], 
// 						accumulator_4[7:0], accumulator_5[7:0], accumulator_6[7:0], accumulator_7[7:0],
// 						accumulator_8[7:0], accumulator_9[7:0], accumulator_10[7:0], accumulator_11[7:0],
// 						accumulator_12[7:0], accumulator_13[7:0], accumulator_14[7:0], accumulator_15[7:0]};
// 	end
// end
// assign data_bus_o = {accumulator_0[7:0], accumulator_1[7:0], accumulator_2[7:0], accumulator_3[7:0], 
// 				accumulator_4[7:0], accumulator_5[7:0], accumulator_6[7:0], accumulator_7[7:0],
// 				accumulator_8[7:0], accumulator_9[7:0], accumulator_10[7:0], accumulator_11[7:0],
// 				accumulator_12[7:0], accumulator_13[7:0], accumulator_14[7:0], accumulator_15[7:0]};
assign data_bus_o = {accumulator_0, accumulator_1, accumulator_2, accumulator_3, 
				accumulator_4, accumulator_5, accumulator_6, accumulator_7,
				accumulator_8, accumulator_9, accumulator_10, accumulator_11,
				accumulator_12, accumulator_13, accumulator_14, accumulator_15};
endmodule