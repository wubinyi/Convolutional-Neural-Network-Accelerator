module cnna_udp_top (
                    // delete due to closed-source
                    );

    // UDP interface
    // --------------------------------------------------------------------------
    // This part instance the UDP module, which is closed-source.
    // --------------------------------------------------------------------------

    // cnn accelerator
    // -------------------------------------------------------------------------- 
    parameter MEM_ADDRESS_BIT_WIDTH           = 8;
    parameter UDP_TO_SRAM_DATA_BIT_WIDTH      = 128;
    parameter UDP_FROM_SRAM_DATA_BIT_WIDTH    = 512;
    parameter CNNA_FROM_SRAM_DATA_BIT_WIDTH   = 128;
    parameter CNNA_TO_SRAM_DATA_BIT_WIDTH     = 512;    
    wire [MEM_ADDRESS_BIT_WIDTH-1:0]        udp_mem_address;
    wire [UDP_TO_SRAM_DATA_BIT_WIDTH-1:0]   udp_to_sram_data;
    wire [UDP_FROM_SRAM_DATA_BIT_WIDTH-1:0] udp_from_sram_data;
    wire                                    udp_mem_write_en;
    wire                                    udp_mem_read_en;

    wire [MEM_ADDRESS_BIT_WIDTH-1:0]          cnna_mem_address;
    wire [CNNA_FROM_SRAM_DATA_BIT_WIDTH-1:0]  cnna_from_sram_data;
    wire [CNNA_TO_SRAM_DATA_BIT_WIDTH-1:0]    cnna_to_sram_data;
    wire                                      cnna_mem_write_en;
    wire                                      cnna_mem_read_en;
    wire                                      cnna_start;
    wire                                      cnna_finish;
    wire [31:0]                               cnna_clk_counter;

    // udp_sram   
    udp_sram i_udp_sram(
        .clk_i(clk_eth),
        .reset_n_i(a_reset_eth_h),
        .udp_og_data_o(og_data),
        .udp_og_data_valid_o(og_data_valid),
        .udp_og_src_port_o(og_src_port),
        .udp_og_dest_port_o(og_dest_port),
        .udp_og_dest_addr_o(og_dest_addr),
        .udp_og_sof_o(og_sof),
        .udp_og_eof_o(og_eof),
        .udp_og_ready_i(og_ready),
        // .udp_og_error_i(),
        .mem_output_i(udp_from_sram_data),
        .mem_rd_en_o(udp_mem_read_en),
        .udp_ic_data_i(ic_data),
        .udp_ic_data_valid_i(ic_data_valid),
        .udp_ic_src_port_i(ic_src_port),
        .udp_ic_dest_port_i(ic_dest_port),
        .udp_ic_src_addr_i(ic_src_addr),
        .udp_ic_sof_i(ic_sof),
        .udp_ic_eof_i(ic_eof),
        // .udp_ic_data_rem_i(),
        .mem_input_o(udp_to_sram_data),
        .mem_wr_en_o(udp_mem_write_en),
        .mem_addr_o(udp_mem_address),
        .cpu_udp_to_cnna_start_o(cnna_start),
        .cnna_finish_to_cpu_udp_i(cnna_finish),
        .cnna_clk_counter(cnna_clk_counter)
    ); 

	
    // sram
    sram i_sram(
          .clk(clk_eth),
          .cnna_mem_read_en_i(cnna_mem_read_en),
          .cnna_mem_write_en_i(cnna_mem_write_en),
          .cnna_mem_address_i(cnna_mem_address),
          .data_from_cnna_i(cnna_to_sram_data),
          .data_to_cnna_o(cnna_from_sram_data),

          .udp_mem_read_en_i(udp_mem_read_en),
          .udp_mem_write_en_i(udp_mem_write_en), 
          .udp_mem_address_i(udp_mem_address),
          .data_from_udp_i(udp_to_sram_data),
          .data_to_udp_o(udp_from_sram_data) 
          );
 
    // cnn accelerator
    cnn_accelerator i_cnn_accelerator(
          .clk(clk_eth),
          .reset(a_reset_eth_h),
          .cpu_to_cnn(cnna_start),
          .data_bus_i(cnna_from_sram_data),
          .data_bus_o(cnna_to_sram_data),
          .mem_read_en(cnna_mem_read_en),
          .mem_write_en(cnna_mem_write_en),
          .mem_address_o(cnna_mem_address),
          .cnn_to_cpu(cnna_finish),
          .cnna_clk_counter(cnna_clk_counter)
          );   
 
endmodule
