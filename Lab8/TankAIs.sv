module TankAIs(
    input logic        Clk,
    input logic        Reset, 
    output logic [3:0] AI_tank_1,
                       AI_tank_2,
                       AI_tank_3,
                       AI_tank_4,
    output logic [23:0] Random_others
);
    logic [31:0] Countervalue_1, Countervalue_2, Countervalue_3, Countervalue_4;
    logic [6:0] Orig_RND1, Orig_RND2, Orig_RND3, Orig_RND4;
    logic [39:0] RND_generated;
    initial begin
        Random_others = 24'b0;
        // Orig_RND1 <= 7'b1001101;
        // Orig_RND2 <= 7'b0011100;
        // Orig_RND3 <= 7'b1000001;
        // Orig_RND4 <= 7'b0000001;
    end
    always_ff@(posedge Clk) begin
        Random_others <= Random_others + 24'b1;
        // Orig_RND1 <= Orig_RND1 +7'b001;
        // Orig_RND2 <= Orig_RND2 +7'b001;
        // Orig_RND3 <= Orig_RND3 +7'b001;
        // Orig_RND4 <= Orig_RND4 +7'b001;
    end
    
    always_comb begin
        Countervalue_1 = 32'd12000000;
        Countervalue_2 = 32'd19000000;
        Countervalue_3 = 32'd25000000;
        Countervalue_4 = 32'd20000000;
        Orig_RND1=RND_generated[6:0];
        Orig_RND2=RND_generated[13:7];
        Orig_RND3=RND_generated[20:14];
        Orig_RND4=RND_generated[27:21];
    end
    
     randomgenerate randomgenerater1(.Clk(Clk), .o(RND_generated));
    RandAI Tank1AI(.Clk(Clk), .Reset_h(Reset), .countervalue(Countervalue_1),
                   .randominput1(Orig_RND1[4:0]), .randominput2(Orig_RND1[6:5]), .AI_tank_control(AI_tank_1));
    RandAI Tank2AI(.Clk(Clk), .Reset_h(Reset), .countervalue(Countervalue_2),
                   .randominput1(Orig_RND2[4:0]), .randominput2(Orig_RND2[6:5]), .AI_tank_control(AI_tank_2));
    RandAI Tank3AI(.Clk(Clk), .Reset_h(Reset), .countervalue(Countervalue_3),
                   .randominput1(Orig_RND3[4:0]), .randominput2(Orig_RND3[6:5]), .AI_tank_control(AI_tank_3));
    RandAI Tank4AI(.Clk(Clk), .Reset_h(Reset), .countervalue(Countervalue_4),
                   .randominput1(Orig_RND4[4:0]), .randominput2(Orig_RND4[6:5]), .AI_tank_control(AI_tank_4));
endmodule
