`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:        Richard D. Kaminsky, Ph.D.
// 
// Create Date:     7/31/2025 - 8/11/2025
// Design Name:     image_filter
// Module Name:     debug_capture_module.v
// Project Name:
// Target Devices:  PYNQ-Z2
// Tool Versions:   Xilinx Vivado 2022.2
// Description:
//
//      This module captures telemetry packets from multiple modules.  It manages a
//      64K x 32b buffer to which the packets are appended.  Each packet should begin with
//      a 32-bit word in which bits 31:26 is the packet type (which indicates the packet's
//      source and length) and bits 25:0 is a timestamp in microseconds modulo 2**26.
//
//      Address:
//        0 .. 24'h00FFFF   data      ro     Buffer, an array of 2**16 uint32_t words
//
//        24'h800000        control   rw     Control register
//
//              Bits  Name   Description
//              ----  -----  -------------------------------------------------------------------------------------
//              31:2   --    Reserved (Always 0)
//              1     dump   Write a 1 to dump the buffer to the Debug Serial Port.  When that 1 is written, the
//                             buffer's length N is latched, N is then transmitted as a 32-bit word (little endian)
//                             followed by the buffer's first N 32-bit words.  Lastly this flag will reset to 0.
//              0     clear  Write a 1 to clear the buffer.  If a telemetry packet is being appended, the
//                             clear operation will happen after the append operation completes.  When done,
//                             this flag will reset to 0.
//
//        24'h800001        length    ro     Number of 32-bit words in the buffer (0 .. 1<<ADDR_WIDTH)
//
//        24'h800002        size      ro     Buffer's capacity in 32-bit words (always 1<<ADDR_WIDTH)
//
//        24'h800003        dec0      rw     Telemetry port 0's decimation - 1 (0..65534, or 65535 to discard all packets; default is 65535)
//
//        24'h800004        dec1      rw     Telemetry port 1's decimation - 1 (0..65534, or 65535 to discard all packets; default is 65535)
//
//        24'h800005        dec2      rw     Telemetry port 2's decimation - 1 (0..65534, or 65535 to discard all packets; default is 65535)
//
//        24'h800006        dec3      rw     Telemetry port 3's decimation - 1 (0..65534, or 65535 to discard all packets; default is 65535)
//
//        24'h800007        dec4      rw     Telemetry port 4's decimation - 1 (0..65534, or 65535 to discard all packets; default is 65535)
//
//        24'h800008        dec5      rw     Telemetry port 5's decimation - 1 (0..65534, or 65535 to discard all packets; default is 65535)
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module debug_capture_module
#(
    parameter real CLK_FREQ   =  100e6,    // frequency of clock s00_axi_aclk (Hz)
    parameter real BAUD_RATE  =  921600    // Debug Serial Port's baud rate in bits/s (115200 .. 921600)
)
(
    input               clk,

    // Current time in microseconds modulo 2**26
    input      [25:0]   us_time,

    // DAP interface
    input      [23:0]   addr,
    input      [31:0]   wdata,
    output reg [31:0]   rdata = 0,
    input               we,
    input               re,
    
    // DAP serial interface
    output              tx,             // serial output for dumping the buffer; is 1 when idle

    // Telemetry port 0
    input               req0,           // request port access
    output reg          ack0 = 0,       // port-access-granted flag, when 1 send tele packet (will remain 1 until req0 transitions to 0)
    output reg          nak0 = 0,       // port-access-not-granted flag, when 1 discard tele packet (will remain 1 until req0 transitions to 0)
    input      [31:0]   din0,           // data
    input               valid0,         // data-valid flag
    output     [25:0]   us_time0,       // current time in microseconds modulo 2**26

    // Telemetry port 1
    input               req1,           // request port access
    output reg          ack1 = 0,       // port-access-granted flag, when 1 send tele packet (will remain 1 until req0 transitions to 0)
    output reg          nak1 = 0,       // port-access-not-granted flag, when 1 discard tele packet (will remain 1 until req0 transitions to 0)
    input      [31:0]   din1,           // data
    input               valid1,         // data-valid flag
    output     [25:0]   us_time1,       // current time in microseconds modulo 2**26

    // Telemetry port 2
    input               req2,           // request port access
    output reg          ack2 = 0,       // port-access-granted flag, when 1 send tele packet (will remain 1 until req0 transitions to 0)
    output reg          nak2 = 0,       // port-access-not-granted flag, when 1 discard tele packet (will remain 1 until req0 transitions to 0)
    input      [31:0]   din2,           // data
    input               valid2,         // data-valid flag
    output     [25:0]   us_time2,       // current time in microseconds modulo 2**26

    // Telemetry port 3
    input               req3,           // request port access
    output reg          ack3 = 0,       // port-access-granted flag, when 1 send tele packet (will remain 1 until req0 transitions to 0)
    output reg          nak3 = 0,       // port-access-not-granted flag, when 1 discard tele packet (will remain 1 until req0 transitions to 0)
    input      [31:0]   din3,           // data
    input               valid3,         // data-valid flag
    output     [25:0]   us_time3,       // current time in microseconds modulo 2**26

    // Telemetry port 4
    input               req4,           // request port access
    output reg          ack4 = 0,       // port-access-granted flag, when 1 send tele packet (will remain 1 until req0 transitions to 0)
    output reg          nak4 = 0,       // port-access-not-granted flag, when 1 discard tele packet (will remain 1 until req0 transitions to 0)
    input      [31:0]   din4,           // data
    input               valid4,         // data-valid flag
    output     [25:0]   us_time4,       // current time in microseconds modulo 2**26

    // Telemetry port 5
    input               req5,           // request port access
    output reg          ack5 = 0,       // port-access-granted flag, when 1 send tele packet (will remain 1 until req0 transitions to 0)
    output reg          nak5 = 0,       // port-access-not-granted flag, when 1 discard tele packet (will remain 1 until req0 transitions to 0)
    input      [31:0]   din5,           // data
    input               valid5,         // data-valid flag
    output     [25:0]   us_time5        // current time in microseconds modulo 2**26
);

    assign  us_time0  =  us_time;
    assign  us_time1  =  us_time;
    assign  us_time2  =  us_time;
    assign  us_time3  =  us_time;
    assign  us_time4  =  us_time;
    assign  us_time5  =  us_time;


    // Decimation Counters

    reg [15:0]  dec0     =  ~0;         // telemetry stream 0's decimation: every dec0 + 1 packet is accepted (0..65534, or 65535 to discard all packets)
    reg [15:0]  dec0cnt  =  0;          // decimation counter (0 .. dec0)

    reg [15:0]  dec1     =  ~0;         // telemetry stream 1's decimation: every dec1 + 1 packet is accepted (0..65534, or 65535 to discard all packets)
    reg [15:0]  dec1cnt  =  0;          // decimation counter (0 .. dec1)

    reg [15:0]  dec2     =  ~0;         // telemetry stream 2's decimation: every dec2 + 1 packet is accepted (0..65534, or 65535 to discard all packets)
    reg [15:0]  dec2cnt  =  0;          // decimation counter (0 .. dec2)

    reg [15:0]  dec3     =  ~0;         // telemetry stream 3's decimation: every dec3 + 1 packet is accepted (0..65534, or 65535 to discard all packets)
    reg [15:0]  dec3cnt  =  0;          // decimation counter (0 .. dec3)

    reg [15:0]  dec4     =  ~0;         // telemetry stream 4's decimation: every dec4 + 1 packet is accepted (0..65534, or 65535 to discard all packets)
    reg [15:0]  dec4cnt  =  0;          // decimation counter (0 .. dec4)

    reg [15:0]  dec5     =  ~0;         // telemetry stream 5's decimation: every dec5 + 1 packet is accepted (0..65534, or 65535 to discard all packets)
    reg [15:0]  dec5cnt  =  0;          // decimation counter (0 .. dec5)


    // 128K x 32b Telemetry Buffer

    localparam integer ADDR_WIDTH = 16;   // buffer size is 1<<ADDR_WIDTH  (1..31)

    reg  [ADDR_WIDTH:0]    count  =  0;                   // number of 32-bit words in the buffer (0 .. 1<<ADDR_WIDTH)
    wire                   full   =  count[ADDR_WIDTH];   // buffer-is-full flag

    reg                    wea    =  0;
    reg  [ADDR_WIDTH-1:0]  addra  =  0;
    reg  [31:0]            dina   =  0;

    reg  [ADDR_WIDTH-1:0]  addrb  =  0;
    wire [31:0]            doutb;

    blk_mem_64K_32b blk_mem_64K_32b_i (

      // Port A (write only)
      .clka(  clk   ),    // input wire clka
      .wea(   wea   ),    // input wire [0 : 0] wea
      .addra( addra ),    // input wire [ADDR_WIDTH-1:0] addra
      .dina(  dina  ),    // input wire [31 : 0] dina

      // Port B (read only)
      .clkb(  clk   ),    // input wire clkb
      .addrb( addrb ),    // input wire [ADDR_WIDTH-1:0] addrb
      .doutb( doutb )     // output wire [31 : 0] doutb
    );


    // Debug Serial Interface
    // For transmitting the buffer out the Debug Serial Port

    wire        uat32_busy;
    reg [31:0]  uat32_data   =  0;
    reg         uat32_valid  =  0;

    uat32 #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE))  uat32_i (
        .clk(    clk          ),
        .tx(     tx           ),
        .busy(   uat32_busy   ),
        .data(   uat32_data   ),
        .valid(  uat32_valid  )
    );
    

    // DAP Interface

    reg                 clear       =  0;   // clear-buffer strobe: pulses for 1 clk cycle to indicate buffer should be cleared after the current tele packet, if any
    reg                 clearing    =  0;   // clear-buffer-pending flag
    reg                 dump        =  0;   // start dumping strobe: pulses for 1 clk cycle to indicate the buffer should be dumped (i.e., transmitted out the serial port)
    reg                 dumping     =  0;   // buffer-is-being-transmitted-out-the-serial-port flag
    reg [ADDR_WIDTH:0]  dump_count  =  0;   // number of 32-bit words left to send (0 .. 1<<ADDR_WIDTH)
    wire dump_count_zero  =  dump_count == 0;

    reg rva      =  0;    // read-from-block-mem-port-a-is-valid
    reg rva_z    =  0;    // future read-from-block-mem-port-a-is-valid 
    reg rva_zz   =  0;    // future future read-from-block-mem-port-a-is-valid 

    localparam [3:0]              // Arbiter's States
        STATE_INIT      =   0,      // initialize
        STATE_LOOP      =   1,      // clear buffer if the clearing flag is set
        STATE_PORT0     =   2,      // telemetry port 0: if there is a request, grant it
        STATE_PORT0_    =   3,      // telemetry port 0: wait for the request to deassert
        STATE_PORT1     =   4,      // telemetry port 1: if there is a request, grant it
        STATE_PORT1_    =   5,      // telemetry port 1: wait for the request to deassert
        STATE_PORT2     =   6,      // telemetry port 2: if there is a request, grant it
        STATE_PORT2_    =   7,      // telemetry port 2: wait for the request to deassert
        STATE_PORT3     =   8,      // telemetry port 3: if there is a request, grant it
        STATE_PORT3_    =   9,      // telemetry port 3: wait for the request to deassert
        STATE_PORT4     =  10,      // telemetry port 4: if there is a request, grant it
        STATE_PORT4_    =  11,      // telemetry port 4: wait for the request to deassert
        STATE_PORT5     =  12,      // telemetry port 5: if there is a request, grant it
        STATE_PORT5_    =  13;      // telemetry port 5: wait for the request to deassert
    reg [3:0]  state  =  STATE_INIT;   // arbiter state machine's state

    always @(posedge clk) begin

        clear        <=  0;
        dump         <=  0;
        uat32_valid  <=  0;
    
        rva     <=  rva_z;
        rva_z   <=  rva_zz;
        rva_zz  <=  0;
        
        if (rva)  rdata <= doutb;
        
        if (addr[23] == 0) begin
            if (re) begin
                rdata <= 32'hDEADBEEF;
                if (!dumping) begin
                    addrb   <=  addr[16:0];
                    rva_zz  <=  1;
                end
            end
        end
        else begin
            if (we)
                case (addr[3:0])
                    0:  begin
                            clear  <=  wdata[0];
                            dump   <=  wdata[1];
                        end
                    3:  dec0  <=  wdata[15:0];
                    4:  dec1  <=  wdata[15:0];
                    5:  dec2  <=  wdata[15:0];
                    6:  dec3  <=  wdata[15:0];
                    7:  dec4  <=  wdata[15:0];
                    8:  dec5  <=  wdata[15:0];
                endcase
            if (re)
                case (addr[3:0])
                    0:  rdata  <=  {30'b0, dumping, clearing};
                    1:  rdata  <=  count;
                    2:  rdata  <=  1 << ADDR_WIDTH;
                    3:  rdata  <=  dec0;
                    4:  rdata  <=  dec1;
                    5:  rdata  <=  dec2;
                    6:  rdata  <=  dec3;
                    7:  rdata  <=  dec4;
                    8:  rdata  <=  dec5;
                    default:  rdata  <=  32'hDEADBEEF;
                endcase
        end

        if (dumping && !uat32_busy) begin
            if (dump_count_zero)  dumping <= 0;
            uat32_data   <=  doutb;
            uat32_valid  <=  ~dump_count_zero;
            addrb        <=  addrb + 1;
            dump_count   <=  dump_count - 1;
        end

        if (dump) begin
            addrb        <=  0;
            dump_count   <=  count;
            uat32_data   <=  count;
            uat32_valid  <=  1;
            dumping      <=  1;
        end

    end


    // Telemetry ports

    always @(posedge clk) begin

        clearing <= clearing | clear;

        case (state)
            STATE_INIT:     begin                   // Initialize
                                dec0cnt   <=  0;
                                dec1cnt   <=  0;
                                dec2cnt   <=  0;
                                dec3cnt   <=  0;
                                dec4cnt   <=  0;
                                dec5cnt   <=  0;
                                count     <=  0;
                                clearing  <=  0;
                                // !!!NOTE Trigger-recording logic could be added here. Presently starts recording immediately.
                                state     <=  STATE_LOOP;
                            end

            STATE_LOOP:     state  <=  clearing ? STATE_INIT : STATE_PORT0;   // If requested to clear the buffer, clear it

            STATE_PORT0:    if (req0) begin         // Check telemetry port 0
                                if (dec0cnt == 0 && ~&dec0)  ack0 <= 1;
                                else  nak0 <= 1;
                                dec0cnt  <=  dec0cnt == dec0  ?  0  :  dec0cnt + 1;
                                state <= STATE_PORT0_;
                            end
                            else  state <= STATE_PORT1;

            STATE_PORT0_:   if (!req0) begin        // Wait for the request line to deassert
                                ack0   <=  0;
                                nak0   <=  0;
                                state  <=  STATE_PORT1;
                            end

            STATE_PORT1:    if (req1) begin         // Check telemetry port 1
                                if (dec1cnt == 0 && ~&dec1)  ack1 <= 1;
                                else  nak1 <= 1;
                                dec1cnt  <=  dec1cnt == dec1  ?  0  :  dec1cnt + 1;
                                state <= STATE_PORT1_;
                            end
                            else  state <= STATE_PORT2;

            STATE_PORT1_:   if (!req1) begin        // Wait for the request line to deassert
                                ack1   <=  0;
                                nak1   <=  0;
                                state  <=  STATE_PORT2;
                            end

            STATE_PORT2:    if (req2) begin     // Check telemetry port 2
                                if (dec2cnt == 0 && ~&dec2)  ack2 <= 1;
                                else  nak2 <= 1;
                                dec2cnt  <=  dec2cnt == dec2  ?  0  :  dec2cnt + 1;
                                state <= STATE_PORT2_;
                            end
                            else  state <= STATE_PORT3;

            STATE_PORT2_:   if (!req2) begin    // Wait for the request line to deassert
                                ack2   <=  0;
                                nak2   <=  0;
                                state  <=  STATE_PORT3;
                            end

            STATE_PORT3:    if (req3) begin     // Check telemetry port 3
                                if (dec3cnt == 0 && ~&dec3)  ack3 <= 1;
                                else  nak3 <= 1;
                                dec3cnt  <=  dec3cnt == dec3  ?  0  :  dec3cnt + 1;
                                state <= STATE_PORT3_;
                            end
                            else  state <= STATE_PORT4;

            STATE_PORT3_:   if (!req3) begin    // Wait for the request line to deassert
                                ack3   <=  0;
                                nak3   <=  0;
                                state  <=  STATE_PORT4;
                            end

            STATE_PORT4:    if (req4) begin     // Check telemetry port 4
                                if (dec4cnt == 0 && ~&dec4)  ack4 <= 1;
                                else  nak4 <= 1;
                                dec4cnt  <=  dec4cnt == dec4  ?  0  :  dec4cnt + 1;
                                state <= STATE_PORT4_;
                            end
                            else  state <= STATE_PORT5;

            STATE_PORT4_:   if (!req4) begin    // Wait for the request line to deassert
                                ack4   <=  0;
                                nak4   <=  0;
                                state  <=  STATE_PORT5;
                            end

            STATE_PORT5:    if (req5) begin     // Check telemetry port 5
                                if (dec5cnt == 0 && ~&dec5)  ack5 <= 1;
                                else  nak5 <= 1;
                                dec5cnt  <=  dec5cnt == dec5  ?  0  :  dec5cnt + 1;
                                state <= STATE_PORT5_;
                            end
                            else  state <= STATE_LOOP;

            STATE_PORT5_:   if (!req5) begin    // Wait for the request line to deassert
                                ack5   <=  0;
                                nak5   <=  0;
                                state  <=  STATE_LOOP;
                            end

            default:  state <= STATE_INIT;
        endcase

        // Append din to buffer, if din is valid and the buffer isn't full
        addra  <=  count[ADDR_WIDTH-1:0];
        dina   <=  din0 & {32{ack0}}  |
                   din1 & {32{ack1}}  |
                   din2 & {32{ack2}}  |
                   din3 & {32{ack3}}  |
                   din4 & {32{ack4}}  |
                   din5 & {32{ack5}};
        wea    =   !full &&
                   ( ack0 & valid0  |
                     ack1 & valid1  |
                     ack2 & valid2  |
                     ack3 & valid3  |
                     ack4 & valid4  |
                     ack5 & valid5 );
        if (wea)  count <= count + 1;

    end


endmodule
