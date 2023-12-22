--=============================================================================
-- @file mandelbrot.vhdl
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
-- mandelbrot
--
-- @brief This file specifies a basic circuit for mandelbrot
--
--=============================================================================

--=============================================================================
-- ENTITY DECLARATION FOR MANDELBROT
--=============================================================================
entity mandelbrot is
  port (
    CLKxCI : in std_logic;
    RSTxRI : in std_logic;

    WExSO   : out std_logic;
    XxDO    : out unsigned(COORD_BW - 1 downto 0);
    YxDO    : out unsigned(COORD_BW - 1 downto 0);
    ITERxDO : out unsigned(MEM_DATA_BW - 1 downto 0)
  );
end entity mandelbrot;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture rtl of mandelbrot is

  -- TODO: Implement your own code here
  signal XCoordxDP, XCoordxDN : unsigned(COORD_BW - 1 downto 0);
  signal YCoordxDP, YCoordxDN : unsigned(COORD_BW - 1 downto 0);
  signal C_RExDP, C_RExDN : signed(N_BITS - 1 downto 0);
  signal C_IMxDP, C_IMxDN : signed(N_BITS - 1 downto 0);
  signal Z_RExDP, Z_RExDN : signed(N_BITS - 1 downto 0);
  signal Z_IMxDP, Z_IMxDN : signed(N_BITS - 1 downto 0);
  signal IterxDP, IterxDN : unsigned(MEM_DATA_BW - 1 downto 0);
  signal SquareZ_RExS, SquareZ_IMxS : unsigned(N_BITS - 1 downto 0);
  signal SizexDP, SizexDN : unsigned(N_BITS - 1 downto 0);
  signal WExDP, WExDN : std_logic;

--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin

  -- TODO: Implement your own code here
  process(CLKxCI, RSTxRI)
  begin
    if RSTxRI = '1' then
      XCoordxDP <= (others => '0');
      YCoordxDP <= (others => '0');
      C_RExDP <= C_RE_0;
      C_IMxDP <= C_IM_0;
      Z_RExDP <= C_RE_0;
      Z_IMxDP <= C_IM_0;
      IterxDP <= (others => '0');
      WExDP <= '0';
      SizexDP <= (others => '0');
    elsif rising_edge(CLKxCI) then
      XCoordxDP <= XCoordxDN;
      YCoordxDP <= YCoordxDN;
      C_RExDP <= C_RExDN;
      C_IMxDP <= C_IMxDN;
      Z_RExDP <= Z_RExDN;
      Z_IMxDP <= Z_IMxDN;
      IterxDP <= IterxDN;
      WExDP <= WExDN;
      SizexDP <= SizexDN;
    end if;
  end process;

  XxDO <= XCoordxDP;
  YxDO <= YCoordxDP;
  ITERxDO <= IterxDP;
  WExSO <= WExDP;

  SquareZ_RExS <= UNSIGNED(shift_right(Z_RExDP * Z_RExDP, N_FRAC)(N_BITS - 1 downto 0));
  SquareZ_IMxS <= UNSIGNED(shift_right(Z_IMxDP * Z_IMxDP, N_FRAC)(N_BITS - 1 downto 0));
  SizexDN <= SquareZ_RExS + SquareZ_IMxS;

  process(all)
  begin
    WExDN <= '0';
    XCoordxDN <= XCoordxDP;
    YCoordxDN <= YCoordxDP;
    C_RExDN <= C_RExDP;
    C_IMxDN <= C_IMxDP;
    Z_RExDN <= Z_RExDP;
    Z_IMxDN <= Z_IMxDP;
    IterxDN <= IterxDP;

    if (SizexDP >= ITER_LIM or IterxDP = MAX_ITER) then
      WExDN <= '1';
      IterxDN <= (others => '0');

      XCoordxDN <= XCoordxDP + 1;
      YCoordxDN <= YCoordxDP;

      C_RExDN <= C_RExDP + C_RE_INC;
      C_IMxDN <= C_IMxDP;

      Z_RExDN <= C_RExDP + C_RE_INC;
      Z_IMxDN <= C_IMxDP;
      if (XCoordxDP = HS_DISPLAY - 1) then
        XCoordxDN <= (others => '0');
        YCoordxDN <= YCoordxDP + 1;

        C_RExDN <= C_RE_0;
        C_IMxDN <= C_IMxDP + C_IM_INC;

        Z_RExDN <= C_RE_0;
        Z_IMxDN <= C_IMxDP + C_IM_INC;
        if (YCoordxDP = VS_DISPLAY - 1) then
          YCoordxDN <= (others => '0');

          C_IMxDN <= C_IM_0;

          Z_IMxDN <= C_IM_0;
        end if;
      end if;
    else
      Z_RExDN <= SIGNED(SquareZ_RExS - SquareZ_IMxS) + C_RExDP;
      Z_IMxDN <= shift_left(shift_right(Z_RExDP * Z_IMxDP, N_FRAC)(N_BITS - 1 downto 0), 1) + C_IMxDP;
      IterxDN <= IterxDP + 1;
    end if;
  end process;

end architecture rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
