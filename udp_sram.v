// Company           :   tud
// Author            :   binyiwu
// E-Mail            :   <$ICPRO_EMAIL not set - insert email address>
//
// Filename          :   udp_sram.v
// Project Name      :   p_eval
// Subproject Name   :   s_deepl
// Description       :   <short description>
//
// Create Date       :   Tue Dec 12 16:15:57 2017
// Last Change       :   $Date: 2017-12-12 17:16:18 +0100 (Tue, 12 Dec 2017) $
// by                :   $Author: binyiwu $
//------------------------------------------------------------

module udp_sram #(
    // udp, noc parameters
    parameter UDP_LISTEN_PORT   = 1800,
    parameter UDP_MAGIC_SEND    = 32'h722acce7,
    parameter UDP_MAGIC_RECV    = 32'h2e2acce7,
    parameter CNNA_START_UDP    = 32'h5a2acce7, 
    parameter CNNA_FINISH_UDP   = 32'haa2acce7, 
    parameter NOC_SRC_MODID     = 6'h01,

    // sram parameters
    parameter MEM_INPUT_BIT_WIDTH = 128,
    parameter MEM_OUTPUT_BIT_WIDTH = 512,
    parameter MEM_ADDR_BIT_WIDTH = 8
) (
    input                           clk_i,
    input                           reset_n_i,

    // sram -> udp (rx, og)
    output                   [31:0] udp_og_data_o,
    output                          udp_og_data_valid_o,
    output                   [15:0] udp_og_src_port_o,
    output                   [15:0] udp_og_dest_port_o,
    output                   [31:0] udp_og_dest_addr_o,
    output                          udp_og_sof_o,
    output                          udp_og_eof_o,
    input                           udp_og_ready_i,
    // input                           udp_og_error_i,

    input  [MEM_OUTPUT_BIT_WIDTH-1:0] mem_output_i,
    output                          mem_rd_en_o,

    // udp -> ram (tx, ic)
    input                    [31:0] udp_ic_data_i,
    input                           udp_ic_data_valid_i,
    input                    [15:0] udp_ic_src_port_i,
    input                    [15:0] udp_ic_dest_port_i,
    input                    [31:0] udp_ic_src_addr_i,
    input                           udp_ic_sof_i,
    input                           udp_ic_eof_i,
    // input                     [2:0] udp_ic_data_rem_i,

    output  [MEM_INPUT_BIT_WIDTH-1:0] mem_input_o,
    output                          mem_wr_en_o,

    // sram address
    output [MEM_ADDR_BIT_WIDTH-1:0] mem_addr_o,

    // cpu to cnna
    output                          cpu_udp_to_cnna_start_o,
    // cnna to cpu
    input                           cnna_finish_to_cpu_udp_i,
    input [31:0]                    cnna_clk_counter
);

    // ============== UDP FSM ==================================================

    reg [31:0]                   udp_packet_data;
    reg                          udp_packet_data_valid;
    reg [15:0]                   udp_port_this;
    reg [15:0]                   udp_port_partner;
    reg [31:0]                   udp_addr_partner;
    reg                          udp_packet_sof;
    reg                          udp_packet_eof;

    assign udp_og_data_o       = udp_packet_data;
    assign udp_og_data_valid_o = udp_packet_data_valid;
    assign udp_og_src_port_o   = udp_port_this;
    assign udp_og_dest_port_o  = udp_port_partner;
    assign udp_og_dest_addr_o  = udp_addr_partner;
    assign udp_og_sof_o        = udp_packet_sof;
    assign udp_og_eof_o        = udp_packet_eof;

    reg                          mem_rd_en;
    reg                          mem_wr_en;
    reg [MEM_INPUT_BIT_WIDTH-1:0]  mem_input;
    reg                          sram_addr_switch;
    reg [MEM_ADDR_BIT_WIDTH-1:0] mem_wr_addr;
    reg [MEM_ADDR_BIT_WIDTH-1:0] mem_rd_addr;
    reg [MEM_OUTPUT_BIT_WIDTH-1:0] mem_output;

    assign mem_rd_en_o =         mem_rd_en;
    assign mem_wr_en_o =         mem_wr_en;
    assign mem_input_o =         mem_input;
    assign mem_addr_o  =   (sram_addr_switch == 1'b0) ? mem_wr_addr : mem_rd_addr;

    reg                            cpu_udp_to_cnna_start;
    assign cpu_udp_to_cnna_start_o = cpu_udp_to_cnna_start;

    localparam ST_INIT           = 'h00;
    localparam ST_RECV_HEAD      = 'h01;

    localparam ST_TX_ADDR        = 'h02;
    localparam ST_TX_DATA1       = 'h03;
    localparam ST_TX_DATA2       = 'h04;
    localparam ST_TX_DATA3       = 'h05;
    localparam ST_TX_DATA4       = 'h06;
    localparam ST_TX_FINISH      = 'h07;

    localparam ST_RX_ADDR        = 'h08;
    localparam ST_RX_DATA_PRE    = 'h09;
    localparam ST_RX_DATA        = 'h0a;
    localparam ST_RX_PACKET1     = 'h0b;
    localparam ST_RX_PACKET2     = 'h0c;
    localparam ST_RX_PACKET3     = 'h0d;
    localparam ST_RX_PACKET4     = 'h0e;
    localparam ST_RX_PACKET5     = 'h0f;
    localparam ST_RX_PACKET6     = 'h10;
    localparam ST_RX_PACKET7     = 'h11;
    localparam ST_RX_PACKET8     = 'h12;
    localparam ST_RX_PACKET9     = 'h13;
    localparam ST_RX_PACKET10    = 'h14;
    localparam ST_RX_PACKET11    = 'h15;
    localparam ST_RX_PACKET12    = 'h16;
    localparam ST_RX_PACKET13    = 'h17;
    localparam ST_RX_PACKET14    = 'h18;
    localparam ST_RX_PACKET15    = 'h19;
    localparam ST_RX_PACKET16    = 'h1a;
    localparam ST_RX_WAIT        = 'h1b;
    localparam ST_RX_FINISH      = 'h1c;

    localparam ST_CNNA_FINISH    = 'h1d;
    localparam ST_CNNA_FINISH_CLK =  'h1e;

    reg cnna_finish_flag;
    always @(posedge clk_i or posedge reset_n_i) begin
        if (reset_n_i == 1'b1) begin
            cnna_finish_flag <= 1'b0;
        end
        else begin
            if (cnna_finish_to_cpu_udp_i) begin
                cnna_finish_flag <= 1'b1;
            end
            else if (cpu_udp_to_cnna_start) begin
                cnna_finish_flag <= 1'b0;
            end
        end
    end

    reg [4:0]   state_udp;
    reg [15:0]  cnt_timeout;
    always @(posedge clk_i or posedge reset_n_i) begin
        if (reset_n_i == 1'b1) begin
            // read sram regs
            mem_rd_en <= 1'b0;
            mem_rd_addr <= 'h0;
            mem_output <= {MEM_OUTPUT_BIT_WIDTH{1'b0}};
            // write sram regs
            mem_wr_en <= 1'b0;
            mem_wr_addr <= 'h0;
            mem_input <= {MEM_INPUT_BIT_WIDTH{1'b0}};

            // udp regs
            udp_packet_data       <= 'h0;
            udp_packet_data_valid <= 1'b0;
            udp_port_this         <= 'h0;
            udp_port_partner      <= 'h0;
            udp_addr_partner      <= 'h0;
            udp_packet_sof        <= 1'b0;
            udp_packet_eof        <= 1'b0;

            // state
            state_udp             <= ST_INIT;
            cnt_timeout           <= 'h0;

            // cnna start
            cpu_udp_to_cnna_start <= 1'b0;

            // switch sram write & read address
            sram_addr_switch <= 1'b0; // -- sram write address

        end else begin
            case (state_udp)
                ST_INIT: begin
                    cpu_udp_to_cnna_start <= 1'b0;
                    sram_addr_switch <= 1'b0; // -- sram write address
                    if (udp_ic_sof_i == 1'b1) begin
                        state_udp        <= ST_RECV_HEAD;
                        udp_packet_data  <= 'h0;
                        udp_port_this    <= udp_ic_dest_port_i;
                        udp_port_partner <= udp_ic_src_port_i;
                        udp_addr_partner <= udp_ic_src_addr_i;
                    end
                    if (cnna_finish_to_cpu_udp_i) begin
                        state_udp <= ST_CNNA_FINISH;
                    end
                end
                ST_RECV_HEAD: begin
                    if ((udp_port_this == UDP_LISTEN_PORT)) begin
                        if (udp_ic_data_valid_i == 1'b1) begin
                            if (udp_ic_data_i == UDP_MAGIC_SEND) begin
                                sram_addr_switch <= 1'b0; // -- sram write address
                                state_udp     <= ST_TX_DATA1;
                                mem_rd_addr <= 'h0;

                            end else if (udp_ic_data_i == UDP_MAGIC_RECV) begin
                                sram_addr_switch <= 1'b1; // -- sram read address
                                state_udp     <= ST_RX_ADDR;
                                cnt_timeout   <= 16'hffff;

                            end else if (udp_ic_data_i == CNNA_START_UDP) begin
                                state_udp <= ST_INIT;
                                cpu_udp_to_cnna_start <= 1'b1;
                            end else begin
                                state_udp <= ST_INIT;
                            end
                        end
                        if (udp_ic_eof_i == 1'b1) begin
                            state_udp <= ST_INIT;
                        end
                    end else begin
                        state_udp <= ST_INIT;
                    end
                end

                /* indicate CNNA is finish */
                ST_CNNA_FINISH: begin
                    udp_packet_data <= CNNA_FINISH_UDP;
                    udp_packet_sof <= 1'b1;
                    state_udp <= ST_CNNA_FINISH_CLK; 
                end
                ST_CNNA_FINISH_CLK: begin
                    if (udp_og_ready_i == 1'b1) begin
                        udp_packet_data_valid <= 1'b1;
                        udp_packet_sof <= 1'b0;
                        udp_packet_data <= cnna_clk_counter;
                        state_udp <= ST_RX_WAIT;                    
                    end
                end

                /* receive 512-bit from sram, send them to UDP-block */
                ST_RX_ADDR: begin
                    if (cnna_finish_flag) begin
                        // read sram
                            //mem_rd_addr <= mem_rd_addr + 'h1;
                        mem_rd_en <= 1'b1;
                        // send UDP_MAGIC_SEND
                        udp_packet_data <= UDP_MAGIC_SEND;
                        // indicate start of frame(including magic paket)
                        udp_packet_sof <= 1'b1; 
                            //cnt_timeout <= 16'hffff;
                        state_udp <= ST_RX_DATA_PRE;                        
                    end
                    else if (cnt_timeout == 'h0) begin
                        state_udp <= ST_INIT;
                    end
                    else begin
                        cnt_timeout <= cnt_timeout - 'h1;
                    end
                end
                ST_RX_DATA_PRE:begin
                    state_udp <= ST_RX_DATA;
                end
                ST_RX_DATA: begin
                    // read data from sram
                    mem_output <= mem_output_i;
                    // do not read sram
                    mem_rd_en <= 1'b0;
                    if (udp_og_ready_i == 1'b1) begin
                        udp_packet_sof <= 1'b0;
                        // indicate begining of the valid data
                        udp_packet_data_valid <= 1'b1;
                        // update address for next use
                        mem_rd_addr <= mem_rd_addr + 'h1;
                        state_udp <= ST_RX_PACKET1;
                    end
                end
                ST_RX_PACKET1: begin
                    if (udp_og_ready_i == 1'b1) begin
                        udp_packet_data <= mem_output[511:480];
                        state_udp <= ST_RX_PACKET2;
                    end
                end
                ST_RX_PACKET2: begin
                    if (udp_og_ready_i == 1'b1) begin
                        udp_packet_data <= mem_output[479:448];
                        state_udp <= ST_RX_PACKET3;
                    end
                end
                ST_RX_PACKET3: begin
                    if (udp_og_ready_i == 1'b1) begin
                        udp_packet_data <= mem_output[447:416];
                        state_udp <= ST_RX_PACKET4;
                    end
                end
                ST_RX_PACKET4: begin
                    if (udp_og_ready_i == 1'b1) begin
                        udp_packet_data <= mem_output[415:384];
                        state_udp <= ST_RX_PACKET5;
                    end
                end                
                ST_RX_PACKET5: begin
                    if (udp_og_ready_i == 1'b1) begin
                        udp_packet_data <= mem_output[383:352];
                        state_udp <= ST_RX_PACKET6;
                    end
                end
                ST_RX_PACKET6: begin
                    if (udp_og_ready_i == 1'b1) begin
                        udp_packet_data <= mem_output[351:320];
                        state_udp <= ST_RX_PACKET7;
                    end
                end
                ST_RX_PACKET7: begin
                    if (udp_og_ready_i == 1'b1) begin
                        udp_packet_data <= mem_output[319:288];
                        state_udp <= ST_RX_PACKET8;
                    end
                end
                ST_RX_PACKET8: begin
                    if (udp_og_ready_i == 1'b1) begin
                        udp_packet_data <= mem_output[287:256];
                        state_udp <= ST_RX_PACKET9;
                    end
                end
                ST_RX_PACKET9: begin
                    if (udp_og_ready_i == 1'b1) begin
                        udp_packet_data <= mem_output[255:224];
                        state_udp <= ST_RX_PACKET10;
                    end
                end
                ST_RX_PACKET10: begin
                    if (udp_og_ready_i == 1'b1) begin
                        udp_packet_data <= mem_output[223:192];
                        state_udp <= ST_RX_PACKET11;
                    end
                end
                ST_RX_PACKET11: begin
                    if (udp_og_ready_i == 1'b1) begin
                        udp_packet_data <= mem_output[191:160];
                        state_udp <= ST_RX_PACKET12;
                    end
                end
                ST_RX_PACKET12: begin
                    if (udp_og_ready_i == 1'b1) begin
                        udp_packet_data <= mem_output[159:128];
                        state_udp <= ST_RX_PACKET13;
                    end
                end
                ST_RX_PACKET13: begin
                    if (udp_og_ready_i == 1'b1) begin
                        udp_packet_data <= mem_output[127:96];
                        state_udp <= ST_RX_PACKET14;
                    end
                end
                ST_RX_PACKET14: begin
                    if (udp_og_ready_i == 1'b1) begin
                        udp_packet_data <= mem_output[95:64];
                        state_udp <= ST_RX_PACKET15;
                    end
                end
                ST_RX_PACKET15: begin
                    if (udp_og_ready_i == 1'b1) begin
                        udp_packet_data <= mem_output[63:32];
                        state_udp <= ST_RX_PACKET16;
                    end
                end
                ST_RX_PACKET16: begin
                    if (udp_og_ready_i == 1'b1) begin
                        udp_packet_data <= mem_output[31:0];
                        state_udp <= ST_RX_WAIT;
                    end
                end
                ST_RX_WAIT:begin
                    if (udp_og_ready_i == 1'b1) begin
                        udp_packet_data_valid <= 1'b0;
                        udp_packet_eof <= 1'b1;
                        state_udp <= ST_RX_FINISH;
                    end                    
                end
                ST_RX_FINISH: begin
                    udp_packet_eof <= 1'b0;
                    state_udp <= ST_INIT;
                end


                /* send 128-bit to sram, accumulate 4 times: 32 x 4 = 128 */
                ST_TX_DATA1: begin
                    if (udp_ic_data_valid_i == 1'b1) begin
                        mem_input[127:96] <= udp_ic_data_i;
                        state_udp <= ST_TX_DATA2;
                    end
                    if (udp_ic_eof_i == 1'b1) begin
                        // unexpected EOF - abort
                        state_udp <= ST_TX_FINISH;
                    end
                end
                ST_TX_DATA2: begin
                    if (udp_ic_data_valid_i == 1'b1) begin
                        mem_input[95:64] <= udp_ic_data_i;
                        state_udp <= ST_TX_DATA3;
                    end
                    if (udp_ic_eof_i == 1'b1) begin
                        // unexpected EOF - abort
                        state_udp <= ST_TX_FINISH;
                    end
                end
                ST_TX_DATA3: begin
                    if (udp_ic_data_valid_i == 1'b1) begin
                        mem_input[63:32] <= udp_ic_data_i;
                        state_udp <= ST_TX_DATA4;
                    end
                    if (udp_ic_eof_i == 1'b1) begin
                        // unexpected EOF - abort
                        state_udp <= ST_TX_FINISH;
                    end
                end
                ST_TX_DATA4: begin
                    if (udp_ic_data_valid_i == 1'b1) begin
                        mem_input[31:0] <= udp_ic_data_i;
                        state_udp <= ST_TX_ADDR;
                    end
                    if (udp_ic_eof_i == 1'b1) begin
                        // unexpected EOF - abort
                        state_udp <= ST_TX_FINISH;
                    end
                end
                ST_TX_ADDR: begin
                    if (udp_ic_data_valid_i == 1'b1) begin
                        mem_wr_addr <= udp_ic_data_i[7:0];
                        mem_wr_en <= 1'b1;
                        //mem_input <= {MEM_INPUT_BIT_WIDTH{1'b0}};
                        state_udp   <= ST_TX_FINISH;
                    end
                    if (udp_ic_eof_i == 1'b1) begin
                        // unexpected EOF - abort
                        state_udp <= ST_TX_FINISH;
                    end
                end
                ST_TX_FINISH: begin
                    mem_wr_en <= 1'b0;
                    // mem_wr_addr <= mem_wr_addr + 8'h1;
                    state_udp <= ST_INIT;
                end
                default: begin
                    state_udp             <= ST_INIT;
                    udp_packet_sof        <= 1'b0;
                    udp_packet_eof        <= 1'b0;
                    udp_packet_data_valid <= 1'b0;
                end
            endcase
        end
    end
endmodule