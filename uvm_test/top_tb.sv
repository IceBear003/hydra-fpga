//file name:top_tb.sv
`timescale 1ns/1ns
`include "uvm_macros.svh"

import uvm_pkg::*;

`include "my_driver.sv"
`include "hydra.sv" 
`include "my_env.sv"
`include "my_monitor.sv"
`include "my_agent.sv"

module top_tb();

parameter T = 4;

reg         clk;
reg         rst_n;

wire full;
wire almost_full;

my_if input_if[4](clk,rst_n);
my_if output_if[4](clk,rst_n);

hydra my_dut
(
    .clk (clk),
    .rst_n (rst_n),

    .wr_sop ({input_if[3].wr_sop,input_if[2].wr_sop,input_if[1].wr_sop,input_if[0].wr_sop}),
    .wr_eop ({input_if[3].wr_eop,input_if[2].wr_eop,input_if[1].wr_eop,input_if[0].wr_eop}),
    .wr_vld ({input_if[3].wr_vld,input_if[2].wr_vld,input_if[1].wr_vld,input_if[0].wr_vld}),
    .wr_data ({input_if[3].wr_data,input_if[2].wr_data,input_if[1].wr_data,input_if[0].wr_data}),
    .pause ({input_if[3].pause,input_if[2].pause,input_if[1].pause,input_if[0].pause}),

    .wrr_en (16'hFFFF),
    .match_threshold (20),
    .match_mode (2),
    
    .full (full),
    .almost_full (almost_full),

    .ready ({output_if[3].ready,output_if[2].ready,output_if[1].ready,output_if[0].ready}),
    //.rd_s ({output_if[3].rd_s,output_if[2].rd_s,output_if[1].rd_s,output_if[0].rd_s}),
    .rd_sop ({output_if[3].rd_sop,output_if[2].rd_sop,output_if[1].rd_sop,output_if[0].rd_sop}),
    .rd_eop ({output_if[3].rd_eop,output_if[2].rd_eop,output_if[1].rd_eop,output_if[0].rd_eop}),
    .rd_vld ({output_if[3].rd_vld,output_if[2].rd_vld,output_if[1].rd_vld,output_if[0].rd_vld}),
    .rd_data ({output_if[3].rd_data,output_if[2].rd_data,output_if[1].rd_data,output_if[0].rd_data})

);

initial begin
    run_test("my_env");
end

int time_stamp;

always @(posedge clk) begin
    time_stamp = time_stamp + 1;
    //$display("tim e = %d",time_stamp);
end

generate
    for(genvar i=0; i<4; i=i+1) begin
        initial begin
            uvm_config_db#(virtual my_if)::set(null,$sformatf("uvm_test_top.i_agt[%0d].drv", i),"vif",input_if[i]);
            uvm_config_db#(virtual my_if)::set(null,$sformatf("uvm_test_top.i_agt[%0d].mon", i),"vif",input_if[i]);
            uvm_config_db#(int)::set(null,$sformatf("uvm_test_top.i_agt[%0d].drv", i),"vr",i);
            uvm_config_db#(int)::set(null,$sformatf("uvm_test_top.i_agt[%0d].drv", i),"time_stamp",time_stamp);
            uvm_config_db#(virtual my_if)::set(null,$sformatf("uvm_test_top.o_agt[%0d].mon_out", i),"vif",output_if[i]);
            //uvm_config_db#(int)::set(null,$sformatf("uvm_test_top.o_agt[%0d].drv", i),"var",i);
        end
        always @(posedge clk) begin
            uvm_config_db#(int)::set(null,$sformatf("uvm_test_top.i_agt[%0d].drv", i),"time_stamp",time_stamp);
            //$display("ti m e = %d",time_stamp);
        end
    end
endgenerate

initial begin
    clk <= 1'b1;
    rst_n <= 1'b0;
    #(T*10);
    rst_n <= 1'b1;
end

always #(T/2) clk <= ~clk;
generate
    for(genvar i=0; i<4; i=i+1) begin
        initial begin
            #70009
            output_if[i].ready <= 1;
        end

        always @(posedge clk) begin 
            if(!rst_n) begin
                output_if[i].ready <= 0;
            end else if(output_if[i].rd_eop) begin
                output_if[i].ready <= 1;
            end else if(output_if[i].ready == 1) begin
                output_if[i].ready <= 0;
            end
        end
    end
endgenerate

endmodule

interface my_if(input clk,input rst_n);
    
    reg  wr_vld  ;
    reg [15:0] wr_data;

    reg ready   ;
    reg wr_sop  ;
    reg wr_eop  ;
    reg wrr_enable = 1;
    reg [4:0] match_threshold = 15;
    reg [1:0] match_mode = 2;
    int time_stamp;

    wire pause;
    wire rd_s;
    wire rd_sop;
    wire rd_eop;
    wire rd_vld;
    wire [15:0] rd_data;
endinterface
