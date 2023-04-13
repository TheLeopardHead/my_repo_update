`timescale 1ns / 1ps

module insert_header_tb #(
parameter DATA_WD = 32,
parameter DATA_BYTE_WD = DATA_WD / 8,
parameter BYTE_CNT_WD = $clog2(DATA_BYTE_WD),
parameter NUM_OF_CYCLES = 50
)();

reg clk;
reg rst_n;
// AXI Stream input original data
wire valid_in;
wire [DATA_WD-1 : 0] data_in;
wire [DATA_BYTE_WD-1 : 0] keep_in;
wire last_in;
wire ready_in;
// AXI Stream output with header inserted
wire valid_out;
wire [DATA_WD-1 : 0] data_out;
wire [DATA_BYTE_WD-1 : 0] keep_out;
wire last_out;
wire ready_out;
// The header to be inserted to AXI Stream input
wire valid_insert;
wire [DATA_WD-1 : 0] data_insert;
wire [DATA_BYTE_WD-1 : 0] keep_insert;
wire [BYTE_CNT_WD-1 : 0] byte_insert_cnt;
wire ready_insert;

axi_stream_input_gen axi_stream_input_gen(
    .clk(clk),
    .rst_n(rst_n),
    .axi_tready(ready_in),
    .axi_tvalid(valid_in),
    .axi_tlast(last_in),
    .axi_keep(keep_in),
    .axi_tdata(data_in)
);

axi_stream_insert_gen axi_stream_insert_gen(
    .clk(clk),
    .rst_n(rst_n),
    .axi_insert_tready(ready_insert),
    .axi_insert_tvalid(valid_insert),
    .axi_insert_keep(keep_insert),
    .axi_byte_insert_cnt(byte_insert_cnt),
    .axi_insert_tdata(data_insert)
);

insert_headeraxi_stream_insert_header insert_header(
    .clk(clk),
    .rst_n(rst_n),
    .valid_in(valid_in),
    .data_in(data_in),
    .keep_in(keep_in),
    .last_in(last_in),
    .ready_in(ready_in),
    .valid_out(valid_out),
    .data_out(data_out),
    .keep_out(keep_out),
    .last_out(last_out),
    .ready_out(ready_out),
    .valid_insert(valid_insert),
    .data_insert(data_insert),
    .keep_insert(keep_insert),
    .byte_insert_cnt(byte_insert_cnt),
    .ready_insert(ready_insert)
);


initial begin
    clk = 0;
    rst_n = 0;
    #4 rst_n = 1;
end

always #1 clk = ~clk;

reg [7:0] packet_count; // count for number of package
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        packet_count <= 0;
    else    
        if (packet_count < NUM_OF_CYCLES - 1)
            packet_count <= packet_count + 1;
        else
            packet_count <= 0;
end

assign ready_out = (packet_count == 30+{$random}%(50-30+1))? 0 : 1;

endmodule