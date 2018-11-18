`include "paramter.v"

module index_calculate(
	neuron,
	index
	);

input  [INPUT_BIT_WIDTH-1:0] neuron [BYTES_OF_REG-1:0];
output [ITER_BIT_WIDTH-1:0]  index [BYTES_OF_REG-1:0];

assign index[0] = neuron[0]==8'h00 ? 6'd0 : 6'd0;
assign index[1] = neuron[1]==8'h00 ? 6'd0 : 6'd1;
assign index[2] = neuron[2]==8'h00 ? 6'd0 : 6'd2;
assign index[3] = neuron[3]==8'h00 ? 6'd0 : 6'd3;
assign index[4] = neuron[4]==8'h00 ? 6'd0 : 6'd4;
assign index[5] = neuron[5]==8'h00 ? 6'd0 : 6'd5;
assign index[6] = neuron[6]==8'h00 ? 6'd0 : 6'd6;
assign index[7] = neuron[7]==8'h00 ? 6'd0 : 6'd7;
assign index[8] = neuron[8]==8'h00 ? 6'd0 : 6'd8;
assign index[9] = neuron[9]==8'h00 ? 6'd0 : 6'd9;
assign index[10] = neuron[10]==8'h00 ? 6'd0 : 6'd10;
assign index[11] = neuron[11]==8'h00 ? 6'd0 : 6'd11;
assign index[12] = neuron[12]==8'h00 ? 6'd0 : 6'd12;
assign index[13] = neuron[13]==8'h00 ? 6'd0 : 6'd13;
assign index[14] = neuron[14]==8'h00 ? 6'd0 : 6'd14;
assign index[15] = neuron[15]==8'h00 ? 6'd0 : 6'd15;
assign index[16] = neuron[16]==8'h00 ? 6'd0 : 6'd16;
assign index[17] = neuron[17]==8'h00 ? 6'd0 : 6'd17;
assign index[18] = neuron[18]==8'h00 ? 6'd0 : 6'd18;
assign index[19] = neuron[19]==8'h00 ? 6'd0 : 6'd19;
assign index[20] = neuron[20]==8'h00 ? 6'd0 : 6'd20;
assign index[21] = neuron[21]==8'h00 ? 6'd0 : 6'd21;
assign index[22] = neuron[22]==8'h00 ? 6'd0 : 6'd22;
assign index[23] = neuron[23]==8'h00 ? 6'd0 : 6'd23;
assign index[24] = neuron[24]==8'h00 ? 6'd0 : 6'd24;
assign index[25] = neuron[25]==8'h00 ? 6'd0 : 6'd25;
assign index[26] = neuron[26]==8'h00 ? 6'd0 : 6'd26;
assign index[27] = neuron[27]==8'h00 ? 6'd0 : 6'd27;
assign index[28] = neuron[28]==8'h00 ? 6'd0 : 6'd28;
assign index[29] = neuron[29]==8'h00 ? 6'd0 : 6'd29;
assign index[30] = neuron[30]==8'h00 ? 6'd0 : 6'd30;
assign index[31] = neuron[31]==8'h00 ? 6'd0 : 6'd31;
assign index[32] = neuron[32]==8'h00 ? 6'd0 : 6'd32;
assign index[33] = neuron[33]==8'h00 ? 6'd0 : 6'd33;
assign index[34] = neuron[34]==8'h00 ? 6'd0 : 6'd34;
assign index[35] = neuron[35]==8'h00 ? 6'd0 : 6'd35;

endmodule