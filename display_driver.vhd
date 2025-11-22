-- Sheikh Mohammad Sadman Sakib-301604533; Kenny Nguyen-301614035 ; Rodrigo Villalon-301621226

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY display_driver IS

	GENERIC (
		N_FLOORS : positive := 4
	);
	PORT (
		current_floor : IN integer RANGE 0 TO N_FLOORS-1;
		door_active   : IN std_logic;
		dir_up        : IN std_logic;
		dir_down      : IN std_logic;
		dir_idle      : IN std_logic;
		estop         : IN std_logic;
		hex_floor     : OUT std_logic_vector(6 DOWNTO 0); -- 7-SEG SEGMENTS (a,b,c,d,e,f,g)
		led_door      : OUT std_logic;
		led_dir_up    : OUT std_logic;
		led_dir_down  : OUT std_logic;
		led_idle      : OUT std_logic;
		led_estop     : OUT std_logic
	);
END ENTITY;

ARCHITECTURE LogicFunction OF display_driver IS

	-- Simple hex digit for floor number 0-9 (no decimal point)
	FUNCTION seg_encode(n : integer) RETURN std_logic_vector IS
		VARIABLE s : std_logic_vector(6 DOWNTO 0);
	BEGIN
		CASE n IS
			WHEN 0 => s := "0000001"; -- assuming active low segments
			WHEN 1 => s := "1001111";
			WHEN 2 => s := "0010010";
			WHEN 3 => s := "0000110";
			WHEN OTHERS => s := (OTHERS => '1');
		END CASE;
		RETURN s;
	END FUNCTION;
	
BEGIN
	hex_floor   <= seg_encode(current_floor);
	led_door    <= door_active;
	led_dir_up  <= dir_up;
	led_dir_down<= dir_down;
	led_idle    <= dir_idle;
	led_estop   <= estop;

END ARCHITECTURE;