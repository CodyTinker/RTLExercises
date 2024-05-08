/******************************************************************************
Design an AXI request generator.
The CPU programs a read or write transaction in the PIO proxy register
via APB interface
PIO proxy executes the transaction via AXI interface

PIO Proxy consists of the following registers as per the spec based on the mapped (relative) addresses:
0x00: CONFIG
0x04: ADDR_LOW
0x08: ADDR_HIGH
0x0C: DATA_0
0x10: DATA_1
0x14: DATA_2
0x18: DATA_3
0x1C: CTRL
0x20: STS
0x24: SCRATCH

Paramteres:
    ADDR_WIDTH: Width of the address bus. Up to 32-bits. Default 32-bits.
    DATA_WIDTH: Width of the data bus. Can be 8-,16-, or 32-bits wide. Default 32-bits.
    USER_REQ_WIDTH: User request attribute width. Recommended to have a maximum
                    width of 128-bits.
    USER_DATA_WIDTH: User wride data attribute width. Recommended to have a maximum
                     width of DATA_WIDTH/2.

Interface:
    input   clock;
    input   reset_n;

    ***     Standard APB slave interface (Requester-only interface)      ***
    // input                   proxy_PCLK;
    // input                   proxy_PRESETn;

    // Requester signals
    input [ADDR_WIDTH:0]    proxy_PADDR;
    input                   proxy_PPROT;
    input                   proxy_PNSE;
    input                   proxy_PSELx;
    input                   proxy_PENABLE;
    input                   proxy_PWRITE;
    input [DATA_WIDTH:0]    proxy_PWDATA;
    input                   proxy_PSTRB;

    input                       proxy_PWAKEUP;
    input [USER_REQ_WIDTH:0]    proxy_PAUSER;
    input [USER_DATA_WIDTH:0]   proxy_PWUSER;

    // (Unused) Completer signals
    // PREADY;
    // PRDATA;
    // PSLVERR;
    // PRUSER;
    // PBUSER;

    ***     Standard AXI master interface       ***
    // Global signals
    // input                   proxy_ACLK;
    // input                   proxy_ARESETn;
    // Write address channel signals
    output [3:0]            proxy_AWID;
    output [31:0]           proxy_AWADDR;
    output [3:0]            proxy_AWLEN;
    output [2:0]            proxy_AWSIZE;
    output [1:0]            proxy_AWBURST;
    output [1:0]            proxy_AWLOCK;
    output [3:0]            proxy_AWCACHE;
    output [2:0]            proxy_AWPROT;
    output                  proxy_AWVALID;
    input                   proxy_AWREADY;
    // Write data channel signals
    output [3:0]            proxy_WID;
    output [31:0]           proxy_DATA;
    output [3:0]            proxy_WSTRB;
    output                  proxy_WLAST;
    output                  proxy_WVALID;
    input                   proxy_WREADY;
    // Write response channel signals
    input [3:0]             proxy_BID;
    input [1:0]             proxy_BRESP;
    input                   proxy_BVALID;
    output                  proxy_BREADY;

    // Read address channel signals
    output [3:0]            proxy_ARID;
    output [31:0]           proxy_ARADDR;
    output [3:0]            proxy_ARLEN;
    output [2:0]            proxy_ARSIZE;
    output [1:0]            proxy_ARBURST;
    output [1:0]            proxy_ARLOCK;
    output [3:0]            proxy_ARCACHE;
    output [2:0]            proxy_ARPROT;
    output                  proxy_ARVALID;
    input                   proxy_ARREADY;
    // Read data channel signals
    input [3:0]             proxy_RID;
    input [31:0]            proxy_RATA;
    input [3:0]             proxy_RSTRB;
    input                   proxy_RLAST;
    input                   proxy_RVALID;
    output                  proxy_RREADY;

    // Low-power interface signals (not implemented)
    // input                   proxy_CSYSREQ;
    // output                  proxy_CSYSACK;
    // output                  proxy_CACTIVE;

******************************************************************************/

module apb2axi_proxy #(
    ADDR_WIDTH = 32;    // Bitwidth
    DATA_WIDTH = 8;     // Bitwidth (can be 8, 16, 32)
) (
    input   clock;
    input   reset_n;

    /***     Standard APB slave interface (Requester-only interface)      ***/
    // Ignoring all 'advanced' signals for the time being and focusing on the
    // primary signals for memory transactions
    input                   proxy_PCLK;
    input                   proxy_PRESETn;

    // Requester signals
    input [ADDR_WIDTH-1:0]      i_proxy_PADDR;
    // input                       i_proxy_PPROT; // Ignoring for now (likely unused)
    // input                       i_proxy_PNSE;  // Ignoring for now (likely unused)
    input                       i_proxy_PSEL;
    input                       i_proxy_PENABLE;
    input                       i_proxy_PWRITE;
    input [DATA_WIDTH-1:0]      i_proxy_PWDATA;
    // input [(DATA_WIDTH/8)-1:0]  i_proxy_PSTRB; // Ignoring for now

    // Ignoring for now
    // input                       i_proxy_PWAKEUP;
    // input [USER_REQ_WIDTH:0]    i_proxy_PAUSER;
    // input [USER_DATA_WIDTH:0]   i_proxy_PWUSER;

    // Completer signals
    output                       o_proxy_PREADY;
    output [DATA_WIDTH-1:0]      o_proxy_PRDATA;
    // PSLVERR;
    // PRUSER;
    // PBUSER;

    /***     Standard AXI master interface       ***/
    // Global signals
    input                   proxy_ACLK;
    input                   proxy_ARESETn;
    // Write address channel signals
    // output [3:0]                o_proxy_AWID;
    output [31:0]               o_proxy_AWADDR;
    output [3:0]                o_proxy_AWLEN;
    output [2:0]                o_proxy_AWSIZE;
    // output [1:0]                o_proxy_AWBURST;
    output [1:0]                o_proxy_AWLOCK;
    // output [3:0]                o_proxy_AWCACHE;
    // output [2:0]                o_proxy_AWPROT;
    output                      o_proxy_AWVALID;
    input                       i_proxy_AWREADY;
    // Write data channel signals
    output [3:0]                o_proxy_WID;
    output [31:0]               o_proxy_DATA;
    output [3:0]                o_proxy_WSTRB;
    output                      o_proxy_WLAST;
    output                      o_proxy_WVALID;
    input                       i_proxy_WREADY;
    // Write response channel signals
    input [3:0]                 i_proxy_BID;
    input [1:0]                 i_proxy_BRESP;
    input                       i_proxy_BVALID;
    output                      o_proxy_BREADY;

    // Read address channel signals
    output [3:0]                o_proxy_ARID;
    output [31:0]               o_proxy_ARADDR;
    output [3:0]                o_proxy_ARLEN;
    output [2:0]                o_proxy_ARSIZE;
    output [1:0]                o_proxy_ARBURST;
    output [1:0]                o_proxy_ARLOCK;
    output [3:0]                o_proxy_ARCACHE;
    output [2:0]                o_proxy_ARPROT;
    output                      o_proxy_ARVALID;
    input                       i_proxy_ARREADY;
    // Read data channel signals
    input [3:0]                 i_proxy_RID;
    input [31:0]                i_proxy_RATA;
    input [3:0]                 i_proxy_RSTRB;
    input                       i_proxy_RLAST;
    input                       i_proxy_RVALID;
    output                      o_proxy_RREADY;

    // Low-power interface signals (not implemented)
    // input                   proxy_CSYSREQ;
    // output                  proxy_CSYSACK;
    // output                  proxy_CACTIVE;
);



// Register base
reg [3:0]   pio_registers_mem [31:0]

endmodule