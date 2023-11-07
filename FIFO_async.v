/******************************************************************************
Design an asynchronous 32-entry FIFO (data width is e.g. 8 bits). Asynchrounous
in this case means that the write and read interfaces have different
clocks and resets.
Bonus: FIFO depth and number of entries are parameterized

Interface:
    input clock_wr;
    input reset_wr_n;
    input clock_rd;
    input reset_rd_n;

    // Write
    input[7:0]  data_in;    //Width will be parameterized for the bonus
    input       write_en;   //Indicates valid data on the data_in,
                            //data should be written into the FIFO in the
                            //same clock cycle
    output fifo_full;       //The sender will not assert write_en when
                            //fifo_full is asserted


    // Read
    output [7:0] data_out;  //Width will be parameterized for the bonus
    input read_en;          //Read enable, data_out is valid 1 clock cycle
                            //after assertion of this signal
    output fifo_empty;      //The receiver will not assert read_en when
                            //fifo_empty is asserted
******************************************************************************/
module FIFO_async #(
    FIFO_SIZE = 32;
    DATA_WIDTH = 8;
) (
    input clock_wr;
    input reset_wr_n;

    input clock_rd;
    input reset_rd_n;

    // Write
    input[DATA_WIDTH:0]     data_in;    //Width will be parameterized for the bonus
    input                   write_en;   //Indicates valid data on the data_in,
                                        //data should be written into the FIFO in the
                                        //same clock cycle
    output                  fifo_full;  //The sender will not assert write_en when
                                        //fifo_full is asserted

    // Read
    output [DATA_WIDTH:0]   data_out;   //Width will be parameterized for the bonus
    input                   read_en;    //Read enable, data_out is valid 1 clock cycle
                                        //after assertion of this signal
    output                  fifo_empty; //The receiver will not assert read_en when
                                        //fifo_empty is asserted
);
    localparam FIFO_DEPTH = $clog2(FIFO_SIZE); // Had to look up clog2 function

    // Allocate size+1 for the FIFO memory for easier fifo full check logic
    // at the expense of 1 unused word of memory.
    reg [DATA_WIDTH:0] memory [FIFO_SIZE+1:0];
    reg [FIFO_DEPTH:0] wr_index; // Part of the clock_wr clock domain
    reg [FIFO_DEPTH:0] rd_index; // Part of the clock_rd clock domain

    wire fifo_full_s;
    wire fifo_empty_s;

    // Note: Since our write and read pointers/indices now need to be synchronized accross each other
    //       clock domains, we should implement them with Gray Code counters instead of increment
    //       counters to avoid misaligned data bits when crossing the clock domains
    //       ie. Only a single bit will change when updating the value and synchronizing
    wire [FIFO_DEPTH:0] wr_index_graycode; // Part of the clock_wr clock domain
    wire [FIFO_DEPTH:0] rd_index_graycode; // Part of the clock_rd clock domain

    // Assumption: we have a bin2gray and gray2bin modules
    // Alternatively, we can just use a clocked gray counter module as well, may save some logic
    bin2gray #(width=DATA_WIDTH) inst_wr_index_graycode (.bin_in(wr_index), .gray_out(wr_index_graycode));
    bin2gray #(width=DATA_WIDTH) inst_rd_index_graycode (.bin_in(rd_index), .gray_out(rd_index_graycode));
    // Need the following for our 'full' flag logic
    bin2gray #(width=DATA_WIDTH) inst_wr_index_inc_1_graycode (.bin_in((wr_index+1)%FIFO_SIZE), .gray_out(wr_index_inc_1_graycode));

    reg [FIFO_DEPTH:0] wr_index_graycode_rdclk_sync [1:0]; // Synchronize wr_index signal to clock_wr domain
    wire [FIFO_DEPTH:0] wr_index_graycode_rdclk_sync_s; // Synchronize wr_index signal to clock_wr domain
    assign wr_index_graycode_rdclk_sync_s <= wr_index_rdclk_sync[1];

    reg [FIFO_DEPTH:0] rd_index_graycode_wrclk_sync [1:0]; // Synchronize rd_index signal to clock_wr domain
    wire [FIFO_DEPTH:0] rd_index_graycode_wrclk_sync_s; // Convienence signal to alias the synchronized signal
    assign rd_index_graycode_wrclk_sync_s <= rd_index_wrclk_sync[1];

    wire wr_index_inc_1_graycode;
    bin2gray #(width=DATA_WIDTH) inst_wr_index_inc_1_graycode (.bin_in(wr_index+1), .gray_out(wr_index_inc_1_graycode));
    always @(*) begin
        // If the read pointer is mapped to the same (ex. such as at reset), flag the fifo as 'empty'
        fifo_empty_s = (wr_index_graycode_rdclk_sync_s == rd_index_graycode) ? 1 : 0;

        // If write pointer is leading right behind the read pointer, flag the fifo as 'full'
        fifo_full_s = (wr_index_inc_1_graycode == rd_index_graycode_wrclk_sync_s) ? 1 : 0;

        // Assign the ports to flag signals
        fifo_empty = fifo_empty_s;
        fifo_full = fifo_full_s;
    end

    /****************************************************************
                Write clock domain
    ****************************************************************/

    // Synchronizers
    always @(posedge clock_wr) begin
        rd_index_wrclk_sync[0] <= rd_index;
        rd_index_wrclk_sync[1] <= rd_index_wrclk_sync[0];
    end

    always @(posedge clock_wr) begin
        if (!reset_wr_n) begin
            wr_index <= 0;
        else
            if (write_en) begin
                if (!fifo_full_s) begin
                    memory[wr_index] <= data_in;
                    wr_index <= (wr_index + 1) % FIFO_SIZE; // Increment and wrap around the write pointer
                else
                    // We could put some sort of assertion here if the design demands it for catching errors in simulation
                end
            end
        end
    end

    // Read clock domain
    // Synchronizers
    always @(posedge clock_rd) begin
        wr_index_rdclk_sync[0] <= wr_index;
        wr_index_rdclk_sync[1] <= wr_index_rdclk_sync[0];
    end

    always @(posedge clock_rd) begin
        // Do we want synchronous reset?
        if (!reset_rd_n) begin
            rd_index <= 0;
        else
            data_out <= memory[rd_index];
            if (read_en) begin
                if (!fifo_empty_s) begin
                    // Advances the read pointer but the data_out will not update till next clock cycle
                    // such that the data_out is ready by the time the driver asserts the read_en and 1 cycle after
                    rd_index <= (rd_index + 1) % FIFO_SIZE; // Increment and wrap around the read pointer
                else
                    // We could put some sort of assertion here if the design demands it for catching errors in simulation
                end
            end
        end
    end

endmodule
