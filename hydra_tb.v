`timescale  1ns / 1ps
`include "hydra.sv"
module tb_test;
    reg clk = 0;
    initial
    begin 
        forever
        #(5)  clk=~clk;
    end
    reg [15:0] cnt = 0;
    reg rst_n;
    //基本IO口
    reg [3:0] wr_sop;
    reg [3:0] wr_eop;
    reg [3:0] wr_vld;
    reg [3:0] [15:0] wr_data;
    wire [3:0] pause;
    reg [3:0] ready;
    wire [3:0] rd_sop;
    wire [3:0] rd_eop;
    wire [3:0] rd_vld; 
    wire [3:0] [15:0] rd_data;
    hydra hydra(
        .clk(clk),
        .rst_n(rst_n),
        .wr_sop(wr_sop),
        .wr_eop(wr_eop),
        .wr_vld(wr_vld),
        .wr_data(wr_data),
        .pause(pause),
        
        .ready(ready),
        .rd_sop(rd_sop), 
        .rd_eop(rd_eop),
        .rd_vld(rd_vld),
        .rd_data(rd_data),

        .wrr_en(4'hF),
        .match_threshold(4'd15),
        .match_mode(2'd2)
    );
    always @(posedge clk) begin
        cnt <= cnt + 1;
    end
    
    reg tmp;
    always @(posedge clk) begin
        // if(rd_eop != 0) begin
        //     ready <= 4'hF;
        //     tmp <= 1;
        // end else if(tmp == 1) begin
        //     ready <= 4'h0;
        //     tmp <= 0;
        // end
    end
    integer i;
    integer j;
    initial
    begin
        $dumpfile("test_result.vcd");
        $dumpvars();
        #5 
        rst_n <= 0;
        ready <= 4'h0;
        wr_sop <= 4'h0;
        wr_vld <= 4'h0;
        wr_eop <= 4'h0;
        #10 
        rst_n <= 1;
        #10 
        wr_sop <= 4'h3;
        #10 
        wr_sop <= 4'h0;
        wr_vld <= 4'h3;
        wr_data <= {{4'd0, 8'd31, 2'd1, 2'd3}, {4'd0, 8'd31, 2'd1, 2'd3}};
        cnt <= 0;
        for(i=0;i<31;i=i+1) begin
            #10 
            wr_data <= {{cnt, 1'b0}, cnt};
        end
        #10 wr_vld <= 4'h0; wr_eop <= 4'h3;
        #10 wr_eop <= 4'h0; ready <= 4'h8;
        #10 ready <= 4'h0;

        #500 ready <= 4'h8;
        #10 ready <= 4'h0;
        #400
        $finish;
    end
endmodule