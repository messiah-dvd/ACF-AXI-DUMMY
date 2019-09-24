`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/25/2019 02:03:38 PM
// Design Name: 
// Module Name: SingleChannelACF_Top
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


module SingleChannelACF #(parameter BIN_SIZE = 8,parameter NUM_BINS = 20,parameter CNTR_SIZE=32)(//defaults are for A735 FPGA
  //DELTA_T0 is expressed in units of 100 ns as is T_ACQ
    input CLK,
    input rst,
    input CE,
    input CH_In, //signal from SPCM
    input initTx, //initialize data transmision to PC
    input [CNTR_SIZE-1:0] presentTime,
    output [NUM_BINS+33-1:0] acfEl,
    output wrEn
    );

wire risingEdge; //output from edge detector
wire ACFbusy; //indicates ACF is updating
wire [0:(1+NUM_BINS)*8-1][NUM_BINS+33-1:0] ACF;//main acf
wire busy;
reg toggle;
reg [31:0] photonCount_d,photonCount_q; //photon counts
reg wrEn_d,wrEn_q;  //write enable cues
reg [NUM_BINS+33-1:0] acfOut_d,acfOut_q; //FIFO output values
reg [7:0] outputCntr_d,outputCntr_q; //output counter


assign acfEl = acfOut_q;//acfOut_q;
assign wrEn = wrEn_q;
assign busy = (outputCntr_d>0);
//genrate counter wires and cf blocks
localparam UA_INTERCEPT = 3;
localparam ACA_INTERCEPT = 31;
genvar i;
    generate
        for(i = 0; i < NUM_BINS; i = i + 1) begin: acfBlocks
            wire [CNTR_SIZE-1-i:0] cntWire;
            assign cntWire = presentTime >> i;
            if (i==0)begin//use to be .UA_Depth(3+i)
                singleCFBlock #(.BIN_SIZE(2*BIN_SIZE),.UA_DEPTH(i+UA_INTERCEPT),.CNTR_SIZE(CNTR_SIZE-i),.WORDSIZE(16),.ACF_WIDTH(i+ACA_INTERCEPT)) acfBlock (
                                                .CLK(CLK),
                                                .RST(rst), 
                                                .cnt(cntWire),
                                                .risingEdge(risingEdge),
                                                .ACF(ACF[0:15]),
                                                .updateACF(ACFbusy)
                                                );
            end else begin //use to be .UA_DEPTH(3+i), .ACF_WIDTH(ACFWidth)
                singleCFBlock #(.BIN_SIZE(2*BIN_SIZE),.UA_DEPTH(i+UA_INTERCEPT),.CNTR_SIZE(CNTR_SIZE-i),.WORDSIZE(16),.ACF_WIDTH(i+ACA_INTERCEPT)) acfBlock (
                                            .CLK(CLK),
                                            .RST(rst),
                                            .cnt(cntWire),
                                            .risingEdge(risingEdge),
                                            .ACF(ACF[(i+1)*8:(i+2)*8-1]),
                                            .updateACF()
                                            );
                
            end    
        end
endgenerate


//Main block
always @(posedge CLK) begin
    if (rst) begin
        photonCount_d<=0;
        acfOut_d <= 0;
        wrEn_d <=0;
        outputCntr_d <=0;
    
    end else begin       
        //increment photon count
        if (risingEdge) begin
            photonCount_d<=photonCount_q+1;
        end
        
        if (initTx & !busy)begin //transmission initiated
            outputCntr_d <=1;
            acfOut_d <= photonCount_q;
            wrEn_d <=1;
            toggle <= 0;
        end else if (toggle & busy & outputCntr_q<BIN_SIZE*(NUM_BINS+1)+1) begin //do not transmit ACF while it is being updated
            acfOut_d = ACF[outputCntr_q-1];
            wrEn_d <=1;  
            outputCntr_d =outputCntr_q+1;
            toggle <=0;
       end else if (busy & !toggle & outputCntr_q<BIN_SIZE*(NUM_BINS+1)+1)begin
            wrEn_d <= 0;
            toggle <= 1;
       end else begin
            wrEn_d <=0;
            acfOut_d <= 0;
            outputCntr_d <=0;
        end
        //update flip-flops
        photonCount_q <= photonCount_d;
        outputCntr_q <=outputCntr_d;
        acfOut_q <= acfOut_d;
        wrEn_q <= wrEn_d;
        
    end //end reset
end //end always


//Instantiate Edge Detector
edgeDetector edgeDetect (
                    .async_sig(CH_In),
                    .clk(CLK),
                    .CE(CE),
                    .rise(risingEdge),
                    .fall() 
                    );
                    
                   
endmodule
