-- Sheikh Mohammad Sadman Sakib-301604533; Kenny Nguyen-301614035 ; Rodrigo Villalon-301621226

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY timers IS

	GENERIC (
		MAX_COUNT : integer := 1  -- NUMBER OF TICKS BEFORE 'done'
	);
	PORT (
		clk    : IN  std_logic;  -- System Clock
		tick   : IN  std_logic;  -- 1Hz tick from clk_div
		enable : IN  std_logic;  
		reset  : IN  std_logic;  -- Active-high reset
		done   : OUT std_logic   -- '1' when count reaches MAX_COUNT
	);
END ENTITY timers;

ARCHITECTURE LogicFunction OF timers IS

	signal count    : integer RANGE 0 TO MAX_COUNT := 0;
	signal done_reg : std_logic := '0';
	
BEGIN
	PROCESS(clk)
	BEGIN
		IF rising_edge(clk) THEN
			IF reset = '1' THEN
				count    <= 0;
				done_reg <= '0';

			ELSIF enable = '1' THEN
				IF tick = '1' THEN
					IF count = MAX_COUNT THEN
						done_reg <= '1'; -- STAY '1' UNTIL RESET OR enable='0'
					ELSE
						count    <= count + 1;
						done_reg <= '0';
					END IF;
				END IF;

			ELSE
				-- TIMER DISABLED: CLEAR COUNT & done
				count    <= 0;
				done_reg <= '0';
			END IF;
		END IF;
	END PROCESS;

	done <= done_reg;
	
END ARCHITECTURE LogicFunction;