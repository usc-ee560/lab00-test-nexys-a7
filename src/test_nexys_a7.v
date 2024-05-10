/*
File     : test_top.v (based on test_nexys3_verilog.v)
Author of the original test_nexys3_verilog.v code  : Gandhi Puvvada and Mark Redekopp
Ported from Nexys-3 to Nexys-4 by: Siqi Sun <siqisun@usc.edu> and Runyi Li <runyili@usc.edu>
Revision  : 1.0
Date of the original code: Feb 14, 2008, Aug 29, 2011, Jan 10, 2011
Date of porting: 5/14/2019
Further revision: 5/09/2024 - Mark Redekopp - modified
  for Artix-7 board and updates naming conventions for top-level I/O
*/
/* 
Copyright (c) 2019,2024 by Gandhi Puvvada and Mark Redekopp, EE-Systems, USC, Los Angeles, CA 90089
USC students are encouraged to copy sections of this code freely.
They need not acknowledge or state that they have extracted those sections.
*/

/*
This is a verilog module for testing the Artix-7 board from Digilent Inc.

The program does the following:

btnC (the Center button) acts as a reset to our test system.

The dot-points on the 8 SSDs flash at a slow rate.

The 16-bit value set by the switches (sw[15]-sw[0]) is displayed
on the 7-seg. displays. The true value of the switches is displayed 
on right four 7-segment displays and the complement of the switches
on the left four 7-segment displays.
The 16 LEDs (ld[15]-ld[0]) display a walking-led pattern. However when one or more
buttons (btnL, btnU, btnD, btnR) is/are pressed, corresponding LEDs glow
and the walking LED display is temporarily suspended.
btnL controls LD15, LD14, LD13, and LD12.
btnU controls LD11, LD10, LD9,  and LD8.
btnD controls LD7,  LD6,  LD5,  and LD4.
btnL controls LD3,  LD2,  LD1,  and LD0.

Make sure to use the test_nexys4_verilog.xdc 
This file contains pin info.

When you setup the project on webpack_ISE or webpack_Vivado,
selct the following project properties:
Family: Artix-7
Device: XC7A100T
Package: CSG324
Speed grade: -1 (i.e. -1C; C=Comercial Temperature)

On the package of the Artix-7 FPGA chip on the Nexys-4 board, the inscriptions read
XC7A100T
CSG324ACX1345
D4635423A
1C
https://www.xilinx.com/support/documentation/data_sheets/ds197-xa-artix7-overview.pdf
https://www.xilinx.com/support/documentation/data_sheets/ds181_Artix_7_Data_Sheet.pdf
https://www.xilinx.com/support/documentation/selection-guides/7-series-product-selection-guide.pdf

------------------------------------------------------------------------------
 */
/*
Some naming conventions we will follow:

- module names and file names: all lower case
- Input and Output variables start with an Upper case alphabet.
- Internal variables start with lower case alphabet.
- Active low signals have a _b suffix. 
- Parameters are all in UPPER CASE
- Macros (`define) also are in all UPPER CASE
*/

module test_nexys_a7   
(   
    // Switches
    input [15:0]      sw,

    // Pushbuttons
    input             btnC,
    input             btnL,
    input             btnU,
    input             btnR,
    input             btnD,

    // LEDs
    output [15:0]     ld,

    // 7 Segment Display control ca=bit6, ..., cg=bit0 
    output  [6:0]     segs,

    output  [7:0]     an,
    output            dp,

    // UART RS-232 signals
    output            txd_pin,
    input             rxd_pin,

    output            qspi_csn,
    // Clock and reset button (if necessary)
    input             btn_rstb,
    input             clk_port);
									
  
// local signal declaration

  wire         reset;
  wire         board_clk;
  wire [3:0]   slow_bits;      	// to control walking led pattern
  wire [2:0]   sev_seg_clk; 		// to control SSD scanning
  reg  [27:0]  divclk;
  wire [3:0]   ssd_dig[7:0]; 	// 7-segment display digits
//------------ 

  // Disable the three memories so that they do not interfere with the rest of the design.
  assign qspi_csn = 1'b1;

  // Default / unused assignments
  assign txd_pin = 1'b0;

// CLOCK DIVISION

	// The clock division circuitary works like this:
	//
	// ClkPort ---> [BUFGP1] ---> board_clk
	// board_clk ---> [clock dividing counter] ---> divclk
	// divclk ---> [constant assignment] ---> sys_clk;
	BUFGP BUFGP1 (board_clk, clk_port); 	

// As the ClkPort signal travels throughout our design,
// it is necessary to provide global routing to this signal. 
// The BUFGPs buffer these input ports and connect them to the global 
// routing resources in the FPGA.

	assign reset = btnC;

//------------
	// Our clock is too fast (100MHz) for SSD scanning
	// create a series of slower "divided" clocks
	// each successive bit is 1/2 frequency
  always @(posedge board_clk, posedge reset) 	
    begin							
        if (reset)
		      divclk <= 0;
        else
		      divclk <= divclk + 1'b1;
    end
//------------
  assign dp = divclk[25]; // The dot point on each SSD flashes 
      // divclk[25] (~1.5Hz) = (100MHz / 2**26)	
			// count the number of flashes for a minute, you should get about 90
  
  assign sev_seg_clk  = divclk[16:14]; // 7 segment display scanning is completed 
						 // every divclk[17] (~381Hz) = (100MHz / 2 **18)
  
  assign slow_bits  =  divclk[26:23];

//------------         
// Buttons and LEDs

  wire         button_pressed;

  assign button_pressed = btnL | btnU | btnD | btnR ;

  reg   [15:0]   walking_leds;
    
  assign ld =	button_pressed ? {btnL, btnL, btnL, btnL, btnU, btnU, btnU, btnU, btnD, btnD, btnD, btnD, btnR, btnR, btnR, btnR} :
                       ( divclk[27] ? 16'b0000000000000000 : walking_leds );
  // Notice that when divclk[27] is zero, the slow_bits (i.e. divclk[26:24])
  // go through a complete sequence of 000-111.

  always @ (slow_bits)
    begin
      case (slow_bits)
        4'b0000: walking_leds = 16'b1000000000000001 ;
        4'b0001: walking_leds = 16'b0100000000000010 ;
        4'b0010: walking_leds = 16'b0010000000000100 ;
        4'b0011: walking_leds = 16'b0001000000001000 ;
        4'b0100: walking_leds = 16'b0000100000010000 ;
        4'b0101: walking_leds = 16'b0000010000100000 ;
        4'b0110: walking_leds = 16'b0000001001000000 ;
        4'b0111: walking_leds = 16'b0000000110000000 ;
    		4'b1000: walking_leds = 16'b0000000110000000 ;
        4'b1001: walking_leds = 16'b0000001001000000 ;
        4'b1010: walking_leds = 16'b0000010000100000 ;
        4'b1011: walking_leds = 16'b0000100000010000 ;
        4'b1100: walking_leds = 16'b0001000000001000 ;
        4'b1101: walking_leds = 16'b0010000000000100 ;
        4'b1110: walking_leds = 16'b0100000000000010 ;
        4'b1111: walking_leds = 16'b1000000000000001 ;
        default: walking_leds = 16'bXXXXXXXXXXXXXXXX ;
      endcase
    end
//------------
// SSD (Seven Segment Display)

reg  [3:0] ssd;
reg  [7:0] an_int;

assign an = an_int;
// assign an[0]	= ~(~(sev_seg_clk[2]) && ~(sev_seg_clk[1]) && ~(sev_seg_clk[0]));  // when sev_seg_clk = 000
// assign an[1]	= ~(~(sev_seg_clk[2]) && ~(sev_seg_clk[1]) &&  (sev_seg_clk[0]));  // when sev_seg_clk = 001
// assign an[2]	= ~(~(sev_seg_clk[2]) &&  (sev_seg_clk[1]) && ~(sev_seg_clk[0]));  // when sev_seg_clk = 010
// assign an[3]	= ~(~(sev_seg_clk[2]) &&  (sev_seg_clk[1]) &&  (sev_seg_clk[0]));  // when sev_seg_clk = 011
// assign an[4]	= ~( (sev_seg_clk[2]) && ~(sev_seg_clk[1]) && ~(sev_seg_clk[0]));  // when sev_seg_clk = 100
// assign an[5]	= ~( (sev_seg_clk[2]) && ~(sev_seg_clk[1]) &&  (sev_seg_clk[0]));  // when sev_seg_clk = 101
// assign an[6]	= ~( (sev_seg_clk[2]) &&  (sev_seg_clk[1]) && ~(sev_seg_clk[0]));  // when sev_seg_clk = 110
// assign an[7]	= ~( (sev_seg_clk[2]) &&  (sev_seg_clk[1]) &&  (sev_seg_clk[0]));  // when sev_seg_clk = 111

assign ssd_dig[0] = {   sw[3],   sw[2],   sw[1],   sw[0]};
assign ssd_dig[1] = {   sw[7],   sw[6],   sw[5],   sw[4]};
assign ssd_dig[2] = {  sw[11],  sw[10],   sw[9],   sw[8]};
assign ssd_dig[3] = {  sw[15],  sw[14],  sw[13],  sw[12]};
assign ssd_dig[4] = {  ~sw[3],  ~sw[2],  ~sw[1],  ~sw[0]};
assign ssd_dig[5] = {  ~sw[7],  ~sw[6],  ~sw[5],  ~sw[4]};
assign ssd_dig[6] = { ~sw[11], ~sw[10],  ~sw[9],  ~sw[8]};
assign ssd_dig[7] = { ~sw[15], ~sw[14],  ~sw[13], ~sw[12]};

always @ (sev_seg_clk, ssd_dig)
begin
    an_int = 8'b11111111;
    ssd = 7'b0000000;

    if(sev_seg_clk[2:0] == 3'b000) begin
      an_int[0] = 1'b0;
      ssd = ssd_dig[0];
    end
    else if(sev_seg_clk[2:0] == 3'b001) begin
      an_int[1] = 1'b0;
      ssd = ssd_dig[1];
    end
    else if(sev_seg_clk[2:0] == 3'b010) begin
      an_int[2] = 1'b0;
      ssd = ssd_dig[2];
    end
    else if(sev_seg_clk[2:0] == 3'b011) begin
      an_int[3] = 1'b0;
      ssd = ssd_dig[3];
    end
    else if(sev_seg_clk[2:0] == 3'b100) begin
      an_int[4] = 1'b0;
      ssd = ssd_dig[4];
    end
    else if(sev_seg_clk[2:0] == 3'b101) begin
      an_int[5] = 1'b0;
      ssd = ssd_dig[5];
    end
    else if(sev_seg_clk[2:0] == 3'b110) begin
      an_int[6] = 1'b0;
      ssd = ssd_dig[6];
    end
    else if(sev_seg_clk[2:0] == 3'b111) begin
      an_int[7] = 1'b0;
      ssd = ssd_dig[7];
    end
end

reg    [6:0]  segs_int;
assign        segs = segs_int; 
//
// Following is Hex-to-SSD conversion. 
always @ (ssd)
    begin
      case (ssd)
        4'b0000: segs_int = 7'b0000001 ; // 0
        4'b0001: segs_int = 7'b1001111 ; // 1
        4'b0010: segs_int = 7'b0010010 ; // 2
        4'b0011: segs_int = 7'b0000110 ; // 3
        4'b0100: segs_int = 7'b1001100 ; // 4
        4'b0101: segs_int = 7'b0100100 ; // 5
        4'b0110: segs_int = 7'b0100000 ; // 6
        4'b0111: segs_int = 7'b0001111 ; // 7
        4'b1000: segs_int = 7'b0000000 ; // 8
        4'b1001: segs_int = 7'b0000100 ; // 9
        4'b1010: segs_int = 7'b0001000 ; // A
        4'b1011: segs_int = 7'b1100000 ; // b
        4'b1100: segs_int = 7'b0110001 ; // C
        4'b1101: segs_int = 7'b1000010 ; // d
        4'b1110: segs_int = 7'b0110000 ; // E
        4'b1111: segs_int = 7'b0111000 ; // F    
        default: segs_int = 7'bXXXXXXX ; // default is actually not needed as we covered all cases
      endcase
    end


// Notice that, when the reset button (btnC) is pressed, the divclk counter 
// is held in the reset (cleared) state and scanning stops. Only An0 anode will be active and 
// the right-most SSD displays SSD0 in much brighter fashion (4 times brighter)!
//------------
endmodule