`include "verilog/sys_defs.svh"

module rob(
    input logic clock,
    input logic reset,
    // from stage_id
    input ID_RS_PACKET id_packet,

    // from functional units
    input CDB_PACKET fu_packet,// Abusing the notation here, this does not come from the CDB. rather, the same CDB packet is written both to CDB and the RS
    
    // to regfile
    output logic [4:0] r,
    output logic [`XLEN-1:0] v
    );

endmodule
