module tank_tank_collide(
    input logic [8:0] Tank_X_1, Tank_Y_1,
    input logic [8:0] Tank_X_1_in, Tank_Y_1_in,
    input logic [8:0] Tank_X_2, Tank_Y_2,
    input logic [2:0] Tank_State_2,
    output logic      is_collide
);
    parameter [8:0] Tank_X_Min = 9'd0;       // Leftmost point on the X axis
    parameter [8:0] Tank_X_Max = 9'd272;     // Rightmost point on the X axis
    parameter [8:0] Tank_Y_Min = 9'd0;       // Topmost point on the Y axis
    parameter [8:0] Tank_Y_Max = 9'd224;     // Bottommost point on the Y axis
    parameter [8:0] Tank_Size = 9'd16;       // Tank size

    always_comb
    begin
        is_collide = 1'b0;

        if (Tank_State_2[2:1] != 2'b00)
        begin
            // collide other tank judgement
            if ( Tank_X_1_in < Tank_X_2 + Tank_Size && Tank_X_1_in + Tank_Size > Tank_X_2 )
            begin
                if ( Tank_Y_1_in < Tank_Y_2 + Tank_Size && Tank_Y_1_in + Tank_Size > Tank_Y_2 )
                begin
                    // allow occasional overlap
                    if ( Tank_X_1 >= Tank_X_2 + Tank_Size || Tank_X_1 + Tank_Size <= Tank_X_2 || Tank_Y_1 >= Tank_Y_2 + Tank_Size || Tank_Y_1 + Tank_Size <= Tank_Y_2 )
                    begin
                        is_collide = 1'b1;
                    end
                end
            end
        end

    end

endmodule
