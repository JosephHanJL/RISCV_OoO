`include "verilog/sys_defs.svh"

// Very simple priority selector for testing
module ps(
    input logic  [`NUM_FU-1:0] dones,
    output logic [`NUM_FU-1:0] ack
);

    // give priority to MSBs
    always_comb begin
        ack = '0;
        for (int i = `NUM_FU-1; i >= 0; i--) begin
            ack[i] = dones[i] & !ack;
        end
    end

endmodule


module cdb(
    // global signals
    input logic clock,
    input logic reset,
    // input packets
    input EX_CDB_PACKET ex_cdb_packet,
    // output packets
    output CDB_EX_PACKET cdb_ex_packet,
    output CDB_PACKET cdb_packet
);

    logic [`NUM_FU-1:0] ack;
    logic [`NUM_FU-1:0] dones;

    // unpack done bits;
    always_comb begin
        for (int i = 0; i < `NUM_FU; i++) begin
            dones[i] = ex_cdb_packet.fu_out_packets[i].done;
        end
    end


    ps u_ps (
    .dones    (dones),
    .ack      (ack)
    );

    always_comb begin
        cdb_packet = '0;
        for (int i = 0; i < `NUM_FU; i++) begin
            if (ack[i]) begin   // if 
                cdb_packet.rob_tag = ex_cdb_packet.fu_out_packets[i].rob_tag;
                cdb_packet.v = ex_cdb_packet.fu_out_packets[i].v;
            end
        end
    end

    assign cdb_ex_packet.ack = ack;

endmodule
