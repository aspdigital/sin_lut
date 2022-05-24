-------------------------------------------------------------------------------
-- Title      : Sine Wave Generator, using lookup table
-- Project    : General use entity
-------------------------------------------------------------------------------
-- File       : sin_lut.vhdl
-- Author     : Andy Peters  <devel@latke.net>
-- Company    : ASP Digital
-- Created    : 2022-04-22
-- Last update: 2022-04-22
-- Platform   : Any reasonable FPGA
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: Implement an FPGA ROM-based sine wave lookup table.
--
-- DEPTH sets the number of entries -- angle steps -- in the table.
-- WIDTH sets the sample word length.
--
-- The index into the table is a natural.
-- The sample outputs are signed.
--
-- The output of the table is synchronous to the clock.
--
-- An angle input greater than width will throw an out-of-range error.
--
-- Make sure to set the syn_romstyle attribute to block_rom for the lookup
-- table, otherwise it will use LUTs and fill the entire FPGA.
-------------------------------------------------------------------------------
-- Copyright (c) 2022 ASP Digital
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2022-04-22           andy    Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
library std;
use std.textio.all;

entity sin_lut is

    generic (
        DEPTH : positive;               -- how many entries are in our table?;
        WIDTH : positive);              -- output word length

    port (
        clk   : in  std_logic;                  -- a clock for our logic
        angle : in  natural range 0 to DEPTH - 1;                    -- index into the array
        sine  : out signed(WIDTH-1 downto 0));  -- the sine wave result

end entity sin_lut;

architecture look_up_table of sin_lut is

    type sin_table_t is array (natural range <>) of signed(WIDTH - 1 downto 0);
    -- Initialize the table.
    -- The math_real sin function takes an argument in real radians.
    -- Sine output is, of course, from -1 to 1, which we scale to our signed
    -- integer output.
    function init_sine_table (
        constant S_WIDTH : in positive;  -- # of bits in entry
        constant T_SIZE  : in positive)  -- # of entries in table
        return sin_table_t is

        -- what we return:
        variable rv            : sin_table_t(0 to T_SIZE - 1);
        -- the step divides the circle by the size.
        constant STEP          : real    := 1.0 / real(T_SIZE);
        -- intermediate, convert angle to radians
        variable v_rad         : real;
        variable v_sine        : real;  -- calculated sine
        variable v_sine_scaled : real;
        -- to prevent rollover at max positive, saturate:
        constant MAX_POS       : integer := 2 ** (S_WIDTH - 1) - 1;
        variable v_sine_int    : integer;

    begin  -- function init_sine_table
        InitLoop : for i in rv'range loop
            -- get the angle in radians.
            v_rad         := MATH_2_PI * real(i) * STEP;
            -- get the sine of that angle
            v_sine        := sin(v_rad);
            -- scale the sine. ensure we saturate to the max.
            v_sine_scaled := trunc(v_sine * 2.0 **real(S_WIDTH-1));
            -- convert to integer
            v_sine_int    := integer(v_sine_scaled);
            -- ensure we don't roll over the max in our range.
            if v_sine_int > MAX_POS then
                v_sine_int := MAX_POS;

            end if;

            -- convert to integer and save in table.
            rv(i) := to_signed(v_sine_int, rv(i)'length);

            -- for debug.
            report "Step " & to_string(i) &
                ", rad = " & to_string(v_rad) &
                ", sine = " & to_string(v_sine) &
                ", scaled = " & to_string(v_sine_scaled) &
                ", as int = " & to_string(v_sine_int)
                severity NOTE;
        end loop InitLoop;

        return rv;

    end function init_sine_table;

    ---------------------------------------------------------------------------
    -- This is the table as initialized by the above.
    ---------------------------------------------------------------------------
    signal SINE_TABLE : sin_table_t(0 to DEPTH - 1) :=
        init_sine_table(WIDTH, DEPTH);
    attribute syn_romstyle : string;
    attribute syn_romstyle of SINE_TABLE : signal is "block_rom";
    
begin  -- architecture rom_based_lut

    ReadLookup : process (clk) is
    begin  -- process ReadLookup
        if rising_edge(clk) then
            sine <= SINE_TABLE(angle);
        end if;
    end process ReadLookup;

end architecture look_up_table;

