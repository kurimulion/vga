--=============================================================================
-- @file pong_fsm.vhdl
--=============================================================================
-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- Packages
library work;
use work.dsd_prj_pkg.all;

--=============================================================================
--
-- pong_fsm
--
-- @brief This file specifies a basic circuit for the pong game. Note that coordinates are counted
-- from the upper left corner of the screen.
--
--=============================================================================

--=============================================================================
-- ENTITY DECLARATION FOR PONG_FSM
--=============================================================================
entity pong_fsm is
  port (
    CLKxCI : in std_logic;
    RSTxRI : in std_logic;

    -- Controls from push buttons
    LeftxSI  : in std_logic;
    RightxSI : in std_logic;

    -- Coordinate from VGA
    VgaXxDI : in unsigned(COORD_BW - 1 downto 0);
    VgaYxDI : in unsigned(COORD_BW - 1 downto 0);

    -- Signals from video interface to synchronize (HIGH for 1 CC, when vertical sync starts)
    VSEdgexSI : in std_logic;

    -- Ball and plate coordinates
    BallXxDO  : out unsigned(COORD_BW - 1 downto 0);
    BallYxDO  : out unsigned(COORD_BW - 1 downto 0);
    PlateXxDO : out unsigned(COORD_BW - 1 downto 0);

    -- Floating plate coordinate
    FloatPlateXxDO : out unsigned(COORD_BW - 1 downto 0);
    
    -- Colour of the ball
    BallColourxDO : out unsigned(3 - 1 downto 0);
    
    PlayerLostxSO : out std_logic
  );
end pong_fsm;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture rtl of pong_fsm is
  type state_type is (BEFORE_START, MOVING_RIGHT_DOWN, MOVING_RIGHT_UP, MOVING_LEFT_DOWN, MOVING_LEFT_UP, GAME_OVER);
  type plate_state_type is (START, IDLE, LEFT, RIGHT, HOLD);

  signal StateBallxDN, StateBallxDP : state_type;

  signal BallXxDP, BallXxDN : unsigned(COORD_BW - 1 downto 0);
  signal BallYxDP, BallYxDN : unsigned(COORD_BW - 1 downto 0);
  signal PlateXxDP, PlateXxDN : unsigned(COORD_BW - 1 downto 0);
  signal FloatPlateXxDP, FloatPlateXxDN : unsigned(COORD_BW - 1 downto 0);
  signal FloatPlateDirxDP, FloatPlateDirxDN : std_logic;
  signal FloatCntxDP, FloatCntxDN : unsigned(4 - 1 downto 0);

  signal StatePlatexDP, StatePlatexDN : plate_state_type;
  
  signal ColourCNTxDP, ColourCNTxDN : unsigned(3 - 1 downto 0);
  
  signal PlayerLostxS : std_logic;
  
--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin

  p_fsm_ball: process(all)
    begin
        BallXxDN <= BallXxDP;
        BallYxDN <= BallYxDP;
        StateBallxDN <= StateBallxDP;
        PlayerLostxS <= '0';
        ColourCNTxDN <= ColourCNTxDP;
        case StateBallxDP is 
          when BEFORE_START =>
            BallXxDN <= TO_UNSIGNED(HS_DISPLAY/2, BallXxDN'length);
            BallYxDN <= TO_UNSIGNED(VS_DISPLAY/2, BallYxDN'length);
            if (LeftxSI = '1' and RightxSI = '1') then
              StateBallxDN <= MOVING_RIGHT_DOWN;
            end if;

          when MOVING_RIGHT_DOWN =>
            BallXxDN <= BallXxDP + BALL_STEP_X;
            BallYxDN <= BallYxDP + BALL_STEP_Y;
            -- BallXxDP - BALL_WIDTH/2 >= PlateXxDP - PLATE_WIDTH/2 and BallXxDP + BALL_WIDTH/2 <= PlateXxDP + PLATE_WIDTH/2 and BallYxDP + BALL_HEIGHT/2 >= VS_DISPLAY - PLATE_HEIGHT
            if (BallXxDP + PLATE_WIDTH/2 >= PlateXxDP + BALL_WIDTH/2 and BallXxDP + BALL_WIDTH/2 <= PlateXxDP + PLATE_WIDTH/2 and BallYxDP + BALL_HEIGHT/2 >= VS_DISPLAY - PLATE_HEIGHT) then
              ColourCNTxDN <= (others => '0') when ColourCNTxDP = NUM_BALL_COLOURS - 1 else ColourCNTxDP + 1;
              StateBallxDN <= MOVING_RIGHT_UP;
            elsif (BallXxDP >= HS_DISPLAY - BALL_WIDTH and BallYxDP /= VS_DISPLAY) then
              ColourCNTxDN <= (others => '0') when ColourCNTxDP = NUM_BALL_COLOURS - 1 else ColourCNTxDP + 1;
              StateBallxDN <= MOVING_LEFT_DOWN;
            -- BallXxDP - BALL_WIDTH/2 >= FloatingPlateXxDP - PLATE_WIDTH/2 and BallXxDP + BALL_WIDTH/2 <= FloatingPlateXxDP + PLATE_WIDTH/2 and BallYxDP + BALL_HEIGHT/2 >= FLOATING_PLATE_Y
            elsif (BallXxDP + FLOATING_PLATE_WIDTH/2 >= FloatPlateXxDP + BALL_WIDTH/2 and 
                   BallXxDP + BALL_WIDTH/2 <= FloatPlateXxDP + FLOATING_PLATE_WIDTH/2 and 
                   BallYxDP + BALL_HEIGHT/2 >= FLOATING_PLATE_Y and
                   BallYxDP + BALL_HEIGHT/2 <= FLOATING_PLATE_Y + PLATE_HEIGHT) then
              ColourCNTxDN <= (others => '0') when ColourCNTxDP = NUM_BALL_COLOURS - 1 else ColourCNTxDP + 1;
              StateBallxDN <= MOVING_RIGHT_UP;
            elsif (BallYxDP + BALL_HEIGHT/2 >= VS_DISPLAY) then 
              StateBallxDN <= GAME_OVER;
            end if;

          when MOVING_RIGHT_UP =>
            BallXxDN <= BallXxDP + BALL_STEP_X;
            if (BallYxDP <= Ball_STEP_Y) then
              BallYxDN <= TO_UNSIGNED(BALL_HEIGHT/2, BallYxDN'length);
            else
              BallYxDN <= BallYxDP - BALL_STEP_Y;
            end if;
            if (BallXxDP + BALL_WIDTH/2 >= HS_DISPLAY and BallYxDP + BALL_HEIGHT/2 < VS_DISPLAY) then
              ColourCNTxDN <= (others => '0') when ColourCNTxDP = NUM_BALL_COLOURS - 1 else ColourCNTxDP + 1;
              StateBallxDN <= MOVING_LEFT_UP;
            elsif (BallYxDP <= BALL_HEIGHT/2) then
              ColourCNTxDN <= (others => '0') when ColourCNTxDP = NUM_BALL_COLOURS - 1 else ColourCNTxDP + 1;
              StateBallxDN <= MOVING_RIGHT_DOWN;
            elsif (BallXxDP + FLOATING_PLATE_WIDTH/2 >= FloatPlateXxDP + BALL_WIDTH/2 and 
                   BallXxDP + BALL_WIDTH/2 <= FloatPlateXxDP + FLOATING_PLATE_WIDTH/2 and 
                   BallYxDP <= FLOATING_PLATE_Y + PLATE_HEIGHT + BALL_HEIGHT/2 and
                   BallYxDP >= FLOATING_PLATE_Y + BALL_HEIGHT/2) then
              ColourCNTxDN <= (others => '0') when ColourCNTxDP = NUM_BALL_COLOURS - 1 else ColourCNTxDP + 1;
              StateBallxDN <= MOVING_RIGHT_DOWN;
            end if;
          
          when MOVING_LEFT_UP =>
            if (BallXxDP <= Ball_STEP_X) then
              BallXxDN <= TO_UNSIGNED(BALL_WIDTH/2, BallXxDN'length);
            else
              BallXxDN <= BallXxDP - BALL_STEP_X;
            end if;
            if (BallYxDP <= Ball_STEP_Y) then
              BallYxDN <= TO_UNSIGNED(BALL_HEIGHT/2, BallYxDN'length);
            else
              BallYxDN <= BallYxDP - BALL_STEP_Y;
            end if;
            if (BallYxDP <= BALL_HEIGHT/2) then
              ColourCNTxDN <= (others => '0') when ColourCNTxDP = NUM_BALL_COLOURS - 1 else ColourCNTxDP + 1;
              StateBallxDN <= MOVING_LEFT_DOWN;
            elsif (BallXxDP <= BALL_WIDTH/2) then
              ColourCNTxDN <= (others => '0') when ColourCNTxDP = NUM_BALL_COLOURS - 1 else ColourCNTxDP + 1;
              StateBallxDN <= MOVING_RIGHT_UP;
            elsif (BallXxDP + FLOATING_PLATE_WIDTH/2 >= FloatPlateXxDP + BALL_WIDTH/2 and 
                   BallXxDP + BALL_WIDTH/2 <= FloatPlateXxDP + FLOATING_PLATE_WIDTH/2 and 
                   BallYxDP <= FLOATING_PLATE_Y + PLATE_HEIGHT + BALL_HEIGHT/2 and
                   BallYxDP >= FLOATING_PLATE_Y + BALL_HEIGHT/2) then
              ColourCNTxDN <= (others => '0') when ColourCNTxDP = NUM_BALL_COLOURS - 1 else ColourCNTxDP + 1;
              StateBallxDN <= MOVING_LEFT_DOWN;
          end if;

          when MOVING_LEFT_DOWN =>
            if (BallXxDP <= Ball_STEP_X) then
              BallXxDN <= TO_UNSIGNED(BALL_WIDTH/2, BallXxDN'length);
            else
              BallXxDN <= BallXxDP - BALL_STEP_X;
            end if;
            BallYxDN <= BallYxDP + BALL_STEP_Y;
            if (BallXxDP <= BALL_WIDTH/2 and BallYxDP + BALL_HEIGHT/2 < VS_DISPLAY) then
              ColourCNTxDN <= (others => '0') when ColourCNTxDP = NUM_BALL_COLOURS - 1 else ColourCNTxDP + 1;
              StateBallxDN <= MOVING_RIGHT_DOWN;
            -- BallXxDP - BALL_WIDTH/2 >= PlateXxDP - PLATE_WIDTH/2 and BallXxDP + BALL_WIDTH/2 <= PlateXxDP + PLATE_WIDTH/2 and BallYxDP + BALL_HEIGHT/2 >= VS_DISPLAY - PLATE_HEIGHT
            elsif (BallXxDP + PLATE_WIDTH/2 >= PlateXxDP + BALL_WIDTH/2 and BallXxDP + BALL_WIDTH/2 <= PlateXxDP + PLATE_WIDTH/2 and BallYxDP + BALL_HEIGHT/2 >= VS_DISPLAY - PLATE_HEIGHT) then
              ColourCNTxDN <= (others => '0') when ColourCNTxDP = NUM_BALL_COLOURS - 1 else ColourCNTxDP + 1;
              StateBallxDN <= MOVING_LEFT_UP;
            elsif (BallXxDP + FLOATING_PLATE_WIDTH/2 >= FloatPlateXxDP + BALL_WIDTH/2 and 
                   BallXxDP + BALL_WIDTH/2 <= FloatPlateXxDP + FLOATING_PLATE_WIDTH/2 and 
                   BallYxDP + BALL_HEIGHT/2 >= FLOATING_PLATE_Y and
                   BallYxDP + BALL_HEIGHT/2 <= FLOATING_PLATE_Y + PLATE_HEIGHT) then
              ColourCNTxDN <= (others => '0') when ColourCNTxDP = NUM_BALL_COLOURS - 1 else ColourCNTxDP + 1;
              StateBallxDN <= MOVING_LEFT_UP;
            elsif (BallYxDP + BALL_HEIGHT/2 >= VS_DISPLAY) then 
              StateBallxDN <= GAME_OVER;
            end if;

          when GAME_OVER =>
            PlayerLostxS <= '1';
            BallXxDN <= TO_UNSIGNED(HS_DISPLAY/2, BallXxDN'length);
            BallYxDN <= TO_UNSIGNED(VS_DISPLAY/2, BallYxDN'length);
            if (LeftxSI = '1' and RightxSI = '1') then
              StateBallxDN <= BEFORE_START;
            end if;

          when others => NULL;
        end case; 

  end process p_fsm_ball;

  process (CLKxCI, RSTxRI, VSEdgexSI) is
    begin
      if (RSTxRI = '1') then
        StateBallxDP <= BEFORE_START;
        ColourCNTxDP <= (others => '0');
      elsif (CLKxCI'event and CLKxCI = '1' and VSEdgexSI = '1') then
        StateBallxDP <= StateBallxDN;
        BallXxDP <= BallXxDN;
        BallYxDP <= BallYxDN;
        ColourCNTxDP <= ColourCNTxDN;
      end if;
    end process;

  BallXxDO <= BallXxDP;
  BallYxDO <= BallYxDN;

  p_fsm_plate: process(all)
    begin
      PlateXxDN <= PlateXxDP;
      StatePlatexDN <= StatePlatexDP;
      case StatePlatexDP is
        when START =>
          PlateXxDN <= TO_UNSIGNED(HS_DISPLAY/2, PlateXxDN'length);
          if (LeftxSI = '1' and RightxSI = '1') then
            StatePlatexDN <= IDLE;
          end if;
        when IDLE =>
          if (StateBallxDP = GAME_OVER) then
            StatePlatexDN <= START;
          elsif (RightxSI = '1') then
            StatePlatexDN <= RIGHT;
          elsif (LeftxSI = '1') then
            StatePlatexDN <= LEFT;
          end if;
        when LEFT =>
          if (PlateXxDP > PLATE_WIDTH/2 + PLATE_STEP_X) then
            PlateXxDN <= PlateXxDP - PLATE_STEP_X;
          else
            PlateXxDN <= TO_UNSIGNED(PLATE_WIDTH/2, PlateXxDN'length);
          end if;
          StatePlatexDN <= HOLD;
        when RIGHT =>
          if (PlateXxDP + PLATE_STEP_X < HS_DISPLAY - PLATE_WIDTH/2) then
            PlateXxDN <= PlateXxDP + PLATE_STEP_X;
          else
            PlateXxDN <= TO_UNSIGNED(HS_DISPLAY - PLATE_WIDTH/2, PlateXxDN'length);
          end if;
          StatePlatexDN <= HOLD;
        when HOLD =>
          StatePlatexDN <= HOLD;
          if (LeftxSI = '0' and RightxSI = '0') then
            StatePlatexDN <= IDLE;
          end if;
      end case;
    end process p_fsm_plate;
  
  process (CLKxCI, RSTxRI, VSEdgexSI) is
    begin
      if (RSTxRI = '1') then
        StatePlatexDP <= START;
      elsif (CLKxCI'event and CLKxCI = '1' and VSEdgexSI = '1') then
        StatePlatexDP <= StatePlatexDN;
        PlateXxDP <= PlateXxDN;
      end if;
    end process;

  PlateXxDO <= PlateXxDP;

  FloatPlateXxDN <= FloatPlateXxDP when FloatCntxDP /= 9 else
                    FloatPlateXxDP + PLATE_STEP_X when FloatPlateDirxDP = '1' and FloatPlateXxDP + PLATE_STEP_X < HS_DISPLAY - FLOATING_PLATE_WIDTH/2 else
                    TO_UNSIGNED(HS_DISPLAY - FLOATING_PLATE_WIDTH/2, FloatPlateXxDN'length) when FloatPlateDirxDP = '1' else
                    FloatPlateXxDP - PLATE_STEP_X when FloatPlateXxDP - PLATE_STEP_X > FLOATING_PLATE_WIDTH/2 else
                    TO_UNSIGNED(FLOATING_PLATE_WIDTH/2, FloatPlateXxDN'length);
  FloatPlateDirxDN <= '0' when (FloatPlateXxDP >= HS_DISPLAY - FLOATING_PLATE_WIDTH/2) else 
                      '1' when (FloatPlateXxDP = FLOATING_PLATE_WIDTH/2) else
                      FloatPlateDirxDP;
  FloatCntxDN <= (others => '0') when FloatCntxDP = 9 else
                FloatCntxDP + 1;

  BallColourxDO <= ColourCNTxDP;
  
  PlayerLostxSO <= PlayerLostxS;

  process (CLKxCI, RSTxRI, VSEdgexSI) is
    begin
      if (RSTxRI = '1') then
        FloatPlateXxDP <= TO_UNSIGNED(HS_DISPLAY/2, PlateXxDP'length);
        FloatPlateDirxDP <= '1';
        FloatCntxDP <= (others => '0');
      elsif (CLKxCI'event and CLKxCI = '1' and VSEdgexSI = '1') then
        FloatPlateXxDP <= FloatPlateXxDN;
        FloatPlateDirxDP <= FloatPlateDirxDN;
        FloatCntxDP <= FloatCntxDN;
      end if;
    end process;

  FloatPlateXxDO <= FloatPlateXxDP;

end rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================