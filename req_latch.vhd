-- Sheikh Mohammad Sadman Sakib-301604533; Kenny Nguyen-301614035 ; Rodrigo Villalon-301621226

-- Remembers which floor have been requested and holds them until the elevator completes service at each floor

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY req_latch IS

	GENERIC (
		N_FLOORS : unsigned := 4
	);
	PORT (
		clk                  : IN  std_logic;
		tick_1hz             : IN  std_logic;
		soft_reset           : IN  std_logic; -- Clears pending requests only
		hard_reset           : IN  std_logic; -- Clears everything
		estop                : IN  std_logic; -- Emergency stop
		new_req_floor        : IN  integer RANGE 0 TO N_FLOORS - 1;
		new_req_valid        : IN  std_logic;
		clear_serviced_floor : IN  integer RANGE 0 TO N_FLOORS - 1;
		clear_valid          : IN  std_logic; -- Asserted after door cycle completion
														  -- If both new_req_valid and clear_valid high: clear takes priorty
		reqs             		: OUT std_logic_vector(N_FLOORS - 1 DOWNTO 0)
	);
END ENTITY;

ARCHITECTURE LogicFunction OF req_latch IS

	SIGNAL reqs : std_logic_vector(N_FLOORS-1 DOWNTO 0) := (OTHERS => '0');
	
BEGIN
	PROCESS (clk)
	BEGIN
		IF rising_edge(clk) THEN
			IF hard_reset = '1' OR soft_reset = '1' THEN
				reqs <= (OTHERS => '0');
			ELSIF estop = '1' THEN 			 -- Hold state
				reqs <= reqs;
			ELSE
				IF new_req_valid = '1' THEN -- Latch new request
					reqs(new_req_floor) <= '1';
				END IF;
				IF clear_valid = '1' THEN 	 -- Clear serviced floor
					reqs(clear_serviced_floor) <= '0';
				END IF;
			END IF;
		END IF;
	END PROCESS;
	
END ARCHITECTURE;