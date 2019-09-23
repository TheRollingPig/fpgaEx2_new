`timescale 1ns/1ps

`include "apb_uart_defs.v"

module tbench();

//-----------------------------------------------------------------------------
// Local Parameters
//-----------------------------------------------------------------------------
	
	localparam 							CLK_PERIOD = 10;

//-----------------------------------------------------------------------------
// Signal declarations
//-----------------------------------------------------------------------------

	reg                  				CLK;        // primary clock
	reg                  				PORESETn;   // power-on-reset

	reg                            		psel;      // APB slave select
	reg [`APB_ADDR_WIDTH - 1:0] 		paddr;     // APB address
	reg                            		pwrite;    // APB write/read
	reg                            		penable;   // APB enable
	reg [`APB_DATA_WIDTH - 1:0] 		pwdata;    // APB write data bus
	wire [`APB_DATA_WIDTH - 1:0] 		prdata;    // APB read data bus
	reg [`APB_DATA_WIDTH - 1:0] 		prdata_temp;
	
	wire                          		wr_en;     // Write enable signal
	wire                           		wr_enx;    // Write enable extra signal
	wire                           		rd_en;     // Read enable signal
	wire [3:0] 							byte_en;   // Active byte lane signal
	wire [`APB_ADDR_WIDTH - 3:0]	 	reg_addr;  // Register address offset
	wire [`MAX_APB_DATA_WIDTH - 1:0] 	ipwdata;   // Internal write data bus
	wire [`MAX_APB_DATA_WIDTH - 1:0] 	iprdata;    // Internal read data bus
	
	reg 								sin;
	wire 								sout;
	
	wire 								intr;
	
	integer 							i;
//-----------------------------------------------------------------------------
// DUT
//-----------------------------------------------------------------------------

	/*
	// port defination
	module apb_uart
	(
		// APB bus bus interface
		input                            		pclk,      	// APB clock
		input                            		presetn,   	// APB reset
		input                            		psel,      	// APB slave select
		input [9:0] 							paddr,     	// APB address
		input                            		pwrite,    	// APB write/read
		input                            		penable,   	// APB enable
		input [31:0] 							pwdata,    	// APB write data bus
		output [31:0] 							prdata,    	// APB read data bus
		
		//UART interface
		output 									sout,		// UART serial output 
		output 									sin,		// UART serial input
		
		output									intr		// interrupt
	);
	*/
	
	apb_uart
	(
		// APB bus bus interface
		.pclk					(CLK),      	// APB clock
		.presetn				(PORESETn),   	// APB reset
		.psel					(psel),      	// APB slave select
		.paddr					(paddr),     	// APB address
		.pwrite					(pwrite),    	// APB write/read
		.penable				(penable),   	// APB enable
		.pwdata					(pwdata),    	// APB write data bus
		.prdata					(prdata),    	// APB read data bus
		
		//UART interface
		.sout					(sout),		// UART serial output 
		.sin					(sin),		// UART serial input
		
		.intr					(intr)		// interrupt
	);
	
//-----------------------------------------------------------------------------
// Stimulis
//-----------------------------------------------------------------------------
	
	initial
	begin
		psel = 1'b0;
		paddr = 0;
		pwrite = 1'b0;
		penable = 1'b0;
		pwdata = 0;
		prdata_temp = 0;
	
		# (CLK_PERIOD * 10);
		
		apb_write(`CR_OFFSET << 2, 32'h12345678);
	end

//-----------------------------------------------------------------------------
// Clock Source
//-----------------------------------------------------------------------------

	initial
	begin
		CLK = 1'b1;
		forever #(CLK_PERIOD/2) CLK = ~CLK;
	end

//-----------------------------------------------------------------------------
// Power-On-Reset
//-----------------------------------------------------------------------------

	initial
    begin
		PORESETn  = 1'b1;
		#1
		PORESETn  = 1'b0;    		// Asserted 3 cycles
		#(CLK_PERIOD * 3)
		PORESETn  = 1'b1;    		// De-asserted
    end
	
//-----------------------------------------------------------------------------
// Task & Function
//-----------------------------------------------------------------------------

	task apb_write
	(
		input [9:0]	    	paddr_in,
		input [31:0]		pwdata_in
	);
		
		begin
			@ (posedge CLK);
			# 1;
			paddr = paddr_in;
			pwrite = 1'b1;
			psel = 1'b1;
			pwdata = pwdata_in;
			
			@ (posedge CLK);
			# 1;
			penable = 1'b1;
			
			@ (posedge CLK);
			# 1;
			pwrite = 1'b0;
			psel = 1'b0;
			penable = 1'b0;
		end
		
	endtask
	
	task apb_read
	(
		input [9:0]	    paddr_in,
		output [31:0]	prdata_out
	);
		
		begin
			@ (posedge CLK);
			# 1;
			paddr = paddr_in;
			pwrite = 1'b0;
			psel = 1'b1;
			
			@ (posedge CLK);
			# 1;
			penable = 1'b1;
			prdata_out = prdata;
			
			@ (posedge CLK);
			# 1;
			pwrite = 1'b0;
			psel = 1'b0;
			penable = 1'b0;
		end
		
	endtask

//-----------------------------------------------------------------------------
// Runaway Simulation Timer
//-----------------------------------------------------------------------------

	//initial
    //begin
	//	# 500_000;
	//	$display ("** TEST KILLED ** (Time:%d)", $time);
	//	$finish(2);
    //end
	
	//initial
    //begin
	//	forever
	//	begin
	//		#1000
	//		$display ("** CURRENT TIME ** (Time:%d)", $time);
	//	end
    //end
	
	//initial begin
	//	$fsdbDumpfile("test.fsdb");
	//	$fsdbDumpvars(0,tbench);
	//end 

endmodule // tbench