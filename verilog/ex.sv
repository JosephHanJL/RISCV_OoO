// Version 1.0

`include "verilog/sys_defs.svh"

`define TESTBENCH

// Fully combinational module to link RS to each FU

module ex(
    // global signals
    input logic clock,
    input logic reset,
    input logic squash,

    // input packets
    input CDB_PACKET cdb_packet,
    input CDB_EX_PACKET cdb_ex_packet,
    input RS_EX_PACKET rs_ex_packet,

    // output packets
    output EX_CDB_PACKET ex_cdb_packet

    // debug
);


    alu_fu fu_1 (
        // global signals
        .clock            (clock),
        .reset            (reset || squash),
        // ack bit from CDB
        .ack              (cdb_ex_packet.ack[1]),
        // input packets
        .fu_in_packet     (rs_ex_packet.fu_in_packets[1]),
        // output packets
        .fu_out_packet    (ex_cdb_packet.fu_out_packets[1])
    );

    alu_fu fu_2 (
        // global signals
        .clock            (clock),
        .reset            (reset || squash),
        // ack bit from CDB
        .ack              (cdb_ex_packet.ack[2]),
        // input packets
        .fu_in_packet     (rs_ex_packet.fu_in_packets[2]),
        // output packets
        .fu_out_packet    (ex_cdb_packet.fu_out_packets[2])
    );

    mult_fu fu_5 (
        // global signals
        .clock            (clock),
        .reset            (reset || squash),
        // ack bit from CDB)
        .ack              (cdb_ex_packet.ack[5]),
        // input packets
        .fu_in_packet     (rs_ex_packet.fu_in_packets[5]),
        // output packets
        .fu_out_packet    (ex_cdb_packet.fu_out_packets[5])
    );

    mult_fu fu_6 (
        // global signals
        .clock            (clock),
        .reset            (reset || squash),
        // ack bit from CDB)
        .ack              (cdb_ex_packet.ack[6]),
        // input packets
        .fu_in_packet     (rs_ex_packet.fu_in_packets[6]),
        // output packets
        .fu_out_packet    (ex_cdb_packet.fu_out_packets[6])
    );


endmodule