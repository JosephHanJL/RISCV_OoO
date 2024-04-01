`include "verilog/sys_defs.svh"

module rob(
    input logic clock,
    input logic reset,
    // from stage_id
    input ID_RS_PACKET id_packet,

    // from CDB
    input CDB_PACKET cdb_packet,
    output logic [`XLEN-1:0] r
    );

typedef rob_entry {

}


endmodule
