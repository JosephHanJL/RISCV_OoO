
// Map Table module

`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"

// Maintain a table mapping source registers in incoming instructions to tags that correspond to outputs of CDB

module map_table(
    input logic clock,
    input logic reset,
    input CDB_PACKET cdb_packet,
    input ID_RS_PACKET id_rs_packet,
    input logic dispatch_valid,
    input RS_TAG fu_source,

    output RS_TAG rs_tag_a,
    output RS_TAG rs_tag_b
);

    RS_TAG mtable [31:0];

    // update the map table field when RS says the dispatch is valid and the inst has a destination reg
    wire write_field = dispatch_valid && id_rs_packet.rd_valid;

    always_ff (@posedge clock) begin
        if (reset) begin
            // clear map table on reset
            for(int i = 0; i < 32; i++) begin
                mtable[i] <= 0;
            end
        end else begin
            // clear field where cdb tag matches mtable entry
            for (int i = 0; i < 32; i++) begin
                mtable[i] <= (mtable[i] == cdb_packet.tag) ? `ZERO_REG : mtable[i];
            end
            // update the map table field
            if (write_field) begin
                mtable[id_rs_packet.dest_reg_idx] <= fu_source;
            end
        end
    end

    assign rs_tag_a = id_rs_packet.rs1_valid ? mtable[id_rs_packet.rs1_idx] : `ZERO_REG;
    assign rs_tag_b = id_rs_packet.rs2_valid ? mtable[id_rs_packet.rs2_idx] : `ZERO_REG;


endmodule