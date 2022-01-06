module tank_boundary_collide(
    input logic [8:0] Tank_X, Tank_Y,
    output logic      is_collide
);
    parameter [8:0] Tank_X_Min = 9'd0;       // Leftmost point on the X axis
    parameter [8:0] Tank_X_Max = 9'd272;     // Rightmost point on the X axis
    parameter [8:0] Tank_Y_Min = 9'd0;       // Topmost point on the Y axis
    parameter [8:0] Tank_Y_Max = 9'd224;     // Bottommost point on the Y axis
    parameter [8:0] Tank_Size = 9'd16;        // Tank size

    always_comb
    begin
        is_collide = 1'b0;

        // Boundary Judgement
        if( Tank_X + Tank_Size > Tank_X_Max || Tank_X > Tank_X_Max )  // Tank is at the edge
            is_collide = 1'b1;
        if( Tank_Y + Tank_Size > Tank_Y_Max || Tank_Y > Tank_Y_Max )  // Tank is at the edge
            is_collide = 1'b1;
    end

endmodule
