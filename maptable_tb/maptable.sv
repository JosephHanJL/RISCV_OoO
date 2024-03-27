`include "sys_defs.svh"
`include "ISA.svh"

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

    RS_TAG mtable [4:0];

    wire write_field = dispatch_valid && id_rs_packet.rd_valid;

    always_ff @(posedge clock) begin
        if (reset) begin
            for(int i = 0; i < 32; i++) begin
                mtable[i] <= 0;
            end
        end else begin
            // clear field where cdb tag matched mtable entry
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
