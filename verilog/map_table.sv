`include "verilog/sys_defs.svh"

`define TESTBENCH

module map_table(
    input logic clock,
    input logic reset,
    input CDB_PACKET cdb_packet,
    input ROB_ENTRY rob_tail_packet,
    input ROB_ENTRY rob_head_packet,
    input logic dispatch_valid,
    input logic retire_valid,

    output MAP_PACKET map_packet_a,
    output MAP_PACKET map_packet_b

    `ifdef TESTBENCH
        , output MAP_PACKET m_table_dbg [31:0]
    `endif
);

    MAP_PACKET mtable [31:0];

    // update the map table field when RS says the dispatch is valid and the inst has a destination reg
    wire write_field = dispatch_valid && rob_tail_packet.id_packet.rd_valid;

    always_ff @(posedge clock) begin
        if (reset) begin
            for(int i = 0; i < 32; i++) begin
                mtable[i] <= 0;
            end
        end else begin
            // set t_plus tag where cdb tag matches mtable entry (data should now be found in ROB)
            for (int i = 0; i < 32; i++) begin
                mtable[i].t_plus <= (mtable[i].rob_tag == cdb_packet.rob_tag) ? 1 : mtable[i].t_plus;
            end
            // clear table entry when ROB retires an instruction
            if (retire_valid) begin
                for (int i = 0; i < 32; i++) begin
                    if (mtable[i].rob_tag == rob_head_packet.rob_tag) begin
                        mtable[i].t_plus  <= 0;
                        mtable[i].rob_tag <= 0;
                    end
                end
            end
            // set ROB tag when new instruction dispatched
            // this has priority over clears and t_plus
            if (write_field) begin
                mtable[rob_tail_packet.id_packet.dest_reg_idx].rob_tag <= rob_tail_packet.rob_tag;
            end
        end
    end

    assign map_packet_a = rob_tail_packet.id_packet.rs1_valid ? mtable[rob_tail_packet.id_packet.rs1_idx] : `ZERO_REG;
    assign map_packet_b = rob_tail_packet.id_packet.rs2_valid ? mtable[rob_tail_packet.id_packet.rs2_idx] : `ZERO_REG;

    `ifdef TESTBENCH
        assign m_table_dbg = mtable;
    `endif

endmodule
