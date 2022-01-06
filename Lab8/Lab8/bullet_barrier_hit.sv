module bullet_barrier_hit(
    input logic [8:0] Bullet_X, Bullet_Y,
    input logic [1:0] Bullet_State,
    input logic [8:0] Barrier_X, Barrier_Y,
    input logic [2:0] Barrier_Id,
    output logic      is_hit,
    output logic      is_destroy
);
    parameter [8:0] Bullet_Size = 9'd4;      // Bullet size
    parameter [8:0] Barrier_Size = 9'd8;     // Barrier size

    always_comb
    begin
        is_hit = 1'b0;
        is_destroy = 1'b0;

        // hit wall
        if ( Barrier_Id == 3'd0 )
        begin
            if ( Barrier_X < Bullet_X + Bullet_Size && Barrier_X + Barrier_Size > Bullet_X )
            begin
                if ( Barrier_Y < Bullet_Y + Bullet_Size && Barrier_Y + Barrier_Size > Bullet_Y )
                begin
                    is_hit = 1'b1;
                    is_destroy = 1'b1;
                end
            end
        end

        // hit stone
        if ( Barrier_Id == 3'd1 )
        begin
            if ( Barrier_X < Bullet_X + Bullet_Size && Barrier_X + Barrier_Size > Bullet_X )
            begin
                if ( Barrier_Y < Bullet_Y + Bullet_Size && Barrier_Y + Barrier_Size > Bullet_Y )
                begin
                    is_hit = 1'b1;
                    if (Bullet_State == 2'b11)
                        is_destroy = 1'b1;
                end
            end
        end
    end
    
endmodule