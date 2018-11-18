//parameter BANDWIDTH_INPUT  = 32;        // bandwidth of input/memory

// multiplier
parameter PRODUCT_BIT_WIDTH = 16;        // bit-width of product
parameter INI_PRODUCT       = 16'h0000;  // initial product
// adder
parameter AUGEND_BIT_WIDTH = 22;
parameter INI_AUGEND       = 22'h000000; 
parameter ADDEND_BIT_WIDTH = 16;
// mac
parameter INI_ACCUMULATOR  = 22'h000000; 

parameter INPUT_BIT_WIDTH   = 8;         // bit-width of neuron-input: 8-bit
parameter OUTPUT_BIT_WIDTH  = 16+6;      // bit-width of output register: sum of 36 number,increase bit-width with 6-bits, total 16+6
parameter BYTES_OF_REG      = 36;        // number of neuron-input: 36 --> max. filter size: 6 x 6
parameter REG_BITS          = 6;
//parameter BYTES_OF_WEIGHT   = 36 * 16;   // number of weight(all filters): 16 filters, each filter with 36 weights
parameter NUM_OF_CHANNELS   = 16;        // channels in each subunit
parameter NUM_OF_FILTERS    = 16;        // number of output: 16, because of 16 filters
parameter FILTER_BITS       = 4;         // use "FILTER_BITS" to represent filters 
parameter ITER_BIT_WIDTH    = 6;         // 36 register, need 6-bit to index them
parameter INI_8_BITS        = 8'h00;
parameter INI_6_BITS        = 6'h00;