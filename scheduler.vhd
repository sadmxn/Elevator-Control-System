-- Sheikh Mohammad Sadman Sakib-301604533; Kenny Nguyen-301614035 ; Rodrigo Villalon-301621226

-- Determines next floor based on these set criteria:
-- Serve all requests in current direction first, when idle choose nearest floor

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY scheduler IS

	GENERIC (
		N_FLOORS : integer := 4
	);
	PORT (
		current_floor : IN  std_logic_vector(1 DOWNTO 0);
		req_lat       : IN  std_logic_vector(N_FLOORS-1 DOWNTO 0); -- Latched floor requests (one bit per floor)
		has_above     : OUT std_logic; -- '1' if there is at least one request above current_floor
		has_below     : OUT std_logic;
		here_req      : OUT std_logic
	);
END ENTITY scheduler;

ARCHITECTURE LogicFunction OF scheduler IS

BEGIN
	PROCESS(req_lat, current_floor)
		VARIABLE above, below : std_logic := '0';
		VARIABLE cfloor_int   : integer RANGE 0 TO N_FLOORS-1;
	BEGIN
		-- Convert 2-bit floor index to integer
		cfloor_int := TO_INTEGER(std_logic_vector(current_floor));

		above := '0';
		below := '0';

		-- Scan all floors to see if there are requests above or below
		
		FOR i IN 0 TO N_FLOORS-1 LOOP
			IF req_lat(i) = '1' THEN
				IF i > cfloor_int THEN
					above := '1';
				ELSIF i < cfloor_int THEN
					below := '1';
				END IF;
			END IF;
		END LOOP;

		has_above <= above;
		has_below <= below;

		-- Request at current floor?
		IF req_lat(cfloor_int) = '1' THEN
			here_req <= '1';
		ELSE
			here_req <= '0';
		END IF;
	END PROCESS;
	
END ARCHITECTURE LogicFunction;