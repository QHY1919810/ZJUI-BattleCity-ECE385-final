module bullet_tank_hit(
    input logic [8:0] Tank_X, Tank_Y,
    input logic [2:0] Tank_State,
    input logic [8:0] Bullet_X, Bullet_Y,
    output logic      is_hit
);
    parameter [8:0] Tank_Size = 9'd16;       // Tank size
    parameter [8:0] Bullet_Size = 9'd4;      // Bullet size

    always_comb
    begin
        is_hit = 1'b0;

        if (Tank_State[2:1] != 2'b00)
        begin
            // bullet hit tank judgement
            if ( Bullet_X < Tank_X + Tank_Size && Bullet_X + Bullet_Size > Tank_X )
            begin
                if ( Bullet_Y < Tank_Y + Tank_Size && Bullet_Y + Bullet_Size > Tank_Y )
                begin
                    is_hit = 1'b1;
                end
            end
        end
    end

endmodule
