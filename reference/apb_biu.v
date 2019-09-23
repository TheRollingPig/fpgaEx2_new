// ------------------------------------------------------------------------
//
// Abstract: Apb bus interface module.
//           This module is intended for use with APB slave
//           macro-cells.  The module generates output signals
//           from the APB bus interface that are intended for use in
//           the register block of the macro-cell.
//
//        1: Generates the write enable (wr_en) and read
//           enable (rd_en) for register accesses to the macro-cell.
//
//        2: Decodes the address bus (paddr) to generate the active
//           byte lane signal (byte_en).
//
//        3: Strips the APB address bus (paddr) to generate the
//           register offset address output (reg_addr).
//
//        4: Registers APB read data (prdata) onto the APB data bus.
//           The read data is routed to the correct byte lane in this
//           module.
//
// -------------------------------------------------------------------
`include "apb_uart_defs.v"

module apb_biu
(
	// APB bus bus interface
	input                            		pclk,      // APB clock
	input                            		presetn,   // APB reset
	input                            		psel,      // APB slave select
	input [`APB_ADDR_WIDTH - 1:0] 			paddr,     // APB address
	input                            		pwrite,    // APB write/read
	input                            		penable,   // APB enable
	input [`APB_DATA_WIDTH - 1:0] 			pwdata,    // APB write data bus
	output reg [`APB_DATA_WIDTH - 1:0] 		prdata,    // APB read data bus

	// regfile interface
	output                          		wr_en,     // Write enable signal
	output                           		wr_enx,    // Write enable extra signal
	output                           		rd_en,     // Read enable signal
	output reg [3:0] 						byte_en,   // Active byte lane signal
	output [`APB_ADDR_WIDTH - 3:0]	 		reg_addr,  // Register address offset
	output reg [`MAX_APB_DATA_WIDTH - 1:0] 	ipwdata,   // Internal write data bus
	input [`MAX_APB_DATA_WIDTH - 1:0] 		iprdata    // Internal read data bus
);
 
   // --------------------------------------------
   // -- write/read enable
   //
   // -- Generate write/read enable signals from
   // -- psel, penable and pwrite inputs
   // --------------------------------------------
   assign wr_en  = psel &  penable &  pwrite;
   assign rd_en  = psel & !penable & !pwrite;

   // Used to perform writes on the previous cycle
   assign wr_enx = psel & !penable &  pwrite;

   
   // --------------------------------------------
   // -- Register address
   //
   // -- Strips register offset address from the
   // -- APB address bus
   // --------------------------------------------
   assign reg_addr = paddr[`APB_ADDR_WIDTH-1:2];

   
   // --------------------------------------------
   // -- APB write data
   //
   // -- ipwdata is zero padded before being
   //    passed through this block
   // --------------------------------------------
   always @(pwdata) begin : IPWDATA_PROC
      ipwdata = { `MAX_APB_DATA_WIDTH{1'b0} };
      ipwdata[`APB_DATA_WIDTH-1:0] = pwdata[`APB_DATA_WIDTH-1:0];
   end
   
   // --------------------------------------------
   // -- Set active byte lane
   //
   // -- This bit vector is used to set the active
   // -- byte lanes for write/read accesses to the
   // -- registers
   // --------------------------------------------
   always @(paddr) begin : BYTE_EN_PROC
      if(`APB_DATA_WIDTH == 8) begin
         case(paddr[1:0])
           2'b00   : byte_en = 4'b0001;
           2'b01   : byte_en = 4'b0010;
           2'b10   : byte_en = 4'b0100;
           default : byte_en = 4'b1000;
         endcase
      end else begin
         if(`APB_DATA_WIDTH == 16) begin
            case(paddr[1])
              1'b0    : byte_en = 4'b0011;
              default : byte_en = 4'b1100;
            endcase
         end else begin
            byte_en = 4'b1111;
         end
      end
   end
   

   // --------------------------------------------
   // -- APB read data.
   //
   // -- Register data enters this block on a
   // -- 32-bit bus (iprdata). The upper unused
   // -- bit have been zero padded before entering
   // -- this block.  The process below strips the
   // -- active byte lane(s) from the 32-bit bus
   // -- and registers the data out to the APB
   // -- read data bus (prdata).
   // --------------------------------------------
   always @(posedge pclk or negedge presetn) begin : PRDATA_PROC
      if(presetn == 1'b0) begin
         prdata <= { `APB_DATA_WIDTH{1'b0} };
      end else begin
         if(rd_en) begin
            if(`APB_DATA_WIDTH == 8) begin
               case(byte_en)
                 4'b0001 : prdata <= iprdata[7:0];
                 4'b0010 : prdata <= iprdata[15:8];
                 4'b0100 : prdata <= iprdata[23:16];
                 default : prdata <= iprdata[31:24];
               endcase
            end else begin
               if(`APB_DATA_WIDTH == 16) begin
                  case(byte_en)
                    4'b0011 : prdata <= iprdata[15:0];
                    default : prdata <= iprdata[31:16];
                  endcase
               end else begin
                  prdata <= iprdata;
               end
            end
         end
      end
   end
   
   
endmodule // DW_apb_biu