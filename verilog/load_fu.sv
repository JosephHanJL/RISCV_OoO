module load_fu (
    // Inputs
    input clock, 
    input reset,
    input ack,
    input FU_IN_PACKET fu_in_packet,
    input logic [`XLEN-1:0]   Dmem2proc_data;
    input logic mem_ack,
    // Outputs
    output FU_OUT_PACKET fu_out_packet,
    output FU_MEM_PACKET fu_mem_packet,
    output logic mem_req
); 

    logic fu_done;
    logic [`XLEN-1:0] read_data;


	assign fu_mem_packet.proc2Dmem_command = BUS_LOAD;
    assign fu_mem_packet.proc2Dmem_addr = fu_in_packet.rs1_value + `RV32_signext_Iimm(fu_in_packet.inst);
    assign fu_mem_packet.proc2Dmem_data = '0;
    assign fu_mem_packet.mem_size = MEM_SIZE'(id_ex_reg.inst.r.funct3[1:0]); 
    
    assign fu_out_packet.v = read_data;

    // Read data from memory and sign extend the proper bits
    always_comb begin
        read_data = Dmem2proc_data;
        if (fu_in_packet.inst.r.funct3[2];) begin
            // unsigned: zero-extend the data
            if (fu_mem_packet.mem_size == BYTE) begin
                read_data[`XLEN-1:8] = 0;
            end else if (fu_mem_packet.mem_size == HALF) begin
                read_data[`XLEN-1:16] = 0;
            end
        end else begin
            // signed: sign-extend the data
            if (fu_mem_packet.mem_size[1:0] == BYTE) begin
                read_data[`XLEN-1:8] = {(`XLEN-8){Dmem2proc_data[7]}};
            end else if (fu_mem_packet.mem_size == HALF) begin
                read_data[`XLEN-1:16] = {(`XLEN-16){Dmem2proc_data[15]}};
            end
        end
    end

    // create output packet and manage done signal
    always_ff @(posedge clock) begin
		if (reset) begin
            fu_out_packet <= '0;
            mem_req <= 0;
        end else begin
            fu_out_packet.rob_tag <= fu_in_packet.rob_tag;
            // ack clear must have priority over setting done
            if (fu_in_packet.issue_valid) mem_req <= 1;
            if (mem_ack) begin
                fu_out_packet.done <= 1;
                mem_req <= 0;
            end
            if (ack) fu_out_packet.done <= 0;
        end
    end

endmodule
