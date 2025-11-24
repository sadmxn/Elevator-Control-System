-- Sheikh Mohammad Sadman Sakib-301604533; Kenny Nguyen-301614035 ; Rodrigo Villalon-301621226

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY controller_fsm IS

	GENERIC (
		N_FLOORS : integer := 4
	);
	PORT (
		clk        : IN  std_logic;
		hard_reset : IN  std_logic;  -- ACTIVE-HIGH
		soft_reset : IN  std_logic;  -- ACTIVE-HIGH
		estop      : IN  std_logic;  -- ACTIVE-HIGH

		-- From scheduler
		has_above : IN  std_logic;
		has_below : IN  std_logic;
		here_req  : IN  std_logic;

		-- FROM timers
		travel_done 	 : IN  std_logic;
		door_done   	 : IN  std_logic;
		door_close_done : IN std_logic;

		-- TO timers
		travel_enable 		: OUT std_logic;
		door_enable   		: OUT std_logic;
		door_close_enable : OUT std_logic;

		-- CONTROL to req_latch
		clear_req : OUT std_logic_vector(N_FLOORS-1 DOWNTO 0);

		-- STATUS to display
      current_floor : OUT std_logic_vector(1 DOWNTO 0); -- Internal 0..3 (Displayed as 1..4)
		door_open     : OUT std_logic;
		door_closing  : OUT std_logic;
		dir_up        : OUT std_logic;
		dir_down      : OUT std_logic;
      estop_active  : OUT std_logic
	);
END ENTITY controller_fsm;

ARCHITECTURE LogicFunction OF controller_fsm IS

    type state_type is (
        IDLE,
        MOVE_UP,
        MOVE_DOWN,
        ARRIVE,
        DOOR_OPEN_STATE,
        DOOR_WAIT,
        DOOR_CLOSE_STATE,
        ESTOP_STATE
    );
    
    type dir_type is (DIR_IDLE_ST, DIR_UP_ST, DIR_DOWN_ST); -- Rename literals to avoid clash with ports

    signal state, next_state       : state_type := IDLE;
    signal direction, next_direction : dir_type := DIR_IDLE_ST;

    signal current_floor_int : integer range 0 to 3 := 0; -- Internal floor index as integer 0..3

    signal clear_req_reg     : std_logic_vector(N_FLOORS-1 downto 0) := (others => '0');
    
	 signal travel_en_reg     : std_logic := '0';
    signal door_en_reg       : std_logic := '0';
    signal door_close_en_reg : std_logic := '0';

BEGIN

------------------------------
-- State & sequential logic --
------------------------------

    PROCESS(clk)
    BEGIN
        IF rising_edge(clk) THEN
			IF hard_reset = '1' THEN 		-- HARD reset: full reset
				state             <= IDLE;
				direction         <= DIR_IDLE_ST;
				current_floor_int <= 0;
				clear_req_reg     <= (OTHERS => '0');
				travel_en_reg     <= '0';
				door_en_reg       <= '0';
				door_close_en_reg <= '0';			
				
			ELSIF soft_reset = '1' THEN 	-- SOFT reset: reset logic, preserve floor & direction
				state         		<= IDLE;
				travel_en_reg  	<= '0';
				door_en_reg   		<= '0';
				door_close_en_reg <= '0';            
			ELSE
				 
				IF estop = '1' THEN 		   -- ESTOP: override FSM to ESTOP_STATE
					state         		<= ESTOP_STATE;
					travel_en_reg 		<= '0';
					door_en_reg   		<= '0';
					door_close_en_reg <= '0';                
			ELSE									-- Normal FSM update
               state     	  <= next_state; 
               direction     <= next_direction;
					clear_req_reg <= (OTHERS => '0'); -- Default: no clear_req unless we explicitly set it
					
------------------------------------------
-- Enable timers based on current state --
------------------------------------------

					IF state = MOVE_UP or state = MOVE_DOWN THEN
						travel_en_reg <= '1';
					ELSE
						travel_en_reg <= '0';
					END IF;

					IF state = DOOR_OPEN_STATE or state = DOOR_WAIT THEN
						door_en_reg <= '1';
					ELSE
						door_en_reg <= '0';
					END IF;

					IF state = DOOR_CLOSE_STATE THEN
						door_close_en_reg <= '1';
					ELSE
						door_close_en_reg <= '0';
					END IF;
					
-------------------------------
-- Move floor on travel_done --
-------------------------------
                    IF (state = MOVE_UP) and (travel_done = '1') THEN
                        IF current_floor_int < 3 THEN
                            current_floor_int <= current_floor_int + 1;
                        END IF;
                    ELSIF (state = MOVE_DOWN) and (travel_done = '1') THEN
                        IF current_floor_int > 0 THEN
                            current_floor_int <= current_floor_int - 1;
                        END IF;
                    END IF;
						  
--------------------------------------------------------------------
-- Clear request when door finishes opening (at end of DOOR_WAIT) --
--------------------------------------------------------------------
                    IF (state = DOOR_WAIT) and (door_done = '1') THEN
                        clear_req_reg <= (OTHERS => '0');
                        clear_req_reg(current_floor_int) <= '1'; -- Clear this floor
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

-----------------------------------------------------
-- Next-state & next-direction combinational logic --
-----------------------------------------------------

    PROCESS(state, has_above, has_below, here_req, travel_done, door_done, door_close_done, direction)
    BEGIN
        next_state      <= state;         -- Default hold
        next_direction  <= direction;     -- Default hold

        CASE state IS
            WHEN IDLE =>
                IF here_req = '1' THEN
                    next_state     <= DOOR_OPEN_STATE;
                    next_direction <= direction;  -- Keep last direcction
                ELSIF has_above = '1' THEN
                    next_state     <= MOVE_UP;
                    next_direction <= DIR_UP_ST;
                ELSIF has_below = '1' THEN
                    next_state     <= MOVE_DOWN;
                    next_direction <= DIR_DOWN_ST;
                ELSE
                    next_state     <= IDLE;
                    next_direction <= DIR_IDLE_ST;
                END IF;

            WHEN MOVE_UP =>
                IF travel_done = '1' THEN
                    next_state <= ARRIVE;
                ELSE
                    next_state <= MOVE_UP;
                END IF;

            WHEN MOVE_DOWN =>
                IF travel_done = '1' THEN
                    next_state <= ARRIVE;
                ELSE
                    next_state <= MOVE_DOWN;
                END IF;

            WHEN ARRIVE =>
                IF here_req = '1' THEN
                    next_state     <= DOOR_OPEN_STATE; -- Keep current direction, we might resume same way
                ELSE
                    IF has_above = '1' THEN
                        next_state     <= MOVE_UP;
                        next_direction <= DIR_UP_ST;
                    ELSIF has_below = '1' THEN
                        next_state     <= MOVE_DOWN;
                        next_direction <= DIR_DOWN_ST;
                    ELSE
                        next_state     <= IDLE;
                        next_direction <= DIR_IDLE_ST;
                    END IF;
                END IF;

            WHEN DOOR_OPEN_STATE => -- Immediately start waiting with door open
                next_state <= DOOR_WAIT;

            WHEN DOOR_WAIT =>
                IF door_done = '1' THEN
                    next_state <= DOOR_CLOSE_STATE;
                ELSE
                    next_state <= DOOR_WAIT;
                END IF;

			WHEN DOOR_CLOSE_STATE =>
				IF door_close_done = '1' THEN
					IF has_above = '1' THEN
						next_state     <= MOVE_UP;
						next_direction <= DIR_UP_ST;
					ELSIF has_below = '1' THEN
						next_state     <= MOVE_DOWN;
						next_direction <= DIR_DOWN_ST;
					ELSE
						next_state     <= IDLE;
						next_direction <= DIR_IDLE_ST;
					END IF;
				ELSE
					next_state <= DOOR_CLOSE_STATE;
				END IF;
				
            WHEN ESTOP_STATE => -- Stay here until reset
                next_state     <= ESTOP_STATE;
                next_direction <= direction;  -- Preserve current direction

            WHEN OTHERS =>
                next_state     <= IDLE;
                next_direction <= DIR_IDLE_ST;
        END CASE;
    END PROCESS;

-------------
-- Outputs --
-------------

	current_floor <= std_logic_vector(to_unsigned(current_floor_int, 2));

	door_open    <= '1' WHEN (state = DOOR_OPEN_STATE OR state = DOOR_WAIT) ELSE '0';
	door_closing <= '1' WHEN state = DOOR_CLOSE_STATE ELSE '0';

	dir_up   <= '1' WHEN (state = MOVE_UP)   ELSE '0';
   dir_down <= '1' WHEN (state = MOVE_DOWN) ELSE '0';

   estop_active <= '1' WHEN state = ESTOP_STATE ELSE '0';

   clear_req         <= clear_req_reg;
   travel_enable     <= travel_en_reg;
   door_enable       <= door_en_reg;
   door_close_enable <= door_close_en_reg;
	 
END ARCHITECTURE LogicFunction;