-- Sheikh Mohammad Sadman Sakib-301604533; Kenny Nguyen-301614035 ; Rodrigo Villalon-301621226

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY controller_fsm_tb IS
END ENTITY;

ARCHITECTURE behaviour OF controller_fsm_tb IS

    CONSTANT N_FLOORS_C : integer := 4;

    --inputs to controller_fsm
    SIGNAL clk             : std_logic := '0';
    SIGNAL hard_reset      : std_logic := '0';
    SIGNAL soft_reset      : std_logic := '0';
    SIGNAL estop           : std_logic := '0';
    SIGNAL has_above       : std_logic := '0';
    SIGNAL has_below       : std_logic := '0';
    SIGNAL here_req        : std_logic := '0';
    SIGNAL travel_done     : std_logic := '0';
    SIGNAL door_done       : std_logic := '0';
    SIGNAL door_close_done : std_logic := '0';

    --outputs from controller_fsm
    SIGNAL travel_enable      : std_logic;
    SIGNAL door_enable        : std_logic;
    SIGNAL door_close_enable  : std_logic;
    SIGNAL clear_req          : std_logic_vector(N_FLOORS_C-1 DOWNTO 0);
    SIGNAL current_floor      : std_logic_vector(1 DOWNTO 0);
    SIGNAL door_open          : std_logic;
    SIGNAL door_closing       : std_logic;
    SIGNAL dir_up             : std_logic;
    SIGNAL dir_down           : std_logic;
    SIGNAL estop_active       : std_logic;

BEGIN
    DUT: ENTITY work.controller_fsm
        GENERIC MAP (
            N_FLOORS => N_FLOORS_C
        )
        PORT MAP (
            clk              => clk,
            hard_reset       => hard_reset,
            soft_reset       => soft_reset,
            estop            => estop,
            has_above        => has_above,
            has_below        => has_below,
            here_req         => here_req,
            travel_done      => travel_done,
            door_done        => door_done,
            door_close_done  => door_close_done,
            travel_enable    => travel_enable,
            door_enable      => door_enable,
            door_close_enable => door_close_enable,
            clear_req        => clear_req,
            current_floor    => current_floor,
            door_open        => door_open,
            door_closing     => door_closing,
            dir_up           => dir_up,
            dir_down         => dir_down,
            estop_active     => estop_active
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

        -- TEST 1: test hard reset
 
        hard_reset      <= '1';
        soft_reset      <= '0';
        estop           <= '0';
        has_above       <= '0';
        has_below       <= '0';
        here_req        <= '0';
        travel_done     <= '0';
        door_done       <= '0';
        door_close_done <= '0';

        WAIT FOR 40 ns;          -- hard reset for a few cycles

        hard_reset <= '0';       -- release hard reset

        WAIT FOR 40 ns;          -- controller should be in idle
        
        -- [TEST 1 ENDED]

        
        -- TEST 2: request at current floor while idle
        
        here_req  <= '1';
        has_above <= '0';
        has_below <= '0';

        WAIT FOR 40 ns;                -- FSM should go to door open and wait

        here_req <= '0';               -- request has been completed

        WAIT FOR 80 ns;                -- Door_open and door_enable should be active
        
        -- [TEST 2 ENDED]
        
        
        -- TEST 3: door timer finishes [door_done]
        --should move FSM from DOOR_WAIT to DOOR_CLOSE_STATE
       
        door_done <= '1';
        WAIT FOR 20 ns;
        door_done <= '0';

        WAIT FOR 80 ns;                -- door_closing/door_close_enable should be active

        -- [TEST 3 ENDED]
        

        -- TEST 4: after door closes, theres a request above

        has_above       <= '1';
        door_close_done <= '1';        -- door finished closing

        WAIT FOR 20 ns;

        door_close_done <= '0';

        WAIT FOR 80 ns;                -- FSM should start moving up, dir_up/travel_enable
        -- [TEST 4 ENDED]
        

        -- TEST 5: travel finishes 
        -- simulate reaching next floor while moving up

        travel_done <= '1';
        WAIT FOR 20 ns;
        travel_done <= '0';

        WAIT FOR 80 ns;                -- FSM arrives and opens door again

        has_above <= '0';              -- no more requests above for now
        -- [TEST 5 ENDED]
        
        -- TEST 6: emergency stop

        estop <= '1';
        WAIT FOR 40 ns;               -- estop_active should go high, all enables should go low

        estop <= '0';                  -- clear the e stop

        -- soft_reset to bring controller back to idle
        soft_reset <= '1';
        WAIT FOR 20 ns;
        soft_reset <= '0';

        WAIT FOR 80 ns;                -- back to idle state

        -- [TEST 6 ENDED]

        WAIT;  -- wait forever
    END PROCESS;

END ARCHITECTURE behaviour;
