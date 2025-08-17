`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:        Richard D. Kaminsky, Ph.D.
// 
// Create Date:     8/17/2025
// Design Name:     image_filter
// Module Name:     dcm_tester.v
// Project Name:
// Target Devices:  PYNQ-Z2
// Tool Versions:   Xilinx Vivado 2022.2
// Description:
//
//      This module generates test telemetry packets for testing the Debug Capture Module.
//      Every 1 second a 2 32-bit word packet is generated (1 header/timestamp word + 1 data word).
//      The data word is {16'hABCD, <16-bit-counter>}
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module dcm_tester
#(
    parameter real CLK_FREQ  =  100e6   // system clock's frequency in Hz
)
(
    input               clk,            // system clock (CLK_FREQ Hz)

    // Telemetry Out
    output reg          req  =  0,      // request port access
    input               ack,            // port-access-granted flag, when 1 send tele packet (will remain 1 until req0 transitions to 0)
    input               nak,            // port-access-not-granted flag, when 1 discard tele packet (will remain 1 until req0 transitions to 0)
    output reg [31:0]   dout,           // data
    output reg          valid,          // data-valid flag
    input      [25:0]   us_time         // current time in microseconds modulo 2**26
);

    // Function for Computing an Unsigned Integer's Width in Bits
    // in: value = unsigned integer (>=0)
    // out: returns value's width in bits = floor(log2(value))+1 if value!=0, 0 if value=0
    function automatic integer width(input integer value);
        integer v;
        begin
            v = value;
            if (v <= 0)  width = 1;
            else
                for (width=0; v!=0; width=width+1)  v = v>>1;
        end
    endfunction


    // 1s Period Strobe
    // out: strobe
    localparam real    STROBE_PERIOD = 1.0;                         // strobe's period in seconds
    localparam integer STROBE_TOP = CLK_FREQ / STROBE_PERIOD - 1,   // clk divisor - 1 for generating 100 Hz (>=1)
                       STROBE_WIDTH = width( STROBE_TOP );          // width of timer register in bits
    reg [STROBE_WIDTH-1:0]  strobe_tmr  =  0;              // up counter (0 .. STROBE_TOP)
    reg                     strobe      =  0;
    always @(posedge clk) begin
        strobe_tmr  <=  strobe  ?  0  :  strobe_tmr + 1;
        strobe      <=  strobe_tmr == STROBE_TOP - 1;
    end


    // Telemetry Generator State Machine

    localparam [1:0]
        STATE_INIT      =   0,      // initialize
        STATE_REQ       =   1,      // request DCM access
        STATE_OUT1      =   2;      // output first data word (which follows the header/timestamp word)

    reg [1:0]  state  =  STATE_INIT;   // arbiter state machine's state
    reg [15:0] iter   =  0;

    always @(posedge clk) begin
    
        dout   <=  0;
        valid  <=  0;

        case (state)
            STATE_INIT:     begin
                                req <= 0;
                                if (strobe) begin
                                    req <= 1;
                                    state <= STATE_REQ;
                                end
                            end

            STATE_REQ:      if (ack) begin
                                dout   <=  {6'd0, us_time};
                                valid  <=  1;
                                state  <=  STATE_OUT1;
                            end
                            else if (nak)  state <= STATE_INIT;

            STATE_OUT1:     begin
                                dout   <=  {16'hABCD, iter};
                                valid  <=  1;
                                iter   <=  iter + 1;
                                state  <=  STATE_INIT;
                            end

            default:        state <= STATE_INIT;
        endcase

    end

endmodule
