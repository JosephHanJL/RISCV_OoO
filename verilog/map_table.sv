
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

    RS_TAG mtable [4:0];


    always_ff (@posedge clock) begin
        if (reset) begin
            // clear map table on reset
            for(int i = 0; i < 4; i++) begin
                mtable[i] <= 0;
            end
        else begin
            if (dispatch_valid) begin
                mtable[id_rs_packet.dest_reg_idx] <= fu_source;
            end
        end
    end

    assign rs_tag_a = id_rs_packet.rs1_valid ? mtable[id_rs_packet.rs1_idx] : `ZERO_REG;
    assign rs_tag_b = id_rs_packet.rs2_valid ? mtable[id_rs_packet.rs2_idx] : `ZERO_REG;


endmodule