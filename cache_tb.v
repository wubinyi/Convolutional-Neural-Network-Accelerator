module cache_tb();

reg clk;
reg layer_reset;
reg write;
reg [2:0] channel_sel_wr;
reg [4:0] address_wr;
reg [7:0] cache_data;

reg neuron_fetch_en;

wire [55:0] fetch_data;
wire       cache_rd_en;
wire [4:0] address_rd;
wire [6:0] channel_sel_rd;
wire [7:0] neuron_activation;
neuron_fetch neuron_fetch_0(
	.clk(clk),
	.layer_reset(layer_reset),
	.neuron_fetch_en_i(neuron_fetch_en),
	.filter_width_i(3'h3),
	.picture_height_i(5'd32),
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
	.cache_data_i(cache_data)
	);


initial begin
	clk = 1'b0;
	forever # 20 clk = ~clk;
end

initial begin
	layer_reset = 1'b0;
	# 10 layer_reset = 1'b1;
	# 40 layer_reset = 1'b0;
end

initial begin
	neuron_fetch_en = 1'b0;
	write = 1'b0;
	# 60
	# 1
	neuron_fetch_en = 1'b1;
	//# 800
	//neuron_fetch_en = 1'b0;

	// # 40
	// read = 1'b0;
	// neuron_fetch_en = 1'b0;	
	// # 40
	// read = 1'b1;
	// neuron_fetch_en = 1'b1;
	// # 40
	// read = 1'b0;
	// neuron_fetch_en = 1'b0;
	// # 40
	// read = 1'b1;
	// neuron_fetch_en = 1'b1;
	// # 40
	// read = 1'b0;
	// neuron_fetch_en = 1'b0;
	// # 40
	// read = 1'b1;
	// neuron_fetch_en = 1'b1;
	// # 40
	// read = 1'b0;
	// neuron_fetch_en = 1'b0;	
	// # 40
	// read = 1'b1;
	// neuron_fetch_en = 1'b1;
	// # 40
	// read = 1'b0;
	// neuron_fetch_en = 1'b0;
	// # 40
	// read = 1'b1;
	// neuron_fetch_en = 1'b1;
	// # 40
	// read = 1'b0;
	// neuron_fetch_en = 1'b0;
	// # 40
	// read = 1'b1;
	// neuron_fetch_en = 1'b1;
	// # 40
	// read = 1'b0;
	// neuron_fetch_en = 1'b0;	
end


endmodule