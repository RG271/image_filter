`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:        Richard D. Kaminsky, Ph.D.
// 
// Create Date:     8/1/2025 - 8/10/2025
// Design Name:     image_filter
// Module Name:     uat.v
// Project Name:
// Target Devices:  PYNQ-Z2
// Tool Versions:   Xilinx Vivado 2022.2
// Description:
// 
//      Universal Asynchronous Transmitter for sending bytes over a serial line
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module uat
#(
    parameter real CLK_FREQ  = 100e6,   // system clock's frequency in Hz (30e6 to 100e6)
    parameter real BAUD_RATE = 115200   // baud rate in bits/s (115200 to 921600)
)
(
    input        clk,       // system clock, whose frequency is CLK_FREQ
    output       tx,        // serial output
    output       busy,      // busy flag, which will be immediately asserted when valid is asserted and the Tx shift register is empty
    input [7:0]  data,      // the byte to send
    input        valid      // pulse to send data. This will be ignored if busy is 1.
);

    localparam [15:0]  INC  =  65536.0 * BAUD_RATE / CLK_FREQ;
    reg [15:0]   tmr  =  0;         // bit timer: counts up by INC and will roll over at each bit time -- approx. BAUD_RATE
    reg [8:0]    sh   =  9'h1FF;    // transmit shift register; shifts right
    reg [3:0]    cnt  =  0;         // number of bits to send (counts down from 10 to 0)
    
    assign       tx        =  sh[0];
    wire [16:0]  tmr_next  =  {1'b0, tmr} + INC;
    wire         _busy     =  cnt != 0;
    assign       busy      =  _busy | valid;

    always @(posedge clk) begin
        tmr  <=  tmr_next[15:0];
        if (!_busy && valid) begin
            sh   <=  {data, 1'b0};
            cnt  <=  10;
            tmr  <=  0;
        end
        if (_busy && tmr_next[16]) begin
            sh   <=  {1'b1, sh[8:1]};
            cnt  <=  cnt - 1; 
        end
    end

endmodule
