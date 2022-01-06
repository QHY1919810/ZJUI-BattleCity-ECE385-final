module game_judgment(
    input logic         Clk, Reset,
    input logic         frame_clk,
    input logic [3:0]   Tank_Control_1,
    input logic [3:0]   Tank_Control_2,
    input logic [3:0]   Tank_Control_3,
    input logic [3:0]   Tank_Control_4,
    input logic [3:0]   Tank_Control_5,
    input logic [3:0]   Tank_Control_6,
    input logic         Confirm, // "enter" pressed
    input logic         Exit, // "esc" pressed

    output logic        Tank_Die, // a tank die
    output logic        Upgrade, //  a tank upgrade

    // Output property of a tank according to ID
    input logic [2:0]   Tank_Id,
    output logic [1:0]  Tank_Direction, // 0: up, 1: left, 2: down, 3: right
    output logic [8:0]  Tank_X,
                        Tank_Y,
    output logic [2:0]  Tank_State, // {2'(0: dead, 1: level_1, 2: level_2, 3: level_3), 1'movement state}

    input logic  [1:0]  Random_Tank_Type,


    // Output property of a bullet according to ID
    input logic [2:0]   Bullet_Id,
    output logic [1:0]  Bullet_Direction,
    output logic [8:0]  Bullet_X,
                        Bullet_Y,
    output logic [1:0]  Bullet_State, // 0: not_exist, 1: level_1, 2: level_2, 3: level_3

    // Barrier buffer interface
    output logic        Barrier_Write,
    output logic [8:0]  Barrier_X,
                        Barrier_Y,
    input logic [2:0]   Barrier_Id_Read,
    output logic [2:0]  Barrier_Id_Write,

    // Bonus
    output logic [8:0]  Bonus_X,
                        Bonus_Y,
    output logic [1:0]  Bonus_Type, // 0: not_exist, 1: upgrade, 2: stop time, 3: kill all
    input logic [1:0]   Random_Bonus,
    input logic [1:0]   Random_Type,


    // Tank life
    output logic [3:0]  Tank_Life_1,
    output logic [3:0]  Tank_Life_2,
    output logic [4:0]  Enemy_Life,

    // Map id
    output logic [3:0]  Map_Id,

    output logic        Ready, // ready = 1, when all judgment completed
    output logic        Menu, // Menu = 1, when the game is at start menu
    output logic        Loading, // Loading = 1, when the game is loading (need to press enter to continue)
    input logic         Load_Ready,
    output logic        Over, // Game over
    output logic        Win // Game win
);
    // parameter [1:0] Tank_Direction_up = 2'b00; // initial direction is UP
    // parameter [8:0] Tank_X_Center = 9'd136;  // Center position on the X axis
    // parameter [8:0] Tank_Y_Center = 9'd112;  // Center position on the Y axis
    parameter [8:0] X_Min = 9'd0;            // Leftmost point on the X axis
    parameter [8:0] X_Max = 9'd272;          // Rightmost point on the X axis
    parameter [8:0] Y_Min = 9'd0;            // Topmost point on the Y axis
    parameter [8:0] Y_Max = 9'd224;          // Bottommost point on the Y axis
    parameter [8:0] Tank_X_Step = 9'd1;      // Step size on the X axis
    parameter [8:0] Tank_Y_Step = 9'd1;      // Step size on the Y axis
    parameter [8:0] Tank_X_Step_fast = 9'd2;      // Step size on the X axis
    parameter [8:0] Tank_Y_Step_fast = 9'd2;      // Step size on the Y axis
    parameter [8:0] Tank_Size = 9'd16;       // Tank size

    parameter [8:0] Bullet_X_Step = 9'd4;
    parameter [8:0] Bullet_Y_Step = 9'd4;
    parameter [8:0] Bullet_X_Step_upgrade = 9'd8;
    parameter [8:0] Bullet_Y_Step_upgrade = 9'd8;
    parameter [8:0] Bullet_Size = 9'd4;

    parameter [8:0] Barrier_Size = 9'd8;

    enum logic [4:0] {
        Start_Menu,
        Load_Map_1,
        Load_Map_2,
        Gameover,
        Victory,
        Game_Status_Judgment,
        Tank_Reborn,
        Tank_Move,
        Tank_Boundary_Judgment,
        Tank_Tank_Judgment,
        Tank_Barrier_Judgment_1,
        Tank_Barrier_Judgment_2,
        Tank_Bonus_Judgment,
        Tank_Fire,
        Bullet_Move_1,
        Bullet_Bullet_Judgment_1,
        Bullet_Move_2,
        Bullet_Bullet_Judgment_2,
        Bullet_Boundary_Judgment,
        Bullet_Barrier_Judgment_1,
        Bullet_Barrier_Judgment_2,
        Bullet_Barrier_Judgment_3,
        Barrier_1_destroy,
        Barrier_2_destroy,
        Bullet_Tank_Judgment,
        Bonus_Generate,
        Base_Judgment,
        Idle
    } State, Next_State;

    logic Ready_in;
    logic [3:0] Map_Id_in;

    logic [2:0] Id, Id_in;
    logic [1:0] Tank_Direction_all [6];
    logic [8:0] Tank_X_all [6];
    logic [8:0] Tank_Y_all [6];
    logic [2:0] Tank_State_all [6];

    logic [8:0] Tank_X_Motion, Tank_Y_Motion, Tank_X_Motion_in, Tank_Y_Motion_in, Tank_X_moved, Tank_Y_moved, Tank_X_in, Tank_Y_in;
    logic [1:0] Tank_Direction_in;
    logic [2:0] Tank_State_in [6];

    logic [3:0] Tank_Life_1_in, Tank_Life_2_in;
    logic [4:0] Enemy_Life_in;
    logic [7:0] Tank_Reborn_Counter [6];
    logic [7:0] Tank_Reborn_Counter_in;

    logic [3:0] Tank_Control;
    logic turn_direction;

    logic [1:0] Bullet_Direction_all [6];
    logic [8:0] Bullet_X_all [6];
    logic [8:0] Bullet_Y_all [6];
    logic [1:0] Bullet_State_all [6];

    logic [8:0] Bullet_X_in, Bullet_Y_in;
    logic [1:0] Bullet_Direction_in;
    logic [1:0] Bullet_State_in [6];

    logic [8:0] Bonus_X_in, Bonus_Y_in;
    logic [1:0] Bonus_Type_in;
    logic [8:0] Stop_Counter, Stop_Counter_in;

    logic is_collide_tank_0, is_collide_tank_1, is_collide_tank_2, is_collide_tank_3, is_collide_tank_4, is_collide_tank_5,
          is_collide_base,
          is_collide_boundary,
          is_collide_bonus,
          is_collide_barrier;
    logic is_hit_tank_0, is_hit_tank_1, is_hit_tank_2, is_hit_tank_3, is_hit_tank_4, is_hit_tank_5,
          is_hit_base,
          is_hit_boundary,
          is_hit_bullet_0, is_hit_bullet_1, is_hit_bullet_2, is_hit_bullet_3, is_hit_bullet_4, is_hit_bullet_5,
          is_hit_barrier, is_destroy_barrier;


    initial
    begin
        State = Start_Menu;
        Map_Id = 4'd1;
        Ready = 1'b0;
        Id = 1'b0;

        Tank_X_Motion = 9'b0;
        Tank_Y_Motion = 9'b0;

        Tank_Direction_all[0] = 2'b00;
        Tank_X_all[0] = 9'd96;
        Tank_Y_all[0] = 9'd200;
        Tank_State_all[0] = 3'b010;
        Tank_Direction_all[1] = 2'b00;
        Tank_X_all[1] = 9'd160;
        Tank_Y_all[1] = 9'd200;
        Tank_State_all[1] = 3'b010;
        Tank_Direction_all[2] = 2'b10;
        Tank_X_all[2] = 9'd0;
        Tank_Y_all[2] = 9'd0;
        Tank_State_all[2] = 3'b010;
        Tank_Direction_all[3] = 2'b10;
        Tank_X_all[3] = 9'd88;
        Tank_Y_all[3] = 9'd0;
        Tank_State_all[3] = 3'b010;
        Tank_Direction_all[4] = 2'b10;
        Tank_X_all[4] = 9'd168;
        Tank_Y_all[4] = 9'd0;
        Tank_State_all[4] = 3'b010;
        Tank_Direction_all[5] = 2'b10;
        Tank_X_all[5] = 9'd256;
        Tank_Y_all[5] = 9'd0;
        Tank_State_all[5] = 3'b010;

        Tank_Reborn_Counter[0] = 8'b0;
        Tank_Reborn_Counter[1] = 8'b0;
        Tank_Reborn_Counter[2] = 8'b0;
        Tank_Reborn_Counter[3] = 8'b0;
        Tank_Reborn_Counter[4] = 8'b0;
        Tank_Reborn_Counter[5] = 8'b0;
        Tank_Life_1 = 4'd2;
        Tank_Life_2 = 4'd2;
        Enemy_Life = 5'd16;

        Bullet_Direction_all[0] = 2'b00;
        Bullet_X_all[0] = 9'd0;
        Bullet_Y_all[0] = 9'd0;
        Bullet_State_all[0] = 2'b00;
        Bullet_Direction_all[1] = 2'b00;
        Bullet_X_all[1] = 9'd0;
        Bullet_Y_all[1] = 9'd0;
        Bullet_State_all[1] = 2'b00;
        Bullet_Direction_all[2] = 2'b00;
        Bullet_X_all[2] = 9'd0;
        Bullet_Y_all[2] = 9'd0;
        Bullet_State_all[2] = 2'b00;
        Bullet_Direction_all[3] = 2'b00;
        Bullet_X_all[3] = 9'd0;
        Bullet_Y_all[3] = 9'd0;
        Bullet_State_all[3] = 2'b00;
        Bullet_Direction_all[4] = 2'b00;
        Bullet_X_all[4] = 9'd0;
        Bullet_Y_all[4] = 9'd0;
        Bullet_State_all[4] = 2'b00;
        Bullet_Direction_all[5] = 2'b00;
        Bullet_X_all[5] = 9'd0;
        Bullet_Y_all[5] = 9'd0;
        Bullet_State_all[5] = 2'b00;
        
        Bonus_X = 9'd0;
        Bonus_Y = 9'd0;
        Bonus_Type = 2'b0;
        Stop_Counter = 9'b0;
    end

    // Detect rising edge of frame_clk
    logic frame_clk_delayed, frame_clk_rising_edge;
    always_ff @ (posedge Clk) begin
        frame_clk_delayed <= frame_clk;
        frame_clk_rising_edge <= (frame_clk == 1'b1) && (frame_clk_delayed == 1'b0);
    end
    // Update registers
    always_ff @ (posedge Clk)
    begin
        if (Reset || Next_State == Start_Menu || Next_State == Load_Map_1)
        begin
            if (Reset || Next_State == Start_Menu)
            begin
                State <= Start_Menu;
                Map_Id <= 4'd1;
                Ready <= 1'b0;
                Tank_State_all[0] <= 3'b010;
                Tank_State_all[1] <= 3'b010;
            end
            else
            begin
                State <= Next_State;
                Map_Id <= Map_Id_in;
                Ready <= 1'b1;
            end
            Id <= 1'b0;

            Tank_X_Motion <= 9'b0;
            Tank_Y_Motion <= 9'b0;

            Tank_Direction_all[0] <= 2'b00;
            Tank_X_all[0] <= 9'd96;
            Tank_Y_all[0] <= 9'd200;
            Tank_Direction_all[1] <= 2'b00;
            Tank_X_all[1] <= 9'd160;
            Tank_Y_all[1] <= 9'd200;
            Tank_Direction_all[2] <= 2'b10;
            Tank_X_all[2] <= 9'd0;
            Tank_Y_all[2] <= 9'd0;
            Tank_State_all[2] <= 3'b010;
            Tank_Direction_all[3] <= 2'b10;
            Tank_X_all[3] <= 9'd88;
            Tank_Y_all[3] <= 9'd0;
            Tank_State_all[3] <= 3'b010;
            Tank_Direction_all[4] <= 2'b10;
            Tank_X_all[4] <= 9'd168;
            Tank_Y_all[4] <= 9'd0;
            Tank_State_all[4] <= 3'b010;
            Tank_Direction_all[5] <= 2'b10;
            Tank_X_all[5] <= 9'd256;
            Tank_Y_all[5] <= 9'd0;
            Tank_State_all[5] <= 3'b010;

            Tank_Reborn_Counter[0] <= 8'b0;
            Tank_Reborn_Counter[1] <= 8'b0;
            Tank_Reborn_Counter[2] <= 8'b0;
            Tank_Reborn_Counter[3] <= 8'b0;
            Tank_Reborn_Counter[4] <= 8'b0;
            Tank_Reborn_Counter[5] <= 8'b0;
            Tank_Life_1 <= 4'd2;
            Tank_Life_2 <= 4'd2;
            Enemy_Life <= 5'd16;

            Bullet_Direction_all[0] <= 2'b00;
            Bullet_X_all[0] <= 9'd0;
            Bullet_Y_all[0] <= 9'd0;
            Bullet_State_all[0] <= 2'b00;
            Bullet_Direction_all[1] <= 2'b00;
            Bullet_X_all[1] <= 9'd0;
            Bullet_Y_all[1] <= 9'd0;
            Bullet_State_all[1] <= 2'b00;
            Bullet_Direction_all[2] <= 2'b00;
            Bullet_X_all[2] <= 9'd0;
            Bullet_Y_all[2] <= 9'd0;
            Bullet_State_all[2] <= 2'b00;
            Bullet_Direction_all[3] <= 2'b00;
            Bullet_X_all[3] <= 9'd0;
            Bullet_Y_all[3] <= 9'd0;
            Bullet_State_all[3] <= 2'b00;
            Bullet_Direction_all[4] <= 2'b00;
            Bullet_X_all[4] <= 9'd0;
            Bullet_Y_all[4] <= 9'd0;
            Bullet_State_all[4] <= 2'b00;
            Bullet_Direction_all[5] <= 2'b00;
            Bullet_X_all[5] <= 9'd0;
            Bullet_Y_all[5] <= 9'd0;
            Bullet_State_all[5] <= 2'b00;
            
            Bonus_X <= 9'd0;
            Bonus_Y <= 9'd0;
            Bonus_Type <= 2'b0;
            Stop_Counter <= 9'b0;
        end
        else
        begin
            State <= Next_State;
            Map_Id <= Map_Id_in;
            Ready <= Ready_in;
            Id <= Id_in;

            Tank_X_Motion <= Tank_X_Motion_in;
            Tank_Y_Motion <= Tank_Y_Motion_in;

            Tank_Direction_all[Id] <= Tank_Direction_in;
            Tank_X_all[Id] <= Tank_X_in;
            Tank_Y_all[Id] <= Tank_Y_in;
            Tank_State_all[0] <= Tank_State_in[0];
            Tank_State_all[1] <= Tank_State_in[1];
            Tank_State_all[2] <= Tank_State_in[2];
            Tank_State_all[3] <= Tank_State_in[3];
            Tank_State_all[4] <= Tank_State_in[4];
            Tank_State_all[5] <= Tank_State_in[5];

            Tank_Reborn_Counter[Id] <= Tank_Reborn_Counter_in;
            Tank_Life_1 <= Tank_Life_1_in;
            Tank_Life_2 <= Tank_Life_2_in;
            Enemy_Life <= Enemy_Life_in;

            Bullet_Direction_all[Id] <= Bullet_Direction_in;
            Bullet_X_all[Id] <= Bullet_X_in;
            Bullet_Y_all[Id] <= Bullet_Y_in;
            Bullet_State_all[0] <= Bullet_State_in[0];
            Bullet_State_all[1] <= Bullet_State_in[1];
            Bullet_State_all[2] <= Bullet_State_in[2];
            Bullet_State_all[3] <= Bullet_State_in[3];
            Bullet_State_all[4] <= Bullet_State_in[4];
            Bullet_State_all[5] <= Bullet_State_in[5];

            Bonus_X <= Bonus_X_in;
            Bonus_Y <= Bonus_Y_in;
            Bonus_Type <= Bonus_Type_in;
            Stop_Counter <= Stop_Counter_in;
        end
    end

    always_comb
    begin
        // By default, keep motion and position unchanged
        Next_State = State;
        Map_Id_in = Map_Id;
        Ready_in = Ready;
        Menu = 1'b0;
        Loading = 1'b0;
        Win = 1'b0;
        Over = 1'b0;
        Id_in = Id;

        Tank_Die = 1'b0;
        Upgrade = 1'b0;

        // Update Tank’s property
        Tank_Direction_in = Tank_Direction_all[Id];
        Tank_X_in = Tank_X_all[Id];
        Tank_Y_in = Tank_Y_all[Id];
        Tank_State_in[0] = Tank_State_all[0];
        Tank_State_in[1] = Tank_State_all[1];
        Tank_State_in[2] = Tank_State_all[2];
        Tank_State_in[3] = Tank_State_all[3];
        Tank_State_in[4] = Tank_State_all[4];
        Tank_State_in[5] = Tank_State_all[5];

        // Tank reborn counter
        Tank_Reborn_Counter_in = Tank_Reborn_Counter[Id];
        Tank_Life_1_in = Tank_Life_1;
        Tank_Life_2_in = Tank_Life_2;
        Enemy_Life_in = Enemy_Life;

        // Update the Tank's position with its motion
        Tank_X_Motion_in = Tank_X_Motion;
        Tank_Y_Motion_in = Tank_Y_Motion;
        Tank_X_moved = Tank_X_all[Id] + Tank_X_Motion;
        Tank_Y_moved = Tank_Y_all[Id] + Tank_Y_Motion;

        // Update Bullet’s property
        Bullet_Direction_in = Bullet_Direction_all[Id];
        Bullet_X_in = Bullet_X_all[Id];
        Bullet_Y_in = Bullet_Y_all[Id];
        Bullet_State_in[0] = Bullet_State_all[0];
        Bullet_State_in[1] = Bullet_State_all[1];
        Bullet_State_in[2] = Bullet_State_all[2];
        Bullet_State_in[3] = Bullet_State_all[3];
        Bullet_State_in[4] = Bullet_State_all[4];
        Bullet_State_in[5] = Bullet_State_all[5];

        Barrier_X = 9'b0;
        Barrier_Y = 9'b0;
        Barrier_Write = 1'b0;
        Barrier_Id_Write = 3'b111;

        Bonus_X_in = Bonus_X;
        Bonus_Y_in = Bonus_Y;
        Bonus_Type_in = Bonus_Type;
        Stop_Counter_in = Stop_Counter;


        turn_direction = 1'b0;

        case (Id)
            3'b000:
                Tank_Control = Tank_Control_1;
            3'b001:
                Tank_Control = Tank_Control_2;
            3'b010:
            begin
                if (Stop_Counter == 9'b0)
                    Tank_Control = Tank_Control_3;
                else
                    Tank_Control = 4'b0;
            end   
            3'b011:
            begin
                if (Stop_Counter == 9'b0)
                    Tank_Control = Tank_Control_4;
                else
                    Tank_Control = 4'b0;
            end 
            3'b100:
            begin
                if (Stop_Counter == 9'b0)
                    Tank_Control = Tank_Control_5;
                else
                    Tank_Control = 4'b0;
            end 
            3'b101:
            begin
                if (Stop_Counter == 9'b0)
                    Tank_Control = Tank_Control_6;
                else
                    Tank_Control = 4'b0;
            end 
            default:
                Tank_Control = 4'b0;
        endcase
        
        // Update position and motion only at rising edge of frame clock
        unique case (State)
            Start_Menu:
            begin
                Menu = 1'b1;
                if (Confirm)
                begin
                    Next_State = Load_Map_1;
                end
            end

            Load_Map_1:
            begin
                Loading = 1'b1;
                if (~Confirm)
                begin
                    Next_State = Load_Map_2;
                end
            end

            Load_Map_2:
            begin
                Loading = 1'b1;
                if (Load_Ready && Confirm)
                begin
                    Ready_in = 1'b0;
                    Next_State = Game_Status_Judgment;
                end
            end

            Gameover:
            begin
                Over = 1'b1;
                if (Exit)
                begin
                    Ready_in = 1'b0;
                    Next_State = Start_Menu;
                end
            end

            Victory:
            begin
                Win = 1'b1;
                if (Exit)
                begin
                    Ready_in = 1'b0;
                    Next_State = Start_Menu;
                end
            end

            Game_Status_Judgment:
            begin
                Next_State = Tank_Reborn;

                if (Tank_Life_1 == 4'b0 && Tank_Life_2 == 4'b0 && Tank_State_all[0][2:1] == 2'b00 && Tank_State_all[1][2:1] == 2'b00)
                begin
                    Ready_in = 1'b1;
                    Next_State = Gameover;
                end
                else if (Enemy_Life == 5'b0 && Tank_State_all[2][2:1] == 2'b00 && Tank_State_all[3][2:1] == 2'b00 && Tank_State_all[4][2:1] == 2'b00 && Tank_State_all[5][2:1] == 2'b00)
                begin
                    Next_State = Load_Map_1;
                    Map_Id_in = Map_Id + 4'b1;
                    if (Map_Id == 4'd10)
                    begin
                        Ready_in = 1'b1;
                        Next_State = Victory;
                    end
                end
            end

            Tank_Reborn:
            begin
                if (Tank_State_all[Id][2:1] == 2'b00)
                begin
                    Tank_Reborn_Counter_in = Tank_Reborn_Counter[Id] + 1;
                    case (Id)
                        3'b000:
                        begin
                            if (Tank_Reborn_Counter[Id] == 8'd59 && Tank_Life_1 != 4'b0)
                            begin
                                Tank_Reborn_Counter_in = 8'b0;
                                Tank_Direction_in = 2'b00;
                                Tank_X_in = 9'd96;
                                Tank_Y_in = 9'd200;
                                Tank_State_in[0] = 3'b010;
                                Tank_Life_1_in = Tank_Life_1 + 4'b1111;
                            end
                        end

                        3'b001:
                        begin
                            if (Tank_Reborn_Counter[Id] == 8'd59 && Tank_Life_2 != 4'b0)
                            begin
                                Tank_Reborn_Counter_in = 8'b0;
                                Tank_Direction_in = 2'b00;
                                Tank_X_in = 9'd160;
                                Tank_Y_in = 9'd200;
                                Tank_State_in[1] = 3'b010;
                                Tank_Life_2_in = Tank_Life_2 + 4'b1111;
                            end
                        end

                        default:
                        begin
                            if (Tank_Reborn_Counter[Id] == 8'd179 && Enemy_Life != 4'b0)
                            begin
                                Tank_Reborn_Counter_in = 8'b0;
                                Tank_Direction_in = 2'b10;
                                case (Id)
                                    3'b010: Tank_X_in = 9'd0;
                                    3'b011: Tank_X_in = 9'd88;
                                    3'b100: Tank_X_in = 9'd168;
                                    3'b101: Tank_X_in = 9'd256;
                                    default: Tank_X_in = 9'd0;
                                endcase
                                Tank_Y_in = 9'd0;
                                if (Random_Tank_Type == 2'b00)
                                begin
                                    Tank_State_in[Id] = 3'b010;
                                end
                                else
                                begin
                                    Tank_State_in[Id] = {Random_Tank_Type, 1'b0};
                                end
                                Enemy_Life_in = Enemy_Life + 5'b11111;
                            end
                        end

                    endcase
                end

                Next_State = Tank_Move;
            end

            Tank_Move:
            begin
                if (Tank_State_all[Id][2:1] != 2'b00)
                begin
                    // When tank turns direction, adjust the position to make operation smooth
                    case (Tank_Control[2:0])
                        3'b101: // A is pressed
                        begin
                            if(Tank_Direction_all[Id] == 2'b01 && Id > 3'b001 && Tank_State_all[Id][2:1] == 2'b10)
                            begin
                                Tank_X_Motion_in = (~(Tank_X_Step_fast)+1'b1);
                                Tank_Y_Motion_in = 9'b0;
                            end
                            else if(Tank_Direction_all[Id] == 2'b01)
                            begin
                                Tank_X_Motion_in = (~(Tank_X_Step)+1'b1);
                                Tank_Y_Motion_in = 9'b0;
                            end
                            else
                            begin
                                turn_direction = 1'b1;
                                Tank_Direction_in = 2'b01;
                                Tank_Y_in = ((Tank_Y_all[Id] + 4) >> 3) << 3;
                            end
                        end
                        3'b111: // D is pressed
                        begin
                            if(Tank_Direction_all[Id] == 2'b11 && Id > 3'b001 && Tank_State_all[Id][2:1] == 2'b10)
                            begin
                                Tank_X_Motion_in = Tank_X_Step_fast;
                                Tank_Y_Motion_in = 9'b0;
                            end
                            else if(Tank_Direction_all[Id] == 2'b11)
                            begin
                                Tank_X_Motion_in = Tank_X_Step;
                                Tank_Y_Motion_in = 9'b0;
                            end
                            else
                            begin
                                turn_direction = 1'b1;
                                Tank_Direction_in = 2'b11;
                                Tank_Y_in = ((Tank_Y_all[Id] + 4) >> 3) << 3;
                            end
                        end
                        3'b100: // W is pressed
                        begin
                            if(Tank_Direction_all[Id] == 2'b00 && Id > 3'b001 && Tank_State_all[Id][2:1] == 2'b10)
                            begin
                                Tank_Y_Motion_in = (~(Tank_Y_Step_fast) + 1'b1);
                                Tank_X_Motion_in = 9'b0;
                            end
                            else if(Tank_Direction_all[Id] == 2'b00)
                            begin
                                Tank_Y_Motion_in = (~(Tank_Y_Step) + 1'b1);
                                Tank_X_Motion_in = 9'b0;
                            end
                            else
                            begin
                                turn_direction = 1'b1;
                                Tank_Direction_in = 2'b00;
                                Tank_X_in = ((Tank_X_all[Id] + 4) >> 3) << 3;
                            end
                        end
                        3'b110: // S is pressed
                        begin
                            if(Tank_Direction_all[Id] == 2'b10 && Id > 3'b001 && Tank_State_all[Id][2:1] == 2'b10)
                            begin
                                Tank_Y_Motion_in = Tank_Y_Step_fast;
                                Tank_X_Motion_in = 9'b0;
                            end
                            else if(Tank_Direction_all[Id] == 2'b10)
                            begin
                                Tank_Y_Motion_in = Tank_Y_Step;
                                Tank_X_Motion_in = 9'b0;
                            end
                            else
                            begin
                                turn_direction = 1'b1;
                                Tank_Direction_in = 2'b10;
                                Tank_X_in = ((Tank_X_all[Id] + 4) >> 3) << 3;
                            end
                        end

                        default:
                        begin
                            Tank_X_Motion_in = 9'b0;
                            Tank_Y_Motion_in = 9'b0;
                            turn_direction = 1'b1;
                        end
                    endcase

                    if(~turn_direction)
                    begin
                        Tank_State_in[Id] = {Tank_State_all[Id][2:1], ~Tank_State_all[Id][0]};
                        Next_State = Tank_Boundary_Judgment;
                    end
                    else
                    begin
                        Id_in = Id + 3'b1;
                        Next_State = Tank_Reborn;
                        if (Id == 3'b101)
                        begin
                            Id_in = 3'b0;
                            Next_State = Tank_Fire;
                        end
                    end
                end
                else
                begin
                    Id_in = Id + 3'b1;
                    Next_State = Tank_Reborn;
                    if (Id == 3'b101)
                    begin
                        Id_in = 3'b0;
                        Next_State = Tank_Fire;
                    end
                end
            end

            Tank_Boundary_Judgment:
            begin
                // collision judgment
                if (is_collide_boundary)
                begin
                    Tank_X_Motion_in = 9'b0;
                    Tank_Y_Motion_in = 9'b0;
                end

                Next_State = Tank_Tank_Judgment;
            end
            
            Tank_Tank_Judgment:
            begin
                // collision judgment
                if (is_collide_tank_0 || is_collide_tank_1 || is_collide_tank_2 || is_collide_tank_3 || is_collide_tank_4 || is_collide_tank_5 || is_collide_base)
                begin
                    Tank_X_Motion_in = 9'b0;
                    Tank_Y_Motion_in = 9'b0;
                end

                Next_State = Tank_Barrier_Judgment_1;
            end

            Tank_Barrier_Judgment_1:
            begin
                case (Tank_Direction_all[Id])
                    2'b00:
                    begin
                        Barrier_X = Tank_X_moved;
                        Barrier_Y = (Tank_Y_moved >> 3) << 3;
                    end
                    2'b01:
                    begin
                        Barrier_Y = Tank_Y_moved;
                        Barrier_X = (Tank_X_moved >> 3) << 3;
                    end
                    2'b10:
                    begin
                        Barrier_X = Tank_X_moved;
                        Barrier_Y = ((Tank_Y_moved + Tank_Size) >> 3) << 3;
                    end
                    2'b11:
                    begin
                        Barrier_Y = Tank_Y_moved;
                        Barrier_X = ((Tank_X_moved + Tank_Size) >> 3) << 3;
                    end
                endcase

                // collision judgment
                if (is_collide_barrier)
                begin
                    Tank_X_Motion_in = 9'b0;
                    Tank_Y_Motion_in = 9'b0;
                end

                Next_State = Tank_Barrier_Judgment_2;
            end

            Tank_Barrier_Judgment_2:
            begin
                case (Tank_Direction_all[Id])
                    2'b00:
                    begin
                        Barrier_X = Tank_X_moved + Barrier_Size;
                        Barrier_Y = (Tank_Y_moved >> 3) << 3;
                    end
                    2'b01:
                    begin
                        Barrier_Y = Tank_Y_moved + Barrier_Size;
                        Barrier_X = (Tank_X_moved >> 3) << 3;
                    end
                    2'b10:
                    begin
                        Barrier_X = Tank_X_moved + Barrier_Size;
                        Barrier_Y = ((Tank_Y_moved + Tank_Size) >> 3) << 3;
                    end
                    2'b11:
                    begin
                        Barrier_Y = Tank_Y_moved + Barrier_Size;
                        Barrier_X = ((Tank_X_moved + Tank_Size) >> 3) << 3;
                    end
                endcase

                // collision judgment
                if (is_collide_barrier)
                begin
                    Tank_X_Motion_in = 9'b0;
                    Tank_Y_Motion_in = 9'b0;
                end

                Next_State = Tank_Bonus_Judgment;
            end

            Tank_Bonus_Judgment:
            begin
                if (is_collide_bonus && Id < 3'b010)
                begin
                    Bonus_Type_in = 2'b00;
                    case (Bonus_Type)
                        2'b01:
                        begin
                            if (Tank_State_all[Id][2:1] != 2'b11 && Tank_State_all[Id][2:1] != 2'b00)
                            begin
                                Tank_State_in[Id] = Tank_State_all[Id] + 3'b010;
                                Upgrade = 1'b0;
                            end
                        end

                        2'b10:
                        begin
                            Stop_Counter_in = 9'd300;
                        end

                        2'b11:
                        begin
                            Tank_State_in[2] = 3'b000;
                            Tank_State_in[3] = 3'b000;
                            Tank_State_in[4] = 3'b000;
                            Tank_State_in[5] = 3'b000;
                            Tank_Die = 1'b1;
                        end
                        
                        default: ;
                    endcase
                end

                Tank_X_in = Tank_X_moved;
                Tank_Y_in = Tank_Y_moved;

                Id_in = Id + 3'b1;
                Next_State = Tank_Reborn;
                if (Id == 3'b101)
                begin
                    Id_in = 3'b0;
                    Next_State = Tank_Fire;
                end
            end

            Tank_Fire:
            begin
                if (Bullet_State_all[Id] == 2'b00 && Tank_Control[3] == 1'b1 && Tank_State_all[Id][2:1] != 2'b00)
                begin
                    case (Tank_Direction_all[Id])
                        2'b00:
                        begin
                            Bullet_X_in = Tank_X_all[Id] + 6;
                            Bullet_Y_in = Tank_Y_all[Id] - 4;
                        end
                        2'b01:
                        begin
                            Bullet_Y_in = Tank_Y_all[Id] + 6;
                            Bullet_X_in = Tank_X_all[Id] - 4;
                        end
                        2'b10:
                        begin
                            Bullet_X_in = Tank_X_all[Id] + 6;
                            Bullet_Y_in = Tank_Y_all[Id] + 16;
                        end
                        2'b11:
                        begin
                            Bullet_Y_in = Tank_Y_all[Id] + 6;
                            Bullet_X_in = Tank_X_all[Id] + 16;
                        end
                    endcase

                    Next_State = Bullet_Bullet_Judgment_2;
                    Bullet_Direction_in = Tank_Direction_all[Id];
                    if (Id < 3'b010)
                    begin
                        Bullet_State_in[Id] = Tank_State_all[Id][2:1];
                    end
                    else
                    begin
                        if (Tank_State_all[Id][2:1] == 2'b11)
                            Bullet_State_in[Id] = 2'b10;
                        else
                            Bullet_State_in[Id] = 2'b01;
                    end
                end
                else if (Bullet_State_all[Id] == 2'b00)
                begin
                    Id_in = Id + 3'b1;
                    Next_State = Tank_Fire;
                    if (Id == 3'b101)
                    begin
                        Id_in = 3'b0;
                        Ready_in = 1'b1;
                        Next_State = Idle;
                    end
                end
                else
                    // if bullet_state = 1, normal speed
                    if (Bullet_State_all[Id] == 2'b01)
                        Next_State = Bullet_Move_2;
                    // if bullet_state = 2 or 3, double speed
                    else
                        Next_State = Bullet_Move_1;
            end

            Bullet_Move_1:
            begin
                Next_State = Bullet_Bullet_Judgment_1;

                case (Bullet_Direction_all[Id])
                    2'b00:
                        Bullet_Y_in = Bullet_Y_all[Id] + (~(Bullet_Y_Step)+1'b1);
                    2'b01:
                        Bullet_X_in = Bullet_X_all[Id] + (~(Bullet_X_Step)+1'b1);
                    2'b10:
                        Bullet_Y_in = Bullet_Y_all[Id] + Bullet_Y_Step;
                    2'b11:
                        Bullet_X_in = Bullet_X_all[Id] + Bullet_X_Step;
                endcase
            end

            Bullet_Bullet_Judgment_1:
            begin
                Next_State = Bullet_Move_2;

                // hit judgment
                if (Id != 3'b000 && is_hit_bullet_0)
                begin
                    Bullet_State_in[Id] = 2'b00;
                    Bullet_State_in[0] = 2'b00;
                end
                else if (Id != 3'b001 && is_hit_bullet_1)
                begin
                    Bullet_State_in[Id] = 2'b00;
                    Bullet_State_in[1] = 2'b00;
                end
                else if (Id != 3'b010 && is_hit_bullet_2)
                begin
                    Bullet_State_in[Id] = 2'b00;
                    Bullet_State_in[2] = 2'b00;
                end
                else if (Id != 3'b011 && is_hit_bullet_3)
                begin
                    Bullet_State_in[Id] = 2'b00;
                    Bullet_State_in[3] = 2'b00;
                end
                else if (Id != 3'b100 && is_hit_bullet_4)
                begin
                    Bullet_State_in[Id] = 2'b00;
                    Bullet_State_in[4] = 2'b00;
                end
                else if (Id != 3'b101 && is_hit_bullet_5)
                begin
                    Bullet_State_in[Id] = 2'b00;
                    Bullet_State_in[5] = 2'b00;
                end

                if (Bullet_State_in[Id] == 2'b00)
                begin
                    Id_in = Id + 3'b1;
                    Next_State = Tank_Fire;
                    if (Id == 3'b101)
                    begin
                        Id_in = 3'b0;
                        Ready_in = 1'b1;
                        Next_State = Idle;
                    end
                end
            end

            Bullet_Move_2:
            begin
                Next_State = Bullet_Bullet_Judgment_2;

                case (Bullet_Direction_all[Id])
                    2'b00:
                        Bullet_Y_in = Bullet_Y_all[Id] + (~(Bullet_Y_Step)+1'b1);
                    2'b01:
                        Bullet_X_in = Bullet_X_all[Id] + (~(Bullet_X_Step)+1'b1);
                    2'b10:
                        Bullet_Y_in = Bullet_Y_all[Id] + Bullet_Y_Step;
                    2'b11:
                        Bullet_X_in = Bullet_X_all[Id] + Bullet_X_Step;
                endcase
            end

            Bullet_Bullet_Judgment_2:
            begin
                Next_State = Bullet_Boundary_Judgment;

                // hit judgment
                if (Id != 3'b000 && is_hit_bullet_0)
                begin
                    Bullet_State_in[Id] = 2'b00;
                    Bullet_State_in[0] = 2'b00;
                end
                else if (Id != 3'b001 && is_hit_bullet_1)
                begin
                    Bullet_State_in[Id] = 2'b00;
                    Bullet_State_in[1] = 2'b00;
                end
                else if (Id != 3'b010 && is_hit_bullet_2)
                begin
                    Bullet_State_in[Id] = 2'b00;
                    Bullet_State_in[2] = 2'b00;
                end
                else if (Id != 3'b011 && is_hit_bullet_3)
                begin
                    Bullet_State_in[Id] = 2'b00;
                    Bullet_State_in[3] = 2'b00;
                end
                else if (Id != 3'b100 && is_hit_bullet_4)
                begin
                    Bullet_State_in[Id] = 2'b00;
                    Bullet_State_in[4] = 2'b00;
                end
                else if (Id != 3'b101 && is_hit_bullet_5)
                begin
                    Bullet_State_in[Id] = 2'b00;
                    Bullet_State_in[5] = 2'b00;
                end

                if (Bullet_State_in[Id] == 2'b00)
                begin
                    Id_in = Id + 3'b1;
                    Next_State = Tank_Fire;
                    if (Id == 3'b101)
                    begin
                        Id_in = 3'b0;
                        Ready_in = 1'b1;
                        Next_State = Idle;
                    end
                end
            end

            Bullet_Boundary_Judgment:
            begin
                Next_State = Bullet_Barrier_Judgment_1;

                // hit judgment
                if (is_hit_boundary)
                begin
                    Bullet_State_in[Id] = 2'b00;

                    Id_in = Id + 3'b1;
                    Next_State = Tank_Fire;
                    if (Id == 3'b101)
                    begin
                        Id_in = 3'b0;
                        Ready_in = 1'b1;
                        Next_State = Idle;
                    end
                end
            end

            Bullet_Barrier_Judgment_1:
            begin
                case (Bullet_Direction_all[Id])
                    2'b00:
                    begin
                        Barrier_X = Bullet_X_all[Id] - 6;
                        Barrier_Y = (Bullet_Y_all[Id] >> 3) << 3;
                    end
                    2'b01:
                    begin
                        Barrier_Y = Bullet_Y_all[Id] - 6;
                        Barrier_X = (Bullet_X_all[Id] >> 3) << 3;
                    end
                    2'b10:
                    begin
                        Barrier_X = Bullet_X_all[Id] - 6;
                        Barrier_Y = ((Bullet_Y_all[Id] + Bullet_Size - 1) >> 3) << 3;
                    end
                    2'b11:
                    begin
                        Barrier_Y = Bullet_Y_all[Id] - 6;
                        Barrier_X = ((Bullet_X_all[Id] + Bullet_Size - 1) >> 3) << 3;
                    end
                endcase

                // hit judgment
                if (is_destroy_barrier)
                begin
                    Next_State = Barrier_1_destroy;
                end
                else if(is_hit_barrier)
                begin
                    Next_State = Bullet_Barrier_Judgment_3;
                end
                else
                begin
                    Next_State = Bullet_Barrier_Judgment_2;
                end
            end

            Bullet_Barrier_Judgment_2:
            begin
                case (Bullet_Direction_all[Id])
                    2'b00:
                    begin
                        Barrier_X = Bullet_X_all[Id] + 2;
                        Barrier_Y = (Bullet_Y_all[Id] >> 3) << 3;
                    end
                    2'b01:
                    begin
                        Barrier_Y = Bullet_Y_all[Id] + 2;
                        Barrier_X = (Bullet_X_all[Id] >> 3) << 3;
                    end
                    2'b10:
                    begin
                        Barrier_X = Bullet_X_all[Id] + 2;
                        Barrier_Y = ((Bullet_Y_all[Id] + Bullet_Size - 1) >> 3) << 3;
                    end
                    2'b11:
                    begin
                        Barrier_Y = Bullet_Y_all[Id] + 2;
                        Barrier_X = ((Bullet_X_all[Id] + Bullet_Size - 1) >> 3) << 3;
                    end
                endcase

                // hit judgment
                if (is_destroy_barrier)
                begin
                    Next_State = Barrier_2_destroy;
                end
                else if(is_hit_barrier)
                begin
                    Bullet_State_in[Id] = 2'b00;
                    Id_in = Id + 3'b1;
                    Next_State = Tank_Fire;
                    if (Id == 3'b101)
                    begin
                        Id_in = 3'b0;
                        Ready_in = 1'b1;
                        Next_State = Idle;
                    end
                end
                else
                begin
                    Next_State = Bullet_Tank_Judgment;
                end
            end

            Bullet_Barrier_Judgment_3:
            begin
                case (Bullet_Direction_all[Id])
                    2'b00:
                    begin
                        Barrier_X = Bullet_X_all[Id] + 2;
                        Barrier_Y = (Bullet_Y_all[Id] >> 3) << 3;
                    end
                    2'b01:
                    begin
                        Barrier_Y = Bullet_Y_all[Id] + 2;
                        Barrier_X = (Bullet_X_all[Id] >> 3) << 3;
                    end
                    2'b10:
                    begin
                        Barrier_X = Bullet_X_all[Id] + 2;
                        Barrier_Y = ((Bullet_Y_all[Id] + Bullet_Size - 1) >> 3) << 3;
                    end
                    2'b11:
                    begin
                        Barrier_Y = Bullet_Y_all[Id] + 2;
                        Barrier_X = ((Bullet_X_all[Id] + Bullet_Size - 1) >> 3) << 3;
                    end
                endcase

                // hit judgment
                if (is_destroy_barrier)
                begin
                    Next_State = Barrier_2_destroy;
                end
                else
                begin
                    Bullet_State_in[Id] = 2'b00;
                    Id_in = Id + 3'b1;
                    Next_State = Tank_Fire;
                    if (Id == 3'b101)
                    begin
                        Id_in = 3'b0;
                        Ready_in = 1'b1;
                        Next_State = Idle;
                    end
                end
            end

            Barrier_1_destroy:
            begin
                case (Bullet_Direction_all[Id])
                    2'b00:
                    begin
                        Barrier_X = Bullet_X_all[Id] - 6;
                        Barrier_Y = (Bullet_Y_all[Id] >> 3) << 3;
                    end
                    2'b01:
                    begin
                        Barrier_Y = Bullet_Y_all[Id] - 6;
                        Barrier_X = (Bullet_X_all[Id] >> 3) << 3;
                    end
                    2'b10:
                    begin
                        Barrier_X = Bullet_X_all[Id] - 6;
                        Barrier_Y = ((Bullet_Y_all[Id] + Bullet_Size - 1) >> 3) << 3;
                    end
                    2'b11:
                    begin
                        Barrier_Y = Bullet_Y_all[Id] - 6;
                        Barrier_X = ((Bullet_X_all[Id] + Bullet_Size - 1) >> 3) << 3;
                    end
                endcase
                
                Barrier_Write = 1'b1;
                Barrier_Id_Write = 3'b111;

                Next_State = Bullet_Barrier_Judgment_3;
            end

            Barrier_2_destroy:
            begin
                case (Bullet_Direction_all[Id])
                    2'b00:
                    begin
                        Barrier_X = Bullet_X_all[Id] + 2;
                        Barrier_Y = (Bullet_Y_all[Id] >> 3) << 3;
                    end
                    2'b01:
                    begin
                        Barrier_Y = Bullet_Y_all[Id] + 2;
                        Barrier_X = (Bullet_X_all[Id] >> 3) << 3;
                    end
                    2'b10:
                    begin
                        Barrier_X = Bullet_X_all[Id] + 2;
                        Barrier_Y = ((Bullet_Y_all[Id] + Bullet_Size - 1) >> 3) << 3;
                    end
                    2'b11:
                    begin
                        Barrier_Y = Bullet_Y_all[Id] + 2;
                        Barrier_X = ((Bullet_X_all[Id] + Bullet_Size - 1) >> 3) << 3;
                    end
                endcase
                
                Barrier_Write = 1'b1;
                Barrier_Id_Write = 3'b111;

                Bullet_State_in[Id] = 2'b00;
                Id_in = Id + 3'b1;
                Next_State = Tank_Fire;
                if (Id == 3'b101)
                begin
                    Id_in = 3'b0;
                    Ready_in = 1'b1;
                    Next_State = Idle;
                end
            end

            Bullet_Tank_Judgment:
            begin
                Next_State = Base_Judgment;

                // hit judgment
                if (is_hit_tank_0)
                begin
                    Bullet_State_in[Id] = 2'b00;
                    Tank_State_in[0] = 3'b000;
                    Tank_Die = 1'b1;
                end
                else if (is_hit_tank_1)
                begin
                    Bullet_State_in[Id] = 2'b00;
                    Tank_State_in[1] = 3'b000;
                    Tank_Die = 1'b1;
                end
                else if (is_hit_tank_2)
                begin
                    Bullet_State_in[Id] = 2'b00;
                    if (Id < 3'b010)
                    begin
                        Tank_State_in[2] = 3'b000;
                        Tank_Die = 1'b1;
                    end
                end
                else if (is_hit_tank_3)
                begin
                    Bullet_State_in[Id] = 2'b00;
                    if (Id < 3'b010)
                    begin
                        Tank_State_in[3] = 3'b000;
                        Tank_Die = 1'b1;
                    end
                end
                else if (is_hit_tank_4)
                begin
                    Bullet_State_in[Id] = 2'b00;
                    if (Id < 3'b010)
                    begin
                        Tank_State_in[4] = 3'b000;
                        Tank_Die = 1'b1;
                    end
                end
                else if (is_hit_tank_5)
                begin
                    Bullet_State_in[Id] = 2'b00;
                    if (Id < 3'b010)
                    begin
                        Tank_State_in[5] = 3'b000;
                        Tank_Die = 1'b1;
                    end
                end

                if (Bullet_State_in[Id] == 2'b00)
                begin
                    if (Random_Bonus == 2'b00 && Id < 3'b010)
                    begin
                        Next_State = Bonus_Generate;
                    end
                    else
                    begin
                        Id_in = Id + 3'b1;
                        Next_State = Tank_Fire;
                        if (Id == 3'b101)
                        begin
                            Id_in = 3'b0;
                            Ready_in = 1'b1;
                            Next_State = Idle;
                        end
                    end
                end
            end

            Bonus_Generate:
            begin
                Bonus_X_in = 9'd128;
                Bonus_Y_in = 9'd176;
                if (Random_Type == 2'b00)
                begin
                    Bonus_Type_in = 2'b01;
                end
                else
                begin
                    Bonus_Type_in = Random_Type;
                end

                Id_in = Id + 3'b1;
                Next_State = Tank_Fire;
                if (Id == 3'b101)
                begin
                    Id_in = 3'b0;
                    Ready_in = 1'b1;
                    Next_State = Idle;
                end
            end

            Base_Judgment:
            begin
                if (is_hit_base)
                begin
                    Ready_in = 1'b1;
                    Next_State = Gameover;
                end
                else
                begin
                    Id_in = Id + 3'b1;
                    Next_State = Tank_Fire;
                    if (Id == 3'b101)
                    begin
                        Id_in = 3'b0;
                        Ready_in = 1'b1;
                        Next_State = Idle;
                    end
                end
            end


            Idle:
            begin
                if(frame_clk_rising_edge)
                begin
                    if (Exit)
                        Next_State = Start_Menu;
                    else
                        Next_State = Game_Status_Judgment;

                    Ready_in = 1'b0;

                    if (Stop_Counter != 9'b0)
                        Stop_Counter_in = Stop_Counter + 9'h1ff;
                end
            end

            default: ;
        endcase
    end

    // modules for judgment of tanks
    tank_boundary_collide tank_boundary_collide_inst(.Tank_X(Tank_X_moved), .Tank_Y(Tank_Y_moved), .is_collide(is_collide_boundary));

    tank_tank_collide tank_tank_collide_inst0(.Tank_X_1(Tank_X_all[Id]), .Tank_Y_1(Tank_Y_all[Id]), .Tank_X_1_in(Tank_X_moved),
                                              .Tank_Y_1_in(Tank_Y_moved), .Tank_X_2(Tank_X_all[0]), .Tank_Y_2(Tank_Y_all[0]),
                                              .Tank_State_2(Tank_State_all[0]), .is_collide(is_collide_tank_0));

    tank_tank_collide tank_tank_collide_inst1(.Tank_X_1(Tank_X_all[Id]), .Tank_Y_1(Tank_Y_all[Id]), .Tank_X_1_in(Tank_X_moved),
                                              .Tank_Y_1_in(Tank_Y_moved), .Tank_X_2(Tank_X_all[1]), .Tank_Y_2(Tank_Y_all[1]),
                                              .Tank_State_2(Tank_State_all[1]), .is_collide(is_collide_tank_1));

    tank_tank_collide tank_tank_collide_inst2(.Tank_X_1(Tank_X_all[Id]), .Tank_Y_1(Tank_Y_all[Id]), .Tank_X_1_in(Tank_X_moved),
                                              .Tank_Y_1_in(Tank_Y_moved), .Tank_X_2(Tank_X_all[2]), .Tank_Y_2(Tank_Y_all[2]),
                                              .Tank_State_2(Tank_State_all[2]), .is_collide(is_collide_tank_2));

    tank_tank_collide tank_tank_collide_inst3(.Tank_X_1(Tank_X_all[Id]), .Tank_Y_1(Tank_Y_all[Id]), .Tank_X_1_in(Tank_X_moved),
                                              .Tank_Y_1_in(Tank_Y_moved), .Tank_X_2(Tank_X_all[3]), .Tank_Y_2(Tank_Y_all[3]),
                                              .Tank_State_2(Tank_State_all[3]), .is_collide(is_collide_tank_3));

    tank_tank_collide tank_tank_collide_inst4(.Tank_X_1(Tank_X_all[Id]), .Tank_Y_1(Tank_Y_all[Id]), .Tank_X_1_in(Tank_X_moved),
                                              .Tank_Y_1_in(Tank_Y_moved), .Tank_X_2(Tank_X_all[4]), .Tank_Y_2(Tank_Y_all[4]),
                                              .Tank_State_2(Tank_State_all[4]), .is_collide(is_collide_tank_4));

    tank_tank_collide tank_tank_collide_inst5(.Tank_X_1(Tank_X_all[Id]), .Tank_Y_1(Tank_Y_all[Id]), .Tank_X_1_in(Tank_X_moved),
                                              .Tank_Y_1_in(Tank_Y_moved), .Tank_X_2(Tank_X_all[5]), .Tank_Y_2(Tank_Y_all[5]),
                                              .Tank_State_2(Tank_State_all[5]), .is_collide(is_collide_tank_5));

    tank_barrier_collide tank_barrier_collide_inst(.Tank_X(Tank_X_moved), .Tank_Y(Tank_Y_moved), .Barrier_X(Barrier_X),
                                                   .Barrier_Y(Barrier_Y), .Barrier_Id(Barrier_Id_Read), .is_collide(is_collide_barrier));

    // modules for judgment of bullets
    bullet_boundary_hit bullet_boundary_hit_inst(.Bullet_X(Bullet_X_all[Id]), .Bullet_Y(Bullet_Y_all[Id]), .is_hit(is_hit_boundary));

    bullet_bullet_hit bullet_bullet_hit_inst0(.Bullet_X_1(Bullet_X_all[Id]), .Bullet_Y_1(Bullet_Y_all[Id]),
                                              .Bullet_X_2(Bullet_X_all[0]), .Bullet_Y_2(Bullet_Y_all[0]),
                                              .Bullet_State_2(Bullet_State_all[0]), .is_hit(is_hit_bullet_0));

    bullet_bullet_hit bullet_bullet_hit_inst1(.Bullet_X_1(Bullet_X_all[Id]), .Bullet_Y_1(Bullet_Y_all[Id]),
                                              .Bullet_X_2(Bullet_X_all[1]), .Bullet_Y_2(Bullet_Y_all[1]),
                                              .Bullet_State_2(Bullet_State_all[1]), .is_hit(is_hit_bullet_1));

    bullet_bullet_hit bullet_bullet_hit_inst2(.Bullet_X_1(Bullet_X_all[Id]), .Bullet_Y_1(Bullet_Y_all[Id]),
                                              .Bullet_X_2(Bullet_X_all[2]), .Bullet_Y_2(Bullet_Y_all[2]),
                                              .Bullet_State_2(Bullet_State_all[2]), .is_hit(is_hit_bullet_2));

    bullet_bullet_hit bullet_bullet_hit_inst3(.Bullet_X_1(Bullet_X_all[Id]), .Bullet_Y_1(Bullet_Y_all[Id]),
                                              .Bullet_X_2(Bullet_X_all[3]), .Bullet_Y_2(Bullet_Y_all[3]),
                                              .Bullet_State_2(Bullet_State_all[3]), .is_hit(is_hit_bullet_3));

    bullet_bullet_hit bullet_bullet_hit_inst4(.Bullet_X_1(Bullet_X_all[Id]), .Bullet_Y_1(Bullet_Y_all[Id]),
                                              .Bullet_X_2(Bullet_X_all[4]), .Bullet_Y_2(Bullet_Y_all[4]),
                                              .Bullet_State_2(Bullet_State_all[4]), .is_hit(is_hit_bullet_4));

    bullet_bullet_hit bullet_bullet_hit_inst5(.Bullet_X_1(Bullet_X_all[Id]), .Bullet_Y_1(Bullet_Y_all[Id]),
                                              .Bullet_X_2(Bullet_X_all[5]), .Bullet_Y_2(Bullet_Y_all[5]),
                                              .Bullet_State_2(Bullet_State_all[5]), .is_hit(is_hit_bullet_5));

    bullet_barrier_hit bullet_barrier_hit_inst(.Bullet_X(Bullet_X_all[Id]), .Bullet_Y(Bullet_Y_all[Id]), .Bullet_State(Bullet_State_all[Id]),
                                               .Barrier_X(Barrier_X), .Barrier_Y(Barrier_Y), .Barrier_Id(Barrier_Id_Read),
                                               .is_hit(is_hit_barrier), .is_destroy(is_destroy_barrier));

    bullet_tank_hit bullet_tank_hit_inst0(.Tank_X(Tank_X_all[0]), .Tank_Y(Tank_Y_all[0]), .Tank_State(Tank_State_all[0]),
                                          .Bullet_X(Bullet_X_all[Id]), .Bullet_Y(Bullet_Y_all[Id]), .is_hit(is_hit_tank_0));

    bullet_tank_hit bullet_tank_hit_inst1(.Tank_X(Tank_X_all[1]), .Tank_Y(Tank_Y_all[1]), .Tank_State(Tank_State_all[1]),
                                          .Bullet_X(Bullet_X_all[Id]), .Bullet_Y(Bullet_Y_all[Id]), .is_hit(is_hit_tank_1));

    bullet_tank_hit bullet_tank_hit_inst2(.Tank_X(Tank_X_all[2]), .Tank_Y(Tank_Y_all[2]), .Tank_State(Tank_State_all[2]),
                                          .Bullet_X(Bullet_X_all[Id]), .Bullet_Y(Bullet_Y_all[Id]), .is_hit(is_hit_tank_2));

    bullet_tank_hit bullet_tank_hit_inst3(.Tank_X(Tank_X_all[3]), .Tank_Y(Tank_Y_all[3]), .Tank_State(Tank_State_all[3]),
                                          .Bullet_X(Bullet_X_all[Id]), .Bullet_Y(Bullet_Y_all[Id]), .is_hit(is_hit_tank_3));

    bullet_tank_hit bullet_tank_hit_inst4(.Tank_X(Tank_X_all[4]), .Tank_Y(Tank_Y_all[4]), .Tank_State(Tank_State_all[4]),
                                          .Bullet_X(Bullet_X_all[Id]), .Bullet_Y(Bullet_Y_all[Id]), .is_hit(is_hit_tank_4));

    bullet_tank_hit bullet_tank_hit_inst5(.Tank_X(Tank_X_all[5]), .Tank_Y(Tank_Y_all[5]), .Tank_State(Tank_State_all[5]),
                                          .Bullet_X(Bullet_X_all[Id]), .Bullet_Y(Bullet_Y_all[Id]), .is_hit(is_hit_tank_5));

    // bonus collide judgment
    tank_tank_collide tank_bonus_collide_inst(.Tank_X_1(Tank_X_all[Id]), .Tank_Y_1(Tank_Y_all[Id]), .Tank_X_1_in(Tank_X_moved),
                                              .Tank_Y_1_in(Tank_Y_moved), .Tank_X_2(Bonus_X), .Tank_Y_2(Bonus_Y),
                                              .Tank_State_2(3'b110), .is_collide(is_collide_bonus));

    // base collide and hit judgment
    tank_tank_collide tank_base_collide_inst(.Tank_X_1(Tank_X_all[Id]), .Tank_Y_1(Tank_Y_all[Id]), .Tank_X_1_in(Tank_X_moved),
                                              .Tank_Y_1_in(Tank_Y_moved), .Tank_X_2(9'd128), .Tank_Y_2(9'd208),
                                              .Tank_State_2(3'b110), .is_collide(is_collide_base));

    bullet_tank_hit bullet_base_hit_inst(.Tank_X(9'd128), .Tank_Y(9'd208), .Tank_State(3'b110),
                                         .Bullet_X(Bullet_X_all[Id]), .Bullet_Y(Bullet_Y_all[Id]), .is_hit(is_hit_base));

    assign Tank_Direction = Tank_Direction_all[Tank_Id];
    assign Tank_X = Tank_X_all[Tank_Id];
    assign Tank_Y = Tank_Y_all[Tank_Id];
    assign Tank_State = Tank_State_all[Tank_Id];

    assign Bullet_Direction = Bullet_Direction_all[Bullet_Id];
    assign Bullet_X = Bullet_X_all[Bullet_Id];
    assign Bullet_Y = Bullet_Y_all[Bullet_Id];
    assign Bullet_State = Bullet_State_all[Bullet_Id];
endmodule
