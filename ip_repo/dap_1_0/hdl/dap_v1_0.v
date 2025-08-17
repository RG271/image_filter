`timescale 1 ns / 1 ps

module dap_v1_0
    #(
        // Users to add parameters here
    
        /*
            IDE:     Xilinx Vivado 2022.2
            author:  Dr. Richard D. Kaminsky
            date:    2/28/2020 - 8/4/2025

    
            Register Map
            ============
            
            Note, Index (below) is a 32-bit register's index; its byte offset from this peripheral's base address is Index * 4.
    
            Index   Name           Access   Description
            -----   ------------   ------   ----------------------------------------------------------------------------------------------------------
    
            0       wdata            rw     32-bit value to write
            
            1       rwModAddr        rw     32-bit command:
                                              Bits   Name           Description
                                              -----  -------------  ---------------------------------------------------------------------------
                                              31     rw             operation flag: 0 = write, 1 = read
                                              30:24  mod            ID of the module to read from or write to (0..127)
                                              23:0   addr           address of the 32-bit word in the module's address space to read/write

            2       rdata            ro     32-bit value read
    
            3       usTime           ro     26-bit free-running timer incrementing at 1 MHz 

            4       creationDate     ro     PL firmware's creation date in 32'hYYMMDDHH format (can be used as a globally unique ID for this firmware)
    
            5       buildDate        ro     PL firmware's build date in 32'hYYMMDDHH format
    
            6-31    reserved          ro    reserved (always 0xDEADBEEF)


            Change History
            ==============
            
            02/28/2020 RK  Initial
            07/25/2025 RK  Created the wdata / rwModAddr / rdata interface
            07/30/2025 RK  Replaced the creation/build date parameters by the cdate/bdate ports
            08/02/2025 RK  Added debug serial port
        */
    
        parameter real CLK_FREQ   =  100e6,    // frequency of clock s00_axi_aclk (Hz)
        parameter real BAUD_RATE  =  921600,   // Debug Serial Port's baud rate in bits/s (115200 .. 921600)
    
        // User parameters ends
        // Do not modify the parameters beyond this line
    
    
        // Parameters of Axi Slave Bus Interface S00_AXI
        parameter integer C_S00_AXI_DATA_WIDTH	=  32,
        parameter integer C_S00_AXI_ADDR_WIDTH	=  7
    )
    (
        // Users to add ports here
        
        input      [31:0]  cdate,           // PL firmware's creation date in 32'hYYMMDDHH format
        input      [31:0]  bdate,           // PL firmware's build date in 32'hYYMMDDHH format
        output reg [25:0]  us_time = 0,     // free running 26-bit timer at 1 MHz
        input              rx,              // debug serial port's receiver input
        output             tx,              // debug serial port's transmitter output

        // Module 0's Interface
        output [23:0]  addr_0,     // address (i.e., index -- not a byte address) of 32-bit word
        output [31:0]  wdata_0,    // 32-bit word to write if rwModAddr_0 specifies a write operation
        input  [31:0]  rdata_0,    // 32-bit word read from address addr_0; sampled 3 (TBR) clk cycles after re_0 pulses
        output         we_0,       // pulses for one clk cycle when wdata_0 should be written to addr_0
        output         re_0,       // pulses for one clk cycle when rdata_0 should be read from addr_0

        // Module 1's Interface
        output [23:0]  addr_1,     // address (i.e., index -- not a byte address) of 32-bit word
        output [31:0]  wdata_1,    // 32-bit word to write if rwModAddr_1 specifies a write operation
        input  [31:0]  rdata_1,    // 32-bit word read from address addr_1; sampled 3 (TBR) clk cycles after re_1 pulses
        output         we_1,       // pulses for one clk cycle when wdata_1 should be written to addr_1
        output         re_1,       // pulses for one clk cycle when rdata_1 should be read from addr_1

        // Module 2's Interface
        output [23:0]  addr_2,     // address (i.e., index -- not a byte address) of 32-bit word
        output [31:0]  wdata_2,    // 32-bit word to write if rwModAddr_2 specifies a write operation
        input  [31:0]  rdata_2,    // 32-bit word read from address addr_2; sampled 3 (TBR) clk cycles after re_2 pulses
        output         we_2,       // pulses for one clk cycle when wdata_2 should be written to addr_2
        output         re_2,       // pulses for one clk cycle when rdata_2 should be read from addr_2
    
        // User ports ends
        // Do not modify the ports beyond this line
    
    
        // Ports of Axi Slave Bus Interface S00_AXI
        input wire  s00_axi_aclk,
        input wire  s00_axi_aresetn,
        input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
        input wire [2 : 0] s00_axi_awprot,
        input wire  s00_axi_awvalid,
        output wire  s00_axi_awready,
        input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
        input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
        input wire  s00_axi_wvalid,
        output wire  s00_axi_wready,
        output wire [1 : 0] s00_axi_bresp,
        output wire  s00_axi_bvalid,
        input wire  s00_axi_bready,
        input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
        input wire [2 : 0] s00_axi_arprot,
        input wire  s00_axi_arvalid,
        output wire  s00_axi_arready,
        output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
        output wire [1 : 0] s00_axi_rresp,
        output wire  s00_axi_rvalid,
        input wire  s00_axi_rready
    );
    
    
    // AXI Master's interface to this peripheral's bank of 32 32-bit registers
    // peripheral's read port (the AXI master reads from this port)
    wire [C_S00_AXI_ADDR_WIDTH - 3 : 0] reg_raddr;   // read address (0..31) -- i.e., index of a 32-bit register
    wire reg_rvalid;                                 // pulsed at the start of a read operation after reg_raddr is updated
    reg [31:0] reg_rdata;                            // value of register reg_raddr; latency is 1 clock cycle
    // peripheral's write port (the AXI master writes to this port)
    wire [C_S00_AXI_ADDR_WIDTH - 3 : 0] reg_waddr;   // write address (0..31) -- i.e., index of a 32-bit register
    wire reg_wvalid;                                 // pulsed at the start of a write operation after reg_waddr and reg_wdata are updated
    wire [31:0] reg_wdata;                           // new value for register reg_waddr
    
    
    // Instantiation of Axi Bus Interface S00_AXI
    dap_v1_0_S00_AXI # ( 
        .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
    ) dap_v1_0_S00_AXI_i (
        .S_AXI_ACLK(s00_axi_aclk),
        .S_AXI_ARESETN(s00_axi_aresetn),
        .S_AXI_AWADDR(s00_axi_awaddr),
        .S_AXI_AWPROT(s00_axi_awprot),
        .S_AXI_AWVALID(s00_axi_awvalid),
        .S_AXI_AWREADY(s00_axi_awready),
        .S_AXI_WDATA(s00_axi_wdata),
        .S_AXI_WSTRB(s00_axi_wstrb),
        .S_AXI_WVALID(s00_axi_wvalid),
        .S_AXI_WREADY(s00_axi_wready),
        .S_AXI_BRESP(s00_axi_bresp),
        .S_AXI_BVALID(s00_axi_bvalid),
        .S_AXI_BREADY(s00_axi_bready),
        .S_AXI_ARADDR(s00_axi_araddr),
        .S_AXI_ARPROT(s00_axi_arprot),
        .S_AXI_ARVALID(s00_axi_arvalid),
        .S_AXI_ARREADY(s00_axi_arready),
        .S_AXI_RDATA(s00_axi_rdata),
        .S_AXI_RRESP(s00_axi_rresp),
        .S_AXI_RVALID(s00_axi_rvalid),
        .S_AXI_RREADY(s00_axi_rready),
        .reg_raddr(reg_raddr),
        .reg_rvalid(reg_rvalid),
        .reg_rdata(reg_rdata),
        .reg_waddr(reg_waddr),
        .reg_wvalid(reg_wvalid),
        .reg_wdata(reg_wdata)
    );
    
    // Add user logic here
    
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
    
    wire clk = s00_axi_aclk;        // clock 
    wire rst = 0;                   // reset: Let rst be ~s00_axi_aresetn, or to save logic resources, set it to 0 (i.e., never assert).

    // Debug Serial Port
    localparam integer RX_TIMEOUT  =  12;      // max. time to wait for next byte (1..15; units: 10 ms)
    reg  [9*8-1:0]  sp_rx_sh         =  0;     // shift register of received packet without COMMAND_HEADER; shifts right
    reg  [3:0]      sp_rx_n          =  0;     // # bytes in sp_rx_sh + 1 (0..10; note, 0 and 1 mean no bytes)
    reg  [3:0]      sp_rx_timeout    =  0;     // waiting-to-receive-a-byte timeout: counts down from RX_TIMEOUT to 0 at 100 Hz
    wire [7:0]      sp_rx_checksum0  =  8'hFF ^ sp_rx_sh[8*8 +: 8] ^ sp_rx_sh[7*8 +: 8] ^ sp_rx_sh[6*8 +: 8] ^ sp_rx_sh[5*8 +: 8];
    wire [7:0]      sp_rx_checksum1  =  sp_rx_checksum0 ^ sp_rx_sh[4*8 +: 8] ^ sp_rx_sh[3*8 +: 8] ^ sp_rx_sh[2*8 +: 8] ^ sp_rx_sh[1*8 +: 8];

    // Arbiter input from AXI4-Lite bus: Control/status registers for reading/writing 32-bit words to up to 128 modules
    reg [31:0]   wdata0       =  0;
    reg [31:0]   rwModAddr0   =  0;
    reg [31:0]   rdata0       =  0;
    reg          rwValid0     =  0;
    
    // Arbiter input from Debug Serial Port: Control/status registers for reading/writing 32-bit words to up to 128 modules
    reg [31:0]   wdata1       =  0;
    reg [31:0]   rwModAddr1   =  0;
    reg [31:0]   rdata1       =  0;
    reg          rwValid1     =  0;
    reg          send_rdata1  =  0;   // pulses after rdata1 has updated and should be transmitted out the serial port
    
    // signals to be demultiplexed/multiplexed to read/write from module mod
    reg  [6:0]   mod    = 0;    // module (0..127)
    reg  [23:0]  addr   = 0;    // address (i.e., index -- not a byte address) of 32-bit word
    reg  [31:0]  wdata  = 0;    // 32-bit word to write if rwModAddr_0 specifies a write operation
    wire [31:0]  rdata;         // 32-bit word read from address addr_0; sampled 3 (TBR) clk cycles after re_0 pulses
    reg          we     = 0;    // pulses for one clk cycle for a write operation
    reg          re     = 0;    // pulses for one clk cycle for a read operation

    // state machine    
    reg [3:0]   state   = 0;    // arbiter / command-processing state 


    // 1MHz Free-Running Timer
    // in out: us_time
    localparam integer US_TOP = CLK_FREQ / 1e6 - 1,     // clk divisor - 1 for generating 1 MHz (>=1)
                       US_WIDTH = width( US_TOP );      // width of timer register in bits
    reg [US_WIDTH-1:0] us_tmr = 0;                      // microsecond time base' up counter (0..US_TOP)
    always @(posedge clk) begin
        if (us_tmr == US_TOP) begin
            us_tmr <= 0;
            us_time <= us_time + 1;
        end
        else  us_tmr <= us_tmr + 1;
    end


    // 10ms Period Strobe
    // out: tms_strobe
    localparam integer TMS_TOP = CLK_FREQ / 100 - 1,    // clk divisor - 1 for generating 100 Hz (>=1)
                       TMS_WIDTH = width( TMS_TOP );    // width of timer register in bits
    reg [TMS_WIDTH-1:0]  tms_tmr     =  0;              // up counter (0..TMS_TOP)
    reg                  tms_strobe  =  0;
    always @(posedge clk) begin
        tms_tmr     <=  tms_strobe  ?  0  :  tms_tmr + 1;
        tms_strobe  <=  tms_tmr == TMS_TOP - 1;
    end


    // Debug Serial Port -- Receiver
    //
    // Receive a read or write command packet.  A read packet is 6 bytes long.  A write packet is 10 bytes long.
    // The first byte of the packet must be COMMAND_HEADER, followed by one 32-bit word (LSByte sent first) for
    // read packets or two 32-bit words for write packets, and finally a checksum byte that is the XOR of 0xFF
    // and the bytes of the one or two 32-bit words.  The first 32-bit word specifies the command: Its MSBit
    // is 0 if a write command or 1 if a read command, bits 30:24 is the module being commanded, and bits 23:0
    // is an address in that module's address space.

    localparam [7:0]  COMMAND_HEADER  =  8'hC0;

    wire [7:0]  uar_data;
    wire        uar_valid;
    wire        uar_framing_error;
    
    uar #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) uar_i (
        .clk(            clk                ),
        .rx(             rx                 ),
        .data(           uar_data           ),
        .valid(          uar_valid          ),
        .framing_error(  uar_framing_error  )
    );


    // Debug Serial Port -- Transmitter
    //
    // Transmit the 32-bit word read by a read command.  The packet sent will be 6 bytes:
    // A header byte RESPONSE_HEADER, the 32-bit word (LSByte sent first), and a checksum that
    // is the XOR of 0xFF and the four bytes of the 32-bit word.

    localparam [7:0]  RESPONSE_HEADER  =  8'hC1;

    wire            uat_busy;
    reg  [7:0]      uat_data      =  0;
    reg             uat_valid     =  0;
    reg             uat_state     =  0;
    reg  [6*8-1:0]  uat_packet    =  0;   // 6-byte response packet to transmit
    reg  [2:0]      uat_count     =  0;   // number of bytes to transmit (0..6)
    wire [7:0]      uat_checksum  =  8'hFF ^ rdata1[0 +: 8] ^ rdata1[8 +: 8] ^ rdata1[16 +: 8] ^ rdata1[24 +: 8];  

    uat #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) uat_i (
        .clk(   clk         ),
        .tx(    tx          ),
        .busy(  uat_busy    ),
        .data(  uat_data    ),
        .valid( uat_valid   )
    );

    always @(posedge clk) begin
        uat_valid <= 0;
        case (uat_state)
            0:  begin
                    uat_packet  <=  {uat_checksum, rdata1, RESPONSE_HEADER};
                    uat_count   <=  6;
                    if (send_rdata1)  uat_state <= 1;
                end
            1:  if (!uat_busy) begin
                    if (uat_count == 0)  uat_state <= 0;
                    else begin
                        uat_data    <=  uat_packet[7:0];
                        uat_valid   <=  1;
                        uat_packet  <=  uat_packet >> 8;
                        uat_count   <=  uat_count - 1;
                    end
                end
            default:  uat_state  <=  0;
        endcase
    end


    // Process AXI reads and writes

    always @(posedge clk) begin
    
        we           <=  0;
        re           <=  0;
        send_rdata1  <=  0;

        // Read/write 32-bit words from AXI4-Lite bus    
        if (reg_rvalid)             // read from a register?
            case (reg_raddr)
                0:  reg_rdata <= wdata0;
                1:  reg_rdata <= rwModAddr0;
                2:  reg_rdata <= rdata0;
                3:  reg_rdata <= {6'b0, us_time};
                4:  reg_rdata <= cdate;
                5:  reg_rdata <= bdate;
               default:  reg_rdata <= 32'hDEADBEEF;
            endcase
        if (reg_wvalid)             // write to a register?
            case (reg_waddr)
                0:  wdata0 <= reg_wdata;
                1:  begin
                        rwModAddr0 <= reg_wdata;
                        rwValid0   <= 1;
                    end
            endcase

        // Receive bytes from Debug Serial Port 
        if (uar_valid) begin
            sp_rx_timeout  <=  RX_TIMEOUT;
            sp_rx_n        =   sp_rx_n + 1;
            sp_rx_sh       =   {uar_data, sp_rx_sh[9*8-1:8]};
            if (sp_rx_n == 1  &&  uar_data != COMMAND_HEADER)  sp_rx_n = 0;   // discard bytes until a command header byte is received
            else if (sp_rx_n == 6  &&  sp_rx_sh[7*8+7] == 1'b1) begin         // received a read command?
                if (sp_rx_sh[8*8 +: 8] == sp_rx_checksum0) begin              //   process the read command iff its checksum is valid
                    rwModAddr1  <=  sp_rx_sh[4*8 +: 32];
                    rwValid1    <=  1;
                end
                sp_rx_n  =  0;
            end
            else if (sp_rx_n == 10  &&  sp_rx_sh[3*8+7] == 1'b0) begin        // received a write command?
                if (sp_rx_sh[8*8 +: 8] == sp_rx_checksum1) begin              //   process the write command iff its checksum is valid
                    wdata1      <=  sp_rx_sh[4*8 +: 32];
                    rwModAddr1  <=  sp_rx_sh[0*8 +: 32];
                    rwValid1    <=  1;
                end
                sp_rx_n  =  0;
            end
        end
        else if (uar_framing_error) begin                                     // if a framing error, discard any received bytes
            sp_rx_n  =  0;
            sp_rx_timeout  <=  0;
        end
        else if (tms_strobe  &&  sp_rx_timeout != 0) begin    // if timed out waiting for a byte, discard any received bytes
            if (sp_rx_timeout == 1)  sp_rx_n = 0;
            sp_rx_timeout  <=  sp_rx_timeout - 1;
        end

        // Arbiter / Read/Write-Operations State Machine
        // Presently this processes just read/write commands sent over the AXI4-Lite bus.
        // Eventually process read/write commands sent over a serial line (debug serial port) too. 
        case (state)

            0:  if (rwValid0) begin
                    mod   <= rwModAddr0[30:24];
                    addr  <= rwModAddr0[23:0];
                    wdata <= wdata0;
                    if (rwModAddr0[31]) begin
                        re     <=  1;
                        state  <=  1;
                    end
                    else begin
                        we        <=  1;
                        rdata0    <=  0;
                        rwValid0  <=  0;
                        state     <=  6;
                    end
                end
                else  state <= 6;
            1:  state <= 2;
            2:  state <= 3;
            3:  state <= 4;
            4:  state <= 5;
            5:  begin
                    rdata0    <=  rdata;
                    rwValid0  <=  0;
                    state     <=  6;
                end
                
            6:  if (rwValid1) begin
                    mod   <= rwModAddr1[30:24];
                    addr  <= rwModAddr1[23:0];
                    wdata <= wdata1;
                    if (rwModAddr1[31]) begin
                        re     <=  1;
                        state  <=  7;
                    end
                    else begin
                        we        <=  1;
                        rdata1    <=  0;
                        rwValid1  <=  0;
                        state     <=  0;
                    end
                end
                else  state <= 0;
            7:  state <= 8;
            8:  state <= 9;
            9:  state <= 10;
           10:  state <= 11;
           11:  begin
                    rdata1       <=  rdata;
                    send_rdata1  <=  1;
                    rwValid1     <=  0;
                    state        <=  0;
                end
                
            default:  state <= 0;
        endcase    
    end


    // Outputs to Module 0
    wire mod_0      =  mod == 0;        // this module is being addressed?
    assign addr_0   =  addr;            // address in the module's address space of a 32-bit word
    assign wdata_0  =  wdata;           // 32-bit word to write if we_0 is pulsed
    assign we_0     =  we & mod_0;      // pulses for one clk cycle when wdata_0 should be written to addr_0
    assign re_0     =  re & mod_0;      // pulses for one clk cycle when rdata_0 should be read from addr_0

    // Outputs to Module 1
    wire mod_1      =  mod == 1;        // this module is being addressed?
    assign addr_1   =  addr;            // address in the module's address space of a 32-bit word
    assign wdata_1  =  wdata;           // 32-bit word to write if we_1 is pulsed
    assign we_1     =  we & mod_1;      // pulses for one clk cycle when wdata_1 should be written to addr_1
    assign re_1     =  re & mod_1;      // pulses for one clk cycle when rdata_1 should be read from addr_1

    // Outputs to Module 2
    wire mod_2      =  mod == 2;        // this module is being addressed?
    assign addr_2   =  addr;            // address in the module's address space of a 32-bit word
    assign wdata_2  =  wdata;           // 32-bit word to write if we_2 is pulsed
    assign we_2     =  we & mod_2;      // pulses for one clk cycle when wdata_2 should be written to addr_2
    assign re_2     =  re & mod_2;      // pulses for one clk cycle when rdata_2 should be read from addr_2

    // Input from Modules
    assign rdata  =  rdata_0 & {32{mod == 0}}   // 32-bit word read from address addr on module mod
                  |  rdata_1 & {32{mod == 1}}
                  |  rdata_2 & {32{mod == 2}};
    
    
    // User logic ends
    
endmodule
