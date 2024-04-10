module insn_buffer (
    input                       clock,
    input                       reset,
    input [1:0]                 dp_packet_req,
    input                       squashed_sig_rob,
    input IF_DP_PACKET [1:0]    if_dp_packet,

    output                      buffer_full, // stall_dp in if stage
    output IF_DP_PACKET [1:0]   if_dp_packet_out
);

    localparam int BUFFER_LENGTH = 16;
    localparam int POINTER_WIDTH = 5;
    logic [POINTER_WIDTH-1:0] tail, next_tail, 
    logic [POINTER_WIDTH-1:0] head, next_head, 
    IF_DP_PACKET [BUFFER_LENGTH-1:0] reg;
    IF_DP_PACKET [BUFFER_LENGTH-1:0] next_reg;
    logic [POINTER_WIDTH-1:0] buffer_status;
    logic empty;
    logic [1:0] process_size; // distance between tail and next tail, max 2, min 0 

    assign empty = (buffer_status == 5'b0);
    assign buffer_full = (buffer_status == 5'd16);

    always_comb begin  
        next_tail = tail;
        for (int i = 0 ; i < 2 ; i++) begin
            if (if_dp_packet[i].valid) begin
                next_tail = tail + i + 1;
            end
        end
        for (int j = 0 ; j < BUFFER_LENGTH; j++) begin
            next_reg[j] = reg[j];
        end
    end

    assign process_size = next_tail - tail;

    always_comb begin
        case(process_size)
        2'b1: begin
            next_reg[tail[3:0]] = if_dp_packet[0];
        end
        2'b10: begin    
            next_reg[tail[3:0]] = if_dp_packet[0];
            next_reg[tail[3:0]+1] = if_dp_packet[1];
        end
        default: begin
            next_reg = reg;
        end
        endcase
        case(dp_packet_req)
        2'b00: begin 
            next_head = head; 
        end
        2'b01: begin
            next_head = head+1; 
        end
        2'b10: begin
            next_head = head+2;
        end
        default: next_head = head;
        endcase
        for (int i = 0; i < 2; i++) begin
            if_dp_packet_out[i].valid = 0;
            if_dp_packet_out[i].inst = `NOP;
            if_dp_packet_out[i].NPC = 0;
            if_dp_packet_out[i].PC = 0;
        end
        case (dp_packet_req) 
        2'b01: begin
            if (~empty) begin
                if_dp_packet_out[0] = reg[head[3:0]];
            end
        end
        2'b10: begin
            if (!empty) begin
                if_dp_packet_out[0] = reg[head[3:0]];
                if_dp_packet_out[1] = reg[head[3:0]+1];
            end 
        end
        endcase
    end

    always_ff @(posegde clock) begin 
        if (reset | squashed_sig_rob) begin
            tail <= 0;
            head <= 0;
        end
        else begin
            if (~buffer_full) begin 
                tail <= next_tail;
            end
            if (!empty) begin
                head <= next_head;
            end
        end
        if (~buffer_full) begin
            reg <= next_reg;
        end
    end
endmodule
