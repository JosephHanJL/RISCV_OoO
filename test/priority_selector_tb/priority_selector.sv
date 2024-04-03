`include "sys_defs.svh"

// Very simple priority selector for testing
module priority_selector(
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