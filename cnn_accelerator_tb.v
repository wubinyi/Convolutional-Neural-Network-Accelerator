module cnn_accelerator_tb();

// port parameter
parameter INPUT_BIT_WIDTH           = 8;         // bit-width of neuron-input for each computation unit: 8-bit
parameter QUAD_DATA_BUS_BIT_WIDTH   = 32;
parameter OUTPUT_BIT_WIDTH          = 16+6+2+2;    // cnn accelerator's output
parameter DATA_BUS_BIT_WIDTH        = 128;
parameter INI_DATA_BUS              = 128'h0;
parameter OUPUT_DATA_BUS_BIT_WIDTH  = 512;
parameter MEM_READ                  = 1'b1;
parameter MEM_WRITE                 = 1'b0;
parameter MEM_ADDRESS_BIT_WIDTH     = 8;
parameter INI_MEM_ADDRESS           = 8'h0;
parameter MEM_ADDRESS_ZERO          = 8'h0;
parameter MEM_ADDRESS_ONE           = 8'h1;
parameter MEM_ADDRESS_OFFSET_ONE    = 8'h1;

reg                               clk;
reg                               reset;
reg                               cpu_to_cnn;
reg  [DATA_BUS_BIT_WIDTH-1:0]     data_bus_i;
wire [OUPUT_DATA_BUS_BIT_WIDTH-1:0]     data_bus_o;
wire                              mem_read_en;
wire                              mem_write_en;
wire [MEM_ADDRESS_BIT_WIDTH-1:0]  mem_address_o;
wire                              cnn_to_cpu;

cnn_accelerator cnn_accelerator_0(
	.clk(clk),
	.reset(reset),
	.cpu_to_cnn(cpu_to_cnn),
	.data_bus_i(data_bus_i),
	.data_bus_o(data_bus_o),
	.mem_read_en(mem_read_en),
	.mem_write_en(mem_write_en),
	.mem_address_o(mem_address_o),
	.cnn_to_cpu(cnn_to_cpu)
);

initial begin
	clk = 1'b0;
	forever #20 clk = ~clk;
end

initial begin
	reset = 1'b0;
	# 35 reset = 1'b1;
	# 10 reset = 1'b0;
end

initial begin
	cpu_to_cnn = 1'b0;
	# 4  // signal delay
	# 60 
	cpu_to_cnn = 1'b1;
	# 40
	cpu_to_cnn = 1'b0;
end
//==============================================================================================
// filter width = 3
// three channel, three filter
//==============================================================================================
// always @(posedge clk) begin
// 	if (mem_read_en) begin
// 		case(mem_address_o)
// 			// filter width-8: 			3-1 
// 			// filter size-8: 			9-1
// 			// picture width-8: 		10-1
// 			// picture height-8: 		5-1
// 			// neuron fetch time-16: 	216-3  (213-->0xd5)
// 			// number of filters-8: 	3-1
// 			// number of channels-8: 	3-1
// 			// filter fetch time-16: 	27-1
// 			// load neuron time-8: 	    35-1
// 			// platform support:        0 (no tensorflow quantization)
// 			// quantized weight zero:   8'd136 --> 8'h88
// 			// last 24-bit: empty
// 			8'h00: data_bus_i <= 128'h0000_0088_0022_001a_0202_00d5_0409_0802;
// 			8'h01: data_bus_i <= 128'hffff_ffff_ffff_0000_1111_1111_1111_8002;
// 			8'h02: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0012_0900;
// 			8'h03: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_002d_241b;
// 			8'h04: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0048_3f36;
// 			8'h05: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0063_5a51;
// 			8'h06: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_007e_756c;
// 			8'h07: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0099_9087;
// 			8'h08: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_00b4_aba2;
// 			8'h09: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_00cf_c6bd;
// 			8'h0a: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_00ea_e1d8;// first filter
// 			8'h0b: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0015_0c03;
// 			8'h0c: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0030_271e;
// 			8'h0d: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_004b_4239;
// 			8'h0e: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0066_5d54;
// 			8'h0f: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0081_786f;
// 			8'h10: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_009c_938a;
// 			8'h11: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_00b7_aea5;
// 			8'h12: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_00d2_c9c0;
// 			8'h13: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_00ed_e4db;// second filter
// 			8'h14: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0018_0f06;
// 			8'h15: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0033_2a21;
// 			8'h16: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_004e_453c;
// 			8'h17: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0069_6057;
// 			8'h18: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0084_7b72;
// 			8'h19: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_009f_968d;
// 			8'h1a: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_00ba_b1a8;
// 			8'h1b: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_00d5_ccc3;
// 			8'h1c: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_00f0_e7de;// second filter

// 			8'h1d: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff02_0100;// loading neuron cache
// 			8'h1e: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff11_100f;// loading neuron cache
// 			8'h1f: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff20_1f1e;// loading neuron cache
// 			8'h20: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff2f_2e2d;// loading neuron cache
// 			8'h21: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff3e_3d3c;// loading neuron cache

// 			8'h22: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff05_0403;// loading neuron cache
// 			8'h23: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff14_1312;// loading neuron cache
// 			8'h24: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff23_2221;// loading neuron cache
// 			8'h25: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff32_3130;// loading neuron cache
// 			8'h26: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff41_403f;// loading neuron cache

// 			8'h27: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff08_0706;// loading neuron cache
// 			8'h28: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff17_1615;// loading neuron cache
// 			8'h29: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff26_2524;// loading neuron cache
// 			8'h2a: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff35_3433;// loading neuron cache
// 			8'h2b: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff44_4342;// loading neuron cache

// 			8'h2c: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff0b_0a09;// loading neuron cache
// 			8'h2d: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff1a_1918;// loading neuron cache
// 			8'h2e: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff29_2827;// loading neuron cache
// 			8'h2f: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff38_3736;// loading neuron cache
// 			8'h30: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff47_4645;// loading neuron cache

// 			8'h31: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff0e_0d0c;// loading neuron cache
// 			8'h32: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff1d_1c1b;// loading neuron cache
// 			8'h33: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff2c_2b2a;// loading neuron cache
// 			8'h34: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff3b_3a39;// loading neuron cache
// 			8'h35: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff4a_4948;// loading neuron cache


// 			8'h36: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff02_0100;// loading neuron cache
// 			8'h37: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff11_100f;// loading neuron cache
// 			8'h38: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff20_1f1e;// loading neuron cache
// 			8'h39: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff2f_2e2d;// loading neuron cache
// 			8'h3a: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff3e_3d3c;// loading neuron cache

// 			8'h3b: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff05_0403;// loading neuron cache
// 			8'h3c: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff14_1312;// loading neuron cache
// 			8'h3d: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff23_2221;// loading neuron cache
// 			8'h3e: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff32_3130;// loading neuron cache
// 			8'h3f: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff41_403f;// loading neuron cache

// 			8'h40: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff08_0706;// loading neuron cache
// 			8'h41: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff17_1615;// loading neuron cache
// 			8'h42: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff26_2524;// loading neuron cache
// 			8'h43: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff35_3433;// loading neuron cache
// 			8'h44: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff44_4342;// loading neuron cache

// 			8'h45: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff0b_0a09;// loading neuron cache
// 			8'h46: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff1a_1918;// loading neuron cache
// 			8'h47: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff29_2827;// loading neuron cache
// 			8'h48: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff38_3736;// loading neuron cache
// 			8'h49: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff47_4645;// loading neuron cache

// 			8'h4a: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff0e_0d0c;// loading neuron cache
// 			8'h4b: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff1d_1c1b;// loading neuron cache
// 			8'h4c: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff2c_2b2a;// loading neuron cache
// 			8'h4d: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff3b_3a39;// loading neuron cache
// 			8'h4e: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff4a_4948;// loading neuron cache

// 			default: data_bus_i <= 128'h1111_1111_1111_1111_1111_1111_1111_1111;
// 		endcase
// 	end
// end
//==============================================================================================
// filter width = 3
// three channel, three filter
//==============================================================================================
// always @(posedge clk) begin
// 	if (mem_read_en) begin
// 		case(mem_address_o)
// 			// filter width-8: 			3-1 
// 			// filter size-8: 			9-1
// 			// picture width-8: 		5-1
// 			// picture height-8: 		5-1
// 			// neuron fetch time-16: 	81-3  (78-->0x4e)
// 			// number of filters-8: 	3-1
// 			// number of channels-8: 	3-1
// 			// filter fetch time-16: 	27-1
// 			// load neuron time-8: 	    25-1
// 			// platform support:        0 (no tensorflow quantization)
// 			// quantized weight zero:   8'd136 --> 8'h88
// 			// last 24-bit: empty
// 			8'h00: data_bus_i <= 128'h0000_0088_0018_001a_0202_004e_0404_0802;
// 			8'h01: data_bus_i <= 128'hffff_ffff_ffff_0000_1111_1111_1111_8002;
// 			8'h02: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0012_0900;
// 			8'h03: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_002d_241b;
// 			8'h04: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0048_3f36;
// 			8'h05: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0063_5a51;
// 			8'h06: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_007e_756c;
// 			8'h07: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0099_9087;
// 			8'h08: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_00b4_aba2;
// 			8'h09: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_00cf_c6bd;
// 			8'h0a: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_00ea_e1d8;// first filter
// 			8'h0b: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0015_0c03;
// 			8'h0c: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0030_271e;
// 			8'h0d: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_004b_4239;
// 			8'h0e: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0066_5d54;
// 			8'h0f: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0081_786f;
// 			8'h10: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_009c_938a;
// 			8'h11: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_00b7_aea5;
// 			8'h12: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_00d2_c9c0;
// 			8'h13: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_00ed_e4db;// second filter
// 			8'h14: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0018_0f06;
// 			8'h15: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0033_2a21;
// 			8'h16: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_004e_453c;
// 			8'h17: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0069_6057;
// 			8'h18: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0084_7b72;
// 			8'h19: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_009f_968d;
// 			8'h1a: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_00ba_b1a8;
// 			8'h1b: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_00d5_ccc3;
// 			8'h1c: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_00f0_e7de;// second filter

// 			8'h1d: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff02_0100;// loading neuron cache
// 			8'h1e: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff11_100f;// loading neuron cache
// 			8'h1f: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff20_1f1e;// loading neuron cache
// 			8'h20: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff2f_2e2d;// loading neuron cache
// 			8'h21: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff3e_3d3c;// loading neuron cache

// 			8'h22: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff05_0403;// loading neuron cache
// 			8'h23: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff14_1312;// loading neuron cache
// 			8'h24: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff23_2221;// loading neuron cache
// 			8'h25: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff32_3130;// loading neuron cache
// 			8'h26: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff41_403f;// loading neuron cache

// 			8'h27: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff08_0706;// loading neuron cache
// 			8'h28: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff17_1615;// loading neuron cache
// 			8'h29: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff26_2524;// loading neuron cache
// 			8'h2a: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff35_3433;// loading neuron cache
// 			8'h2b: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff44_4342;// loading neuron cache

// 			8'h2c: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff0b_0a09;// loading neuron cache
// 			8'h2d: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff1a_1918;// loading neuron cache
// 			8'h2e: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff29_2827;// loading neuron cache
// 			8'h2f: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff38_3736;// loading neuron cache
// 			8'h30: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff47_4645;// loading neuron cache

// 			8'h31: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff0e_0d0c;// loading neuron cache
// 			8'h32: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff1d_1c1b;// loading neuron cache
// 			8'h33: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff2c_2b2a;// loading neuron cache
// 			8'h34: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff3b_3a39;// loading neuron cache
// 			8'h35: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ff4a_4948;// loading neuron cache

// 			default: data_bus_i <= 128'h1111_1111_1111_1111_1111_1111_1111_1111;
// 		endcase
// 	end
// end


// uint8_t sram_data[864] = {
// 		0x00, 0x00, 0x00, 0x88, 0x00, 0x18, 0x00, 0x1a, 0x02, 0x02, 0x00, 0x4e, 0x04, 0x04, 0x08, 0x02,
// 		0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x00, 0x00, 0x11, 0x11, 0x11, 0x11, 0x11, 0x11, 0x80, 0x02,
//    		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 18, 9, 0,
//    		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 45, 36, 27,
//    		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 72, 63, 54,
//    		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 99, 90, 81,
//    		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 126, 117, 108,
//    		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 153, 144, 135,
//    		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 180, 171, 162,
//    		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 207, 198, 189,
//    		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 234, 225, 216,
//    		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 21, 12, 3,
//    		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 48, 39, 30,
//    		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 75, 66, 57,
//    		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 102, 93, 84,
//    		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 129, 120, 111,
//    		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 156, 147, 138,
//    		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 183, 174, 165,
//    		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 210, 201, 192,
//    		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 237, 228, 219,
//    		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 24, 15, 6,
//    		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 51, 42, 33,
//    		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 78, 69, 60,
//    		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 105, 96, 87,
//    		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 132, 123, 114,
//    		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 159, 150, 141,
//    		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 186, 177, 168,
//    		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 213, 204, 195,
//    		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 240, 231, 222,
// 		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 1, 0,
// 		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 17, 16, 15,
// 		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 31, 30,
// 		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 47, 46, 45,
// 		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 62, 61, 60,
// 		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 4, 3,
// 		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 20, 19, 18,
// 		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 35, 34, 33,
// 		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 50, 49, 48,
// 		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 65, 64, 63,
// 		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 7, 6,
// 		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 23, 22, 21,
// 		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 38, 37, 36,
// 		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 53, 52, 51,
// 		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 68, 67, 66,
// 		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 11, 10, 9,
// 		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 26, 25, 24,
// 		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 41, 40, 39,
// 		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 56, 55, 54,
// 		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 71, 70, 69,
// 		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 14, 13, 12,
// 		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 29, 28, 27,
// 		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 44, 43, 42,
// 		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 59, 58, 57,
// 		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 74, 73, 72};
//==============================================================================================
// filter width = 2
// one channel
//==============================================================================================
always @(posedge clk) begin
	if (mem_read_en) begin
		case(mem_address_o)
			// filter width-8: 			2-1 
			// filter size-8: 			4-1
			// picture width-8: 		5-1
			// picture height-8: 		5-1
			// neuron fetch time-16: 	64-3  (61-->0x3d)
			// number of filters-8: 	4-1
			// number of channels-8: 	1-1
			// filter fetch time-16: 	16-1
			// load neuron time-8: 	    25-1
			// platform support:        0 (no tensorflow quantization)
			// quantized weight zero:   8'd136 --> 8'h88
			// last 24-bit: empty
			8'h0: data_bus_i <= 128'h0000_0000_001b_0007_0201_0051_0307_0301;
			8'h1: data_bus_i <= 128'hffff_ffff_ffff_0000_1111_1111_1111_0002;
			8'h00: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ff23;
			8'h01: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ff84;
			8'h02: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ffd9;
			8'h03: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ff82;// first filter
			8'h04: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ffff;
			8'h05: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ffa6;
			8'h06: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ff8d;
			8'h07: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ffde;// second filter
			8'h08: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ff00;
			8'h09: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ffad;
			8'h0a: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ffd1;
			8'h0b: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ff96;// third filter
			8'h0c: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ff91;
			8'h0d: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ff76;
			8'h0e: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ff3b;
			8'h0f: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ffcc;// fourth filter

			8'h10: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ffcc;// loading neuron cache
			8'h11: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache
			8'h12: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache
			8'h13: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache
			8'h14: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ffd9;// loading neuron cache
			8'h15: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff;// loading neuron cache
			8'h16: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache
			8'h17: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache
			8'h18: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff;// loading neuron cache
			8'h19: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache
			8'h1a: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff;// loading neuron cache
			8'h1b: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff1a;// loading neuron cache
			8'h1c: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_fff2;// loading neuron cache
			8'h1d: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache
			8'h1e: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache
			8'h1f: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff;// loading neuron cache
			8'h20: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff;// loading neuron cache
			8'h21: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache
			8'h22: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache
			8'h23: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache
			8'h24: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff;// loading neuron cache
			8'h25: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff0d;// loading neuron cache
			8'h26: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache
			8'h27: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache
			8'h28: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache

			default: data_bus_i <= 128'h1111_1111_1111_1111_1111_1111_1111_1111;
		endcase
	end
end

//==============================================================================================
// filter width = 3
// one channel
//==============================================================================================
// always @(posedge clk) begin
// 	if (mem_read_en) begin
// 		case(mem_address_o)
// 			// filter width-8: 			3-1 
// 			// filter size-8: 			9-1
// 			// picture width-8: 		5-1
// 			// picture height-8: 		5-1
// 			// neuron fetch time-16: 	81-3
// 			// number of filters-8: 	2-1
// 			// number of channels-8: 	1-1
// 			// filter fetch time-16: 	18-1
// 			// load neuron time-8: 	    25-1
// 			// platform support:        1 (tensorflow quantization)
// 			// quantized weight zero:   8'd136 --> 8'h88
// 			// last 24-bit: empty
// 			64'h0: data_bus_i <= 128'h0000_0088_0118_0011_0001_004e_0404_0802;
// 			64'h1: data_bus_i <= 128'hffff_ffff_ffff_0000_1111_1111_1111_0000;
// 			64'h1111_1111_1111_0000: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ff23;
// 			64'h1111_1111_1111_0001: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ffff;
// 			64'h1111_1111_1111_0002: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ff00;
// 			64'h1111_1111_1111_0003: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ff91;
// 			64'h1111_1111_1111_0004: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ff84;
// 			64'h1111_1111_1111_0005: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ffa6;
// 			64'h1111_1111_1111_0006: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ffad;
// 			64'h1111_1111_1111_0007: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ff76;
// 			64'h1111_1111_1111_0008: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ffd9;// first filter
// 			64'h1111_1111_1111_0009: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ff8d;
// 			64'h1111_1111_1111_000a: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ffd1;
// 			64'h1111_1111_1111_000b: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ff3b;
// 			64'h1111_1111_1111_000c: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ff82;
// 			64'h1111_1111_1111_000d: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ffde;
// 			64'h1111_1111_1111_000e: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ff96;
// 			64'h1111_1111_1111_000f: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ffcc;
// 			64'h1111_1111_1111_0010: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ff97;
// 			64'h1111_1111_1111_0011: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ff3c;// second filter

// 			64'h1111_1111_1111_0012: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ffcc;// loading neuron cache
// 			64'h1111_1111_1111_0013: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache
// 			64'h1111_1111_1111_0014: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache
// 			64'h1111_1111_1111_0015: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache
// 			64'h1111_1111_1111_0016: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ffd9;// loading neuron cache
// 			64'h1111_1111_1111_0017: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff;// loading neuron cache
// 			64'h1111_1111_1111_0018: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache
// 			64'h1111_1111_1111_0019: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache
// 			64'h1111_1111_1111_001a: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff;// loading neuron cache
// 			64'h1111_1111_1111_001b: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache
// 			64'h1111_1111_1111_001c: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff;// loading neuron cache
// 			64'h1111_1111_1111_001d: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff1a;// loading neuron cache
// 			64'h1111_1111_1111_001e: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_fff2;// loading neuron cache
// 			64'h1111_1111_1111_001f: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache
// 			64'h1111_1111_1111_0020: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache
// 			64'h1111_1111_1111_0021: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff;// loading neuron cache
// 			64'h1111_1111_1111_0022: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff;// loading neuron cache
// 			64'h1111_1111_1111_0023: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache
// 			64'h1111_1111_1111_0024: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache
// 			64'h1111_1111_1111_0025: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache
// 			64'h1111_1111_1111_0026: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff;// loading neuron cache
// 			64'h1111_1111_1111_0027: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff0d;// loading neuron cache
// 			64'h1111_1111_1111_0028: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache
// 			64'h1111_1111_1111_0029: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache
// 			64'h1111_1111_1111_002a: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache

// 			default: data_bus_i <= 128'h1111_1111_1111_1111_1111_1111_1111_1111;
// 		endcase
// 	end
// end


//==============================================================================================
// filter width = 4
// one channel
//==============================================================================================
// always @(posedge clk) begin
// 	if (mem_read_en) begin
// 		case(mem_address_o)
// 			// filter width-8: 			4-1 
// 			// filter size-8: 			16-1
// 			// picture width-8: 		5-1
// 			// picture height-8: 		5-1
// 			// neuron fetch time-16: 	64-3
// 			// number of filters-8: 	1-1
// 			// number of channels-8: 	1-1
// 			// filter fetch time-16: 	16-1
// 			// load neuron time-8: 	    25-1
// 			// platform support:        0 (no tensorflow quantization)
// 			// quantized weight zero:   8'd136 --> 8'h88
// 			// last 24-bit: empty
// 			64'h0: data_bus_i <= 128'h0000_0088_0018_000f_0000_003d_0404_0f03;
// 			64'h1: data_bus_i <= 128'hffff_ffff_ffff_0000_1111_1111_1111_0000;
// 			64'h1111_1111_1111_0000: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ff23;
// 			64'h1111_1111_1111_0001: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ffff;
// 			64'h1111_1111_1111_0002: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ff00;
// 			64'h1111_1111_1111_0003: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ff91;
// 			64'h1111_1111_1111_0004: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ff84;
// 			64'h1111_1111_1111_0005: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ffa6;
// 			64'h1111_1111_1111_0006: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ffad;
// 			64'h1111_1111_1111_0007: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ff76;
// 			64'h1111_1111_1111_0008: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ffd9;// first filter
// 			64'h1111_1111_1111_0009: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ff8d;
// 			64'h1111_1111_1111_000a: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ffd1;
// 			64'h1111_1111_1111_000b: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ff3b;
// 			64'h1111_1111_1111_000c: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ff82;
// 			64'h1111_1111_1111_000d: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ffde;
// 			64'h1111_1111_1111_000e: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ff96;
// 			64'h1111_1111_1111_000f: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ffcc;
// 			// 64'h1111_1111_1111_0010: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ff97;
// 			// 64'h1111_1111_1111_0011: data_bus_i <= 128'h0000_0000_0000_0000_0000_0000_0000_ff3c;// first filter


// 			64'h1111_1111_1111_0010: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ffcc;// loading neuron cache
// 			64'h1111_1111_1111_0011: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache
// 			64'h1111_1111_1111_0012: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache
// 			64'h1111_1111_1111_0013: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache
// 			64'h1111_1111_1111_0014: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ffd9;// loading neuron cache
// 			64'h1111_1111_1111_0015: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff;// loading neuron cache
// 			64'h1111_1111_1111_0016: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache
// 			64'h1111_1111_1111_0017: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache
// 			64'h1111_1111_1111_0018: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff;// loading neuron cache
// 			64'h1111_1111_1111_0019: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache
// 			64'h1111_1111_1111_001a: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff;// loading neuron cache
// 			64'h1111_1111_1111_001b: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff1a;// loading neuron cache
// 			64'h1111_1111_1111_001c: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_fff2;// loading neuron cache
// 			64'h1111_1111_1111_001d: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache
// 			64'h1111_1111_1111_001e: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache
// 			64'h1111_1111_1111_001f: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff;// loading neuron cache
// 			64'h1111_1111_1111_0020: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff;// loading neuron cache
// 			64'h1111_1111_1111_0021: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache
// 			64'h1111_1111_1111_0022: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache
// 			64'h1111_1111_1111_0023: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache
// 			64'h1111_1111_1111_0024: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ffff;// loading neuron cache
// 			64'h1111_1111_1111_0025: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff0d;// loading neuron cache
// 			64'h1111_1111_1111_0026: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache
// 			64'h1111_1111_1111_0027: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache
// 			64'h1111_1111_1111_0028: data_bus_i <= 128'hffff_ffff_ffff_ffff_ffff_ffff_ffff_ff00;// loading neuron cache

// 			default: data_bus_i <= 128'h1111_1111_1111_1111_1111_1111_1111_1111;
// 		endcase
// 	end
// end

reg  [OUPUT_DATA_BUS_BIT_WIDTH-1:0]     data [8:0];
always @(posedge clk) begin
	if (mem_write_en) begin
		case(mem_address_o[3:0])
			4'h0: data[0] <= data_bus_o;
			4'h1: data[1] <= data_bus_o;
			4'h2: data[2] <= data_bus_o;
			4'h3: data[3] <= data_bus_o;
			4'h4: data[4] <= data_bus_o;
			4'h5: data[5] <= data_bus_o;
			4'h6: data[6] <= data_bus_o;
			4'h7: data[7] <= data_bus_o;
			4'h8: data[8] <= data_bus_o;
		endcase
	end
end

endmodule