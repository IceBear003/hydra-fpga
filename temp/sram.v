module sram
(
    input clk,
    input rst_n,
    
    input wr_en,
    input [10:0] wr_addr,
    input [15:0] din,
    
    input rd_en,
    input [10:0] rd_addr,
    output reg [15:0] dout
);

/* 8*36Kbit BRAM */
(* ram_style = "block" *) reg [15:0] d_latches [2047:0];

always @(posedge clk) begin
    if(wr_en && rst_n) begin 
        d_latches[wr_addr] <= din;
        //$display("wr_addr = %d",wr_addr);
        //$display("din = %d",din);
    end
end

always @(posedge clk) begin
    if(rd_en && rst_n) begin
        dout <= d_latches[rd_addr];
        //$display("read = %d %d",rd_addr,d_latches[rd_addr]);
    end
end

endmodule