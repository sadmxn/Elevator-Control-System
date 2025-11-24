-- Sheikh Mohammad Sadman Sakib-301604533; Kenny Nguyen-301614035 ; Rodrigo Villalon-301621226

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY top_elevator IS

	PORT (
		CLOCK_50 : IN  std_logic;
		SW       : IN  std_logic_vector(9 DOWNTO 0);
		KEY      : IN  std_logic_vector(1 DOWNTO 0);
		LEDR     : OUT std_logic_vector(9 DOWNTO 0);
		HEX0     : OUT std_logic_vector(6 DOWNTO 0);
		HEX1		: OUT std_logic_vector(6 DOWNTO 0);
		HEX2		: OUT std_logic_vector(6 DOWNTO 0);
		HEX3		: OUT std_logic_vector(6 DOWNTO 0);
		HEX4		: OUT std_logic_vector(6 DOWNTO 0);
		HEX5		: OUT std_logic_vector(6 DOWNTO 0)
	);
END ENTITY top_elevator;

ARCHITECTURE LogicFunction OF top_elevator IS
	-- CONSTANTS
	CONSTANT N_FLOORS              : integer := 4;
	CONSTANT TRAVEL_TIME_PER_FLOOR : integer := 3; -- SECONDS
	CONSTANT DOOR_OPEN_TIME        : integer := 4; -- SECONDS
	CONSTANT DOOR_CLOSE_TIME       : integer := 4; -- SECONDS

	-- CLOCK / RESET / ESTOP
	SIGNAL tick_1hz    : std_logic;
	SIGNAL hard_reset  : std_logic;
	SIGNAL soft_reset  : std_logic;
	SIGNAL estop       : std_logic;

	-- REQUEST / CONTROL SIGNALS
	SIGNAL req_in        	 : std_logic_vector(N_FLOORS-1 DOWNTO 0);
	SIGNAL req_lat       	 : std_logic_vector(N_FLOORS-1 DOWNTO 0);
	SIGNAL clear_req     	 : std_logic_vector(N_FLOORS-1 DOWNTO 0);
	SIGNAL current_floor 	 : std_logic_vector(1 DOWNTO 0); -- internal 0..3, display shows 1..4
	SIGNAL has_above     	 : std_logic;
	SIGNAL has_below       	 : std_logic;
	SIGNAL here_req        	 : std_logic;
	SIGNAL travel_done     	 : std_logic;
	SIGNAL door_done       	 : std_logic;
	SIGNAL door_close_done 	 : std_logic;
	SIGNAL travel_enable   	 : std_logic;
	SIGNAL door_enable       : std_logic;
	SIGNAL door_close_enable : std_logic;
	SIGNAL door_open_sig   	 : std_logic;
	SIGNAL door_closing_sig  : std_logic;
	SIGNAL dir_up_sig    	 : std_logic;
	SIGNAL dir_down_sig      : std_logic;
	SIGNAL estop_active  	 : std_logic;

BEGIN
	-- INPUT MAPPING
	hard_reset <= NOT KEY(0);
	soft_reset <= NOT KEY(1);
	estop      <= SW(9);
	req_in     <= SW(3 DOWNTO 0);

	-- CLOCK DIVIDER (50 MHz -> 1 Hz)
	clk_div_inst : ENTITY work.clk_div
		GENERIC MAP (
			CLK_FREQ_HZ  => 50000000,
			TICK_FREQ_HZ => 1
		)
		PORT MAP (
			clk        => CLOCK_50,
			hard_reset => hard_reset,
			tick_1hz   => tick_1hz
		);

	-- REQUEST LATCH
	req_latch_inst : ENTITY work.req_latch
		GENERIC MAP (N_FLOORS => N_FLOORS)
		PORT MAP (
			clk        => CLOCK_50,
			soft_reset => soft_reset,
			hard_reset => hard_reset,
			req_in     => req_in,
			clear_req  => clear_req,
			req_lat    => req_lat
		);

	-- SCHEDULER SUMMARY
	scheduler_inst : ENTITY work.scheduler
		GENERIC MAP (N_FLOORS => N_FLOORS)
		PORT MAP (
			current_floor => current_floor,
			req_lat       => req_lat,
			has_above     => has_above,
			has_below     => has_below,
			here_req      => here_req
		);

	-- CONTROLLER FSM
	controller_inst : ENTITY work.controller_fsm
		GENERIC MAP (N_FLOORS => N_FLOORS)
		PORT MAP (
			clk           	 	=> CLOCK_50,
			soft_reset    	   => soft_reset,
			hard_reset    	   => hard_reset,
			estop         	   => estop,
			has_above     	 	=> has_above,
			has_below     	 	=> has_below,
			here_req        	=> here_req,
			travel_done   	 	=> travel_done,
			door_done     	 	=> door_done,
			door_close_done 	=> door_close_done,
			travel_enable 	 	=> travel_enable,
			door_enable   	 	=> door_enable,
			door_close_enable => door_close_enable,
			clear_req     		=> clear_req,
			current_floor 		=> current_floor,
			door_open     		=> door_open_sig,
			door_closing  		=> door_closing_sig,
			dir_up        		=> dir_up_sig,
			dir_down      		=> dir_down_sig,
			estop_active  		=> estop_active
		);

	-- TRAVEL TIMER
	travel_timer_inst : ENTITY work.timers
		GENERIC MAP (MAX_COUNT => TRAVEL_TIME_PER_FLOOR)
		PORT MAP (
			clk    => CLOCK_50,
			tick   => tick_1hz,
			enable => travel_enable,
			reset  => hard_reset OR soft_reset,
			done   => travel_done
		);

	-- DOOR TIMER
	door_timer_inst : ENTITY work.timers
		GENERIC MAP (MAX_COUNT => DOOR_OPEN_TIME)
		PORT MAP (
			clk    => CLOCK_50,
			tick   => tick_1hz,
			enable => door_enable,
			reset  => hard_reset OR soft_reset,
			done   => door_done
		);

	-- DOOR CLOSE TIMER
	door_close_timer_inst : ENTITY work.timers
		GENERIC MAP (MAX_COUNT => DOOR_CLOSE_TIME)
		PORT MAP (
			clk    => CLOCK_50,
			tick   => tick_1hz,
			enable => door_close_enable,
			reset  => hard_reset OR soft_reset,
			done   => door_close_done
		);

	-- DISPLAY DRIVER
	display_inst : ENTITY work.display_driver
		PORT MAP (
			floor_in     => current_floor,
			door_open    => door_open_sig,
			door_closing => door_closing_sig,
			dir_up       => dir_up_sig,
			dir_down     => dir_down_sig,
			estop_active => estop_active,
			req_lat      => req_lat,
			HEX0         => HEX0,
			HEX1			 => HEX1,
			HEX2         => HEX2,
			HEX3         => HEX3,
			HEX4         => HEX4,
			HEX5         => HEX5,
			LEDR         => LEDR
		);
		
END ARCHITECTURE LogicFunction;