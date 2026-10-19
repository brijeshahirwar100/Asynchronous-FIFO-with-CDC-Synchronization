`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.10.2026 11:24:28
// Design Name: 
// Module Name: wptr_full
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module wptr_full#(parameter ADDRSIZE =4)
  (output reg wfull ,
   output [ADDRSIZE-1:0]waddr,
   output reg [ADDRSIZE:0]wptr,
   input [ADDRSIZE:0]wq2_rptr,
   input winc ,wclk ,wrst_n );
  
  reg [ADDRSIZE:0] wbin ;
  wire [ADDRSIZE:0]wbinnext ,wgraynext ;
  wire wfull_val ;
  
  //rbin , rptr ffs 
  
  always@(posedge wclk or negedge wrst_n )begin 
    if(!wrst_n) {wbin ,wptr} <= 0 ;
    else  {wbin ,wptr} <= {wbinnext ,wgraynext};
  end
  
  //update bin ,gnext ,raddr
  
  assign waddr = wbin[ADDRSIZE-1:0];
  
  assign wbinnext = wbin + (winc & ~wfull) ;
  
  assign wgraynext = (wbinnext>>1)^(wbinnext) ;
  
  //rempty
  
  assign wfull_val = (wgraynext == {~wq2_rptr[ADDRSIZE:ADDRSIZE-1] ,wq2_rptr[ADDRSIZE-2 :0] });
  
 always@(posedge wclk or negedge wrst_n)begin
   if(!wrst_n) wfull <= 1'b0;
    else wfull <= wfull_val ;
    
  end
  
endmodule
  
  
  
  