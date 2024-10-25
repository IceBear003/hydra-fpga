
module port_rd_dispatch(
    input clk,
    input rst_n,

    /* 
     * 配置IO
     * |- wrr_en - WRR调度使能信号
     *           |- 0 - 严格优先级调度
     *           |- 1 - WRR调度
     */
    input wrr_en,

    /* 
     * 调度器信号
     * |- queue_empty - 端口各队列空闲状态
     * |- prior_update - 调度器更新信号
     * |- prior_next - 下一次读出的队列编号
     */
    input [3:0] queue_empty,
    input prior_update,
    output reg [2:0] prior_next
);

/* 
 * 快速WRR机制
 * |- wrr_mask_set - WRR掩码集
 * |- wrr_mask - WRR掩码
 * |- wrr_round - WRR回合
 * |- masked_queue_empty - 掩码遮盖过的队列空闲状态
 * |- wrr_update_state - WRR更新自动机
 *                     |- 0 - 无更新
 *                     |- 1 - 第一次更新wrr_mask完毕(到上次读取队列号对应的掩码)，若遮盖结果无可读队列，跳转至2，否则跳转至0
 *                     |- 2 - 更新wrr_round(新的一回合)
 *                     |- 3 - 根据新的wrr_round第二次更新wrr_mask
 *                     |- 4 - 第二次更新wrr_mask完毕(到新一回合第一个掩码)，若遮盖结果无可读队列，跳转至5，否则跳转至0
 *                     |- 5 - 重置wrr_round和wrr_mask
 */
wire [3:0] wrr_mask_set [4:0];
reg [3:0] wrr_mask;
reg [2:0] wrr_round;
wire [3:0] masked_queue_empty = wrr_mask | queue_empty;
reg [2:0] wrr_update_state;

/* 掩码集硬连接初始化 */
assign wrr_mask_set[4] = 4'h0;
assign wrr_mask_set[0] = 4'h1;
assign wrr_mask_set[1] = 4'h3;
assign wrr_mask_set[2] = 4'h7;
assign wrr_mask_set[3] = 4'hF;

/* WRR更新自动机状态转移 */
always @(posedge clk) begin
    if(~rst_n || ~wrr_en) begin
        wrr_update_state <= 3'd0;
    end else if(wrr_update_state == 3'd0 && prior_update) begin
        wrr_update_state <= 3'd1;
    end else if(wrr_update_state == 3'd1) begin
        wrr_update_state <= masked_queue_empty == 4'hF ? 3'd2 : 3'd0;
    end else if(wrr_update_state == 3'd2) begin
        wrr_update_state <= 3'd3; 
    end else if(wrr_update_state == 3'd3) begin
        wrr_update_state <= 3'd4; 
    end else if(wrr_update_state == 3'd4) begin
        wrr_update_state <= masked_queue_empty == 4'hF ? 3'd5 : 3'd0;
    end else if(wrr_update_state == 3'd5) begin
        wrr_update_state <= 3'd0;
    end
end

/* 掩码刷新器 */
always @(posedge clk) begin
    if(~rst_n || ~wrr_en || wrr_update_state == 3'd5) begin
        wrr_mask <= 4'd0;
    end else if(prior_update) begin
        wrr_mask <= wrr_mask_set[prior_next];
    end else if(wrr_update_state == 3'd2) begin
        wrr_mask <= wrr_mask_set[wrr_round];
    end
end

/* 回合计数器 */
always @(posedge clk) begin
    if(~rst_n) begin
        wrr_round <= 3'd0;
    end else if(wrr_update_state == 3'd3) begin
        wrr_round <= wrr_round + 1;
    end else if(wrr_update_state == 3'd5) begin
        wrr_round <= 3'd0;
    end
end

wire [2:0] wire_prior_next;

/* 消除组合逻辑的延时 */
always @(posedge clk) begin
    prior_next <= wire_prior_next;
end

encoder_4_2_rev encoder_4_2_rev(
    .select(masked_queue_empty),
    .idx(wire_prior_next)
); 

endmodule