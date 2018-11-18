module memory_operation_tb();

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


reg                                  clk;
reg                                  layer_reset;
reg [ADDRESS_BUS_BIT_WIDTH-1:0]      read_address_i;
reg [ADDRESS_BUS_BIT_WIDTH-1:0]      write_address_i;
reg                                  stage_finish_i;
wire                                 mem_rd_en_o;
wire                                 mem_wr_en_o;
wire [ADDRESS_BUS_BIT_WIDTH-1:0]     address_o;

memory_operation memory_operation_0(
	clk,
	layer_reset,
	read_address_i,
	write_address_i,
	stage_finish_i,
	mem_rd_en_o,
	mem_wr_en_o,
	address_o
	);

initial begin
	clk = 1'b0;
	forever #20 clk = ~clk;
end

initial begin
	layer_reset = 1'b0;
	# 61 layer_reset = 1'b1;
	# 40 layer_reset = 1'b0;
end

initial begin
	read_address_i = 32'h00000000;
	write_address_i = 32'h00000004;
	stage_finish_i = 1'b0;
	# 1
	# 20
	# 320
	stage_finish_i = 1'b1;
	# 40
	stage_finish_i = 1'b0;
end

reg [7:0] mem [7:0];
reg [7:0] memory_out;
always @(posedge clk or posedge layer_reset) begin
	if (layer_reset) begin
		mem[0] <= 8'h01;
		mem[1] <= 8'h02;
		mem[2] <= 8'h03;
		mem[3] <= 8'h04;
	end
	else if (mem_wr_en_o) begin
		mem[address_o[3:0]] = 8'hff;
	end
	else if (mem_rd_en_o) begin
		memory_out = mem[address_o[3:0]];
	end
end


endmodule