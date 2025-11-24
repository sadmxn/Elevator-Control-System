-- Sheikh Mohammad Sadman Sakib-301604533; Kenny Nguyen-301614035 ; Rodrigo Villalon-301621226

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY display_driver IS

	PORT (
		floor_in     : IN  std_logic_vector(1 DOWNTO 0); -- internal 0..3, displayed as 1..4
		door_open    : IN  std_logic;
		door_closing : IN  std_logic;
		dir_up       : IN  std_logic;
		dir_down     : IN  std_logic;
		estop_active : IN  std_logic;
		req_lat      : IN  std_logic_vector(3 DOWNTO 0); -- PENDING REQUESTS
	
	-- 7-SEG (ACTIVE-LOW)
	
		HEX0         : OUT std_logic_vector(6 DOWNTO 0); 
		HEX1		 	 : OUT std_logic_vector(6 DOWNTO 0);
		HEX2         : OUT std_logic_vector(6 DOWNTO 0); 
		HEX3         : OUT std_logic_vector(6 DOWNTO 0); 
		HEX4         : OUT std_logic_vector(6 DOWNTO 0); 
		HEX5         : OUT std_logic_vector(6 DOWNTO 0); 
		LEDR         : OUT std_logic_vector(9 DOWNTO 0)  -- STATUS LEDS
	);
END ENTITY display_driver;

ARCHITECTURE LogicFunction OF display_driver IS

	SIGNAL hex0_seg : std_logic_vector(6 DOWNTO 0);
	
BEGIN

-------------------------------------
-- HEX0: SHOW CURRENT FLOOR (0..3) --
-------------------------------------
	PROCESS(floor_in)
	BEGIN
		CASE floor_in IS
			WHEN "00" 	=> hex0_seg 	<= "1111001"; -- display 1 (internal 0)
			WHEN "01" 	=> hex0_seg 	<= "0100100"; -- display 2 (internal 1)
			WHEN "10" 	=> hex0_seg 	<= "0110000"; -- display 3 (internal 2)
			WHEN "11" 	=> hex0_seg 	<= "0011001"; -- display 4 (internal 3)
			WHEN OTHERS => hex0_seg 	<= "1111111"; -- BLANK/OFF
		END CASE;
	END PROCESS;

	HEX0 <= hex0_seg;

-------------------------------------------------------------------------------------
-- HEX5-HEX2 DISPLAY PRIORITY: ESTOP > DOOR OPEN > DOOR CLOSING > DIRECTION > IDLE --
-------------------------------------------------------------------------------------
	PROCESS(estop_active, door_open, door_closing, dir_up, dir_down)
	BEGIN
		IF estop_active = '1' THEN
			HEX5 <= "0000110"; -- E
			HEX4 <= "0010010"; -- S
			HEX3 <= "0000111"; -- T
			HEX2 <= "0100011"; -- O
			HEX1 <= "0001100"; -- P
			
		ELSIF door_open = '1' THEN
			HEX5 <= "0100011"; -- O
			HEX4 <= "0001100"; -- P
			HEX3 <= "0000110"; -- E
			HEX2 <= "0101011"; -- n
			HEX1 <= "1111111"; -- BLANK
			
		ELSIF door_closing = '1' THEN
			HEX5 <= "0100111"; -- C
			HEX4 <= "1000111"; -- L
			HEX3 <= "0100011"; -- o
			HEX2 <= "0010010"; -- S
			HEX1 <= "0000110"; -- E
			
		ELSIF dir_up = '1' THEN
			HEX5 <= "1000001"; -- U
			HEX4 <= "0001100"; -- P
			HEX3 <= "1111111"; -- BLANK
			HEX2 <= "1111111"; -- BLANK
			HEX1 <= "1111111"; -- BLANK
			
		ELSIF dir_down = '1' THEN
			HEX5 <= "0100001"; -- d
			HEX4 <= "0100011"; -- o
			HEX3 <= "1000001"; -- w
			HEX2 <= "0101011"; -- n
			HEX1 <= "1111111"; -- BLANK
			
		ELSE
			HEX5 <= "1111011"; -- I
			HEX4 <= "0100001"; -- d
			HEX3 <= "1000111"; -- L
			HEX2 <= "0000110"; -- E
			HEX1 <= "1111111"; -- BLANK
			
		END IF;
	END PROCESS;

--------------------------------------------
-- LED ASSIGNMENTS: ALL RED ON WHEN ESTOP --
--------------------------------------------
	PROCESS(estop_active, req_lat, door_open, door_closing, dir_up, dir_down)
	BEGIN
		IF estop_active = '1' THEN
			LEDR <= (OTHERS => '1'); -- ALL RED LEDS ON
		ELSE
			LEDR(3 DOWNTO 0) <= req_lat;      -- QUEUED FLOORS
			LEDR(9) 			  <= '0';          -- ESTOP OFF
			LEDR(8) 			  <= door_open;    -- DOOR OPEN
			LEDR(7) 			  <= door_closing; -- DOOR CLOSE
			LEDR(6) 			  <= dir_up;       -- UP
			LEDR(5) 			  <= dir_down;     -- DOWN
			LEDR(4) 			  <= '0';          -- UNUSED
		END IF;
	END PROCESS;
	
END ARCHITECTURE LogicFunction;