/******************************************************************************
Design an AXI request generator.
The CPU programs a read or write transaction in the PIO proxy register
via APB interface
PIO proxy executes the transaction via AXI interface

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
