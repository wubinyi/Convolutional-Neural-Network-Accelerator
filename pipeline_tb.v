module pipeline_tb();

reg clk;
reg layer_reset;
reg [2:0] filter_width_i;
reg neuron_fetch_en_i;
wire addressing_en_o;
wire cache_rd_o;
wire store_data_en_o;
wire output_neuron_ac_en_o;

neuron_fetch_pipelline pipeline_0(
	clk,
	layer_reset,
	filter_width_i,
	neuron_fetch_en_i,
	addressing_en_o,
	cache_rd_o,
	store_data_en_o,
	output_neuron_ac_en_o
	);


initial begin
	clk = 1'b0;
	forever #20 clk = ~clk;
end

initial begin
	neuron_fetch_en_i = 1'b0;
	layer_reset = 1'b0;
	filter_width_i = 3'b000;
	# 5
	# 60
	layer_reset = 1'b1;
	# 40
	layer_reset = 1'b0;
	neuron_fetch_en_i = 1'b1;
	# 720  // read 18 data
	# 120
	neuron_fetch_en_i = 1'b0;
end

reg [4:0] output_counter;
always @(posedge clk or posedge layer_reset) begin
	if (layer_reset) begin
		output_counter <= 5'h00;
	end
	else if (output_neuron_ac_en_o) begin
		output_counter <= output_counter + 5'h01;
	end
end
endmodule