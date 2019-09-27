`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/07/2019 02:27:35 PM
// Design Name: 
// Module Name: edgeDetector
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

module edgeDetector (
                    input async_sig,
                    input smpl_clk,
                    input CE,
                    output reg rise,
                    output reg fall);

  reg [1:3] resync;

  always @(posedge smpl_clk)
  begin
    if (CE) begin
        // detect rising and falling edges.
        rise <= resync[2] & !resync[3];
        fall <= resync[3] & !resync[2];
        // update history shifter.
        resync <= {async_sig , resync[1:2]};
    end
  end

endmodule
