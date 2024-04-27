// Version 2.0
`include "verilog/sys_defs.svh"

`define TESTBENCH

module map_table(
    // global signals
    input logic clock,
    input logic reset,
    input logic dispatch_valid,

    // input packets
    input CDB_PACKET cdb_packet,
    input ROB_MAP_PACKET rob_map_packet,
    input DP_PACKET dp_packet,
    input BRANCH_PACKET branch_packet,

    // output packets
    output MAP_RS_PACKET map_rs_packet,
    output MAP_ROB_PACKET map_rob_packet,

    // debug
    output MAP_PACKET [31:0] m_table_dbg
);

    // map table memory
    MAP_PACKET [31:0] m_table;
    MAP_PACKET [`ROB_SZ:0][31:0] m_table_record;

    // update the map table field when RS says the dispatch is valid and the inst has a destination reg
    wire write_field = dispatch_valid && dp_packet.has_dest && dp_packet.dest_reg_idx != `ZERO_REG;

    // packets for current instr to be dispatched
    MAP_PACKET map_packet_a, map_packet_b;

    always_ff @(posedge clock) begin
        if (reset) begin
            for(int i = 0; i < 32; i++) begin
                m_table[i] <= '0;
                m_table_record <= '0;
            end
        end else begin
            // store state for later jumps
            if (dispatch_valid) m_table_record[rob_map_packet.rob_new_tail.rob_tag-1] <= m_table;
            // set t_plus tag where cdb tag matches m_table entry (data should now be found in ROB)
            for (int i = 0; i < 32; i++) begin
                // rob_tag = 0 means default.
                if (cdb_packet.rob_tag !== 0) begin
                    m_table[i].t_plus <= (m_table[i].rob_tag == cdb_packet.rob_tag && m_table[i].rob_tag != `ZERO_REG) ? 1 : m_table[i].t_plus;
                end
                // update map table record (inefficient)
                for (int j = 0; j<= `ROB_SZ; j++) begin
                    if (cdb_packet.rob_tag !== 0) begin
                        m_table_record[j][i].t_plus <= (m_table_record[j][i].rob_tag == cdb_packet.rob_tag && m_table_record[j][i].rob_tag != `ZERO_REG) ? 
                                                       1 : m_table_record[j][i].t_plus;
                    end
                end
            end
            // clear table entry when ROB retires an instruction
            if (rob_map_packet.retire_valid) begin
                for (int i = 0; i < 32; i++) begin
                    if (m_table[i].rob_tag == rob_map_packet.rob_head.rob_tag) begin
                        m_table[i].t_plus  <= 0;
                        m_table[i].rob_tag <= 0;
                    end
                    // also clear record (will only clear the once)
                    for (int j = 0; j<= `ROB_SZ; j++) begin
                        if (m_table_record[j][i].rob_tag == rob_map_packet.rob_head.rob_tag) begin
                            m_table_record[j][i].t_plus  <= 0;
                            m_table_record[j][i].rob_tag <= 0;
                        end
                    end
                end
                
            end
            // set ROB tag when new instruction dispatched
            // this has priority over clears and t_plus
            if (write_field) begin
                m_table[dp_packet.dest_reg_idx].rob_tag <= rob_map_packet.rob_new_tail.rob_tag;
                m_table[dp_packet.dest_reg_idx].t_plus <= 0;
                // store state of m_table for later rollback if jump
                m_table_record[rob_map_packet.rob_new_tail.rob_tag][dp_packet.dest_reg_idx].rob_tag <= rob_map_packet.rob_new_tail.rob_tag;
                m_table_record[rob_map_packet.rob_new_tail.rob_tag][dp_packet.dest_reg_idx].t_plus <= 0;
            end
            // Squash logic
            if (branch_packet.branch_valid) begin
                // revert to earlier m_table state (captures incorrect overwrites)
                m_table <= m_table_record[branch_packet.rob_tag];
                // preserve t_plus (copied from above)
                // for (int i = 0; i < 32; i++) begin
                //     // re-assert clearing
                //     if (cdb_packet.rob_tag !== 0) begin
                //         m_table[i].t_plus <= (m_table[i].rob_tag == cdb_packet.rob_tag && m_table[i].rob_tag != `ZERO_REG) ? 1 : m_table[i].t_plus;
                //     end
                // end
                m_table_record <= '0;
            end
        end
    end

    // index map table for rs1 and rs2
    assign map_packet_a =   dp_packet.rs1_valid ? 
                            m_table[dp_packet.rs1_idx] : `ZERO_REG;
    assign map_packet_b =   dp_packet.rs2_valid ? 
                            m_table[dp_packet.rs2_idx] : `ZERO_REG;

    // form output packets
    assign map_rs_packet.map_packet_a = map_packet_a;
    assign map_rs_packet.map_packet_b = map_packet_b;
    assign map_rob_packet = map_rs_packet;

    assign map_table_dbg = m_table;

endmodule
