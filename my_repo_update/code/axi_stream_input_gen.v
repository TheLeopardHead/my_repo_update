module axi_stream_input_gen #(
parameter DATA_WD = 32,
parameter DATA_BYTE_WD = DATA_WD / 8,
parameter NUM_OF_CYCLES = 50 // number of package
)(
input wire clk,
input wire rst_n,
input wire axi_tready,
output wire axi_tvalid,
output wire axi_tlast,
output wire [DATA_BYTE_WD-1 : 0] axi_keep,
output wire [DATA_WD-1 : 0] axi_tdata
);


reg [DATA_WD-1 : 0] axi_tdata_pre;

//define axi_tvalid
assign axi_tvalid = (axi_tdata == 0)? 0 : 1;

//data generation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        axi_tdata_pre <= 0;
    else
        if (axi_tready) 
            axi_tdata_pre <= $random;
        else
            axi_tdata_pre <= axi_tdata_pre;
end

// Output axi_tdata_pre on valid signal
assign axi_tdata = axi_tdata_pre;

reg [7:0] packet_count; // count for number of package
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        packet_count <= 0;
    else    
        if (axi_tready & (packet_count < NUM_OF_CYCLES - 1))
            packet_count <= packet_count + 1;
        else
            packet_count <= 0;
end

assign axi_tlast = (packet_count == 30+{$random}%(50-30+1))? 1 : 0;


assign axi_keep = (axi_tlast)? (4'b1111 << ({$random} % 4)) : (axi_tready & axi_tvalid)? 4'b1111 : 0;

assign axi_tvalid = (axi_tdata == 0)? 0 : 1;

endmodule
