`timescale 1ns/1ns

module tb_port_rd_dispatch();

reg clk;
reg rst_n;

initial begin
    clk <= 0;
    rst_n <= 0;
    #40
    rst_n <= 1;
end

always #2 clk = ~clk;

wire wrr_en = 1;

reg [3:0] queue_empty;
reg update;
reg [1:0] rd_prior;

reg [6:0] cnt;

reg [3:0][7:0] queue_num;

always @(posedge clk) begin
    if(!rst_n) begin
        cnt <= 0;
    end else begin
        cnt <= cnt + 1;
    end
end

always @(posedge clk) begin
    if(!rst_n) begin
        queue_num[0] <= 1;
        queue_num[1] <= 0;
        queue_num[2] <= 1;
        queue_num[3] <= 3;
    end else if(update) begin
        queue_num[rd_prior] <= queue_num[rd_prior] - 1;
    end
end

integer i;

always @(posedge clk) begin
    if(!rst_n) begin
        queue_empty <= 4'hF;
    end else begin
        for(i = 0; i < 4; i = i+1)
            queue_empty[i] <= queue_num[i] == 0;
    end
end

reg [10:0] cnt_out;

always @(posedge clk) begin
    if(!rst_n) begin
        cnt_out <= 0;
    end else if(update && rd_prior != 4) begin
        cnt_out <= cnt_out + 1;
    end
end

always @(posedge clk) begin
    if(!rst_n) begin
        update <= 0;
    end else if(cnt[3:0] == 0) begin
        update <= 1;
    end else begin
        update <= 0;
    end
end

port_rd_dispatch port_rd_dispatch_inst
(
    .clk(clk),
    .rst_n(rst_n),

    .wrr_en(wrr_en),
    .queue_empty(queue_empty),
    .prior_update(update),

    .prior_next(rd_prior)

);

endmodule