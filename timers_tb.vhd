-- Sheikh Mohammad Sadman Sakib-301604533; Kenny Nguyen-301614035 ; Rodrigo Villalon-301621226

--tb for travel timer
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY timers_tb IS
END ENTITY;

ARCHITECTURE behaviour OF timers_tb IS
    
    CONSTANT MAX_COUNT_C : integer := 3;  --travel time

    SIGNAL clk    : std_logic := '0';
    SIGNAL tick   : std_logic := '0';
    SIGNAL enable : std_logic := '0';
    SIGNAL reset  : std_logic := '0';
    SIGNAL done   : std_logic;

BEGIN

    DUT: ENTITY work.timers
        GENERIC MAP (
            MAX_COUNT => MAX_COUNT_C
        )
        PORT MAP (
            clk    => clk,
            tick   => tick,
            enable => enable,
            reset  => reset,
            done   => done
        );

    --- 10 ns period clock
    clkGenerator : PROCESS
    BEGIN
        clk <= '0';
        WAIT FOR 5 ns;
        clk <= '1';
        WAIT FOR 5 ns;
    END PROCESS;

    stim_proc : PROCESS
    BEGIN
    
        -- Initial reset:
        reset  <= '1';
        enable <= '0';
        tick   <= '0';

        WAIT FOR 40 ns;         -- hold reset

        reset <= '0';           -- release reset

        WAIT FOR 20 ns;         -- done should stay at low (0)


        -- TEST 1: enable timer, send tick pulses
        -- MAX_COUNT = 3, therefore 'done' will go high on 3rd tick.

        enable <= '1';

        -- Tick 1
        tick <= '1';
        WAIT FOR 10 ns;         -- 1 full clock period with tick high
        tick <= '0';
        WAIT FOR 10 ns;         

        -- Tick 2
        tick <= '1';
        WAIT FOR 10 ns;
        tick <= '0';
        WAIT FOR 10 ns;

        -- Tick 3  [should cause done to pulse high for one cycle]
        tick <= '1';
        WAIT FOR 10 ns;
        tick <= '0';
        WAIT FOR 20 ns; 
            
        -- [TEST 1 ENDED]

        -- TEST 2: show enable low clears state
        enable <= '0';
        WAIT FOR 30 ns;         -- while disabled, done should stay low
        -- [TEST 2 ENDED]

        
        -- TEST 3: repeat test 1 to show it works repeatedly
        
        enable <= '1';

        -- Tick 1
        tick <= '1';
        WAIT FOR 10 ns;        
        tick <= '0';
        WAIT FOR 10 ns;         

        -- Tick 2
        tick <= '1';
        WAIT FOR 10 ns;
        tick <= '0';
        WAIT FOR 10 ns;

        -- Tick 3  [should cause done to pulse high for one cycle]
        tick <= '1';
        WAIT FOR 10 ns;
        tick <= '0';
        WAIT FOR 20 ns; 
        -- [TEST 3 ENDED]

        WAIT FOR 40 ns;

        WAIT;  -- stop forever
    END PROCESS;

END ARCHITECTURE behaviour;
