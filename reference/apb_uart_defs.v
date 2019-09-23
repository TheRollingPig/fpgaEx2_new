//-----------------------------------------------------------------------------
// Description:
//				apb uart IP define file
//
// Modification:
//				
//-----------------------------------------------------------------------------

// Name:         APB_DATA_WIDTH
// Default:      32
// Values:       8 16 32
// 
// Width of APB data bus to which this component is attached. Note that 
// even though the data width can be set to 8, 16 or 32, only the lowest 8 
// data bits are ever used, since register access is on 32-bit boundaries. 
// All other bits are held at static 0.
`define APB_DATA_WIDTH 32


// Name:         MAX_APB_DATA_WIDTH
// Default:      32
// Values:       -2147483648, ..., 2147483647
// 
// Maximum allowed APB Data bus width.
`define MAX_APB_DATA_WIDTH 32

`define APB_ADDR_WIDTH 10

`define CR_OFFSET 0
