`include "uvm_macros.svh"

import uvm_pkg::*;

`include "my_monitor.sv"
`include "my_transaction.sv"

class my_scoreboard extends uvm_scoreboard;
    logic [47:0] expect_queue[$];
    uvm_blocking_get_port#(my_transaction) exp_port;
    uvm_blocking_get_port#(my_transaction) exp_port_1;
    uvm_blocking_get_port#(my_transaction) act_port;
    uvm_analysis_port#(my_transaction) ap;
    extern function new(string name,uvm_component parent = null);
    extern function void build_phase(uvm_phase phase);
    extern virtual task main_phase(uvm_phase phase);
    `uvm_component_utils(my_scoreboard)
endclass

function my_scoreboard::new(string name,uvm_component parent = null);
    super.new(name,parent);
endfunction

function void my_scoreboard::build_phase(uvm_phase phase);
    super.build_phase(phase);
    exp_port = new("exp_port",this);
    exp_port_1 = new("exp_port_1",this);
    act_port = new("act_port",this);
    ap = new("ap",this);
endfunction

task my_scoreboard::main_phase(uvm_phase phase);
    my_transaction get_expect,get_actual;
    logic [15:0] tmp_tran;
    logic result;
    int num_suc = 0;
    int num_err = 0;
    super.main_phase(phase);
    //int file;
    //file = $fopen("D:/Engineer/Hydra_2/hydra/debug_temp/in.txt","r+");
    `uvm_info("my_scoreboard","begin to compare",UVM_LOW);
    fork
        while(1) begin
            //`uvm_info("my_scoreboard","getting expect",UVM_LOW);
            exp_port.get(get_expect);
            $display("expect = %d %d",get_expect.ctrl[15:0],get_expect.vld);
            if(get_expect.vld)
                expect_queue.push_back(get_expect.ctrl);
        end
        while(1) begin
            act_port.get(get_actual);
            if(expect_queue.size() > 0 && get_actual.vld) begin
                $display("acutal = %d %d %d %d",get_actual.ctrl[1:0],
                get_actual.ctrl,get_actual.vld,get_actual.ctrl[3:2]);
                tmp_tran = expect_queue[0];
                //ap.write(get_actual);
                //exp_port_1.get(tmp_tran);
                result = (get_actual.ctrl[15:0] == tmp_tran);
                if(result) begin
                    `uvm_info("my_scoreboard","Compare SUCCESSFULLY",UVM_LOW);
                    expect_queue.pop_front();
                    num_suc = num_suc + 1;
                    //$display("Successful packet number is: %d",num_suc);
                end else begin
                    $display("the expect pkt is %d %d",tmp_tran,tmp_tran[3:2]);
                    $display("the actural pkt is %d %d %d"
                    ,get_actual.ctrl,expect_queue.size(),get_actual.ctrl[3:2]);
                    `uvm_error("my_scoreboard","Com pare FAILED");
                    expect_queue.pop_front();
                    num_err = num_err + 1;
                    //$display("Failed packet number is: %d",num_err);
                end
            end else if(get_actual.vld) begin
                $display("the unexpected pkt is %d",get_actual.ctrl);
                `uvm_error("my_scoreboard","Received from DUT, while Expected Queue is empty");
                num_err = num_err + 1;
                $display("Failed packet number is: %d",num_err);
            end
            $display("Successful packet number is: %d",num_suc);
            $display("Failed packet number is: %d",num_err);
        end
    join
endtask