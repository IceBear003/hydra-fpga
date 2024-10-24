`timescale  1ns / 1ps
`include "hydra.sv"
module testbench_hydra();

reg clk = 0;
reg rst_n;
integer tick = 0;

initial
begin 
    forever
    #(5) clk=~clk;
end

always @(posedge clk) begin
    tick = tick + 1;
end

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
// wire [3:0] ppa_port;
// wire [31:0][8:0]  ppa;

reg [31:0] left_packet_amounts[15:0];

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
    
    // .ppa_port(ppa_port),
    // .ppa(ppa),

    .wrr_en(4'hF),
    .match_threshold(4'd15),
    .match_mode(2'd2)
);

reg [3:0] finish_wr = 4'hF;
reg [3:0] finish_rd = 4'hF;

integer out_file;
initial begin
    out_file = $fopen("statistic.txt");
    $dumpfile("testbench_hydra.vcd");
    $dumpvars();
    #5 
    rst_n <= 0;
    ready <= 4'h0;
    wr_sop <= 4'h0;
    wr_vld <= 4'h0;
    wr_eop <= 4'h0;
    #10 
    rst_n <= 1;
end

genvar port_wr;
generate for(port_wr = 0; port_wr < 4; port_wr = port_wr + 1) begin : port_wr_loop
    integer packet_amount;
    integer length;
    integer prior;
    integer dest_port;
    integer i;
    wire [31:0] left = left_packet_amounts[port_wr];
    initial begin
        left_packet_amounts[port_wr] = 0;
        #1005
        for(packet_amount = 0; packet_amount < 100; packet_amount = packet_amount + 1) begin
            length = $urandom_range(31,255);
            prior = $urandom_range(0,3);
            dest_port = $urandom_range(0,3);
            wr_sop[port_wr] <= 1;
            wr_eop[port_wr] <= 0;
            #10
            wr_sop[port_wr] <= 0;
            wr_vld[port_wr] <= 1;
            wr_data[port_wr] <= {length[7:0], prior[1:0], dest_port[1:0]};
            #10
            for(i = 0; i < length; i = i + 1) begin
                while(pause) begin
                    wr_vld[port_wr] <= 0;
                    #10;
                end
                wr_vld[port_wr] <= 1;
                wr_data[port_wr] <= i[15:0];
                #10;
            end
            wr_vld[port_wr] <= 0;
            wr_eop[port_wr] <= 1;
            #10;
            wr_eop[port_wr] <= 0;
            #10;
            left_packet_amounts[dest_port] = left_packet_amounts[dest_port] + 1; 
            $fdisplay(out_file, "Write Packet%d: Port#%d -> Port#%d", port_wr, packet_amount, dest_port);
        end
        finish_wr[port_wr] <= 0;
    end
end endgenerate

integer tmp;

// initial begin
//     #1000
//     while(finish_wr != 0) begin
//         #10;
//     end
//     for(tmp = 0; tmp < 16; tmp = tmp + 1) begin
//         $fdisplay(out_file, "%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d ", 
//         ppa_port, ppa[0], ppa[1], ppa[2], ppa[3], ppa[4], ppa[5], ppa[6], ppa[7], ppa[8], ppa[9], ppa[10], ppa[11], ppa[12], ppa[13], ppa[14], ppa[15], 
//         ppa[16], ppa[17], ppa[18], ppa[19], ppa[20], ppa[21], ppa[22], ppa[23], ppa[24], ppa[25], ppa[26], ppa[27], ppa[28], ppa[29], ppa[30], ppa[31]);
//         #10;
//     end
// end

integer rd_cnt = 0;

genvar port_rd;
generate for(port_rd = 0; port_rd < 4; port_rd = port_rd + 1) begin : port_rd_loop
    integer start_tick;
    integer response_tick;
    integer end_tick;
    integer packet_length;
    initial begin
        while (finish_wr != 0) begin
            #10;
        end
        #2005
        while(left_packet_amounts[port_rd] > 0 || finish_wr != 0) begin
            if(left_packet_amounts[port_rd] > 0) begin
                ready[port_rd] <= 1;
                #10;
                ready[port_rd] <= 0;
                #10;
                if(rd_sop[port_rd]) begin
                    start_tick <= tick;
                    response_tick <= 0;
                    left_packet_amounts[port_rd] <= left_packet_amounts[port_rd] - 1;
                    rd_cnt <= rd_cnt + 1;
                    while(rd_eop[port_rd] != 1) begin
                        #10;
                        if(rd_vld[port_rd] == 1 && response_tick == 0) begin
                            response_tick <= tick;
                            packet_length <= rd_data[port_rd][11:4];
                        end 
                    end
                    end_tick = tick;
                    $fdisplay(out_file, "Read packet from port: %d, left packet: %d", port_rd, left_packet_amounts[port_rd]);
                end
            end else begin
                #10;
            end
        end
        #10;
        $fdisplay(out_file, "over: %d", port_rd);
        ready[port_rd] <= 0;
        finish_rd[port_rd] <= 0;
    end
end endgenerate

always @(posedge clk) begin
    if(finish_rd == 0) begin
// initial begin
    #3000
    $fclose(out_file);
    $finish;
// end
    end
end

endmodule