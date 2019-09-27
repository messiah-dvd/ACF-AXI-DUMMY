`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/23/2019 08:52:05 PM
// Design Name: 
// Module Name: TDC_DeltaT_1Chan
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


module TDC_DeltaT_1Chan #(parameter WORDSIZE=16,parameter CNTSIZE=38)(
    input CH1,
    input [CNTSIZE-1:0] cnt,
    input clk,
    input rst,
    output [WORDSIZE-1:0] outData,
    output wrEn
    );
    
    reg [CNTSIZE-1:0] last1_d,last1_q; //last time point registers
    reg wrEn_d,wrEn_q; //write enable registers
    reg [WORDSIZE-1:0] outData_d,outData_q; //output data registers
    
    //assign outputs
    
    assign outData = outData_q;
    assign wrEn = wrEn_q;
   
   always @(posedge clk) begin
        if (rst) begin
            wrEn_d <=0;
            last1_d <=0;
            outData_d <=0;
        end else begin
            wrEn_d <= CH1;
            if (CH1) begin
                last1_d <= cnt;
                outData_d <= cnt-last1_q;
            end   
        end
        outData_q <= outData_d;
        last1_q <= last1_d;
        wrEn_q <= wrEn_d;
    end


endmodule

