module frame_drawer(
    input logic         Clk, Reset,
    input logic         Ready, // if game judgement completed
    input logic         Menu, // if game is at the start menu
    input logic         Loading, // if map is loaded
    input logic         Over, // Game over
    input logic         Win, // Game win
    input logic         frame_clk, // 60Hz V-SYNC signal

    // property of tanks
    output logic [2:0]  Tank_Id,
    input logic [1:0]   Tank_Direction,
    input logic [8:0]   Tank_X,
                        Tank_Y,
    input logic [2:0]   Tank_State,

    // property of bullets
    output logic [2:0]  Bullet_Id,
    input logic [1:0]   Bullet_Direction,
    input logic [8:0]   Bullet_X,
                        Bullet_Y,
    input logic [1:0]   Bullet_State,

    // Barrier buffer interface
    input logic [2:0]   Barrier_Id,
    output logic [8:0]  Barrier_X,
                        Barrier_Y,

    // Bonus on the map
    input logic [8:0]   Bonus_X,
                        Bonus_Y,
    input logic [1:0]   Bonus_Type, // 0: not_exist, 1: upgrade, 2: stop time, 3: kill all

    // Tank life
    input logic [3:0]   Tank_Life_1,
    input logic [3:0]   Tank_Life_2,
    input logic [4:0]   Enemy_Life,

    // Map id
    input logic [3:0]   Map_Id,
    
    // control signal for sprite OCM
    // output logic        SRAM_Read,
    output logic [19:0] ADDR,
    input logic [4:0]   ColorId_Read,
    
    // control signal for frame_buffer
    output logic        frame,
    output logic        FB_Write,
    output logic [8:0]  FB_AddrX,
                        FB_AddrY,
    output logic [4:0]  ColorId_Write
);
parameter [19:0] Enemy_Tank_ADDR = 20'd12288;
parameter [19:0] Star_ADDR = 20'd18432;
parameter [19:0] Base_ADDR = 20'd18688;
parameter [19:0] Barrier_ADDR = 20'd18944;
parameter [19:0] Bullet_ADDR = 20'd19200;
parameter [19:0] Bonus_ADDR = 20'd19264;
parameter [19:0] Stage_ADDR = 20'd20032;
parameter [19:0] UI_ADDR = 20'd20352;
parameter [19:0] Number_ADDR = 20'd21184;
parameter [19:0] Start_Menu_ADDR = 20'd21824;
parameter [19:0] Gameover_ADDR = 20'd98624;
parameter [19:0] Victory_ADDR = 20'd175424;

    enum logic [4:0] {
		Start_Menu,
        Load_Map_1,
        Load_Map_2,
        Load_Map_3,
        Load_Map_4,
        Gameover,
        Victory,
        Background_1,
        Background_2,
        Wait_Judgment,
        Base_Render,
        Tank_Render_read,
        Star_Render,
        Tank_Render_write,
        Enemy_Tank_Render_write,
        Barrier_Render_read,
        Barrier_Render_write,
        Bullet_Render_read,
        Bullet_Render_write,
        Bonus_Render,
        // Bullet_Blast_Render,
        // Tank_Blast_Render,
        UI_Render_1,
        UI_Render_2,
        UI_Render_3,
        UI_Render_4,
        UI_Render_Number_1,
        UI_Render_Number_2,
        UI_Render_Number_3,
        UI_Render_Number_4,
        UI_Render_Number_5,
        UI_Render_Number_6,
        Idle_1,
        Idle_2
    } State, Next_State;
    logic frame_clk_delayed, frame_clk_rising_edge;

    // logic [8:0] h_counter, v_counter, h_counter_in, v_counter_in;

    logic frame_in;
    // logic wait_sram, wait_sram_in;
    // logic FB_Write_in;
    // logic [8:0] FB_AddrX_in, FB_AddrY_in;
    // logic [4:0] ColorId_in;

    logic Drawing, Drawing_in, Draw_Ready;
    logic [19:0] Start_ADDR;
    logic [4:0] ColorId;
    logic Transparent;
    logic [8:0] X_Max, Y_Max,
                X_Offset, Y_Offset;

    logic [2:0] Tank_Id_in;
    logic [8:0] Barrier_X_in, Barrier_Y_in;
    logic [2:0] Bullet_Id_in;

    // drawing engine
    drawer drawer_inst(.*);

    initial
    begin
        State = Start_Menu;
        frame = 1'b0;
        // FB_Write = 1'b0;
        // FB_AddrX = 9'd0;
        // FB_AddrY = 9'd0;
        // h_counter = 9'b0;
        // v_counter = 9'b0;
        // ColorId = 5'd0;
        Drawing = 1'b0;
        Tank_Id = 1'b0;
        Barrier_X = 9'd0;
        Barrier_Y = 9'd0;
        Bullet_Id = 1'b0;
    end

    // Detect rising edge of frame_clk
    always_ff @ (posedge Clk) begin
        frame_clk_delayed <= frame_clk;
        frame_clk_rising_edge <= (frame_clk == 1'b1) && (frame_clk_delayed == 1'b0);
    end
    
    // update registers
    always_ff @ (posedge Clk)
    begin
        if (Reset)
        begin
            State <= Start_Menu;
            // wait_sram <= 1'b0;
            frame <= 1'b0;
            // FB_Write <= 1'b0;
            // FB_AddrX <= 9'd0;
            // FB_AddrY <= 9'd0;
            // h_counter <= 9'b0;
            // v_counter <= 9'b0;
            // ColorId <= 5'd0;
            Drawing <= 1'b0;
            Tank_Id <= 1'b0;
            Barrier_X <= 9'd0;
            Barrier_Y <= 9'd0;
            Bullet_Id <= 1'b0;
        end
        else
        begin
            State <= Next_State;
            // wait_sram <= wait_sram_in;
            frame <= frame_in;
            // FB_Write <= FB_Write_in;
            // FB_AddrX <= FB_AddrX_in;
            // FB_AddrY <= FB_AddrY_in;
            // h_counter <= h_counter_in;
            // v_counter <= v_counter_in;
            // ColorId <= ColorId_in;
            Drawing <= Drawing_in;
            Tank_Id <= Tank_Id_in;
            Barrier_X <= Barrier_X_in;
            Barrier_Y <= Barrier_Y_in;
            Bullet_Id <= Bullet_Id_in;
        end
    end

    always_comb
    begin
        Next_State = State;

        // SRAM_Read = 1'b0;
        // wait_sram_in = 1'b0;
        frame_in = frame;
        // FB_Write_in = 1'b0;
        // FB_AddrX_in = FB_AddrX;
        // FB_AddrY_in = FB_AddrY;
        // ColorId_in = 5'd0;

        // h_counter_in = h_counter;
        // v_counter_in = v_counter;

        Drawing_in = 1'b0;
        Start_ADDR = 20'b0;
        ColorId = 5'b0;
        Transparent = 1'b0;
        X_Max = 9'b0;
        Y_Max = 9'b0;
        X_Offset = 9'b0;
        Y_Offset = 9'b0;

        Tank_Id_in = Tank_Id;

        Barrier_X_in = Barrier_X;
        Barrier_Y_in = Barrier_Y;

        Bullet_Id_in = Bullet_Id;

        unique case (State)

            // Render Start Menu
            Start_Menu:
            begin
                // ADDR = Start_Menu_ADDR + h_counter + (v_counter * 320);

                // FB_Write_in = 1'b1;
                // FB_AddrX_in = h_counter;
                // FB_AddrY_in = v_counter;
                // ColorId_in = Data_Read[4:0];

                // h_counter_in = h_counter + 9'd1;
                // if(h_counter + 9'd1 == X_Max)
                // begin
                //     h_counter_in = 9'd0;
                //     v_counter_in = v_counter + 9'd1;
                //     if(v_counter + 9'd1 == Y_Max)
                //     begin
                //         v_counter_in = 9'd0;
                //         Next_State = Idle_1;
                //     end
                // end
                Drawing_in = 1'b1;
                Start_ADDR = Start_Menu_ADDR;
                ColorId = ColorId_Read;
                X_Max = 9'd320;
                Y_Max = 9'd240;

                if (Draw_Ready)
                begin
                    Next_State = Idle_1;
                    Drawing_in = 1'b0;
                end
            end

            // Render gray background when loading maps
            Load_Map_1:
            begin
                // FB_Write_in = 1'b1;
                // FB_AddrX_in = h_counter;
                // FB_AddrY_in = v_counter;
                // ColorId_in = 5'd21;

                // h_counter_in = h_counter + 9'd1;
                // if(h_counter + 9'd1 == X_Max)
                // begin
                //     h_counter_in = 9'd0;
                //     v_counter_in = v_counter + 9'd1;
                //     if(v_counter + 9'd1 == Y_Max)
                //     begin
                //         v_counter_in = 9'd0;
                //         Next_State = Load_Map_2;
                //     end
                // end
                Drawing_in = 1'b1;
                ColorId = 5'd21;
                X_Max = 9'd320;
                Y_Max = 9'd240;

                if (Draw_Ready)
                begin
                    Next_State = Load_Map_2;
                    Drawing_in = 1'b0;
                end
            end

            // Render "stage"
            Load_Map_2:
            begin
                // ADDR = Stage_ADDR + h_counter + (v_counter * 40);

                // FB_Write_in = 1'b1;
                // FB_AddrX_in = 9'd140 + h_counter;
                // FB_AddrY_in = 9'd112 + v_counter;
                // ColorId_in = Data_Read[4:0];

                // h_counter_in = h_counter + 9'd1;
                // if(h_counter == 9'd39)
                // begin
                //     h_counter_in = 9'd0;
                //     v_counter_in = v_counter + 9'd1;
                //     if(v_counter == 9'd7)
                //     begin
                //         v_counter_in = 9'd0;
                //         Next_State = Load_Map_3;
                //     end
                // end

                Drawing_in = 1'b1;
                Start_ADDR = Stage_ADDR;
                ColorId = ColorId_Read;
                X_Max = 9'd40;
                Y_Max = 9'd8;
                X_Offset = 9'd140;
                Y_Offset = 9'd112;

                if (Draw_Ready)
                begin
                    Next_State = Load_Map_3;
                    Drawing_in = 1'b0;
                end
            end

            // Render stage_number[0]
            Load_Map_3:
            begin
                // ADDR = Number_ADDR + 64 + h_counter + (v_counter << 3);

                // FB_Write_in = 1'b1;
                // FB_AddrX_in = 9'd160 + h_counter;
                // FB_AddrY_in = 9'd120 + v_counter;
                // ColorId_in = Data_Read[4:0];

                // h_counter_in = h_counter + 9'd1;
                // if(h_counter == 9'd7)
                // begin
                //     h_counter_in = 9'd0;
                //     v_counter_in = v_counter + 9'd1;
                //     if(v_counter == 9'd7)
                //     begin
                //         v_counter_in = 9'd0;
                //         Next_State = Load_Map_4;
                //     end
                // end

                Drawing_in = 1'b1;
                Start_ADDR = Number_ADDR + ((Map_Id % 4'd10) << 6);
                ColorId = ColorId_Read;
                X_Max = 9'd8;
                Y_Max = 9'd8;
                X_Offset = 9'd160;
                Y_Offset = 9'd120;

                if (Draw_Ready)
                begin
                    Next_State = Load_Map_4;
                    Drawing_in = 1'b0;
                end
            end

            // Render stage_number[1]
            Load_Map_4:
            begin
                // ADDR = Number_ADDR + h_counter + (v_counter << 3);

                // FB_Write_in = 1'b1;
                // FB_AddrX_in = 9'd152 + h_counter;
                // FB_AddrY_in = 9'd120 + v_counter;
                // ColorId_in = Data_Read[4:0];

                // h_counter_in = h_counter + 9'd1;
                // if(h_counter == 9'd7)
                // begin
                //     h_counter_in = 9'd0;
                //     v_counter_in = v_counter + 9'd1;
                //     if(v_counter == 9'd7)
                //     begin
                //         v_counter_in = 9'd0;
                //         Next_State = Idle_1;
                //     end
                // end

                Drawing_in = 1'b1;
                Start_ADDR = Number_ADDR + ((Map_Id / 4'd10) << 6);
                ColorId = ColorId_Read;
                X_Max = 9'd8;
                Y_Max = 9'd8;
                X_Offset = 9'd152;
                Y_Offset = 9'd120;

                if (Draw_Ready)
                begin
                    Next_State = Idle_1;
                    Drawing_in = 1'b0;
                end
            end

            Gameover:
            begin
                Drawing_in = 1'b1;
                Start_ADDR = Gameover_ADDR;
                ColorId = ColorId_Read;
                X_Max = 9'd320;
                Y_Max = 9'd240;

                // Drawing_in = 1'b1;
                // ColorId = 5'd21;
                // X_Max = 9'd320;
                // Y_Max = 9'd240;

                if (Draw_Ready)
                begin
                    Next_State = Idle_1;
                    Drawing_in = 1'b0;
                end
            end

            Victory:
            begin
                Drawing_in = 1'b1;
                Start_ADDR = Victory_ADDR;
                ColorId = ColorId_Read;
                X_Max = 9'd320;
                Y_Max = 9'd240;

                // Drawing_in = 1'b1;
                // ColorId = 5'd21;
                // X_Max = 9'd320;
                // Y_Max = 9'd240;

                if (Draw_Ready)
                begin
                    Next_State = Idle_1;
                    Drawing_in = 1'b0;
                end
            end

            // Render the background (grey)
            Background_1:
            begin
                // FB_Write_in = 1'b1;
                // FB_AddrX_in = h_counter;
                // FB_AddrY_in = v_counter;
                // if(h_counter >= 9'd8 && h_counter < 9'd280 && v_counter >= 9'd8 && v_counter < 9'd232)
                //     ColorId_in = 5'd5;
                // else
                //     ColorId_in = 5'd21;

                // h_counter_in = h_counter + 9'd1;
                // if(h_counter + 9'd1 == X_Max)
                // begin
                //     h_counter_in = 9'd0;
                //     v_counter_in = v_counter + 9'd1;
                //     if(v_counter + 9'd1 == Y_Max)
                //     begin
                //         v_counter_in = 9'd0;
                //         Next_State = Wait_Judgment;
                //     end
                // end

                Drawing_in = 1'b1;
                ColorId = 5'd21;
                X_Max = 9'd320;
                Y_Max = 9'd240;

                if (Draw_Ready)
                begin
                    Next_State = Background_2;
                    Drawing_in = 1'b0;
                end
            end

            // Render the background (black)
            Background_2:
            begin
                // FB_Write_in = 1'b1;
                // FB_AddrX_in = h_counter;
                // FB_AddrY_in = v_counter;
                // if(h_counter >= 9'd8 && h_counter < 9'd280 && v_counter >= 9'd8 && v_counter < 9'd232)
                //     ColorId_in = 5'd5;
                // else
                //     ColorId_in = 5'd21;

                // h_counter_in = h_counter + 9'd1;
                // if(h_counter + 9'd1 == X_Max)
                // begin
                //     h_counter_in = 9'd0;
                //     v_counter_in = v_counter + 9'd1;
                //     if(v_counter + 9'd1 == Y_Max)
                //     begin
                //         v_counter_in = 9'd0;
                //         Next_State = Wait_Judgment;
                //     end
                // end

                Drawing_in = 1'b1;
                ColorId = 5'd0;
                X_Max = 9'd272;
                Y_Max = 9'd224;
                X_Offset = 9'd8;
                Y_Offset = 9'd8;

                if (Draw_Ready)
                begin
                    Next_State = Base_Render;
                    Drawing_in = 1'b0;
                end
            end

            // Render base in map
            Base_Render:
            begin
                Drawing_in = 1'b1;
                Start_ADDR = Base_ADDR;
                ColorId = ColorId_Read;
                Transparent = 1'b1;
                X_Max = 9'd16;
                Y_Max = 9'd16;
                X_Offset = 9'd136;
                Y_Offset = 9'd216;

                if (Draw_Ready)
                begin
                    Next_State = Wait_Judgment;
                    Drawing_in = 1'b0;
                end
            end

            Wait_Judgment:
            begin
                if(Ready)
                    Next_State = Tank_Render_read;
            end

            Tank_Render_read:
            begin
                if (Tank_State[2:1] == 2'b00)
                begin
                    if ((Tank_Id == 3'b000 && Tank_Life_1 > 4'b0) || (Tank_Id == 3'b001 && Tank_Life_2 > 4'b0) || (Tank_Id > 3'b001 && Enemy_Life > 5'b0))
                    begin
                        Next_State = Star_Render;
                    end
                    else
                    begin
                        Tank_Id_in = Tank_Id + 3'b1;
                        Next_State = Tank_Render_read;
                        if(Tank_Id == 3'b101)
                        begin
                            Tank_Id_in = 3'b0;
                            Next_State = Barrier_Render_read;
                        end
                    end
                end
                else
                begin
                    if (Tank_Id < 3'b010)
                        Next_State = Tank_Render_write;
                    else
                        Next_State = Enemy_Tank_Render_write;
                end
            end

            // Render stars in map
            Star_Render:
            begin
                Drawing_in = 1'b1;
                Start_ADDR = Star_ADDR;
                ColorId = ColorId_Read;
                Transparent = 1'b1;
                X_Max = 9'd16;
                Y_Max = 9'd16;
                
                case (Tank_Id)
                    3'b000:
                    begin
                        X_Offset = 9'd104;
                        Y_Offset = 9'd208;
                    end
                    3'b001:
                    begin
                        X_Offset = 9'd168;
                        Y_Offset = 9'd208;
                    end
                    3'b010:
                    begin
                        X_Offset = 9'd8;
                        Y_Offset = 9'd8;
                    end
                    3'b011:
                    begin
                        X_Offset = 9'd96;
                        Y_Offset = 9'd8;
                    end
                    3'b100:
                    begin
                        X_Offset = 9'd176;
                        Y_Offset = 9'd8;
                    end
                    3'b101:
                    begin
                        X_Offset = 9'd264;
                        Y_Offset = 9'd8;
                    end
                    default: ;
                endcase

                if (Draw_Ready)
                begin
                    Drawing_in = 1'b0;
                    Tank_Id_in = Tank_Id + 3'b1;
                    Next_State = Tank_Render_read;
                    if(Tank_Id == 3'b101)
                    begin
                        Tank_Id_in = 3'b0;
                        Next_State = Barrier_Render_read;
                    end
                end
            end

            // Render tanks in map
            Tank_Render_write:
            begin
                Drawing_in = 1'b1;
                Start_ADDR = ((Tank_State[2:1] - 1) << 11) + Tank_Id * 6144 + (Tank_Direction << 9) + (Tank_State[0] << 8);
                ColorId = ColorId_Read;
                Transparent = 1'b1;
                X_Max = 9'd16;
                Y_Max = 9'd16;
                X_Offset = Tank_X + 9'd8;
                Y_Offset = Tank_Y + 9'd8;

                if (Draw_Ready)
                begin
                    Drawing_in = 1'b0;
                    Tank_Id_in = Tank_Id + 3'b1;
                    Next_State = Tank_Render_read;
                    if(Tank_Id == 3'b101)
                    begin
                        Tank_Id_in = 3'b0;
                        Next_State = Barrier_Render_read;
                    end
                end
            end

            // Render enemy tanks in map
            Enemy_Tank_Render_write:
            begin
                Drawing_in = 1'b1;
                Start_ADDR = Enemy_Tank_ADDR + ((Tank_State[2:1] - 1) << 11) + (Tank_Direction << 9) + (Tank_State[0] << 8);
                ColorId = ColorId_Read;
                Transparent = 1'b1;
                X_Max = 9'd16;
                Y_Max = 9'd16;
                X_Offset = Tank_X + 9'd8;
                Y_Offset = Tank_Y + 9'd8;

                if (Draw_Ready)
                begin
                    Drawing_in = 1'b0;
                    Tank_Id_in = Tank_Id + 3'b1;
                    Next_State = Tank_Render_read;
                    if(Tank_Id == 3'b101)
                    begin
                        Tank_Id_in = 3'b0;
                        Next_State = Barrier_Render_read;
                    end
                end
            end

            Barrier_Render_read:
            begin
                if (Barrier_Id < 3'd4)
                begin
                    Next_State = Barrier_Render_write;
                end
                else
                begin
                    Barrier_X_in = Barrier_X + 9'd8;
                    if(Barrier_X == 9'd264)
                    begin
                        Barrier_X_in = 9'd0;
                        Barrier_Y_in = Barrier_Y + 9'd8;
                        if(Barrier_Y == 9'd216)
                        begin
                            Barrier_Y_in = 9'd0;
                            Next_State = Bullet_Render_read;
                        end
                    end
                end
            end

            // Render barriers
            Barrier_Render_write:
            begin
                // ADDR = Barrier_ADDR + ((Barrier_Id) << 6) + h_counter + (v_counter << 3);

                // FB_AddrX_in = Barrier_X + h_counter + 9'd8;
                // FB_AddrY_in = Barrier_Y + v_counter + 9'd8;
                // ColorId_in = Data_Read[4:0];
                // if(ColorId_in == 5'd0)
                //     FB_Write_in = 1'b0;
                // else
                //     FB_Write_in = 1'b1;

                // h_counter_in = h_counter + 9'd1;
                // if(h_counter == 9'd7)
                // begin
                //     h_counter_in = 9'd0;
                //     v_counter_in = v_counter + 9'd1;
                //     if(v_counter == 9'd7)
                //     begin
                //         v_counter_in = 9'd0;
                //         Next_State = Barrier_Render_wait; // wait for Barrier_OCM
                //         Barrier_X_in = Barrier_X + 9'd8;
                //         if(Barrier_X == 9'd264)
                //         begin
                //             Barrier_X_in = 9'd0;
                //             Barrier_Y_in = Barrier_Y + 9'd8;
                //             if(Barrier_Y == 9'd216)
                //             begin
                //                 Barrier_Y_in = 9'd0;
                //                 Next_State = Bullet_Render;
                //             end
                //         end
                //     end
                // end

                
                Drawing_in = 1'b1;
                Start_ADDR = Barrier_ADDR + ((Barrier_Id) << 6);
                ColorId = ColorId_Read;
                Transparent = 1'b1;
                X_Max = 9'd8;
                Y_Max = 9'd8;
                X_Offset = Barrier_X + 9'd8;
                Y_Offset = Barrier_Y + 9'd8;

                if (Draw_Ready)
                begin
                    Drawing_in = 1'b0;
                    Next_State = Barrier_Render_read; // wait for Barrier_OCM
                    Barrier_X_in = Barrier_X + 9'd8;
                    if(Barrier_X == 9'd264)
                    begin
                        Barrier_X_in = 9'd0;
                        Barrier_Y_in = Barrier_Y + 9'd8;
                        if(Barrier_Y == 9'd216)
                        begin
                            Barrier_Y_in = 9'd0;
                            Next_State = Bullet_Render_read;
                        end
                    end
                end
            end

            Bullet_Render_read:
            begin
                if (Bullet_State != 2'b00)
                begin
                    // FB_AddrX_in = Bullet_X + h_counter + 9'd8;
                    // FB_AddrY_in = Bullet_Y + v_counter + 9'd8;
                    // ColorId_in = Data_Read[4:0];
                    // // set black color as transparent
                    // if(ColorId_in == 5'd0)
                    //     FB_Write_in = 1'b0;
                    // else
                    //     FB_Write_in = 1'b1;

                    // h_counter_in = h_counter + 9'd1;
                    // if(h_counter == 9'd3)
                    // begin
                    //     h_counter_in = 9'd0;
                    //     v_counter_in = v_counter + 9'd1;
                    //     if(v_counter == 9'd3)
                    //     begin
                    //         v_counter_in = 9'd0;
                    //         Bullet_Id_in = Bullet_Id + 1'd1;
                    //         if(Bullet_Id == 1'd1)
                    //         begin
                    //             Bullet_Id_in = 1'd0;
                    //             Next_State = UI_Render_1;
                    //         end
                    //     end
                    // end

                    Next_State = Bullet_Render_write;
                end
                else
                begin
                    Bullet_Id_in = Bullet_Id + 3'b1;
                    if(Bullet_Id == 3'b101)
                    begin
                        Bullet_Id_in = 3'b0;
                        Next_State = Bonus_Render;
                    end        
                end
            end

            // Render bullets
            Bullet_Render_write:
            begin
                // ADDR = Bullet_ADDR + (Bullet_Direction << 4) + h_counter + (v_counter << 2);

                // if (Bullet_State != 2'b00)
                // begin
                //     FB_AddrX_in = Bullet_X + h_counter + 9'd8;
                //     FB_AddrY_in = Bullet_Y + v_counter + 9'd8;
                //     ColorId_in = Data_Read[4:0];
                //     // set black color as transparent
                //     if(ColorId_in == 5'd0)
                //         FB_Write_in = 1'b0;
                //     else
                //         FB_Write_in = 1'b1;

                //     h_counter_in = h_counter + 9'd1;
                //     if(h_counter == 9'd3)
                //     begin
                //         h_counter_in = 9'd0;
                //         v_counter_in = v_counter + 9'd1;
                //         if(v_counter == 9'd3)
                //         begin
                //             v_counter_in = 9'd0;
                //             Bullet_Id_in = Bullet_Id + 1'd1;
                //             if(Bullet_Id == 1'd1)
                //             begin
                //                 Bullet_Id_in = 1'd0;
                //                 Next_State = UI_Render_1;
                //             end
                //         end
                //     end
                // end
                // else
                // begin
                //     Bullet_Id_in = Bullet_Id + 1'd1;
                //     if(Bullet_Id == 1'd1)
                //     begin
                //         Bullet_Id_in = 1'd0;
                //         Next_State = UI_Render_1;
                //     end        
                // end

                Drawing_in = 1'b1;
                Start_ADDR = Bullet_ADDR + (Bullet_Direction << 4);
                ColorId = ColorId_Read;
                Transparent = 1'b1;
                X_Max = 9'd4;
                Y_Max = 9'd4;
                X_Offset = Bullet_X + 9'd8;
                Y_Offset = Bullet_Y + 9'd8;

                if (Draw_Ready)
                begin
                    Drawing_in = 1'b0;
                    Next_State = Bullet_Render_read; // wait for Barrier_OCM
                    Bullet_Id_in = Bullet_Id + 3'b1;
                    if(Bullet_Id == 3'b101)
                    begin
                        Bullet_Id_in = 3'b0;
                        Next_State = Bonus_Render;
                    end   
                end
            end

            Bonus_Render:
            begin
                if (Bonus_Type != 2'b00)
                begin
                    Drawing_in = 1'b1;
                    Start_ADDR = Bonus_ADDR + ((Bonus_Type - 1) << 8);
                    ColorId = ColorId_Read;
                    Transparent = 1'b1;
                    X_Max = 9'd16;
                    Y_Max = 9'd16;
                    X_Offset = Bonus_X + 9'd8;
                    Y_Offset = Bonus_Y + 9'd8;

                    if (Draw_Ready)
                    begin
                        Drawing_in = 1'b0;
                        Next_State = UI_Render_1;
                    end
                end
                else
                begin
                    Next_State = UI_Render_1;
                end
            end

            UI_Render_1:
            begin
                // ADDR = UI_ADDR + h_counter + (v_counter << 4);

                // FB_Write_in = 1'b1;
                // FB_AddrX_in = 9'd292 + h_counter;
                // FB_AddrY_in = 9'd120 + v_counter;
                // ColorId_in = Data_Read[4:0];

                // h_counter_in = h_counter + 9'd1;
                // if(h_counter == 9'd15)
                // begin
                //     h_counter_in = 9'd0;
                //     v_counter_in = v_counter + 9'd1;
                //     if(v_counter == 9'd15)
                //     begin
                //         v_counter_in = 9'd0;
                //         Next_State = UI_Render_2;
                //     end
                // end

                Drawing_in = 1'b1;
                Start_ADDR = UI_ADDR;
                ColorId = ColorId_Read;
                X_Max = 9'd16;
                Y_Max = 9'd16;
                X_Offset = 9'd292;
                Y_Offset = 9'd120;

                if (Draw_Ready)
                begin
                    Next_State = UI_Render_2;
                    Drawing_in = 1'b0;
                end
            end

            UI_Render_2:
            begin
                // ADDR = UI_ADDR + 256 + h_counter + (v_counter << 4);

                // FB_Write_in = 1'b1;
                // FB_AddrX_in = 9'd292 + h_counter;
                // FB_AddrY_in = 9'd148 + v_counter;
                // ColorId_in = Data_Read[4:0];

                // h_counter_in = h_counter + 9'd1;
                // if(h_counter == 9'd15)
                // begin
                //     h_counter_in = 9'd0;
                //     v_counter_in = v_counter + 9'd1;
                //     if(v_counter == 9'd15)
                //     begin
                //         v_counter_in = 9'd0;
                //         Next_State = UI_Render_3;
                //     end
                // end
                
                Drawing_in = 1'b1;
                Start_ADDR = UI_ADDR + 256;
                ColorId = ColorId_Read;
                X_Max = 9'd16;
                Y_Max = 9'd16;
                X_Offset = 9'd292;
                Y_Offset = 9'd148;

                if (Draw_Ready)
                begin
                    Next_State = UI_Render_3;
                    Drawing_in = 1'b0;
                end
            end

            UI_Render_3:
            begin
                // ADDR = UI_ADDR + 512 + h_counter + (v_counter << 4);

                // FB_Write_in = 1'b1;
                // FB_AddrX_in = 9'd292 + h_counter;
                // FB_AddrY_in = 9'd176 + v_counter;
                // ColorId_in = Data_Read[4:0];

                // h_counter_in = h_counter + 9'd1;
                // if(h_counter == 9'd15)
                // begin
                //     h_counter_in = 9'd0;
                //     v_counter_in = v_counter + 9'd1;
                //     if(v_counter == 9'd15)
                //     begin
                //         v_counter_in = 9'd0;
                //         Next_State = UI_Render_4;
                //     end
                // end

                Drawing_in = 1'b1;
                Start_ADDR = UI_ADDR + 512;
                ColorId = ColorId_Read;
                X_Max = 9'd16;
                Y_Max = 9'd16;
                X_Offset = 9'd292;
                Y_Offset = 9'd176;

                if (Draw_Ready)
                begin
                    Next_State = UI_Render_4;
                    Drawing_in = 1'b0;
                end
            end

            UI_Render_4:
            begin
                // ADDR = UI_ADDR + 768 + h_counter + (v_counter << 3);

                // FB_Write_in = 1'b1;
                // FB_AddrX_in = 9'd292 + h_counter;
                // FB_AddrY_in = 9'd92 + v_counter;
                // ColorId_in = Data_Read[4:0];

                // h_counter_in = h_counter + 9'd1;
                // if(h_counter == 9'd7)
                // begin
                //     h_counter_in = 9'd0;
                //     v_counter_in = v_counter + 9'd1;
                //     if(v_counter == 9'd7)
                //     begin
                //         v_counter_in = 9'd0;
                //         Next_State = UI_Render_Number_1;
                //     end
                // end

                Drawing_in = 1'b1;
                Start_ADDR = UI_ADDR + 768;
                ColorId = ColorId_Read;
                X_Max = 9'd8;
                Y_Max = 9'd8;
                X_Offset = 9'd292;
                Y_Offset = 9'd92;

                if (Draw_Ready)
                begin
                    Next_State = UI_Render_Number_1;
                    Drawing_in = 1'b0;
                end
            end

            UI_Render_Number_1:
            begin
                // ADDR = Number_ADDR + (Tank_Life_1 << 6) + h_counter + (v_counter << 3);

                // FB_Write_in = 1'b1;
                // FB_AddrX_in = 9'd300 + h_counter;
                // FB_AddrY_in = 9'd128 + v_counter;
                // ColorId_in = Data_Read[4:0];

                // h_counter_in = h_counter + 9'd1;
                // if(h_counter == 9'd7)
                // begin
                //     h_counter_in = 9'd0;
                //     v_counter_in = v_counter + 9'd1;
                //     if(v_counter == 9'd7)
                //     begin
                //         v_counter_in = 9'd0;
                //         Next_State = UI_Render_Number_2;
                //     end
                // end

                Drawing_in = 1'b1;
                Start_ADDR = Number_ADDR + (Tank_Life_1 << 6);
                ColorId = ColorId_Read;
                X_Max = 9'd8;
                Y_Max = 9'd8;
                X_Offset = 9'd300;
                Y_Offset = 9'd128;

                if (Draw_Ready)
                begin
                    Next_State = UI_Render_Number_2;
                    Drawing_in = 1'b0;
                end
            end

            UI_Render_Number_2:
            begin
                // ADDR = Number_ADDR + (Tank_Life_2 << 6) + h_counter + (v_counter << 3);

                // FB_Write_in = 1'b1;
                // FB_AddrX_in = 9'd300 + h_counter;
                // FB_AddrY_in = 9'd156 + v_counter;
                // ColorId_in = Data_Read[4:0];

                // h_counter_in = h_counter + 9'd1;
                // if(h_counter == 9'd7)
                // begin
                //     h_counter_in = 9'd0;
                //     v_counter_in = v_counter + 9'd1;
                //     if(v_counter == 9'd7)
                //     begin
                //         v_counter_in = 9'd0;
                //         Next_State = UI_Render_Number_3;
                //     end
                // end

                Drawing_in = 1'b1;
                Start_ADDR = Number_ADDR + (Tank_Life_2 << 6);
                ColorId = ColorId_Read;
                X_Max = 9'd8;
                Y_Max = 9'd8;
                X_Offset = 9'd300;
                Y_Offset = 9'd156;

                if (Draw_Ready)
                begin
                    Next_State = UI_Render_Number_3;
                    Drawing_in = 1'b0;
                end
            end

            UI_Render_Number_3:
            begin
                // ADDR = Number_ADDR + 64 + h_counter + (v_counter << 3);

                // FB_Write_in = 1'b1;
                // FB_AddrX_in = 9'd300 + h_counter;
                // FB_AddrY_in = 9'd192 + v_counter;
                // ColorId_in = Data_Read[4:0];

                // h_counter_in = h_counter + 9'd1;
                // if(h_counter == 9'd7)
                // begin
                //     h_counter_in = 9'd0;
                //     v_counter_in = v_counter + 9'd1;
                //     if(v_counter == 9'd7)
                //     begin
                //         v_counter_in = 9'd0;
                //         Next_State = UI_Render_Number_4;
                //     end
                // end

                Drawing_in = 1'b1;
                Start_ADDR = Number_ADDR + ((Map_Id % 4'd10) << 6);
                ColorId = ColorId_Read;
                X_Max = 9'd8;
                Y_Max = 9'd8;
                X_Offset = 9'd300;
                Y_Offset = 9'd192;

                if (Draw_Ready)
                begin
                    Next_State = UI_Render_Number_4;
                    Drawing_in = 1'b0;
                end
            end

            UI_Render_Number_4:
            begin
                // ADDR = Number_ADDR + h_counter + (v_counter << 3);

                // FB_Write_in = 1'b1;
                // FB_AddrX_in = 9'd292 + h_counter;
                // FB_AddrY_in = 9'd192 + v_counter;
                // ColorId_in = Data_Read[4:0];

                // h_counter_in = h_counter + 9'd1;
                // if(h_counter == 9'd7)
                // begin
                //     h_counter_in = 9'd0;
                //     v_counter_in = v_counter + 9'd1;
                //     if(v_counter == 9'd7)
                //     begin
                //         v_counter_in = 9'd0;
                //         Next_State = UI_Render_Number_5;
                //     end
                // end
                
                Drawing_in = 1'b1;
                Start_ADDR = Number_ADDR + ((Map_Id / 4'd10) << 6);
                ColorId = ColorId_Read;
                X_Max = 9'd8;
                Y_Max = 9'd8;
                X_Offset = 9'd292;
                Y_Offset = 9'd192;

                if (Draw_Ready)
                begin
                    Next_State = UI_Render_Number_5;
                    Drawing_in = 1'b0;
                end
            end

            UI_Render_Number_5:
            begin
                // ADDR = Number_ADDR + ((Enemy_Life % 5'd10) << 6) + h_counter + (v_counter << 3);

                // FB_Write_in = 1'b1;
                // FB_AddrX_in = 9'd300 + h_counter;
                // FB_AddrY_in = 9'd100 + v_counter;
                // ColorId_in = Data_Read[4:0];

                // h_counter_in = h_counter + 9'd1;
                // if(h_counter == 9'd7)
                // begin
                //     h_counter_in = 9'd0;
                //     v_counter_in = v_counter + 9'd1;
                //     if(v_counter == 9'd7)
                //     begin
                //         v_counter_in = 9'd0;
                //         Next_State = UI_Render_Number_6;
                //     end
                // end
                
                Drawing_in = 1'b1;
                Start_ADDR = Number_ADDR + ((Enemy_Life % 5'd10) << 6);
                ColorId = ColorId_Read;
                X_Max = 9'd8;
                Y_Max = 9'd8;
                X_Offset = 9'd300;
                Y_Offset = 9'd100;

                if (Draw_Ready)
                begin
                    Next_State = UI_Render_Number_6;
                    Drawing_in = 1'b0;
                end
            end

            UI_Render_Number_6:
            begin
                // ADDR = Number_ADDR + ((Enemy_Life / 5'd10) << 6) + h_counter + (v_counter << 3);

                // FB_Write_in = 1'b1;
                // FB_AddrX_in = 9'd292 + h_counter;
                // FB_AddrY_in = 9'd100 + v_counter;
                // ColorId_in = Data_Read[4:0];

                // h_counter_in = h_counter + 9'd1;
                // if(h_counter == 9'd7)
                // begin
                //     h_counter_in = 9'd0;
                //     v_counter_in = v_counter + 9'd1;
                //     if(v_counter == 9'd7)
                //     begin
                //         v_counter_in = 9'd0;
                //         Next_State = Idle_1;
                //     end
                // end
                
                Drawing_in = 1'b1;
                Start_ADDR = Number_ADDR + ((Enemy_Life / 5'd10) << 6);
                ColorId = ColorId_Read;
                X_Max = 9'd8;
                Y_Max = 9'd8;
                X_Offset = 9'd292;
                Y_Offset = 9'd100;

                if (Draw_Ready)
                begin
                    Next_State = Idle_1;
                    Drawing_in = 1'b0;
                end
            end


            Idle_1:
            begin
                if(frame_clk_rising_edge)
                begin
                    Next_State = Idle_2;
                end
            end

            Idle_2:
            begin
                if (Menu)
                    Next_State = Start_Menu;
                else if (Loading)
                    Next_State = Load_Map_1;
                else if (Over)
                    Next_State = Gameover;
                else if (Win)
                    Next_State = Victory;
                else
                    Next_State = Background_1;
                frame_in = ~frame;
            end

            default: ;
        endcase
    end

endmodule
