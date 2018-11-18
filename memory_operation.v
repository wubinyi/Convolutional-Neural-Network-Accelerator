module memory_operation(
	clk,
	layer_reset,
	read_address_i,
	write_address_i,
	stage_finish_i,
	mem_rd_en_o,
	mem_wr_en_o,
	address_o
	);

parameter MEMORY_STATE_BIT_WIDTH = 4;
parameter ADDRESS_BUS_BIT_WIDTH  = 32;
parameter INI_ADDRESS_BUS        = 32'h0000;
parameter ADDRESS_OFFSET_ONE     = 32'h0001;
// memory state
parameter IDLE                   = 4'd0;
parameter WRITE_PHASE_0          = 4'd1;
parameter WRITE_PHASE_1          = 4'd2;
parameter READ_PHASE_0           = 4'd3;
parameter READ_PHASE_1           = 4'd4;


input                                  clk;
input                                  layer_reset;
input [ADDRESS_BUS_BIT_WIDTH-1:0]      read_address_i;
input [ADDRESS_BUS_BIT_WIDTH-1:0]      write_address_i;
input                                  stage_finish_i;
output reg                             mem_rd_en_o;
output reg                             mem_wr_en_o;
output reg [ADDRESS_BUS_BIT_WIDTH-1:0] address_o;

//==========================================================================
// internal register
//==========================================================================
reg  [ADDRESS_BUS_BIT_WIDTH-1:0] write_address_bus;
reg  [ADDRESS_BUS_BIT_WIDTH-1:0] read_address_bus;


//==========================================================================
// memory operation state machine
//==========================================================================
reg [MEMORY_STATE_BIT_WIDTH-1:0] memory_state;
reg [MEMORY_STATE_BIT_WIDTH-1:0] next_memory_state;
always @(posedge clk or posedge layer_reset) begin
	if (layer_reset) begin
		memory_state <= IDLE;
	end
	else begin
		memory_state <= next_memory_state;
	end
end

//reg wr_rd_addr_sel;
reg wr_addr_update_en;
reg rd_addr_update_en;
always @(memory_state or stage_finish_i) begin
	//wr_rd_addr_sel = 1'b0;
	mem_rd_en_o = 1'b0;
	mem_wr_en_o = 1'b0;
	wr_addr_update_en = 1'b0;
	rd_addr_update_en = 1'b0;
	case(memory_state)
		IDLE:begin
			address_o = write_address_bus;
			if (stage_finish_i) begin
				next_memory_state = WRITE_PHASE_0;
			end
			else begin
				next_memory_state = IDLE;
			end
		end
		WRITE_PHASE_0:begin
			address_o = write_address_bus;
			//wr_rd_addr_sel = 1'b0;
			mem_wr_en_o = 1'b1;
			next_memory_state = WRITE_PHASE_1;
		end
		WRITE_PHASE_1: begin
			address_o = write_address_bus;
			//wr_rd_addr_sel = 1'b0;
			mem_wr_en_o = 1'b1;
			wr_addr_update_en = 1'b1;
			next_memory_state = READ_PHASE_0;
		end
		READ_PHASE_0: begin
			address_o = read_address_bus;
			//wr_rd_addr_sel = 1'b1;
			mem_rd_en_o = 1'b1;
			next_memory_state = READ_PHASE_1;
		end
		READ_PHASE_1: begin
			address_o = read_address_bus;
			//wr_rd_addr_sel = 1'b1;
			mem_rd_en_o = 1'b1;
			rd_addr_update_en = 1'b1;
			next_memory_state = IDLE;
		end
	endcase
end


//==========================================================================
// address update
//==========================================================================
wire [ADDRESS_BUS_BIT_WIDTH-1:0] write_address_bus_plus_one;
always @(posedge clk) begin
	if (layer_reset) begin
		write_address_bus <= write_address_i;
	end
	else if (wr_addr_update_en) begin
		write_address_bus <= write_address_bus_plus_one;
	end
end
assign write_address_bus_plus_one = write_address_bus + ADDRESS_OFFSET_ONE;

wire [ADDRESS_BUS_BIT_WIDTH-1:0] read_address_bus_plus_one;
always @(posedge clk) begin
	if (layer_reset) begin
		read_address_bus <= read_address_i;
	end
	else if (rd_addr_update_en) begin
		read_address_bus <= read_address_bus_plus_one;
	end
end
assign read_address_bus_plus_one = read_address_bus + ADDRESS_OFFSET_ONE;

endmodule