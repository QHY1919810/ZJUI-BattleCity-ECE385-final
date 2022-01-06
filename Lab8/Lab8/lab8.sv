//-------------------------------------------------------------------------
//      lab8.sv                                                          --
//      Christine Chen                                                   --
//      Fall 2014                                                        --
//                                                                       --
//      Modified by Po-Han Huang                                         --
//      10/06/2017                                                       --
//                                                                       --
//      Fall 2017 Distribution                                           --
//                                                                       --
//      For use with ECE 385 Lab 8                                       --
//      UIUC ECE Department                                              --
//-------------------------------------------------------------------------


module lab8( input               CLOCK_50,
             input        [3:0]  KEY,          //bit 0 is set up as Reset
             output logic [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7,
             // VGA Interface
             output logic [7:0]  VGA_R,        //VGA Red
                                 VGA_G,        //VGA Green
                                 VGA_B,        //VGA Blue
             output logic        VGA_CLK,      //VGA Clock
                                 VGA_SYNC_N,   //VGA Sync signal
                                 VGA_BLANK_N,  //VGA Blank signal
                                 VGA_VS,       //VGA virtical sync signal
                                 VGA_HS,       //VGA horizontal sync signal
             // CY7C67200 Interface
             inout  wire  [15:0] OTG_DATA,     //CY7C67200 Data bus 16 Bits
             output logic [1:0]  OTG_ADDR,     //CY7C67200 Address 2 Bits
             output logic        OTG_CS_N,     //CY7C67200 Chip Select
                                 OTG_RD_N,     //CY7C67200 Write
                                 OTG_WR_N,     //CY7C67200 Read
                                 OTG_RST_N,    //CY7C67200 Reset
             input  logic        OTG_INT,      //CY7C67200 Interrupt
             // SDRAM Interface for Nios II Software
             output logic [12:0] DRAM_ADDR,    //SDRAM Address 13 Bits
             inout  wire  [31:0] DRAM_DQ,      //SDRAM Data 32 Bits
             output logic [1:0]  DRAM_BA,      //SDRAM Bank Address 2 Bits
             output logic [3:0]  DRAM_DQM,     //SDRAM Data Mast 4 Bits
             output logic        DRAM_RAS_N,   //SDRAM Row Address Strobe
                                 DRAM_CAS_N,   //SDRAM Column Address Strobe
                                 DRAM_CKE,     //SDRAM Clock Enable
                                 DRAM_WE_N,    //SDRAM Write Enable
                                 DRAM_CS_N,    //SDRAM Chip Select
                                 DRAM_CLK,     //SDRAM Clock
             // SRAM Interface
            //  output logic        SRAM_CE_N,
            //                      SRAM_UB_N,
            //                      SRAM_LB_N,
            //                      SRAM_OE_N,
            //                      SRAM_WE_N,
            //  output logic [19:0] SRAM_ADDR,
            //  inout  wire  [15:0] SRAM_DQ,
            //  // P/S 2 Interface
            //  input  logic        PS2_KBCLK,
            //                      PS2_KBDAT
             //Flash
             output logic [22:0] FL_ADDR, // Flash Address
             input  logic [7:0] FL_DQ,   // Data
             output logic FL_OE_N, FL_RST_N, FL_WE_N, FL_CE_N,
             //Audio and I2C
             input logic          		AUD_ADCDAT,
             inout logic          		AUD_ADCLRCK,
             inout logic          		AUD_BCLK,
             output logic          		AUD_DACDAT,
             inout logic          		AUD_DACLRCK,
             output logic          		AUD_XCK,

             output logic          		I2C_SCLK,
             inout logic          		I2C_SDAT,

             input logic [17:0] SW
);
    
    logic Reset_h, Clk;
    // logic press;
    // logic [7:0] keycode;
    logic [15:0] keycode_0, keycode_1, keycode_2;
    logic [9:0] DrawX, DrawY;

    logic [1:0] hpi_addr;
    logic [15:0] hpi_data_in, hpi_data_out;
    logic hpi_r, hpi_w, hpi_cs, hpi_reset;

    logic Ready,
          Menu,
          Loading,
          Load_Ready,
          Over,
          Win,
          Tank_Die,
          Upgrade;

    logic [3:0] Tank_Control_1,
                Tank_Control_2, 
                Tank_Control_3,
                Tank_Control_4,
                Tank_Control_5,
                Tank_Control_6;
    logic Confirm, Exit;

    logic [2:0] Tank_Id;
    logic [1:0] Tank_Direction;
    logic [8:0] Tank_X, Tank_Y;
    logic [2:0] Tank_State;

    logic [2:0] Bullet_Id;
    logic [1:0] Bullet_Direction;
    logic [8:0] Bullet_X, Bullet_Y;
    logic [1:0] Bullet_State;

    logic [8:0] Barrier_X, Barrier_Y,
                Barrier_X_Write, Barrier_Y_Write,
                Barrier_X_drawer, Barrier_Y_drawer,
                Barrier_X_judgment, Barrier_Y_judgment,
                Barrier_X_loader, Barrier_Y_loader;
    logic [2:0] Barrier_Id,
                Barrier_Id_loader,
                Barrier_Id_map,
                Barrier_Id_judgment,
                Barrier_Id_Write;
    logic Barrier_Write, Barrier_Write_loader, Barrier_Write_judgment;

    logic [8:0] Bonus_X, Bonus_Y;
    logic [1:0] Bonus_Type;

    logic [3:0] Tank_Life_1, Tank_Life_2;
    logic [4:0] Enemy_Life;
    logic [3:0] Map_Id;


    logic frame;
    logic FB_Write;
    logic [8:0] FB_AddrX, FB_AddrY;
    logic [4:0] ColorId_Write, ColorId_Out, ColorId_Out_0, ColorId_Out_1;

    logic CLK_200;
    logic [19:0] ADDR;
    logic [4:0] ColorId_Read;

    // Random signal for bonus, spawn, etc.
    logic [23:0] Random_others;

    // Audio Signals
    logic [15:0] WM8731_LDATA, WM8731_RDATA;
    logic WM8731_DATA_OVER, WM8731_DATA_OVER_PREV;
    logic WM8731_READY;
    logic INIT_FINISH;
    logic play,loop;  //play audio or loop audio
    logic [22:0] Start_Addr,End_Addr;
    logic [15:0] Audio_Data;
    logic Audio_Reset;
    logic [17:0] InputSelect;
    logic End_flag;
    
    assign Clk = CLOCK_50;
    always_ff @ (posedge Clk) begin
        Reset_h <= ~(KEY[0]);        // The push buttons are active low
    end
    
    // Interface between NIOS II and EZ-OTG chip
    hpi_io_intf hpi_io_inst(
                            .Clk(Clk),
                            .Reset(Reset_h),
                            // signals connected to NIOS II
                            .from_sw_address(hpi_addr),
                            .from_sw_data_in(hpi_data_in),
                            .from_sw_data_out(hpi_data_out),
                            .from_sw_r(hpi_r),
                            .from_sw_w(hpi_w),
                            .from_sw_cs(hpi_cs),
                            .from_sw_reset(hpi_reset),
                            // signals connected to EZ-OTG chip
                            .OTG_DATA(OTG_DATA),    
                            .OTG_ADDR(OTG_ADDR),    
                            .OTG_RD_N(OTG_RD_N),    
                            .OTG_WR_N(OTG_WR_N),    
                            .OTG_CS_N(OTG_CS_N),
                            .OTG_RST_N(OTG_RST_N)
    );
     
    // You need to make sure that the port names here match the ports in Qsys-generated codes.
    lab7_soc nios_system(
                            .clk_clk(Clk),  					  
                            .reset_reset_n(1'b1),    // Never reset NIOS
                            .sdram_wire_addr(DRAM_ADDR),
                            .sdram_wire_ba(DRAM_BA),
                            .sdram_wire_cas_n(DRAM_CAS_N),
                            .sdram_wire_cke(DRAM_CKE),
                            .sdram_wire_cs_n(DRAM_CS_N),
                            .sdram_wire_dq(DRAM_DQ),
                            .sdram_wire_dqm(DRAM_DQM),
                            .sdram_wire_ras_n(DRAM_RAS_N),
                            .sdram_wire_we_n(DRAM_WE_N),
                            .sdram_clk_clk(DRAM_CLK),
                            .keycode_0_export(keycode_0),
                            .keycode_1_export(keycode_1),
                            .keycode_2_export(keycode_2),
                            .otg_hpi_address_export(hpi_addr),
                            .otg_hpi_data_in_port(hpi_data_in),
                            .otg_hpi_data_out_port(hpi_data_out),
                            .otg_hpi_cs_export(hpi_cs),
                            .otg_hpi_r_export(hpi_r),
                            .otg_hpi_w_export(hpi_w),
                            .otg_hpi_reset_export(hpi_reset)
    );
     
     
    // Audio
    //audio to flash Interface
    Flash_Audio_Interface fetch_music(
         .Clk(Clk), .Reset(~Reset_h), .data_over(WM8731_DATA_OVER),.Audio_Reset(Audio_Reset),
         .play(play),.loop(loop),
         .Start_Addr(Start_Addr),.End_Addr(End_Addr),
         .FL_DQ(FL_DQ),.FL_OE_N(FL_OE_N),.FL_RST_N(FL_RST_N), .FL_WE_N(FL_WE_N), .FL_CE_N(FL_CE_N),
         .FL_ADDR(FL_ADDR),
         .Audio_Data(Audio_Data),
         .End_flag(End_flag)
    );
      
    //Audio Interface
    audio_interface wm8731_inst(
          .clk(Clk), .Reset(Reset_h), .INIT(1'd1),
          .INIT_FINISH(INIT_FINISH),
          .AUD_ADCDAT(AUD_ADCDAT), .AUD_ADCLRCK(AUD_ADCLRCK), .AUD_BCLK(AUD_BCLK),
          .AUD_DACDAT(AUD_DACDAT), .AUD_DACLRCK(AUD_DACLRCK), .AUD_MCLK(AUD_XCK),
          .I2C_SDAT(I2C_SDAT), .I2C_SCLK(I2C_SCLK),
          .LDATA(Audio_Data), .RDATA(Audio_Data),
          .data_over(WM8731_DATA_OVER)
    );

    SoundFX_Selector Select_Audio(
         .Clk(Clk),
         .InputSelect(InputSelect),
         .loop(loop),.play(play),.Audio_Reset(Audio_Reset),
         .Start_Addr(Start_Addr),.End_Addr(End_Addr)
    );

    Audio_judgement Audio_judgement_inst(.Clk(CLOCK_50), .End_flag(End_flag), .Tank_Die(Tank_Die), .Win(Win),.Upgrade(Upgrade), 
                                         .Menu(Menu), .Loading(Loading), .Over(Over), .Tank_Control_1(Tank_Control_1),
                                         .Tank_Control_2(Tank_Control_2), .Bonus_Type(Bonus_Type), .InputSelect(InputSelect)
    );
    
    // Use PLL to generate the 25MHZ VGA_CLK.
    vga_clk vga_clk_instance(.inclk0(Clk), .c0(VGA_CLK));
    
    // Output VGA control signals
    VGA_controller vga_controller_instance(.*, .Reset(Reset_h));

    // Use PLL to generate the 100MHZ CLK for OCM
    ocm_clk ocm_clk_instance(.inclk0(Clk), .c0(CLK_200));

    // SRAM control signals
    // SRAM_controller tristate(.*, .Clk(CLK_200), .Reset(Reset_h), .Read(SRAM_Read), .Write(1'b0), .Data_Write(16'h0000));

    // sprite ROM control signal
    sprite rom(.*, .Clk(CLK_200));

    // P/S 2 Keyboard signals
    // keyboard keyboard_instance(.Clk(Clk),.psClk(PS2_KBCLK),.psData(PS2_KBDAT),.reset(Reset_h),.keyCode(keycode),.press(press));

    // generate the frame according to position of items in SRAM
    frame_drawer frame_drawer_instance(.*, .Reset(Reset_h), .frame_clk(VGA_VS), .Barrier_X(Barrier_X_drawer), .Barrier_Y(Barrier_Y_drawer));
                                    //    .Tank_Direction(Tank_Direction), .Tank_X(Tank_X), .Tank_Y(Tank_Y), .Tank_State(Tank_State),
                                    //    .SRAM_Read(SRAM_Read), .ADDR(ADDR),
                                    //    .Data_Read_1(Data_UB), .Data_Read_0(Data_LB),
                                    //    .Data_Read(Data_Read),
                                    //    .FB_Write(FB_Write), .FB_AddrX(FB_AddrX), .FB_AddrY(FB_AddrY), .ColorId(ColorId)

    frame_buffer frame_0(.*, .WE(FB_Write && frame), .Reset(Reset_h),
                        .Read_AddrX(DrawX[9:1]), .Read_AddrY(DrawY[9:1]),
                        .Write_AddrX(FB_AddrX), .Write_AddrY(FB_AddrY),
                        .ColorId_In(ColorId_Write), .ColorId_Out(ColorId_Out_0));

    frame_buffer frame_1(.*, .WE(FB_Write && ~frame), .Reset(Reset_h),
                        .Read_AddrX(DrawX[9:1]), .Read_AddrY(DrawY[9:1]),
                        .Write_AddrX(FB_AddrX), .Write_AddrY(FB_AddrY),
                        .ColorId_In(ColorId_Write), .ColorId_Out(ColorId_Out_1));

    assign ColorId_Out = frame ? ColorId_Out_1 : ColorId_Out_0;

    palette palette_instance(.*, .ColorId(ColorId_Out));

    // Game judgement logic
    game_judgment game_judgment_instance(.*, .Reset(Reset_h), .frame_clk(VGA_VS), .Barrier_Write(Barrier_Write_judgment), .Barrier_X(Barrier_X_judgment),
                                         .Barrier_Y(Barrier_Y_judgment), .Barrier_Id_Read(Barrier_Id), .Barrier_Id_Write(Barrier_Id_judgment),
                                         .Random_Tank_Type(Random_others[21:20]), .Random_Bonus(Random_others[15:14]), .Random_Type(Random_others[13:12]));

    // Control signals for tanks
    key_controller key_controller_instance(.*, .Reset(Reset_h));

    TankAIs TankAIs_inst(.*, .Reset(Reset_h), .AI_tank_1(Tank_Control_3), .AI_tank_2(Tank_Control_4), .AI_tank_3(Tank_Control_5), .AI_tank_4(Tank_Control_6), 
                         .Random_others(Random_others));

    // Barriers in game
    assign Barrier_X = Ready ? Barrier_X_drawer : Barrier_X_judgment;
    assign Barrier_Y = Ready ? Barrier_Y_drawer : Barrier_Y_judgment;

    assign Barrier_X_Write = Load_Ready ? Barrier_X_judgment : Barrier_X_loader;
    assign Barrier_Y_Write = Load_Ready ? Barrier_Y_judgment : Barrier_Y_loader;
    assign Barrier_Id_Write = Load_Ready ? Barrier_Id_judgment : Barrier_Id_loader;
    assign Barrier_Write = Load_Ready ? Barrier_Write_judgment : Barrier_Write_loader;

    load_map load_map_inst(.Clk(Clk), .Reset(Reset_h), .Loading(Loading), .Load_Ready(Load_Ready), .Barrier_Write(Barrier_Write_loader), .Barrier_X(Barrier_X_loader),
                           .Barrier_Y(Barrier_Y_loader), .Barrier_Id_Read(Barrier_Id_map), .Barrier_Id_Write(Barrier_Id_loader));

    map map_inst(.Clk(CLK_200), .Map_Id(Map_Id), .Barrier_X(Barrier_X_loader), .Barrier_Y(Barrier_Y_loader), .Barrier_Id(Barrier_Id_map));

    barrier barrier_instance(.Clk(CLK_200), .WE(Barrier_Write), .Barrier_X_In(Barrier_X_Write), .Barrier_Y_In(Barrier_Y_Write),
                             .Barrier_Id_In(Barrier_Id_Write), .Barrier_X_Out(Barrier_X), .Barrier_Y_Out(Barrier_Y), .Barrier_Id_Out(Barrier_Id));

    // Display keycode on hex display
    HexDriver hex_inst_0 (keycode_0[3:0], HEX0);
    HexDriver hex_inst_1 (keycode_0[7:4], HEX1);
    HexDriver hex_inst_2 (keycode_0[11:8], HEX2);
    HexDriver hex_inst_3 (keycode_0[15:12], HEX3);
    HexDriver hex_inst_4 (Tank_Life_1, HEX4);
    HexDriver hex_inst_5 (Tank_Life_2, HEX5);
    HexDriver hex_inst_6 (Tank_Control_1, HEX6);
    HexDriver hex_inst_7 (Tank_Control_2, HEX7);

endmodule
