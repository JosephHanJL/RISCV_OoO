`include "sys_defs.svh"


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
    input logic clock,
    input logic reset,
    input logic clear,
    input FU_CDB_PACKET fu_cdb_packet,
    output CDB_FU_PACKET cdb_fu_packet,
    output CDB_PACKET cdb_packet
);

    logic [`NUM_FU-1:0] ack;

    ps u_ps (
    .dones    (fu_cdb_packet.dones),
    .ack      (ack)
    );

    // Assumes done signal is only ever active one clock cycle
    always_ff @(posedge clock) begin
        if (reset || clear) begin
            cdb_packet <= '0;
        end else begin
            for (int i = 0; i < `NUM_FU; i++) begin
                // copy FU fields to CDB for acknowledged done signal
                if (ack[i]) begin
                    cdb_packet.rob_tag <= fu_cdb_packet.rob_tags[i];
                    cdb_packet.v <= fu_cdb_packet.v[i];
                end
            end
        end
    end

    assign cdb_fu_packet.ack = ack;

endmodule
