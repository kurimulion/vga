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
  signal NxDP, NxDN : unsigned(MEM_DATA_BW - 1 downto 0);
  signal Z_RExDP, Z_RExDN : signed(N_BITS - 1 downto 0);
  signal Z_IMxDP, Z_IMxDN : signed(N_BITS - 1 downto 0);
  signal XxDP, XxDN : unsigned(COORD_BW - 1 downto 0);
  signal YxDP, YxDN : unsigned(COORD_BW - 1 downto 0);
  signal CoordXxDP, CoordXxDN : signed(N_BITS - 1 downto 0);
  signal CoordYxDP, CoordYxDN : signed(N_BITS - 1 downto 0);
  signal ResxD : signed(N_BITS - 1 downto 0);
  signal LenxD : unsigned(N_BITS - 1 downto 0);
  
--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin

  -- TODO: Implement your own code here
  ResxD <= shift_right(Z_RExDP * Z_RExDP, N_FRAC)(N_BITS - 1 downto 0) - shift_right(Z_IMxDP * Z_IMxDP, N_FRAC)(N_BITS - 1 downto 0) + coordXxDP;
  LenxD <= unsigned(shift_right(Z_RExDP * Z_RExDP, N_FRAC)(N_BITS - 1 downto 0)) + unsigned(shift_right(Z_IMxDP * Z_IMxDP, N_FRAC)(N_BITS - 1 downto 0));

  process(CLKxCI, RSTxRI)
  begin
    if RSTxRI = '1' then
      NxDP <= (others => '0');
      Z_RExDP <= C_RE_0;
      Z_IMxDP <= C_IM_0;
      CoordXxDP <= C_RE_0;
      CoordYxDP <= C_IM_0;
      XxDP <= (others => '0');
      YxDP <= (others => '0');
    elsif (CLKxCI'event and CLKxCI = '1') then
      NxDP <= NxDN;
      Z_RExDP <= Z_RExDN;
      Z_IMxDP <= Z_IMxDN;
      XxDP <= XxDN;
      YxDP <= YxDN;
      CoordXxDP <= CoordXxDN;
      CoordYxDP <= CoordYxDN;
    end if;
  end process;

  XxDO <= XxDP;
  YxDO <= YxDP;
  ITERxDO <= NxDP;

  process(all)
  begin
    if NxDP = MAX_ITER or LenxD > ITER_LIM then
      NxDN <= (others => '0');
      WExSO <= '1';
      -- increment X and Y if necessary
      if XxDP = HS_DISPLAY - 1 then
        XxDN <= (others => '0');
        CoordXxDN <= C_RE_0;
        Z_RExDN <= C_RE_0;
        -- check if Y is at the end of the line
        if YxDP = VS_DISPLAY - 1 then
          YxDN <= (others => '0');
          CoordYxDN <= C_IM_0;
          Z_IMxDN <= C_IM_0;
        else
          YxDN <= YxDP + 1;
          CoordYxDN <= CoordYxDP + C_IM_INC;
          Z_IMxDN <= CoordYxDP + C_IM_INC;
        end if;
      else
        XxDN <= XxDP + 1;
        CoordXxDN <= CoordXxDP + C_RE_INC;
        Z_RExDN <= CoordXxDP + C_RE_INC;

        YxDN <= YxDP;
        CoordYxDN <= CoordYxDP;
        Z_IMxDN <= CoordYxDP;
      end if;
    else
      NxDN <= NxDP + 1;
      WExSO <= '0';
      Z_IMxDN <= shift_left(shift_right(Z_RExDP * Z_IMxDP, N_FRAC)(N_BITS - 1 downto 0), 1) + CoordYxDP;
      Z_RExDN <= ResxD;
      
      XxDN <= XxDP;
      CoordXxDN <= CoordXxDP;
      YxDN <= YxDP;
      CoordYxDN <= CoordYxDP;
    end if;
  end process;

end architecture rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
