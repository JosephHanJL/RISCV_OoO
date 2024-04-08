//////////////////////////////////////////////////////////////////////////////////////////////////
// Version 2.7.0
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
    ROB_TAG head, tail; // logic [2:0], 3 bits index
    logic rd_en; // Read enable signal.
    ROB_ENTRY data_in; // Data input to fifo.
    ROB_ENTRY data_out; // Data output of custom type ROB_ENTRY.
    logic full; // FIFO full flag.
    logic empty; // FIFO empty flag.
    logic [$clog2(`ROB_SZ)-1:0] wr_ptr, rd_ptr; // Write and read pointers.
    logic [$clog2(`ROB_SZ):0] count; // Counter to track the number of items in FIFO.

    //////////////////////////////////////////////////////////////////////////////////////////////
    // ROB internal signals define:
    logic data_available;

    //////////////////////////////////////////////////////////////////////////////////////////////
    // ROB Operational logic:
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            rob_map_packet <= '0; // Output packets initialization
            rob_rs_packet  <= '0;

            structural_hazard_rob <= '0; // Output signal initialization

        end else begin                          
        end                                              
    end

    always_comb begin
        if (empty)
            rob_rs_packet.rob_tail.dp_packet = instructions_buffer_rob_packet;
        else
            rob_rs_packet.rob_tail = rob_memory[tail];
        
        rob_rs_packet.rob_dep_a = rob_memory[map_rob_packet.map_packet_a.rob_tag];
        rob_rs_packet.rob_dep_b = rob_memory[map_rob_packet.map_packet_b.rob_tag];

        for (logic [$clog2(`ROB_SZ)-1:0] index = 0;  index < ROB_SZ; i++) begin
            if (index >= tail && index <= head) begin
                if (rob_memory[index].r === cdb_rob_packet.rob_tag)
                    rob_memory[index].V = cdb_rob_packet.v;
                
                if (rob_memory[index].V )
            end
        end

        
    end

    //////////////////////////////////////////////////////////////////////////////////////////////
    // FIFO Operational logic:
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            for (int i = 0; i < `ROB_SZ; i++) begin // FIFO initialation
                rob_memory[i] <= '0;
            end

            // initialize FIFO signals
            head        <= '0;
            tail        <= '0;
            rd_en       <= '0;
            data_in     <= '0;
            data_out    <= '0;
            wr_ptr      <= '0;
            rd_ptr      <= '0;
            count       <= '0;

        end else begin
            if (!empty) begin
                data_out <= rob_memory[rd_ptr]; // Read data from memory.
                rd_ptr <= (rd_ptr + 1) % `ROB_SZ; // Increment read pointer with wrap-around.
                count <= count - 1; // Decrement counter.

            end else if (data_available) begin
                rob_memory[wr_ptr] <= data_in; // Write data into memory.
                wr_ptr <= (wr_ptr + 1) % `ROB_SZ; // Increment write pointer with wrap-around.
                count <= count + 1; // Increment counter.
            end
        end                                              
    end

    always_comb begin
        rob_map_packet.rob_head = head;
        rob_map_packet.rob_new_tail = tail;
        rob_map_packet.retire_valid = rob_memory[head].complete && rob_memory[head].dp_packet.valid;
    end

    assign full     = (count === `ROB_SZ)   ? 1'b1 : 1'b0;
    assign empty    = (count === 0)         ? 1'b1 : 1'b0;
    assign rob_dp_available = (count === `ROB_SZ)   ? 2'b00 : (count === `ROB_SZ - 1) ? 2'b01 : 2'b10;
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