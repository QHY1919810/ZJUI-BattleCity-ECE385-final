module frame_buffer(
    input logic        Clk, WE, Reset,
    input logic [8:0]  Read_AddrX,
                       Read_AddrY,
                       Write_AddrX,
                       Write_AddrY,
    input logic [4:0]  ColorId_In,
    output logic [4:0] ColorId_Out
);
    logic [4:0] frame [320*240];
    
    always_ff @(posedge Clk)
    begin
        if(WE)
            frame[Write_AddrY * 320 + Write_AddrX] <= ColorId_In;
        ColorId_Out <= frame[Read_AddrY * 320 + Read_AddrX];
    end
endmodule
