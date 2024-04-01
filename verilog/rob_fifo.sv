`include "verilog/sys_defs.svh"

// Parameterized FIFO module definition with generic depth and data type.
module rob_fifo #(
    parameter int DEPTH = 8,                      // FIFO depth, configurable.
    parameter int ADDR_WIDTH = $clog2(DEPTH)      // Address width calculated based on the depth.
)(
    input logic clock,                            // Clock signal.
    input logic reset,                            // Asynchronous reset signal.
    input logic wr_en,                            // Write enable signal.
    input logic rd_en,                            // Read enable signal.
    input ROB_ENTRY data_in,                      // Data input of custom type ROB_ENTRY.
    output ROB_ENTRY data_out,                    // Data output of custom type ROB_ENTRY.
    output logic full,                            // FIFO full flag.
    output logic empty                            // FIFO empty flag.
);

// Internal memory and pointers
ROB_ENTRY memory [DEPTH-1:0];                    // Memory array to store FIFO data.
logic [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;           // Write and read pointers.
logic [ADDR_WIDTH:0] count;                      // Counter to track the number of items in FIFO.

// Write logic
always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
        wr_ptr <= 0;                             // Reset write pointer.
        count <= 0;                              // Reset counter.
        full <= 0;                               // Clear full flag.
    end else if (wr_en && !full) begin
        memory[wr_ptr] <= data_in;               // Write data into memory.
        wr_ptr <= (wr_ptr + 1) % DEPTH;          // Increment write pointer with wrap-around.
        count <= count + 1;                      // Increment counter.
    end
    full <= (count == DEPTH);                    // Set full flag if counter equals FIFO depth.
end

// Read logic
always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
        rd_ptr <= 0;                             // Reset read pointer.
        empty <= 1;                              // Set empty flag.
    end else if (rd_en && !empty) begin
        data_out <= memory[rd_ptr];              // Read data from memory.
        rd_ptr <= (rd_ptr + 1) % DEPTH;          // Increment read pointer with wrap-around.
        count <= count - 1;                      // Decrement counter.
    end
    empty <= (count == 0);                       // Set empty flag if counter is zero.
end

endmodule
