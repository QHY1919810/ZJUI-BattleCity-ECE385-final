module key_controller(
    input logic        Clk, Reset,
    input logic [15:0]  keycode_0, keycode_1, keycode_2,
    // input logic        press, // 1: key pressed, 0: key released
    output logic [3:0] Tank_Control_1, // {1'fire, 1' is_move, 2'move_direction}
                       Tank_Control_2,
    output logic       Confirm, // "enter" pressed
    output logic       Exit // "esc" pressed
);
    // w: 1D, s: 1B, a: 1C, d: 23, j: 3B, up: 75, down: 72, left: 6B, right: 74, 5(numpad): 73, enter: 5A
    logic [2:0] tank_move_1, tank_move_in_1;
    logic tank_fire_1, tank_fire_in_1;
    logic [2:0] tank_move_2, tank_move_in_2;
    logic tank_fire_2, tank_fire_in_2;
    logic [7:0] player_key_1, player_key_2;

    always_ff @(posedge Clk)
    begin
        tank_move_1 <= tank_move_in_1;
        tank_fire_1 <= tank_fire_in_1;
        tank_move_2 <= tank_move_in_2;
        tank_fire_2 <= tank_fire_in_2;
    end

    always_comb
    begin
        player_key_1 = 8'h00;
        player_key_2 = 8'h00;

        if (keycode_2[15:8] == 8'h1a || keycode_2[15:8] == 8'h04 || keycode_2[15:8] == 8'h16 || keycode_2[15:8] == 8'h07)
            player_key_1 = keycode_2[15:8];
        else
        begin
            if (keycode_2[7:0] == 8'h1a || keycode_2[7:0] == 8'h04 || keycode_2[7:0] == 8'h16 || keycode_2[7:0] == 8'h07)
                player_key_1 = keycode_2[7:0];
            else
            begin
                if (keycode_1[15:8] == 8'h1a || keycode_1[15:8] == 8'h04 || keycode_1[15:8] == 8'h16 || keycode_1[15:8] == 8'h07)
                    player_key_1 = keycode_1[15:8];
                else
                begin
                    if (keycode_1[7:0] == 8'h1a || keycode_1[7:0] == 8'h04 || keycode_1[7:0] == 8'h16 || keycode_1[7:0] == 8'h07)
                        player_key_1 = keycode_1[7:0];
                    else
                    begin
                        if (keycode_0[15:8] == 8'h1a || keycode_0[15:8] == 8'h04 || keycode_0[15:8] == 8'h16 || keycode_0[15:8] == 8'h07)
                            player_key_1 = keycode_0[15:8];
                        else
                        begin
                            if (keycode_0[7:0] == 8'h1a || keycode_0[7:0] == 8'h04 || keycode_0[7:0] == 8'h16 || keycode_0[7:0] == 8'h07)
                                player_key_1 = keycode_0[7:0];
                        end
                    end
                end
            end
        end

        if (keycode_2[15:8] == 8'h52 || keycode_2[15:8] == 8'h50 || keycode_2[15:8] == 8'h51 || keycode_2[15:8] == 8'h4f)
            player_key_2 = keycode_2[15:8];
        else
        begin
            if (keycode_2[7:0] == 8'h52 || keycode_2[7:0] == 8'h50 || keycode_2[7:0] == 8'h51 || keycode_2[7:0] == 8'h4f)
                player_key_2 = keycode_2[7:0];
            else
            begin
                if (keycode_1[15:8] == 8'h52 || keycode_1[15:8] == 8'h50 || keycode_1[15:8] == 8'h51 || keycode_1[15:8] == 8'h4f)
                    player_key_2 = keycode_1[15:8];
                else
                begin
                    if (keycode_1[7:0] == 8'h52 || keycode_1[7:0] == 8'h50 || keycode_1[7:0] == 8'h51 || keycode_1[7:0] == 8'h4f)
                        player_key_2 = keycode_1[7:0];
                    else
                    begin
                        if (keycode_0[15:8] == 8'h52 || keycode_0[15:8] == 8'h50 || keycode_0[15:8] == 8'h51 || keycode_0[15:8] == 8'h4f)
                            player_key_2 = keycode_0[15:8];
                        else
                        begin
                            if (keycode_0[7:0] == 8'h52 || keycode_0[7:0] == 8'h50 || keycode_0[7:0] == 8'h51 || keycode_0[7:0] == 8'h4f)
                                player_key_2 = keycode_0[7:0];
                        end
                    end
                end
            end
        end

        case (player_key_1)
            8'h1a: tank_move_in_1 = 3'b100;
            8'h04: tank_move_in_1 = 3'b101;
            8'h16: tank_move_in_1 = 3'b110;
            8'h07: tank_move_in_1 = 3'b111;
            default: tank_move_in_1 = 3'b000;
        endcase

        case (player_key_2)
            8'h52: tank_move_in_2 = 3'b100;
            8'h50: tank_move_in_2 = 3'b101;
            8'h51: tank_move_in_2 = 3'b110;
            8'h4f: tank_move_in_2 = 3'b111;
            default: tank_move_in_2 = 3'b000;
        endcase

        if (keycode_0[7:0] == 8'h0d || keycode_0[15:8] == 8'h0d || keycode_1[7:0] == 8'h0d || keycode_1[15:8] == 8'h0d || keycode_2[7:0] == 8'h0d || keycode_2[15:8] == 8'h0d)
            tank_fire_in_1 = 1'b1;
        else
            tank_fire_in_1 = 1'b0;

        if (keycode_0[7:0] == 8'h5d || keycode_0[15:8] == 8'h5d || keycode_1[7:0] == 8'h5d || keycode_1[15:8] == 8'h5d || keycode_2[7:0] == 8'h5d || keycode_2[15:8] == 8'h5d)
            tank_fire_in_2 = 1'b1;
        else
            tank_fire_in_2 = 1'b0;

        if (keycode_0[7:0] == 8'h28 || keycode_0[15:8] == 8'h28 || keycode_1[7:0] == 8'h28 || keycode_1[15:8] == 8'h28 || keycode_2[7:0] == 8'h28 || keycode_2[15:8] == 8'h28)
            Confirm = 1'b1;
        else
            Confirm = 1'b0;

        if (keycode_0[7:0] == 8'h29 || keycode_0[15:8] == 8'h29 || keycode_1[7:0] == 8'h29 || keycode_1[15:8] == 8'h29 || keycode_2[7:0] == 8'h29 || keycode_2[15:8] == 8'h29)
            Exit = 1'b1;
        else
            Exit = 1'b0;

        // case (keycode)
        //     8'h1d: // w
        //     begin
        //         if (press)
        //             tank_move_in_1 = 3'b100;
        //         else
        //         begin
        //             if (tank_move_1 == 3'b100)
        //                 tank_move_in_1 = 3'b000;
        //         end
        //     end
        //     8'h1b: // s
        //     begin
        //         if (press)
        //             tank_move_in_1 = 3'b110;
        //         else
        //         begin
        //             if (tank_move_1 == 3'b110)
        //                 tank_move_in_1 = 3'b000;
        //         end
        //     end
        //     8'h1c: // a
        //     begin
        //         if (press)
        //             tank_move_in_1 = 3'b101;
        //         else
        //         begin
        //             if (tank_move_1 == 3'b101)
        //                 tank_move_in_1 = 3'b000;
        //         end
        //     end
        //     8'h23: // d
        //     begin
        //         if (press)
        //             tank_move_in_1 = 3'b111;
        //         else
        //         begin
        //             if (tank_move_1 == 3'b111)
        //                 tank_move_in_1 = 3'b000;
        //         end
        //     end
        //     8'h3b: // j
        //     begin
        //         if (press)
        //             tank_fire_in_1 = 1'b1;
        //         else
        //             tank_fire_in_1 = 1'b0;
        //     end
        //     8'h75: // up
        //     begin
        //         if (press)
        //             tank_move_in_2 = 3'b100;
        //         else
        //         begin
        //             if (tank_move_2 == 3'b100)
        //                 tank_move_in_2 = 3'b000;
        //         end
        //     end
        //     8'h72: // down
        //     begin
        //         if (press)
        //             tank_move_in_2 = 3'b110;
        //         else
        //         begin
        //             if (tank_move_2 == 3'b110)
        //                 tank_move_in_2 = 3'b000;
        //         end
        //     end
        //     8'h6b: // left
        //     begin
        //         if (press)
        //             tank_move_in_2 = 3'b101;
        //         else
        //         begin
        //             if (tank_move_2 == 3'b101)
        //                 tank_move_in_2 = 3'b000;
        //         end
        //     end
        //     8'h74: // right
        //     begin
        //         if (press)
        //             tank_move_in_2 = 3'b111;
        //         else
        //         begin
        //             if (tank_move_2 == 3'b111)
        //                 tank_move_in_2 = 3'b000;
        //         end
        //     end
        //     8'h73: // 5(numpad)
        //     begin
        //         if (press)
        //             tank_fire_in_2 = 1'b1;
        //         else
        //             tank_fire_in_2 = 1'b0;
        //     end
        //     default: ;
        // endcase
    end

    assign Tank_Control_1 = {tank_fire_1, tank_move_1};
    assign Tank_Control_2 = {tank_fire_2, tank_move_2};
endmodule
