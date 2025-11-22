-- Sheikh Mohammad Sadman Sakib-301604533; Kenny Nguyen-301614035 ; Rodrigo Villalon-301621226

-- Slows down the clock to 1Hz

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY clk_div IS

	GENERIC (
		CLK_FREQ_HZ  : integer := 50000000; -- Input clock frequency (Hz)
		TICK_FREQ_HZ : integer := 1         -- Output tick frequency (Hz)
	);
	PORT (
		clk        : IN  std_logic;
		hard_reset : IN  std_logic;
		tick_1hz   : OUT std_logic -- Ticks high every 1 second
	);	
END ENTITY;

ARCHITECTURE LogicFunction OF clk_div IS

	CONSTANT MAX_COUNT : integer := (CLK_FREQ_HZ / TICK_FREQ_HZ) - 1;
	SIGNAL counter : integer RANGE 0 TO MAX_COUNT := 0;
	
BEGIN
	PROCESS (clk)
	BEGIN
		IF rising_edge(clk) THEN
			IF hard_reset = '1' THEN
				counter  <= 0;
				tick_1hz <= '0';
			ELSIF counter = MAX_COUNT THEN -- Every 50M cycles, tick pulses once 
				counter  <= 0;
				tick_1hz <= '1';
			ELSE
				counter  <= counter + 1;
				tick_1hz <= '0';
			END IF;
		END IF;
	END PROCESS;
	
END ARCHITECTURE;