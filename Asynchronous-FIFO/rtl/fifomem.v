`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.10.2026 11:22:19
// Design Name: 
// Module Name: fifomem
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


module fifomem#(parameter DATASIZE = 8,parameter ADDRSIZE = 4)
  (output [DATASIZE-1:0] rdata ,
   input [DATASIZE-1:0] wdata,
   input [ADDRSIZE-1:0] raddr ,waddr,
   input wclken ,wclk ,wfull);
  
  localparam DEPTH = 1<< ADDRSIZE ;
  
  reg [DATASIZE-1 :0] mem [0:DEPTH-1] ;
  
  assign rdata = mem[raddr];
  
  always@(posedge wclk) begin 
    if(wclken&& !wfull)
      mem[waddr] <= wdata ;
 
  end
  
endmodule
