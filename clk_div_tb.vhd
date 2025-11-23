library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clk_div_tb is
end entity;

architecture Behaviour of clk_div_tb is
    signal clk        : std_logic := '0';
    signal hard_reset : std_logic := '1';
    signal tick_1hz   : std_logic := '0';
begin
    -- DUT
    DUT: entity work.clk_div
        generic map (
            CLK_FREQ_HZ  => 10,   -- faster sim instead of 50000000
            TICK_FREQ_HZ => 1
        )
        port map (
            clk        => clk,
            hard_reset => hard_reset,
            tick_1hz   => tick_1hz
        );

    -- Clock: 10 ns period
    clkGenerator : process
    begin
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;
    end process;

    -- Stimulus
    stimulus : process
    begin
        -- Hold reset for a bit
        hard_reset <= '1';
        wait for 40 ns;

        hard_reset <= '0';
        -- Run long enough to see multiple ticks
        wait for 300 ns;

        -- Pulse reset again mid-run
        hard_reset <= '1';
        wait for 20 ns;
        hard_reset <= '0';

        wait for 200 ns;
        wait;  -- stop
    end process;
end architecture;
