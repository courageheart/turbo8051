//////////////////////////////////////////////////////////////////////
////                                                              ////
////  Tubo 8051 cores common library Module                       ////
////                                                              ////
////  This file is part of the Turbo 8051 cores project           ////
////  http://www.opencores.org/cores/turbo8051/                   ////
////                                                              ////
////  Description                                                 ////
////  Turbo 8051 definitions.                                     ////
////                                                              ////
////  To Do:                                                      ////
////    nothing                                                   ////
////                                                              ////
////  Author(s):                                                  ////
////      - Dinesh Annayya, dinesha@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////

/**********************************************
      Web-bone , Read from Memory and Write to WebBone External Memory
**********************************************/

module wb_wr_mem2mem (

              rst_n               , 
              clk                 ,


    // Master Interface Signal
              mem_taddr           ,
              mem_addr            ,
              mem_empty           ,
              mem_aempty          ,
              mem_rd              , 
              mem_dout            ,
 
    // Slave Interface Signal
              wbo_din             , 
              wbo_taddr           , 
              wbo_addr            , 
              wbo_be              , 
              wbo_we              , 
              wbo_ack             ,
              wbo_stb             , 
              wbo_cyc             , 
              wbo_err             ,
              wbo_rty
         );


parameter D_WD    = 16; // Data Width
parameter BE_WD   = 2;  // Byte Enable
parameter ADR_WD  = 28; // Address Width
parameter TAR_WD  = 4;  // Target Width

// State Machine
parameter   IDLE = 0;
parameter   XFR  = 1;

input               clk      ;  // CLK_I The clock input [CLK_I] coordinates all activities 
                                // for the internal logic within the WISHBONE interconnect. 
                                // All WISHBONE output signals are registered at the 
                                // rising edge of [CLK_I]. 
                                // All WISHBONE input signals must be stable before the 
                                // rising edge of [CLK_I]. 
input               rst_n    ;  // RST_I The reset input [RST_I] forces the WISHBONE interface 
                                // to restart. Furthermore, all internal self-starting state 
                                // machines will be forced into an initial state. 

//------------------------------------------
// Stanard Memory Interface
//------------------------------------------
input [TAR_WD-1:0]  mem_taddr;  // target address 
input [15:0]        mem_addr;   // memory address 
input               mem_empty;  // memory empty 
input               mem_aempty; // memory empty 
output              mem_rd;     // memory read
input  [7:0]        mem_dout;   // memory read data

//------------------------------------------
// External Memory WB Interface
//------------------------------------------
output [TAR_WD-1:0] wbo_taddr ;
output              wbo_stb  ; // STB_O The strobe output [STB_O] indicates a valid data 
                               // transfer cycle. It is used to qualify various other signals 
                               // on the interface such as [SEL_O(7..0)]. The SLAVE must 
                               // assert either the [ACK_I], [ERR_I] or [RTY_I] signals in 
                               // response to every assertion of the [STB_O] signal. 
output              wbo_we   ; // WE_O The write enable output [WE_O] indicates whether the 
                               // current local bus cycle is a READ or WRITE cycle. The 
                               // signal is negated during READ cycles, and is asserted 
                               // during WRITE cycles. 
input               wbo_ack  ; // The acknowledge input [ACK_I], when asserted, 
                               // indicates the termination of a normal bus cycle. 
                               // Also see the [ERR_I] and [RTY_I] signal descriptions. 

output [ADR_WD-1:0] wbo_addr  ; // The address output array [ADR_O(63..0)] is used 
                               // to pass a binary address, with the most significant 
                               // address bit at the higher numbered end of the signal array. 
                               // The lower array boundary is specific to the data port size. 
                               // The higher array boundary is core-specific. 
                               // In some cases (such as FIFO interfaces) 
                               // the array may not be present on the interface. 

output [BE_WD-1:0] wbo_be     ; // Byte Enable 
                               // SEL_O(7..0) The select output array [SEL_O(7..0)] indicates 
                               // where valid data is expected on the [DAT_I(63..0)] signal 
                               // array during READ cycles, and where it is placed on the 
                               // [DAT_O(63..0)] signal array during WRITE cycles. 
                               // Also see the [DAT_I(63..0)], [DAT_O(63..0)] and [STB_O] 
                               // signal descriptions.

output            wbo_cyc    ; // CYC_O The cycle output [CYC_O], when asserted, 
                               // indicates that a valid bus cycle is in progress. 
                               // The signal is asserted for the duration of all bus cycles. 
                               // For example, during a BLOCK transfer cycle there can be 
                               // multiple data transfers. The [CYC_O] signal is asserted 
                               // during the first data transfer, and remains asserted 
                               // until the last data transfer. The [CYC_O] signal is useful 
                               // for interfaces with multi-port interfaces 
                               // (such as dual port memories). In these cases, 
                               // the [CYC_O] signal requests use of a common bus from an 
                               // arbiter. Once the arbiter grants the bus to the MASTER, 
                               // it is held until [CYC_O] is negated. 

output [D_WD-1:0] wbo_din;     // DAT_I(63..0) The data input array [DAT_I(63..0)] is 
                               // used to pass binary data. The array boundaries are 
                               // determined by the port size. Also see the [DAT_O(63..0)] 
                               // and [SEL_O(7..0)] signal descriptions. 

input             wbo_err; // ERR_I The error input [ERR_I] indicates an abnormal 
                           // cycle termination. The source of the error, and the 
                           // response generated by the MASTER is defined by the IP core 
                           // supplier in the WISHBONE DATASHEET. Also see the [ACK_I] 
                           // and [RTY_I] signal descriptions. 

input             wbo_rty; // RTY_I The retry input [RTY_I] indicates that the indicates 
                           // that the interface is not ready to accept or send data, and 
                           // that the cycle should be retried. When and how the cycle is 
                           // retried is defined by the IP core supplier in the WISHBONE 
                           // DATASHEET. Also see the [ERR_I] and [RTY_I] signal 
                           // descriptions. 

//-------------------------------------------
// Register Dec
//-------------------------------------------

reg [TAR_WD-1:0]     wbo_taddr ;
reg [ADR_WD-1:0]     wbo_addr  ;
reg                  wbo_stb   ;
reg                  wbo_we    ;
reg [BE_WD-1:0]      wbo_be    ;
reg                  wbo_cyc   ;
reg [D_WD-1:0]       wbo_din   ;
reg                  state     ;

wire      mem_rd    = wbo_ack;

always @(negedge rst_n or posedge clk) begin
   if(rst_n == 0) begin
      wbo_taddr <= 0;
      wbo_addr  <= 0;
      wbo_stb   <= 0;
      wbo_we    <= 0;
      wbo_be    <= 0;
      wbo_cyc   <= 0;
      wbo_din   <= 0;
      state     <= IDLE;
   end
   else begin
      case(state)
       IDLE: begin
          if(!mem_empty) begin
             wbo_taddr <= mem_taddr;
             wbo_addr  <= mem_addr[14:2];
             wbo_stb   <= 1'b1;
             wbo_we    <= 1'b1;
             wbo_be    <= 1 << mem_addr[1:0];
             wbo_cyc   <= 1;
             wbo_din   <= {mem_dout,mem_dout,mem_dout,mem_dout};
             state     <= XFR;
          end
       end
       XFR: begin
          if(wbo_ack) begin
             wbo_addr  <= mem_taddr;
             wbo_be    <= 1 << mem_addr[1:0];
             wbo_din   <= {mem_dout,mem_dout,mem_dout,mem_dout};
             if(mem_aempty) begin
                wbo_stb   <= 1'b0;
                wbo_cyc   <= 0;
                state     <= IDLE;
             end
          end 
       end
      endcase
   end
end



endmodule
