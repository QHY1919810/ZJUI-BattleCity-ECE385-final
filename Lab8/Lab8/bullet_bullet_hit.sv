module bullet_bullet_hit(
    input logic [8:0] Bullet_X_1, Bullet_Y_1,
    input logic [8:0] Bullet_X_2, Bullet_Y_2,
    input logic [1:0] Bullet_State_2,
    output logic      is_hit
);
    parameter [8:0] Bullet_Size = 9'd4;        // Bullet size

    always_comb
    begin
        is_hit = 1'b0;

        // hit other bullet judgement
        if (Bullet_State_2 != 2'b00)
        begin
            if ( Bullet_X_1 < Bullet_X_2 + Bullet_Size && Bullet_X_1 + Bullet_Size > Bullet_X_2 )
            begin
                if ( Bullet_Y_1 < Bullet_Y_2 + Bullet_Size && Bullet_Y_1 + Bullet_Size > Bullet_Y_2 )
                begin
                    is_hit = 1'b1;
                end
            end
        end
    end

endmodule
