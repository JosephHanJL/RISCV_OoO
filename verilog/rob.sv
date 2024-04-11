///////////////////////////////
// ---- Test_Bench_Def ----- //
// ------Version 20.4--------//
///////////////////////////////
`timescale 1ns/100ps

`ifdef TESTBENCH
    `include "sys_defs.svh"
    `define INTERFACE_PORT rob_interface.producer rob_memory_intf
`else
    `include "verilog/sys_defs.svh"
    `define INTERFACE_PORT
`endif

///////////////////////////////
// ---- ROB Module --------- //
///////////////////////////////
module rob(
    // Basic Signal Input:
    input logic clock,
    input logic reset,
    // Signal for rob:
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

    // dispatch available
    input logic [1:0] dp_rob_available, 
    output logic [10:0] rob_dp_available, 

    // output retire inst to dispatch_module:
    output ROB_RT_PACKET  rob_rt_packet,
    
    // Rob_interface, just for rob_test
    `INTERFACE_PORT
    );

    ///////////////////////////////
    // ----- FIFO internal ----- //
    ///////////////////////////////
    ROB_ENTRY rob_memory [`ROB_SZ - 1:0]; // ROB_SZ default to 8

    ROB_TAG head; // head and tail pointer for FIFO
    ROB_TAG tail;

    ROB_ENTRY data_in; // Data input to fifo.

    logic full; // FIFO full flag.
    logic empty; // FIFO empty flag.

    logic [`ROB_TAG_WIDTH + 1 : 0] count; // Counter to track the number of items in FIFO.

    // ROB internal signals define:
    logic data_available;

    ///////////////////////////////
    //   ROB Operational logic   //
    ///////////////////////////////
    always_comb begin
        // Sending packets to map_table: (index problem)
        //rob_map_packet.rob_head = rob_memory[head];
        // rob_map_packet.rob_new_tail = rob_memory[tail]; //update to below:
        //rob_map_packet.retire_valid = rob_memory[head].complete && rob_memory[head].dp_packet.valid;

        // Modulate info sending to Reservation Station
        /*
        if (empty) begin
            // If ROB is empty, just forward the new dp packet to rs:
            rob_rs_packet.rob_tail.dp_packet = instructions_buffer_rob_packet;
            // If ROB is empty, just forward the new dp packet to map_table:
            rob_map_packet.rob_head.dp_packet = instructions_buffer_rob_packet;
            rob_map_packet.rob_new_tail.dp_packet = instructions_buffer_rob_packet;
            rob_map_packet.retire_valid = 1'b0;
        end else begin
            // If ROB is not empty:
            rob_rs_packet.rob_tail = rob_memory[tail];
            rob_map_packet.rob_head = rob_memory[head];
            rob_map_packet.rob_new_tail = rob_memory[tail];
            rob_map_packet.retire_valid = rob_memory[head].complete && rob_memory[head].dp_packet.valid;
        end
        */
        rob_rs_packet.rob_tail = rob_memory[tail];
        rob_map_packet.rob_head = rob_memory[head];
        rob_map_packet.rob_new_tail = rob_memory[tail];
        rob_map_packet.retire_valid = rob_memory[head].complete && rob_memory[head].dp_packet.valid;

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

    ///////////////////////////////
    // -FIFO Operational logic-- //
    ///////////////////////////////
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            for (int i = 0; i < `ROB_SZ; i++) begin // FIFO initialation
                rob_memory[i] <= '0;
            end

            // initialize FIFO signals
            head            <= 0;
            tail            <= 0;
            count           <= 0;

        end else begin
            // Read Logic
            if (!empty && rob_memory[head].complete) begin
                rob_rt_packet.data_retired <= rob_memory[head];   // Read data from memory.
                rob_memory[head]           <= '0;
                head <= (head + 1) % `ROB_SZ ;       // Increment read pointer with wrap-around.

            end

            // Write Logic
            if (!full && data_available) begin // Accept data available signal from dispatch
                rob_memory[tail].dp_packet <= instructions_buffer_rob_packet; // Write dp part into memory.
                rob_memory[tail].rob_tag <= tail + 1; // Assign the rob_tag
                if (instructions_buffer_rob_packet.has_dest)
                    rob_memory[tail].r <= instructions_buffer_rob_packet.dest_reg_idx; // Assign the destination reg to current ROB#
                tail <= (tail + 1) % `ROB_SZ; // Increment write pointer with wrap-around.
            end

            case ({data_available && !full, !empty & rob_memory[head].complete})
                2'b10: count <= count + 1; // Write but not full
                2'b01: count <= count - 1; // read but not empty
                default: count <= count; // stay the same
            endcase
        end       

        // Check CDB, and update the broadcast value in fifo
        if (cdb_rob_packet.rob_tag !== 0)
            for (int index = 0; index < `ROB_SZ; index++) begin
                if (rob_memory[index].rob_tag === cdb_rob_packet.rob_tag) begin
                    rob_memory[index].V <= cdb_rob_packet.v;
                    rob_memory[index].complete <= 1'b1;
                end
            end                                    
    end

    assign full  = ((count === `ROB_SZ) | 
                    (instructions_buffer_rob_packet.fu_sel === Store && empty)) ? 1'b1 : 1'b0;

    assign empty = (count === 0) ? 1'b1 : 1'b0;
    assign rob_dp_available = full ? 2'b00 : 
           (count === `ROB_SZ - 1) ? 2'b01 : 2'b10; // Send the ROB fifo state to duspatch
    //assign rob_dp_available = count;

    assign data_available = ^dp_rob_available;

    always_comb begin
        `ifdef TESTBENCH
            foreach (rob_memory_intf.rob_memory[i]) begin
                rob_memory_intf.rob_memory[i] = rob_memory[i];
            end
        `endif
    end
endmodule

///////////////////////////////
// --Interface for rob_test- //
///////////////////////////////
interface rob_interface;
    ROB_ENTRY rob_memory[`ROB_SZ - 1:0];

    modport producer (output rob_memory);
    modport consumer (input rob_memory);
endinterface