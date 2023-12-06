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
use work.pong_pkg.all;

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
    PlateXxDO : out unsigned(COORD_BW - 1 downto 0)
  );
end pong_fsm;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture rtl of pong_fsm is
  type state_type is (BEFORE_START, MOVING_RIGHT_DOWN, MOVING_RIGHT_UP, MOVING_LEFT_DOWN, MOVING_LEFT_UP, GAME_OVER, MOVE_LEFT, MOVE_RIGHT, IDLE);
  type plate_state_type is (IDLE, LEFT, RIGHT);

  signal STATEBallxDN, STATEBallxDP : state_type;

  signal BallXxDP, BallYxDN : unsigned(COORD_BW - 1 downto 0);
  signal BallYxDP, BallYxDN : unsigned(COORD_BW - 1 downto 0);
  signal PlateXxDP, PlateXxDN : unsigned(COORD_BW - 1 downto 0);

  signal STATEPlatexDP, STATEPlatexDN : plate_state_type;
  
--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin

  p_fsm_ball: process(all)
    begin
        case StateBallxDP is 
          when BEFORE_START =>
            if (LeftxSI = '1' and RightxSI = '1') then
              STATEBallxDN <= MOVING_RIGHT_DOWN;
            end if;

          when MOVING_RIGHT_DOWN => 
            BallXxDN <= BallXxDP + BALL_STEP_X;
            BallYxDN <= BallYxDP - BALL_STEP_Y;
            if (BallXxDP - BALL_HEIGHT/2 >= PlateXxDP - PLATE_WIDTH/2 and BallXxDP + BALL_HEIGHT/2 <= PlateXxDP + PLATE_WIDTH/2 and BallYxDP + BALL_HEIGHT/2 = VS_DISPLAY - PLATE_HEIGHT) then
              STATEBallxDN <= MOVING_RIGHT_UP;
            elsif (BallXxDP = 0 and BallYxDP /= VS_DISPLAY) then
              STATEBallxDN <= MOVING_LEFT_DOWN;
            elsif (BallXxDP + BALL_HEIGHT/2 <= PlateXxDP - PLATE_WIDTH/2 and BallXxDP - BALL_HEIGHT/2 >= PlateXxDP + PLATE_WIDTH/2 and BallYxDP + BALL_HEIGHT/2 = VS_DISPLAY) then 
              STATEBallxDN <= GAME_OVER;
            end if;

          when MOVING_RIGHT_UP => 
            BallXxDN <= BallXxDP + BALL_STEP_X;
            BallYxDN <= BallYxDP + BALL_STEP_Y;
            if (BallXxDP + BALL_HEIGHT/2 = HS_DISPLAY and BallYxDP + BALL_HEIGHT/2 /= VS_DISPLAY) then
              STATEBallxDN <= MOVING_LEFT_UP;
            elsif (BallYxDP - BALL_HEIGHT/2 = 0) then
              STATEBallxDN <= MOVING_RIGHT_DOWN;
            elsif (BallXxDP + BALL_HEIGHT/2 <= PlateXxDP - PLATE_WIDTH/2 and BallXxDP - BALL_HEIGHT/2 >= PlateXxDP + PLATE_WIDTH/2 and BallYxDP + BALL_HEIGHT/2 = VS_DISPLAY) then 
              STATEBallxDN <= GAME_OVER;
            end if;
          
          when MOVING_LEFT_UP => 
            BallXxDN <= BallXxDP - BALL_STEP_X;
            BallYxDN <= BallYxDP + BALL_STEP_Y;
            if (BallYxDP - BALL_HEIGHT/2 = 0) then
              STATEBallxDN <= MOVING_LEFT_DOWN;
            elsif (BallXxDP + BALL_HEIGHT/2 = 0) then
              STATEBallxDN <= MOVING_RIGHT_UP;
            elsif (BallXxDP + BALL_HEIGHT/2 <= PlateXxDP - PLATE_WIDTH/2 and BallXxDP - BALL_HEIGHT/2 >= PlateXxDP + PLATE_WIDTH/2 and BallYxDP + BALL_HEIGHT/2 = VS_DISPLAY) then 
              STATEBallxDN <= GAME_OVER;
          end if;

          when MOVING_LEFT_DOWN =>
          BallXxDN <= BallXxDP - BALL_STEP_X;
          BallYxDN <= BallYxDP - BALL_STEP_Y;
          if (BallXxDP - BALL_HEIGHT/2 = 0 and BallYxDP + BALL_HEIGHT/2 /= VS_DISPLAY) then
            STATEBallxDN <= MOVING_RIGHT_DOWN;
          elsif (BallXxDP - BALL_HEIGHT/2 >= PlateXxDP - PLATE_WIDTH/2 and BallXxDP + BALL_HEIGHT/2 <= PlateXxDP + PLATE_WIDTH/2 and BallYxDP + BALL_HEIGHT/2 = VS_DISPLAY - PLATE_HEIGHT) then
            STATEBallxDN <= MOVING_RIGHT_UP;
          elsif (BallXxDP + BALL_HEIGHT/2 <= PlateXxDP - PLATE_WIDTH/2 and BallXxDP - BALL_HEIGHT/2 >= PlateXxDP + PLATE_WIDTH/2 and BallYxDP + BALL_HEIGHT/2 = VS_DISPLAY) then 
            STATEBallxDN <= GAME_OVER;
          end if;

          when others => NULL;
        end case;

  end process p_fsm_ball;

  process (CLKxCI, RSTxRI, VSEdgexSI) is
    begin
      if (RSTxRI = '1') then
        STATEBallxDP <= BEFORE_START;
      elsif (CLKxCI'event and CLKxCI = '1' and VSEdgexSI) then
        STATEBallxDP <= STATEBallxDN;
        BallXxDP <= BallXxDN;
        BallYxDP <= BallYxDN;
      end if;
    end process;

  BallxDO <= BallxDP;
  BallYxDO <= BallYxDN;

  p_fsm_plate: process(all)
    begin
      case STATEPlatexDP is
        when IDLE =>
          if (RightxSI = '1') then
            STATEPlatexDN <= RIGHT;
          elsif (LeftxSI = '1') then
            STATEPlatexDN <= LEFT;
          end if;
        when LEFT =>
          if (PlatexDP - PLATE_WIDHT/2 /= 0) then
            if (PlateXxDP <= PLATE_STEP/2) then
              PlatexDN <= PLATE_WIDHT/2;
            else
              PlatexDN <= PlatexDP - PLATE_STEP;
            end if;
          end if;

          PlatexDN <= PlatexDP - PLATE_STEP;
          if (RightxSI = '1') then
            STATEPlatexDN <= RIGHT;
          elsif (LeftxSI = '1') then
            STATEPlatexDN <= LEFT;
          else
            STATEPlatexDN <= IDLE;
          end if;
        when RIGHT =>
          if (PlatexDP + PLATE_WIDHT/2 /= HS_DISPLAY) then
            if (PlateXxDP >= HS_DISPLAY - PLATE_STEP/2) then
              PlatexDN <= HS_DISPLAY - PLATE_WIDHT/2;
            else
              PlatexDN <= PlatexDP + PLATE_STEP;
            end if;
          end if;

          PlatexDN <= PlatexDP + PLATE_STEP;
          if (RightxSI = '1') then
            STATEPlatexDN <= RIGHT;
          elsif (LeftxSI = '1') then
            STATEPlatexDN <= LEFT;
          else
            STATEPlatexDN <= IDLE;
          end if;
      end case;
    end process p_fsm_plate;
  
  process (CLKxCI, RSTxRI) is
    begin
      if (RSTxRI = '1') then
        STATEPlatexDP <= (others => '0');
      elsif (CLKxCI'event and CLKxCI = '1') then
        STATEPlatexDP <= STATEPlatexDN;
        PlateXxDP <= PlateXxDN;
      end if;
    end process;

  PlateXxDO <= PlateXxDP;

  p_fsm_seq: process(CLKxCI, RSTxRI) is
    begin
    if (RSTxRI = '1') then
        StatexDP <= BEFORE_START;
    elsif (CLKxCI'event and CLKxCI = '1') then
        StatexDP <= StatexDN;
    end if;
  end process p_fsm_seq;

end rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
