`include "uvm_macros.svh"

import uvm_pkg::*;

`include "my_monitor.sv"
`include "my_transaction.sv"

class my_model extends uvm_component;
    uvm_blocking_get_port#(my_transaction) port[4];
    uvm_blocking_get_port#(my_transaction) ready[4];
    uvm_blocking_get_port#(my_transaction) act_port[4];
    uvm_analysis_port#(my_transaction) ap[4];
    uvm_analysis_port#(my_transaction) ap_1[4];
    uvm_analysis_port#(my_transaction) rec[4];

    extern function new(string name,uvm_component parent);
    extern function void build_phase(uvm_phase phase);
    extern virtual task main_phase(uvm_phase phase);
    `uvm_component_utils(my_model);
endclass

function my_model::new(string name,uvm_component parent);
    super.new(name,parent);
endfunction

function void my_model::build_phase(uvm_phase phase);
    super.build_phase(phase);
    for(int i=0; i<4; i=i+1) begin
        port[i] = new($sformatf("port[%0d]", i),this);
        act_port[i] = new($sformatf("act_port[%0d]", i),this);
        ready[i] = new($sformatf("ready[%0d]", i),this);
        ap[i] = new($sformatf("ap[%0d]", i),this);
        ap_1[i] = new($sformatf("ap_1[%0d]", i),this);
        rec[i] = new($sformatf("rec[%0d]", i),this);
    end
endfunction

task my_model::main_phase(uvm_phase phase);
    my_transaction tr[4];
    my_transaction rd_tr[4];
    my_transaction sd_tr[4];
    my_transaction rd_get[4];
    logic [47:0] que[4][4][$];
    logic [1:0] port_round[4];
    logic [2:0] port_reach[4];
    logic [2:0] tmp_prior[4];
    logic [2:0] big_prior[4];
    super.main_phase(phase);
    for(int i=0; i<4; i=i+1) begin
        port_round[i] = 0;
        port_reach[i] = 0;
    end
    while(1) begin
        for(int i=0; i<4; i=i+1) begin
            port[i].get(tr[i]);
            if(tr[i].vld) begin
                que[tr[i].ctrl[1:0]][tr[i].ctrl[3:2]].push_back(tr[i].ctrl);
                for(int j=port_round[tr[i].ctrl[1:0]]; j<4; j=j+1) begin
                    if(que[tr[i].ctrl[1:0]][j].size() != 0) begin
                        if(tr[i].ctrl[3:2] == j && que[tr[i].ctrl[1:0]][j].size() == 1)
                            port_reach[tr[i].ctrl[1:0]] = j;
                        break;
                    end
                end
                //if(tr[i].ctrl[1:0] == 7)
                //$display("port_in = %d %d %d %d",i,tr[i].ctrl[1:0],tr[i].ctrl[3:2],port_reach[tr[i].ctrl[1:0]]);
            end
        end
        for(int i=0; i<4; i=i+1) begin
            ready[i].get(rd_tr[i]);
            //if(rd_tr[i].rd_ready)
                //$display("i = %d %d %d %d",i,port_reach[i],que[i][port_reach[i]][0],que[i][port_reach[i]].size());
            if(rd_tr[i].rd_ready && que[i][port_reach[i]].size() > 0) begin
                `uvm_info("my_model","begin to collect one pkt",UVM_LOW);
                $display("i = %d %d %b %d",i,port_reach[i],que[i][port_reach[i]][0],que[i][port_reach[i]].size());
                sd_tr[i] = new($sformatf("sd_tr[%0d]", i));
                sd_tr[i].ctrl = que[i][port_reach[i]].pop_front();
                sd_tr[i].vld = 1;
                $display("port_r each = %d %d %d",port_reach[i],i,que[i][port_reach[i]][0][47:16]);
                ap[i].write(sd_tr[i]);
                for(int j=3; j >= 0; j=j-1) begin
                    if(que[i][j].size() > 0) begin
                        big_prior[i] = j;
                        break;
                    end
                end
                tmp_prior[i] = port_reach[i];
                if(port_reach[i] < big_prior[i]) begin
                    for(int j=port_reach[i] + 1; j<4; j=j+1)
                        if(que[i][j].size() != 0) begin
                            port_reach[i] = j;
                            $display("por t_reach = %d",port_reach[i]);
                            break;
                        end
                    if(port_reach[i] == tmp_prior[i]) begin
                        port_round[i] = 0;
                        for(int j=port_round[i]; j<4; j=j+1) begin
                            if(que[i][j].size() != 0) begin
                                port_reach[i] = j;
                                break;
                            end
                        end
                    end
                end else begin
                    port_round[i] = port_round[i] + 1;
                    for(int j=port_round[i]; j<4; j=j+1) begin
                        if(que[i][j].size() != 0) begin
                            port_reach[i] = j;
                            break;
                        end
                    end
                    if((port_reach[i] == tmp_prior[i] && tmp_prior[i] != big_prior[i])
                     || (port_round[i] == big_prior[i] + 1 && tmp_prior[i] == big_prior[i])) begin
                        port_round[i] = 0;
                        for(int j=port_round[i]; j<4; j=j+1) begin
                            if(que[i][j].size() != 0) begin
                                port_reach[i] = j;
                                break;
                            end
                        end
                    end
                end
                $display("port_reac h = %d %d",port_reach[i],i);
            end
        end
    end
    /*while(1) begin
        port.get(tr);
        new_tr = new("new_tr");
        new_tr.my_copy(tr);
        `uvm_info("my_model","get one transaction, copy and print it:",UVM_LOW)
        new_tr.my_print();
        ap.write(new_tr);
    end*/
endtask