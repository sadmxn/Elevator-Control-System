LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY controller_fsm IS
    GENERIC (
        N_FLOORS              : integer := 4;
        TRAVEL_TIME_PER_FLOOR : integer := 3; -- seconds (not used here but kept for consistency)
        DOOR_OPEN_TIME        : integer := 4  -- seconds (not used here but kept for consistency)
    );
    PORT (
        clk         : IN  std_logic;
        soft_reset  : IN  std_logic;  -- active-high
        hard_reset  : IN  std_logic;  -- active-high
        estop       : IN  std_logic;  -- active-high

        -- From scheduler
        has_above   : IN  std_logic;
        has_below   : IN  std_logic;
        here_req    : IN  std_logic;

        -- From timers
        travel_done : IN  std_logic;
        door_done   : IN  std_logic;

        -- To timers
        travel_enable : OUT std_logic;
        door_enable   : OUT std_logic;

        -- Control to req_latch
        clear_req   : OUT std_logic_vector(N_FLOORS-1 DOWNTO 0);

        -- Status to outside world
        current_floor : OUT std_logic_vector(1 DOWNTO 0); -- 0..3
        door_open     : OUT std_logic;
        dir_up_o      : OUT std_logic;   -- renamed to avoid any name clashes
        dir_down_o    : OUT std_logic;   -- renamed to avoid any name clashes
        estop_active  : OUT std_logic
    );
END ENTITY controller_fsm;

ARCHITECTURE LogicFunction OF controller_fsm IS

    TYPE state_type IS (
        IDLE,
        MOVE_UP,
        MOVE_DOWN,
        ARRIVE,
        DOOR_OPEN_STATE,
        DOOR_WAIT,
        DOOR_CLOSE_STATE,
        ESTOP_STATE
    );

    TYPE dir_type IS (DIR_IDLE, DIR_UP, DIR_DOWN);

    SIGNAL state, next_state       : state_type := IDLE;
    SIGNAL direction, next_direction : dir_type := DIR_IDLE;

    SIGNAL current_floor_int : integer RANGE 0 TO 3 := 0;

    SIGNAL clear_req_reg : std_logic_vector(N_FLOORS-1 DOWNTO 0) := (OTHERS => '0');

    SIGNAL travel_en_reg : std_logic := '0';
    SIGNAL door_en_reg   : std_logic := '0';

BEGIN

    ----------------------------------------------------------------
    -- SEQUENTIAL PROCESS: REGISTERS FOR STATE, DIRECTION, FLOOR
    ----------------------------------------------------------------
    PROCESS(clk)
    BEGIN
        IF rising_edge(clk) THEN

            -- HARD RESET: FULL RESET
            IF hard_reset = '1' THEN
                state             <= IDLE;
                direction         <= DIR_IDLE;
                current_floor_int <= 0;
                clear_req_reg     <= (OTHERS => '0');
                travel_en_reg     <= '0';
                door_en_reg       <= '0';

            -- SOFT RESET: CLEAR REQUESTS AND RETURN TO IDLE (KEEP FLOOR)
            ELSIF soft_reset = '1' THEN
                state         <= IDLE;
                direction     <= DIR_IDLE;
                clear_req_reg <= (OTHERS => '0');
                travel_en_reg <= '0';
                door_en_reg   <= '0';

            ELSE
                -- ESTOP OVERRIDES EVERYTHING
                IF estop = '1' THEN
                    state         <= ESTOP_STATE;
                    direction     <= DIR_IDLE;
                    clear_req_reg <= (OTHERS => '0');
                    travel_en_reg <= '0';
                    door_en_reg   <= '0';

                ELSE
                    -- NORMAL FSM UPDATE
                    state      <= next_state;
                    direction  <= next_direction;
                    clear_req_reg <= (OTHERS => '0');  -- default, may be set below

                    -- TIMER ENABLES BASED ON CURRENT STATE
                    IF state = MOVE_UP OR state = MOVE_DOWN THEN
                        travel_en_reg <= '1';
                    ELSE
                        travel_en_reg <= '0';
                    END IF;

                    IF state = DOOR_OPEN_STATE OR state = DOOR_WAIT THEN
                        door_en_reg <= '1';
                    ELSE
                        door_en_reg <= '0';
                    END IF;

                    -- FLOOR UPDATE WHEN TRAVEL COMPLETES
                    IF (state = MOVE_UP) AND (travel_done = '1') THEN
                        IF current_floor_int < 3 THEN
                            current_floor_int <= current_floor_int + 1;
                        END IF;
                    ELSIF (state = MOVE_DOWN) AND (travel_done = '1') THEN
                        IF current_floor_int > 0 THEN
                            current_floor_int <= current_floor_int - 1;
                        END IF;
                    END IF;

                    -- CLEAR REQUEST WHEN DOOR FINISHES CLOSING
                    IF state = DOOR_CLOSE_STATE THEN
                        clear_req_reg                <= (OTHERS => '0');
                        clear_req_reg(current_floor_int) <= '1';
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    ----------------------------------------------------------------
    -- COMBINATIONAL NEXT STATE AND NEXT DIRECTION LOGIC
    ----------------------------------------------------------------
    PROCESS(state, direction, has_above, has_below, here_req, travel_done, door_done)
    BEGIN
        -- defaults
        next_state     <= state;
        next_direction <= direction;

        CASE state IS

            WHEN IDLE =>
                IF here_req = '1' THEN
                    next_state     <= DOOR_OPEN_STATE;
                    next_direction <= DIR_IDLE;
                ELSIF has_above = '1' THEN
                    next_state     <= MOVE_UP;
                    next_direction <= DIR_UP;
                ELSIF has_below = '1' THEN
                    next_state     <= MOVE_DOWN;
                    next_direction <= DIR_DOWN;
                ELSE
                    next_state     <= IDLE;
                    next_direction <= DIR_IDLE;
                END IF;

            WHEN MOVE_UP =>
                IF travel_done = '1' THEN
                    next_state <= ARRIVE;
                ELSE
                    next_state <= MOVE_UP;
                END IF;
                -- direction stays DIR_UP

            WHEN MOVE_DOWN =>
                IF travel_done = '1' THEN
                    next_state <= ARRIVE;
                ELSE
                    next_state <= MOVE_DOWN;
                END IF;
                -- direction stays DIR_DOWN

            WHEN ARRIVE =>
                IF here_req = '1' THEN
                    next_state <= DOOR_OPEN_STATE;
                ELSE
                    IF has_above = '1' THEN
                        next_state     <= MOVE_UP;
                        next_direction <= DIR_UP;
                    ELSIF has_below = '1' THEN
                        next_state     <= MOVE_DOWN;
                        next_direction <= DIR_DOWN;
                    ELSE
                        next_state     <= IDLE;
                        next_direction <= DIR_IDLE;
                    END IF;
                END IF;

            WHEN DOOR_OPEN_STATE =>
                -- immediately go to wait with door open
                next_state <= DOOR_WAIT;
                -- direction unchanged

            WHEN DOOR_WAIT =>
                IF door_done = '1' THEN
                    next_state <= DOOR_CLOSE_STATE;
                ELSE
                    next_state <= DOOR_WAIT;
                END IF;

            WHEN DOOR_CLOSE_STATE =>
                IF has_above = '1' THEN
                    next_state     <= MOVE_UP;
                    next_direction <= DIR_UP;
                ELSIF has_below = '1' THEN
                    next_state     <= MOVE_DOWN;
                    next_direction <= DIR_DOWN;
                ELSE
                    next_state     <= IDLE;
                    next_direction <= DIR_IDLE;
                END IF;

            WHEN ESTOP_STATE =>
                -- stay here until reset
                next_state     <= ESTOP_STATE;
                next_direction <= DIR_IDLE;

            WHEN OTHERS =>
                next_state     <= IDLE;
                next_direction <= DIR_IDLE;
        END CASE;
    END PROCESS;

    ----------------------------------------------------------------
    -- OUTPUT ASSIGNMENTS
    ----------------------------------------------------------------
    current_floor <= std_logic_vector(to_unsigned(current_floor_int, 2));
    door_open     <= '1' WHEN (state = DOOR_OPEN_STATE OR state = DOOR_WAIT) ELSE '0';

    dir_up_o      <= '1' WHEN direction = DIR_UP   ELSE '0';
    dir_down_o    <= '1' WHEN direction = DIR_DOWN ELSE '0';

    estop_active  <= '1' WHEN state = ESTOP_STATE ELSE '0';

    clear_req     <= clear_req_reg;
    travel_enable <= travel_en_reg;
    door_enable   <= door_en_reg;

END ARCHITECTURE LogicFunction;