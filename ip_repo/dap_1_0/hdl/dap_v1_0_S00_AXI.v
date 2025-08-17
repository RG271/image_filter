`timescale 1 ns / 1 ps

// AXI-Lite Slave Interface to 32 32-bit-words Memory-Mapped Peripheral
//
// author: Richard Kaminsky
// date:   10/20/2017 - 12/11/2017

module dap_v1_0_S00_AXI
	#(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXI data bus (Always 32)
        parameter integer C_S_AXI_DATA_WIDTH = 32,
        // Width of S_AXI address bus
        parameter integer C_S_AXI_ADDR_WIDTH = 7
	)
	(
        // Users to add ports here
        
        // Interface to Bank of 32 32-bit Registers
        // peripheral's read port (the AXI master reads from this port)
        output reg [C_S_AXI_ADDR_WIDTH - 3 : 0] reg_raddr = 0,  // read address (0..31) -- i.e., index of a 32-bit register
        output reg reg_rvalid = 0,                              // pulsed at the start of a read operation after reg_raddr is updated
        input wire [31:0] reg_rdata,                            // value of register reg_raddr; latency is 1 clock cycle
        // peripheral's write port (the AXI master writes to this port)
        output reg [C_S_AXI_ADDR_WIDTH - 3 : 0] reg_waddr = 0,  // write address (0..31) -- i.e., index of a 32-bit register
        output reg reg_wvalid = 0,                              // pulsed at the start of a write operation after reg_waddr and reg_wdata are updated
        output reg [31:0] reg_wdata,                            // new value for register reg_waddr

        // User ports ends
        // Do not modify the ports beyond this line

        // Global Clock Signal
        input wire  S_AXI_ACLK,
        // Global Reset Signal. This Signal is Active LOW
        input wire  S_AXI_ARESETN,
        // Write address (issued by master, acceped by Slave)
        input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
        // Write channel Protection type. This signal indicates the
            // privilege and security level of the transaction, and whether
            // the transaction is a data access or an instruction access.
        input wire [2 : 0] S_AXI_AWPROT,
        // Write address valid. This signal indicates that the master signaling
            // valid write address and control information.
        input wire  S_AXI_AWVALID,
        // Write address ready. This signal indicates that the slave is ready
            // to accept an address and associated control signals.
        output wire  S_AXI_AWREADY,
        // Write data (issued by master, acceped by Slave) 
        input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
        // Write strobes. This signal indicates which byte lanes hold
            // valid data. There is one write strobe bit for each eight
            // bits of the write data bus.    
        input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
        // Write valid. This signal indicates that valid write
            // data and strobes are available.
        input wire  S_AXI_WVALID,
        // Write ready. This signal indicates that the slave
            // can accept the write data.
        output wire  S_AXI_WREADY,
        // Write response. This signal indicates the status
            // of the write transaction.
        output wire [1 : 0] S_AXI_BRESP,
        // Write response valid. This signal indicates that the channel
            // is signaling a valid write response.
        output wire  S_AXI_BVALID,
        // Response ready. This signal indicates that the master
            // can accept a write response.
        input wire  S_AXI_BREADY,
        // Read address (issued by master, acceped by Slave)
        input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
        // Protection type. This signal indicates the privilege
            // and security level of the transaction, and whether the
            // transaction is a data access or an instruction access.
        input wire [2 : 0] S_AXI_ARPROT,
        // Read address valid. This signal indicates that the channel
            // is signaling valid read address and control information.
        input wire  S_AXI_ARVALID,
        // Read address ready. This signal indicates that the slave is
            // ready to accept an address and associated control signals.
        output wire  S_AXI_ARREADY,
        // Read data (issued by slave)
        output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
        // Read response. This signal indicates the status of the
            // read transfer.
        output wire [1 : 0] S_AXI_RRESP,
        // Read valid. This signal indicates that the channel is
            // signaling the required read data.
        output wire  S_AXI_RVALID,
        // Read ready. This signal indicates that the master can
            // accept the read data and response information.
        input wire  S_AXI_RREADY
    );


    // AXI4LITE signals

    reg [C_S_AXI_ADDR_WIDTH-1 : 0]  axi_awaddr = 0;
    reg        axi_awready = 0;
    reg        axi_wready  = 0;
    reg [1:0]  axi_bresp   = 0;
    reg        axi_bvalid  = 0;
    reg        axi_arready = 0;
    reg [C_S_AXI_DATA_WIDTH-1 : 0]  axi_rdata = 0;
    reg [1:0]  axi_rresp   = 0;
    reg        axi_rvalid  = 0;


    // I/O Connections

    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY  = axi_wready;
    assign S_AXI_BRESP   = axi_bresp;
    assign S_AXI_BVALID  = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA   = axi_rdata;
    assign S_AXI_RRESP   = axi_rresp;
    assign S_AXI_RVALID  = axi_rvalid;


    // Read/Write Operations' State Machines
    
    localparam RSTATE_IDLE   = 0,
               RSTATE_DELAY1 = 1,
               RSTATE_DELAY2 = 2,
               RSTATE_DONE   = 3;

    reg [1:0] rstate = RSTATE_IDLE;
    
    localparam WSTATE_IDLE   = 0,
               WSTATE_WRITE  = 1,
               WSTATE_DONE   = 2;

    reg [1:0] wstate = WSTATE_IDLE;
    
    always @(posedge S_AXI_ACLK)
        if (!S_AXI_ARESETN) begin
            reg_raddr   <= 0;
            reg_rvalid  <= 0;
            reg_waddr   <= 0;
            reg_wvalid  <= 0;
            reg_wdata   <= 0;
            axi_arready <= 0;
            axi_rvalid  <= 0;
            axi_rresp   <= 2'b00;    // read response, i.e. status (2'b00 = OK) 
            axi_awready <= 0;
            axi_wready  <= 0;
            axi_bvalid  <= 0;
            axi_bresp   <= 2'b00;    // write response, i.e. status (2'b00 = OK)
        end 
        else begin

            // Read State Machine

            axi_arready <= 0;
            axi_rvalid  <= 0;
            reg_rvalid <= 0;
            
            case (rstate)
            
                RSTATE_IDLE:
                    if (S_AXI_ARVALID) begin              // wait for a valid read address
                        reg_raddr <= S_AXI_ARADDR[C_S_AXI_ADDR_WIDTH - 1 : 2];  // latch address
                        reg_rvalid <= 1;                    // pulse reg_rvalid to indicate read operation
                        axi_arready <= 1;                   // pulse axi_arready to indicate the read address has been accepted
                        rstate <= RSTATE_DELAY1;
                    end

                RSTATE_DELAY1:  rstate <= RSTATE_DELAY2;

                RSTATE_DELAY2:  rstate <= RSTATE_DONE;

                RSTATE_DONE:
                    begin
                        axi_rdata  <= reg_rdata;            // return data read from address reg_raddr 
                        axi_rvalid <= 1;                    // pulse axi_rvalid to indicate valid data is available on the read data bus
                        axi_rresp  <= 2'b00;                // read succeeded; so, return status 2'b00 = OK
                        rstate <= RSTATE_IDLE;
                    end

                default:  rstate <= RSTATE_IDLE;

            endcase

            // Write State Machine

            axi_awready <= 0;
            axi_wready <= 0;
            reg_wvalid <= 0;
            
            case (wstate)
            
                WSTATE_IDLE:
                    // An AXI slave is ready to accept write address when there is a 
                    // valid write address and write data on the write address and 
                    // data bus. This design expects no outstanding transactions. 
                    if (S_AXI_AWVALID && S_AXI_WVALID) begin   // wait for valid write address & data
                        reg_waddr <= S_AXI_AWADDR[C_S_AXI_ADDR_WIDTH - 1 : 2];   // latch address
                        axi_awready <= 1;                       // pulse axi_awready to indicate the write address has been accepted
                        axi_wready <= 1;                        // pulse axi_awready to indicate the write data has been accepted
                        wstate <= WSTATE_WRITE;
                    end

                WSTATE_WRITE:
                    begin
                        if (&S_AXI_WSTRB) begin           // 32-bit write?  Ignore if not all bytes are written. 
                            reg_wdata <= S_AXI_WDATA;       // data to write to address reg_waddr
                            reg_wvalid <= 1;                // pulse reg_wvalid to indicate write operation
                        end
                        axi_bvalid <= 1;                    // assert axi_bvalid to indicate write succeeded
                        axi_bresp  <= 2'b00;                // write succeeded; so, return status 2'b00 = OK
                        wstate <= WSTATE_DONE;
                    end

                WSTATE_DONE:
                    if (S_AXI_BREADY) begin    // wait to release axi_bvalid (note, S_AXI_BREADY may always be 1) 
                        axi_bvalid <= 0;
                        wstate <= WSTATE_IDLE;
                    end

                default:  wstate <= WSTATE_IDLE;

            endcase
        end

endmodule
