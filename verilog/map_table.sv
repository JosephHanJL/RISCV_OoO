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

    output MAP_TAG rob_tag_a,
    output MAP_TAG rob_tag_b,
    `ifdef TESTBENCH
        , output RS_TAG m_table_dbg [31:0]
    `endif
);

    RS_TAG mtable [31:0];

     // update the map table field when RS says the dispatch is valid and the inst has a destination reg
    wire write_field = dispatch_valid && rob_tail_packet.id_packet.rd_valid;

    always_ff @(posedge clock) begin
        if (reset) begin
            for(int i = 0; i < 32; i++) begin
                mtable[i] <= 0;
            end
        end else begin
            // set  field where cdb tag matched mtable entry
            for (int i = 0; i < 32; i++) begin
                mtable[i] <= (mtable[i] == cdb_packet.tag) ? `ZERO_REG : mtable[i];
            end
            // update the map table field
            if (write_field) begin
                mtable[rob_tail_packet.id_packet.dest_reg_idx] <= fu_source;
            end
        end
    end

    assign rob_tag_a = rob_tail_packet.id_packet.rs1_valid ? mtable[rob_tail_packet.id_packet.rs1_idx] : `ZERO_REG;
    assign rob_tag_b = rob_tail_packet.id_packet.rs2_valid ? mtable[rob_tail_packet.id_packet.rs2_idx] : `ZERO_REG;

    `ifdef TESTBENCH
        assign m_table_dbg = mtable;
    `endif

endmodule
