`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:        Richard D. Kaminsky, Ph.D.
// 
// Create Date:     8/1/2025
// Design Name:     image_filter
// Module Name:     uar.v
// Project Name:
// Target Devices:  PYNQ-Z2
// Tool Versions:   Xilinx Vivado 2022.2
// Description:
// 
//      Universal Asynchronous Receiver for receiving bytes over a serial line
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module uar
#(
    parameter real CLK_FREQ  = 100e6,       // system clock's frequency in Hz (30e6 to 100e6)
    parameter real BAUD_RATE = 115000       // baud rate in bits/s (115200 to 921600)
)
(
    input             clk,                  // system clock, whose frequency is CLK_FREQ
    input             rx,                   // serial input which is asynchronous to clk
    output reg [7:0]  data          = 0,    // the last byte received
    output reg        valid         = 0,    // pulses when a valid byte (start and stop bits are correct) is received
    output reg        framing_error = 0     // pulses when an invalid byte (start or stop bit is wrong) is received
);


    // Synchronize rx to clk
    // out: _rx

    (* ASYNC_REG = "TRUE" *) reg rx_sync = 1;
    reg _rx = 1;

    always @(posedge clk) begin
        _rx      <=  rx_sync;
        rx_sync  <=  rx;
    end


    // Receiver

    localparam [15:0]  INC  =  65536.0 * BAUD_RATE / CLK_FREQ;
    reg [15:0]   tmr  =  0;     // bit timer: counts up by INC and will roll over at each bit time -- approx. BAUD_RATE
    wire [16:0]  tmr_next  =  {1'b0, tmr} + INC;
    reg          ce   =  0;     // clock enable which pulses each bit time -- approx. BAUD_RATE

    localparam  STATE_IDLE       =  0,
                STATE_RECEIVING  =  1;

    reg         state  =  STATE_IDLE;
    reg [9:0]   sh     =  10'h3FF;      // receive shift register; shifts right
    reg [3:0]   cnt    =  0;            // number of bits received (counts up from 0 to 10)

    always @(posedge clk) begin
    
        valid          =  0;
        framing_error  =  0;

        // Baud Rate Generator
        tmr  <=  tmr_next[15:0];
        ce   <=  tmr_next[16]; 

        // Rx State Machine
        case (state)

            STATE_IDLE:
                begin
                    tmr  <=  16'h8000 + INC;
                    ce   <=  0;
                    sh   =   10'h3FF;
                    cnt  <=  0;
                    if (_rx == 0)  state <= STATE_RECEIVING;
                end

            STATE_RECEIVING:
                if (ce) begin
                    sh   =   {_rx, sh[9:1]};
                    cnt  <=  cnt + 1;
                    if (cnt == 10 - 1) begin
                        data           <=  sh[8:1];
                        valid          =   sh[9] & ~sh[0];
                        framing_error  =   !valid;
                        state <= STATE_IDLE;
                    end
                end

        endcase
    end

endmodule
