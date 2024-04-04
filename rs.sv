`include "sys_defs.svh"
`include "issue.svh"

typedef struct packed {
    logic [4:0] t1;
    logic [4:0] t2;
    logic [`XLEN-1:0] v1;
    logic [`XLEN-1:0] v2;
    FU_TYPE fu;
    logic [4:0] phy_dest_reg;
    logic [6:0] opcode;
    logic valid;
    logic busy;
    ID_EX_PACKET id_packet;
} ISSUE_PACKET;

module rs(
    input logic clock,
    input logic reset,
    input ID_RS_PACKET id_ex_reg,
    output ID_RS_PACKET out_reg,
) {
    // Define and initialize the issue packets array
    ISSUE_PACKET issue [4:0];

    // Initialize FU types for each issue packet instance
    initial begin
        issue[0].fu = ALU;
        issue[1].fu = Load;
        issue[2].fu = Store;
        issue[3].fu = FloatingPoint;
        issue[4].fu = FloatingPoint;
    end

    // Clearing mechanism on reset, preserving the FU content
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            for (int i = 0; i < 5; i++) begin
                issue[i].t1 = '0;
                issue[i].t2 = '0;
                issue[i].v1 = '0;
                issue[i].v2 = '0;
                issue[i].phy_dest_reg = '0;
                issue[i].opcode = '0;
                issue[i].valid = '0;
                issue[i].busy = '0;
                issue[i].id_packet = '0;
            end
        end else begin
            case (id_ex_packet.inst.opcode)
            7'b0000011: begin // Load
                for (int i = 0; i < 5; i++) begin
                    if (!issue[i].busy && issue[i].fu == Load) begin
                        issue[i].dest_reg_idx = id_ex_packet.dest_reg_idx;
                        issue[i].v1 = id_ex_packet.rs1_value;
                        issue[i].v2 = id_ex_packet.rs2_value;
                        issue[i].id_packet = id_rs_packet;
                        issue[i].busy = 1'b1;
                        break;
                    end
                end
            end
            7'b0100011: begin // Store
                for (int i = 0; i < 5; i++) begin
                    if (!issue[i].busy && issue[i].fu == Store) begin
                        issue[i].dest_reg_idx = id_ex_packet.dest_reg_idx;
                        issue[i].v1 = id_ex_packet.rs1_value;
                        issue[i].v2 = id_ex_packet.rs2_value;
                        issue[i].id_packet = id_rs_packet;
                        issue[i].busy = 1'b1;
                        break; 
                    end
                end
            end
            7'b1000011: begin // Floating Point
                for (int i = 0; i < 5; i++) begin
                    if (issue[i].fu == FloatingPoint) {
                        if (!issue[i].busy) {
                            issue[i].dest_reg_idx = id_ex_packet.dest_reg_idx;
                            issue[i].v1 = id_ex_packet.rs1_value;
                            issue[i].v2 = id_ex_packet.rs2_value;
                            issue[i].id_packet = id_ex_packet;
                            issue[i].busy = 1'b1;
                            break; 
                        }
                    end
                end
            end
        endcase
    end
end

endmodule
	
	


