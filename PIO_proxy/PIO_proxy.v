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
    DATA_WIDTH = 32;     // Bitwidth (can be 8, 16, 32)
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

    /****************************************/
    /***          APB Domain              ***/
    /****************************************/

    // APB-to-Register Sync boundary Flops
    reg [ADDR_WIDTH-1:0] addr_handoff;
    reg [DATA_WIDTH-1:0] wr_data_handoff;
    reg pwrite_handoff;
    reg [DATA_WIDTH-1:0] rd_data_sync;
    reg handoff_ack_sync [1:0];

    // State machine signals
    wire transmit_sync;
    reg transmit_sync_toggle;
    wire handoff_ack_pulse;
    wire apb_pready_s;

    reg [2:0] state, next_state;

    // State machine states
    localparam SM_APB__IDLE            = 'h0;
    localparam SM_APB__WAIT_PENABLE    = 'h1;
    localparam SM_APB__ACCESS_TOGGLE   = 'h2;
    localparam SM_APB__ACCESS_WAIT     = 'h3;
    localparam SM_APB__ACCESS_DONE     = 'h4;

    // Flops
    always @(posedge proxy_PCLK) begin
        if (transmit_setup) begin
            addr_handoff <= i_proxy_PADDR;
            wr_data_handoff <= i_proxy_PWDATA;
            pwrite_handoff <= i_proxy_PWRITE;
        end

        if (handoff_ack_pulse) begin
            rd_data_sync <= pio_rd_data;
        end

        transmit_sync_toggle <= transmit_sync_toggle ^ transmit_sync;

        // PIO-to-APB domain synchronizer
        handoff_ack_sync[0] <= handoff_ack;
        handoff_ack_sync[1] <= handoff_ack_sync[0];
        handoff_ack_sync[2] <= handoff_ack_sync[1];
    end

    assign handoff_ack_pulse = handoff_ack_sync[2] ^ handoff_ack_sync[1];

    // State transition block
    always @(posedge proxy_PCLK) begin
        if (proxy_PRESETn) begin
            state <= idle;
        else
            state <= next_state;
        end
    end

    // State transition and output logic
    always @(*) begin
        transmit_sync = 0;
        apb_pready_s = 0;
        next_state = state;
        case (state)
            SM_APB__IDLE: begin
                apb_pready_s = 0;
                if (i_proxy_PSEL && !i_proxy_PENABLE) begin
                    next_state = SM_APB__SETUP;
                end
            end
            SM_APB__WAIT_PENABLE: begin
                if (i_proxy_PENABLE) begin
                    next_state = SM_APB__ACCESS_TOGGLE;
                end
            end
            SM_APB__ACCESS_TOGGLE: begin
                transmit_sync = 1;
                next_state = SM_APB__ACCESS_WAIT;
            end
            SM_APB__ACCESS_WAIT: begin
                transmit_sync = 0;
                if (handoff_ack_pulse) begin
                    next_state = SM_APB__ACCESS_DONE;
                end
            end
            SM_APB__ACCESS_DONE: begin
                apb_pready_s = 1;
                next_state = SM_APB__IDLE;
            end
        endcase
    end
    assign o_proxy_PREADY = apb_pready_s;

    /****************************************/
    /***         Register Domain          ***/
    /****************************************/
    localparam CONFIG_ADDR      = 'h00;
    localparam ADDR_LOW_ADDR    = 'h04;
    localparam ADDR_HIGH_ADDR   = 'h08;
    localparam DATA_0_ADDR      = 'h0C;
    localparam DATA_1_ADDR      = 'h10;
    localparam DATA_2_ADDR      = 'h14;
    localparam DATA_3_ADDR      = 'h18;
    localparam CTRL_ADDR        = 'h1C;
    localparam STS_ADDR         = 'h20;
    localparam SCRATCH_ADDR     = 'h24;

    localparam LOW_ADDR_BOUND   = CONFIG_ADDR;
    localparam HIGH_ADDR_BOUND  = SCRATCH_ADDR;

    // Register base
    reg [31:0]   pio_registers_mem [7:0];

    // APB-to-Register sync barrier
    wire [DATA_WIDTH-1:0] pio_rd_data;
    reg [DATA_WIDTH-1:0] pio_wr_data;
    reg [ADDR_WIDTH-1:0] pio_addr_flop;
    wire [7:0] pio_addr;
    reg pio_wr_en;

    // Technically we dont need to flop the entire ADDR_WIDTH from the APB since
    // the register depth is only 8-bits wide but keeping here for example simplicity
    // and we may need it for error detection or other reasons
    // Obviously a full spec'd design would trim this out as needed.
    assign pio_addr[7:0] = pio_addr_flop[7:0];

    wire handoff_enable_pulse;
    reg handoff_enable_sync [1:0];
    reg handoff_ack_delay_0;
    reg handoff_ack;


    // Flops
    always @(posedge clock) begin
        if (handoff_enable_pulse) begin
            pio_addr <= addr_handoff;
            pio_wr_data <= wr_data_handoff;
        end

        pio_wr_en <= pwrite_handoff & handoff_enable_pulse;

        // PIO-to-APB domain synchronizer
        handoff_enable_sync[0] <= transmit_sync_toggle;
        handoff_enable_sync[1] <= handoff_enable_sync[0];
        handoff_enable_sync[2] <= handoff_enable_sync[1];

        handoff_enable_pulse <= handoff_enable_sync ^ handoff_enable_sync;

         // Delaying handoff ack by two cycles to setup rd data
        handoff_ack_delay_0 <= handoff_enable_sync[2];
        handoff_ack <= handoff_ack_delay_0;
    end

    // Register Memory
    always @(posedge clock) begin
        if (pio_wr_en) begin
            pio_registers_mem[pio_addr] <= pio_wr_data;
        end
    end
    pio_rd_data <= pio_registers_mem[pio_addr]; // Just mux it out

endmodule