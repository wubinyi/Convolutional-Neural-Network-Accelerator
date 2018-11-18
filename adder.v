
// Company           :   tud
// Author            :   binyiwu
// E-Mail            :   <$ICPRO_EMAIL not set - insert email address>
//
// Filename          :   adder.v
// Project Name      :   sa_wubinyi
// Subproject Name   :   cnn_accelerator
// Description       :   <short description>
//
// Create Date       :   Tue Oct 10 09:56:42 2017
// Last Change       :   $Date$
// by                :   $Author$
//------------------------------------------------------------

module adder(
	clk,
	layer_reset,
	stage_finish,
	adder_en,
	addend,
	sum
	);

parameter AUGEND_BIT_WIDTH = 22+2;
parameter INI_AUGEND       = 24'h000000; 
parameter ADDEND_BIT_WIDTH = 16+4;

input                             clk;
input                             layer_reset;
input                             stage_finish;
input                             adder_en;
input      [ADDEND_BIT_WIDTH-1:0] addend;
output reg [AUGEND_BIT_WIDTH-1:0] sum;

always @(posedge clk or posedge layer_reset) begin
	if (layer_reset) begin
		sum <= INI_AUGEND;
	end
	else if (stage_finish) begin
		sum <= {{4{addend[ADDEND_BIT_WIDTH-1]}}, addend};
	end
	else if (adder_en) begin
		sum <= sum + {{4{addend[ADDEND_BIT_WIDTH-1]}}, addend};
	end

	// if (adder_en) begin
	// 	if (stage_finish) begin
	// 		sum <= {6'h00, addend};
	// 	end
	// 	else begin
	// 		sum <= sum + {6'h00, addend};
	// 	end
	// end
end

endmodule