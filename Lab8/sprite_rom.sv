// 0x0 ~ 0x1000 tank sprite
module sprite(
    input logic         Clk,
    input logic [19:0]  ADDR,
    output logic [4:0]  ColorId_Read
);
logic [7:0] mem [252224];

initial
begin
    $readmemh("sprites_txt/tank_war.txt", mem);
end

always_ff @ (posedge Clk) begin
    ColorId_Read <= mem[ADDR][4:0];
end
endmodule
