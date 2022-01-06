module bullet_boundary_hit(
    input logic [8:0] Bullet_X, Bullet_Y,
    output logic      is_hit
);
    parameter [8:0] Bullet_X_Min = 9'd0;       // Leftmost point on the X axis
    parameter [8:0] Bullet_X_Max = 9'd272;     // Rightmost point on the X axis
    parameter [8:0] Bullet_Y_Min = 9'd0;       // Topmost point on the Y axis
    parameter [8:0] Bullet_Y_Max = 9'd224;     // Bottommost point on the Y axis
    parameter [8:0] Bullet_Size = 9'd4;        // Bullet size

    always_comb
    begin
        is_hit = 1'b0;

        // Boundary Judgement
        if( Bullet_X + Bullet_Size > Bullet_X_Max || Bullet_X > Bullet_X_Max )  // Bullet is at the edge
            is_hit = 1'b1;
        if( Bullet_Y + Bullet_Size > Bullet_Y_Max || Bullet_Y > Bullet_Y_Max )  // Bullet is at the edge
            is_hit = 1'b1;
    end

endmodule
