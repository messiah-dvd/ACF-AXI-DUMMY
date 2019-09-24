`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/23/2019 08:22:57 PM
// Design Name: 
// Module Name: singleCFBlock
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


module singleCFBlock #(parameter BIN_SIZE = 8,parameter UA_DEPTH =3, parameter CNTR_SIZE = 32,parameter WORDSIZE=16,parameter ACF_WIDTH=16)(
    input CLK,
    input RST,
    input [CNTR_SIZE-1:0] cnt,
    input risingEdge,
    output [0:7][ACF_WIDTH-1:0] ACF,
    output updateACF
    );

wire [WORDSIZE-1:0] deltaT;//time between subsequent photons
wire calcUA; //indicator to update ACF


reg [0:BIN_SIZE][UA_DEPTH-1:0] UA_d,UA_q; //note: This is CORRECT, not BINSIZE-1 because we wish to include a zero delay element
reg [0:BIN_SIZE][ACF_WIDTH-1:0] ACF_d,ACF_q;
reg dataOut_d,dataOut_q;

assign updateACF = dataOut_q;
assign ACF[0:7] = ACF_q[BIN_SIZE-7:BIN_SIZE];
integer j;

always @(posedge CLK)begin
    if (RST) begin
        dataOut_d <= 0;
        dataOut_q <=0;
        UA_d[0:BIN_SIZE] <= '{default:'0};
        UA_q[0:BIN_SIZE] <= '{default:'0};
        ACF_d[0:BIN_SIZE] <= '{default:'0};
        ACF_q[0:BIN_SIZE] <= '{default:'0};
    end else begin
        if (calcUA) begin //Operate if new data incoming
            dataOut_d <=1; //indicate new Data
            for(j=0;j<=BIN_SIZE;j=j+1)begin
                ACF_d[j] <= UA_q[j]+ACF_q[j]; //update the ACF for previous photon
            end
            //Implement algorithm
            if (deltaT<BIN_SIZE)begin //if time shift is less than size of indexes
                for(j=BIN_SIZE;j>=0;j=j-1)begin
                    if (j>=deltaT) begin
                        UA_d[j] <= UA_q[j-deltaT]; //shift entries down by delta T
                    end else begin
                        UA_d[j] <= 0; //replace earlier entries with 0's
                    end
                end //End for loop
                UA_d[deltaT] <= UA_q[0]+1; //increment the current values
             end else begin
                UA_d[0:BIN_SIZE] <='{default:'0}; //all shifted out of frame
            end //end update on deltaT
           
        end else begin //If not new data:
            dataOut_d <=0; //no new data out
        end// update new data condition
        
        //Update flip flops
        ACF_q <= ACF_d;
        dataOut_q <= dataOut_d;
        UA_q <= UA_d;
    end //End reset conditional
end //End always loop


                    
//Instantiate DeltaT time stamper
TDC_DeltaT_1Chan #(.WORDSIZE(WORDSIZE),.CNTSIZE(CNTR_SIZE)) deltaTs(
    .CH1(risingEdge),
    .cnt(cnt),
    .clk(CLK),
    .rst(RST),
    .outData(deltaT),
    .wrEn(calcUA)
    );



    
endmodule
