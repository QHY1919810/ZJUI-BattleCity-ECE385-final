module tank_barrier_collide(
    input logic [8:0] Tank_X, Tank_Y,
    input logic [8:0] Barrier_X, Barrier_Y,
    input logic [2:0] Barrier_Id,
    output logic      is_collide
);
    parameter [8:0] Tank_Size = 9'd16;       // Tank size
    parameter [8:0] Barrier_Size = 9'd8;     // Barrier size

    always_comb
    begin
        is_collide = 1'b0;

        // collide wall, stone and water
        if ( Barrier_Id < 3'd3 )
        begin
            if ( Barrier_X < Tank_X + Tank_Size && Barrier_X + Barrier_Size > Tank_X )
            begin
                if ( Barrier_Y < Tank_Y + Tank_Size && Barrier_Y + Barrier_Size > Tank_Y )
                begin
                    is_collide = 1'b1;
                end
            end
        end
    end
    
endmodule
