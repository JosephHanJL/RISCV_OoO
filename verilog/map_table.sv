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
    output MAP_PACKET map_packet_b,

    output MAP_PACKET m_table [31:0]

);


    // update the map table field when RS says the dispatch is valid and the inst has a destination reg
    wire write_field = dispatch_valid && rob_tail_packet.id_packet.rd_valid;

    always_ff @(posedge clock) begin
        if (reset) begin
            for(int i = 0; i < 32; i++) begin
                m_table[i] <= 0;
            end
        end else begin
            // set t_plus tag where cdb tag matches m_table entry (data should now be found in ROB)
            for (int i = 0; i < 32; i++) begin
                m_table[i].t_plus <= (m_table[i].rob_tag == cdb_packet.rob_tag) ? 1 : m_table[i].t_plus;
            end
            // clear table entry when ROB retires an instruction
            if (retire_valid) begin
                for (int i = 0; i < 32; i++) begin
                    if (m_table[i].rob_tag == rob_head_packet.rob_tag) begin
                        m_table[i].t_plus  <= 0;
                        m_table[i].rob_tag <= 0;
                    end
                end
            end
            // set ROB tag when new instruction dispatched
            // this has priority over clears and t_plus
            if (write_field) begin
                m_table[rob_tail_packet.id_packet.dest_reg_idx].rob_tag <= rob_tail_packet.rob_tag;
            end
        end
    end

    assign map_packet_a = rob_tail_packet.id_packet.rs1_valid ? m_table[rob_tail_packet.id_packet.rs1_idx] : `ZERO_REG;
    assign map_packet_b = rob_tail_packet.id_packet.rs2_valid ? m_table[rob_tail_packet.id_packet.rs2_idx] : `ZERO_REG;

endmodule
