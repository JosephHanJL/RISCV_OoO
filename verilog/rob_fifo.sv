module fifo_sv #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH = 8,
    parameter int ADDR_WIDTH = $clog2(DEPTH)
)(
    input logic clk,
    input logic rst,
    input logic wr_en,
    input logic rd_en,
    input logic [DATA_WIDTH-1:0] data_in,
    output logic [DATA_WIDTH-1:0] data_out,
    output logic full,
    output logic empty
);

// FIFO 存储和指针
logic [DATA_WIDTH-1:0] memory [DEPTH-1:0];
logic [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;
logic [ADDR_WIDTH:0] count;  // 多一位以区分满和空

// 写操作
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        wr_ptr <= 0;
        count <= 0;
        full <= 0;
    end else if (wr_en && !full) begin
        memory[wr_ptr] <= data_in;
        wr_ptr <= (wr_ptr + 1) % DEPTH;
        count <= count + 1;
    end
    full <= (count == DEPTH); // 简化了条件判断
end

// 读操作
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        rd_ptr <= 0;
        empty <= 1;
    end else if (rd_en && !empty) begin
        data_out <= memory[rd_ptr];
        rd_ptr <= (rd_ptr + 1) % DEPTH;
        count <= count - 1;
    end
    empty <= (count == 0); // 简化了条件判断
end

endmodule
