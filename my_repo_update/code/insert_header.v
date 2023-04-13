module insert_headeraxi_stream_insert_header #(
parameter DATA_WD = 32,
parameter DATA_BYTE_WD = DATA_WD / 8,
parameter BYTE_CNT_WD = $clog2(DATA_BYTE_WD)
) (
input wire clk,
input wire rst_n,
// AXI Stream input original data
input wire valid_in,
input wire [DATA_WD-1 : 0] data_in,
input wire [DATA_BYTE_WD-1 : 0] keep_in,
input wire last_in,
output wire ready_in,
// AXI Stream output with header inserted
output wire valid_out,
output wire [DATA_WD-1 : 0] data_out,
output wire [DATA_BYTE_WD-1 : 0] keep_out,
output wire last_out,
input wire ready_out,
// The header to be inserted to AXI Stream input
input wire valid_insert,
input wire [DATA_WD-1 : 0] data_insert,
input wire [DATA_BYTE_WD-1 : 0] keep_insert,
input wire [BYTE_CNT_WD-1 : 0] byte_insert_cnt,
output wire ready_insert
);
// Your code here


parameter STREAM_LENGTH = 6;
parameter ODELAY_PERIOD = 3;

//define valid_out
assign valid_out = ((data_out == 0) | !ready_out)? 0 : 1;

//define ready_insert
assign ready_insert = valid_in & ready_in & !valid_out;

//define last_in_r
reg last_in_r;
always @(posedge clk or negedge rst_n)  begin
  if(!rst_n)
    last_in_r <= 0;
  else
    last_in_r <= last_in;
end

//define data_in_r
reg [DATA_WD-1 : 0] data_in_r;
always @(posedge clk or negedge rst_n)  begin
  if(!rst_n)
    data_in_r <= 0;
  else
    data_in_r <= data_in;
end

//define data_insert_r
reg [DATA_WD-1 : 0] data_insert_r;
always @(posedge clk or negedge rst_n)  begin
  if(!rst_n)
    data_insert_r <= 0;
  else
    data_insert_r <= data_insert;
end

//define datain_counter, counting the numbers of data_in
reg [STREAM_LENGTH-1:0] datain_counter; 
always @(posedge clk or negedge rst_n) begin
  if(!rst_n)
    datain_counter <= 0;
  else
    if(last_in)
      datain_counter <= 0;
    else
      if(valid_in & ready_in)
        datain_counter <= datain_counter + 1;
      else
        datain_counter <= 0;
end

//define flag_first_datain which indicates the first data
wire flag_first_datain;
assign flag_first_datain = valid_in & !valid_out;

//define flag_header_out indicating that there is a header to be inserted  
wire flag_header_out;
assign flag_header_out = (valid_out)? 0 : valid_in & ready_in & valid_insert & ready_insert & flag_first_datain;

//if there is a header inserted to the stream, flag_insert will be pull up
reg flag_insert;
always @(posedge clk or negedge rst_n) begin
  if(!rst_n)
    flag_insert <= 0;
  else
    if(last_in)
      flag_insert <= 0;
    else
      if(flag_header_out)
        flag_insert <= 1;
      else
        flag_insert <= flag_insert;
end

reg flag_insert_r;
always @(posedge clk or negedge rst_n) begin
  if(!rst_n)
    flag_insert_r <= 0;
  else
    flag_insert_r <= flag_insert;
end

//if there is a inserted header, header_out is the first DATA_WD of data_out
wire [DATA_WD-1 : 0] header_out;
assign header_out = (flag_header_out)? ((data_insert << 8*(DATA_BYTE_WD-(byte_insert_cnt+1))) ^ (data_in >> 8*(byte_insert_cnt+1))) : 0;

//if there is a inserted header, data_buffer is a bunch of data after header_out
reg [DATA_WD-1 : 0] data_buffer;
always @(posedge clk or negedge rst_n) begin
  if(!rst_n | last_out)
    data_buffer <= 0;
  else  
    if  (!ready_out)  
      data_buffer <= data_buffer;
    else    
      if(flag_header_out | flag_insert | flag_insert_r)
        data_buffer <= (data_in << 8*(DATA_BYTE_WD-(byte_insert_cnt+1)));
      else
        data_buffer <= 0;
end

//define data_out and data_out_pre
reg [DATA_WD-1 : 0] data_out_pre;

always @(posedge clk or negedge rst_n) begin
  if(!rst_n | last_out)
    data_out_pre <= 0;
  else
    if(flag_header_out)
      data_out_pre <= header_out;
    else
      if(!ready_out)
        data_out_pre <= data_out_pre;
      else
        if({(flag_insert | flag_insert_r) , flag_header_out} == 2'b10)
          data_out_pre <= (data_buffer ^ (data_in >> 8*(byte_insert_cnt+1)));
        else
          data_out_pre <= data_in;
end

assign data_out = data_out_pre;

//define byte_datain_cnt and byte_datain_cnt_r
reg [BYTE_CNT_WD : 0] byte_datain_cnt;

integer i;
always @(*) begin
  byte_datain_cnt = 0;
    for (i=0; i<DATA_BYTE_WD; i=i+1) begin
      if (keep_in[i]==1'b1) begin
        byte_datain_cnt = byte_datain_cnt + keep_in[i];
        end
    end
end

reg [BYTE_CNT_WD : 0] byte_datain_cnt_r;
always @(posedge clk or negedge rst_n) begin
  if(!rst_n)
    byte_datain_cnt_r <= 0;
  else
    if(last_in)
      byte_datain_cnt_r <= byte_datain_cnt;
    else
      byte_datain_cnt_r <= byte_datain_cnt_r;
end 

//define byte_insert_cnt_r
reg [BYTE_CNT_WD-1 : 0] byte_insert_cnt_r;
always @(posedge clk or negedge rst_n) begin
  if(!rst_n)
    byte_insert_cnt_r <= 0;
  else
    if(!(flag_insert | flag_insert_r))
      byte_insert_cnt_r <= 0;
    else
      if(last_in)
        byte_insert_cnt_r <= byte_insert_cnt;
      else
        byte_insert_cnt_r <= byte_insert_cnt_r;
end 


//define last_out
reg last_out_pre;
always @(posedge clk or negedge rst_n) begin
  if(!rst_n)
    last_out_pre <= 0;
  else
    if(last_in & ((byte_datain_cnt + (byte_insert_cnt+1)) <= DATA_BYTE_WD))
      last_out_pre  <= 1;
    else  
    if(last_in_r & ((byte_datain_cnt_r + (byte_insert_cnt_r+1)) > DATA_BYTE_WD))
      last_out_pre  <= 1;
    else  
      last_out_pre <= 0;
end

assign last_out = (last_in & !flag_insert)? 1 : last_out_pre;


//define ready_in
assign ready_in = ready_out & !last_in & !(last_in_r & !last_out);

//define keep_out_total
wire [DATA_BYTE_WD-1 : 0] keep_out_total;
assign keep_out_total[0+ : DATA_BYTE_WD] = ~(1'b0<<(DATA_BYTE_WD - 1)); 

//define keep_out
assign keep_out = !valid_out? 0 : !last_out? keep_out_total : last_in? keep_in : last_in_r? (keep_out_total << (DATA_BYTE_WD - (byte_datain_cnt_r + (byte_insert_cnt_r+1)))) : (keep_out_total << (2*DATA_BYTE_WD - (byte_datain_cnt_r + (byte_insert_cnt_r+1))));



endmodule
