/******************************************************************************
Design a 32-entry FIFO (data width is e.g. 8 bits).
Bonus: FIFO depth and number of entries are parameterized

Parameters:
    FIFO_DEPTH: Entry depth of the FIFO. FIFO will store 2**(FIFO_DEPTH) entries.
    DATA_WIDTH: Data width size of a single entry in DATA_WIDTH bits.
Interface:
    input clock;
    input reset_n;

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

module FIFO #(
    FIFO_DEPTH = 4; // Number of entries is 2**FIFO_DEPTH
    DATA_WIDTH = 8;
) (
    input clock;
    input reset_n;

    // Write
    input[DATA_WIDTH-1:0]   data_in;    //Width will be parameterized for the bonus
    input                   write_en;   //Indicates valid data on the data_in,
                                        //data should be written into the FIFO in the
                                        //same clock cycle
    output                  fifo_full;  //The sender will not assert write_en when
                                        //fifo_full is asserted

    // Read
    output [DATA_WIDTH-1:0] data_out;   //Width will be parameterized for the bonus
    input                   read_en;    //Read enable, data_out is valid 1 clock cycle
                                        //after assertion of this signal
    output                  fifo_empty; //The receiver will not assert read_en when
                                        //fifo_empty is asserted
);

reg [DATA_WIDTH-1:0] memory [FIFO_DEPTH-1:0];
// Read and write counters allocate one extra bit width. The upper
// bit is reserved for a rollover flag to check if the read pointer
// is 'catching up' to the write pointer for full and empty flag
// checking
reg [FIFO_DEPTH:0] wr_index_ctr;
reg [FIFO_DEPTH:0] rd_index_ctr;
wire [FIFO_DEPTH-1:0] wr_index;
wire [FIFO_DEPTH-1:0] rd_index;
assign wr_index = wr_index_ctr[FIFO_DEPTH-1:0];
assign rd_index = rd_index_ctr[FIFO_DEPTH-1:0];

wire fifo_full_s;
wire fifo_empty_s;

always @(*) begin
    // If the read pointer is mapped to the same (ex. such as at reset), flag the fifo as 'empty'
    fifo_empty_s = (wr_index == rd_index) and (wr_index_ctr[FIFO_DEPTH] == rd_index_ctr[FIFO_DEPTH]);

    // If write pointer is leading ahead (ie. counter has rolled-over), flag the fifo as 'full'
    fifo_full_s = (wr_index == rd_index) and (wr_index_ctr[FIFO_DEPTH] != rd_index_ctr[FIFO_DEPTH]);

    // Assign the ports to flag signals
    fifo_empty = fifo_empty_s;
    fifo_full = fifo_full_s;
end

always @(posedge clock) begin
    if (!reset_n) begin
        wr_index <= 0;
        rd_index <= 0;
        // It's not really that important to reset the memory since we won't be
        // /shouldn't/ be using any un-initialized data. ie. We will write to
        // memory before we even read from it
    else
        if (write_en) begin
            if (!fifo_full_s) begin
                memory[wr_index] <= data_in;
                wr_index_ctr <= wr_index_ctr + 1; // Increment and wrap around the write pointer
            else
                // We could put some sort of assertion here if the design demands it for catching errors in simulation
            end
        end

        // Assign to whatever is currently pointing
        data_out <= memory[rd_index];
        if (read_en) begin
            if (!fifo_empty_s) begin
                // Advances the read pointer but the data_out will not update till next clock cycle
                // such that the data_out is ready by the time the driver asserts the read_en and 1 cycle after
                rd_index_ctr <= rd_index_ctr + 1; // Increment and wrap around the read pointer
            else
                // We could put some sort of assertion here if the design demands it for catching errors in simulation
            end
        end
    end
end

endmodule

// Example instantiation
// FIFO #(FIFO_SIZE=64, DATA_WIDTH=8) FIFO_64B ( .clock(clk_in), .reset_n(rst_n),
//                 .data_in(input_bus), .write_en(wr_en), .fifo_full(full_s),
//                 .data_out(output_bus), .read_en(rd_en), .fifo_empty(empty_s));