//////////////////////////////////////////////////////////////////////////////////////////////////
// Version 11.2
`ifdef TESTBENCH
    `include "sys_defs.svh"
    `define INTERFACE_PORT rob_interface.producer rob_memory_intf
`else
    `include "verilog/sys_defs.svh"
    `define INTERFACE_PORT
`endif
//////////////////////////////////////////////////////////////////////////////////////////////////

module rob(
    // Basic Signal Input:
    input logic clock,
    input logic reset,
    //////////////////////////////////////////////////////////////////////////////////////////////
    // Signal for rob
    // Input packages from Map_Table:
    input MAP_ROB_PACKET map_rob_packet,
    // Output packages to Map_Table:
    output ROB_MAP_PACKET rob_map_packet,

    // Input packages from Instructions_Buffer:
    input DP_PACKET instructions_buffer_rob_packet,

    // Output packages to Map_Table:
    output ROB_RS_PACKET rob_rs_packet, 

    // Input packages to ROB
    input CDB_ROB_PACKET cdb_rob_packet,
    
    // Harzard Signal for ROB
    output logic structural_hazard_rob,

    // dispatch available
    input logic [1:0] dp_rob_available, 
    output logic [1:0] rob_dp_available, 
    
    // Rob_interface, just for rob_test
    `INTERFACE_PORT
    );

    //////////////////////////////////////////////////////////////////////////////////////////////
    // FIFO internal signals define:
    ROB_ENTRY rob_memory [`ROB_SZ - 1:0]; // ROB_SZ default to 8

    ROB_TAG head; // head and tail pointer for FIFO
    ROB_TAG tail;

    ROB_ENTRY data_in; // Data input to fifo.
    ROB_ENTRY data_retired; // Data output of custom type ROB_ENTRY.

    logic full; // FIFO full flag.
    logic empty; // FIFO empty flag.

    logic [`ROB_TAG_WIDTH : 0] count; // Counter to track the number of items in FIFO.

    //////////////////////////////////////////////////////////////////////////////////////////////
    // ROB internal signals define:
    logic data_available;

    //////////////////////////////////////////////////////////////////////////////////////////////
    // ROB Operational logic:
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            structural_hazard_rob <= '0; // Output signal initialization

        end else begin                          
        end                                              
    end

    always_comb begin
        // Sending packets to map_table: (index problem)
        rob_map_packet.rob_head = rob_memory[head];
        // rob_map_packet.rob_new_tail = rob_memory[tail]; //update to below:
        rob_map_packet.retire_valid = rob_memory[head].complete && rob_memory[head].dp_packet.valid;

        // Modulate info sending to Reservation Station
        if (empty) begin
            // If ROB is empty, just forward the new dp packet to rs:
            rob_rs_packet.rob_tail.dp_packet = instructions_buffer_rob_packet;
            // If ROB is empty, just forward the new dp packet to map_table:
            rob_map_packet.rob_new_tail.dp_packet = instructions_buffer_rob_packet;

        end else begin
            // If ROB is not empty:
            rob_rs_packet.rob_tail = rob_memory[tail];
            rob_map_packet.rob_new_tail = rob_memory[tail];

        end

        // Sending packets to rs:
        if (map_rob_packet.map_packet_a !== `ZERO_REG)
            rob_rs_packet.rob_dep_a = rob_memory[map_rob_packet.map_packet_a.rob_tag];
        else
            rob_rs_packet.rob_dep_a = `ZERO_REG;

        if (map_rob_packet.map_packet_b !== `ZERO_REG)
            rob_rs_packet.rob_dep_b = rob_memory[map_rob_packet.map_packet_b.rob_tag];
        else
            rob_rs_packet.rob_dep_b = `ZERO_REG;
        
    end

    //////////////////////////////////////////////////////////////////////////////////////////////
    // FIFO Operational logic:
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            for (int i = 0; i < `ROB_SZ; i++) begin // FIFO initialation
                rob_memory[i] <= '0;
            end

            // initialize FIFO signals
            head            <= '0;
            tail            <= '0;
            data_retired    <= '0;
            count           <= '0;

        end else begin
            if (!empty && rob_memory[head].complete) begin
                data_retired <= rob_memory[head];   // Read data from memory.
                rob_memory[head] <= `ZERO_REG;      // Clearation
                head <= (head + 1) % `ROB_SZ;       // Increment read pointer with wrap-around.
                count <= count - 1; // Decrement counter.

            end else if (!full & data_available) begin // Accept data available signal from dispatch
                rob_memory[tail].dp_packet <= instructions_buffer_rob_packet; // Write dp part into memory.
                rob_memory[tail].rob_tag <= tail; // Assign the rob_tag
                tail <= (tail + 1) % `ROB_SZ; // Increment write pointer with wrap-around.
                count <= count + 1; // Increment counter.
            end

            // Check CDB, and update the broadcast value in fifo
            for (logic [$clog2(`ROB_SZ)-1:0] index = 0; index < `ROB_SZ; index++) begin
                // Check if the index is within the valid range:
                if ((tail > head && index >= head && index < tail) ||
                    (tail < head && (index >= head || index < tail))) begin
                    if (rob_memory[index].r === cdb_rob_packet.rob_tag) begin
                        rob_memory[index].V <= cdb_rob_packet.v;
                        // Set the complete bit:
                        rob_memory[index].complete <= 1'b1;
                    end
                end
            end

        end                                              
    end

    always_comb begin

    end

    assign full  = ((count === `ROB_SZ) || 
                    (instructions_buffer_rob_packet.alu_func === Store && !empty)) ? 1'b1 : 1'b0;

    assign empty = (count === 0) ? 1'b1 : 1'b0;
    assign rob_dp_available = full ? 2'b00 : 
           (count === `ROB_SZ - 1) ? 2'b01 : 2'b10; // Send the ROB fifo state to duspatch

    assign data_available = ^dp_rob_available;

    //////////////////////////////////////////////////////////////////////////////////////////////
    // rob_memory interface:
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            // rob_memory_intf initialization
            `ifdef TESTBENCH
                foreach (rob_memory_intf.rob_memory[i]) begin
                    rob_memory_intf.rob_memory[i] = '{default:0};
                end
            `endif

        end else begin
            // rob_memory_intf assignment
            `ifdef TESTBENCH
                foreach (rob_memory_intf.rob_memory[i]) begin
                    rob_memory_intf.rob_memory[i] = rob_memory[i];
                end
            `endif

        end                                              
    end

    //////////////////////////////////////////////////////////////////////////////////////////////

endmodule

//////////////////////////////////////////////////////////////////////////////////////////////////
// Interface for rob_test
interface rob_interface;
    ROB_ENTRY rob_memory[`ROB_SZ - 1:0];

    modport producer (output rob_memory);
    modport consumer (input rob_memory);
endinterface
//////////////////////////////////////////////////////////////////////////////////////////////////
