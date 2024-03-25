
// Map Table module

`include "verilog/sys_defs.svh"
`include "verilog/ISA.svh"

// Maintain a table mapping source registers in incoming instructions to tags that correspond to outputs of CDB

module map_table(
    input logic clock,
    input logic reset,
    input CDB_PACKET cdb_packet,
    input ID_RS_PACKET id_rs_packet,
    output logic []
);