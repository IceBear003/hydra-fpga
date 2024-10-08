module encoder_4_2(
    /*
     * |- select - 4位选通信号
     * |- idx - 3位编码信号，检测选通信号中最低0的位置
     */
    input [3:0] select,
    output reg [2:0] idx
);

always @(select) begin
    casex(select)
        4'bxxx1: idx = 3'd0;
        4'bxx10: idx = 3'd1;
        4'bx100: idx = 3'd2;
        4'b1000: idx = 3'd3;
        4'b0000: idx = 3'd4;
    endcase
end

endmodule