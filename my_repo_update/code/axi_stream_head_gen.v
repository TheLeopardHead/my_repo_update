module axi_stream_insert_gen #(
parameter DATA_WD = 32,
parameter DATA_BYTE_WD = DATA_WD / 8,
parameter BYTE_CNT_WD = $clog2(DATA_BYTE_WD)
)(
input wire clk,
input wire rst_n,
input wire axi_insert_tready,
output wire axi_insert_tvalid,
output wire [DATA_BYTE_WD-1 : 0] axi_insert_keep,
output wire [BYTE_CNT_WD-1 : 0] axi_byte_insert_cnt,
output wire [DATA_WD-1 : 0] axi_insert_tdata
);


reg [DATA_WD-1 : 0] axi_insert_tdata_pre;


//data generation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        axi_insert_tdata_pre <= 0;
    else
        if (axi_insert_tready) 
            axi_insert_tdata_pre <= $random;
        else
            axi_insert_tdata_pre <= axi_insert_tdata_pre;
end

reg [BYTE_CNT_WD-1 : 0] axi_byte_insert_cnt_r;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        axi_byte_insert_cnt_r <= 0;
    else
        if (axi_insert_tready) 
            axi_byte_insert_cnt_r <= {$random} % 4;
        else
            axi_byte_insert_cnt_r <= axi_byte_insert_cnt_r;
end

assign axi_byte_insert_cnt = axi_byte_insert_cnt_r;

assign axi_insert_keep = 4'b1111 >> 3 - axi_byte_insert_cnt_r;

// Output axi_insert_tdata_pre on valid signal
assign axi_insert_tdata = axi_insert_tdata_pre;
assign axi_insert_tvalid = (axi_insert_tdata == 0)? 0 : 1;

endmodule
