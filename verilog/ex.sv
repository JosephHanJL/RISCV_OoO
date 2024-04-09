// Version 1.0
`include "verilog/sys_defs.svh"

`define TESTBENCH

// Fully combinational module to link RS to each FU

module ex(
    // global signals
    input logic clock,
    input logic reset,
    input logic squash,
    input logic ack,

    // input packets
    input CDB_PACKET cdb_packet,
    input CDB_EX_PACKET cdb_ex_packet,
    input RS_EX_PACKET rs_ex_packet,

    // output packets
    output EX_CDB_PACKET ex_cdb_packet

    // debug
);

    mult_fu fu_4 (
        // global signals
        .clock            (clock),
        .reset            (reset || squash),
        .ack              (cdb_ex_packet.ack[4]),
        .fu_in_packet     (rs_ex_packet.fu_in_packets[4]),
        .fu_out_packet    (ex_cdb_packet.fu_out_packets[4])
    );

    mult_fu fu_5 (
        // global signals
        .clock            (clock),
        .reset            (reset || squash),
        .ack              (cdb_ex_packet.ack[5]),
        .fu_in_packet     (rs_ex_packet.fu_in_packets[5]),
        .fu_out_packet    (ex_cdb_packet.fu_out_packets[5])
    );


endmodule