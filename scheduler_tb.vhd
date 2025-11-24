--Sheikh Mohammad Sadman Sakib-301604533; Kenny Nguyen-301614035 ; Rodrigo Villalon-301621226

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY scheduler_tb IS
END ENTITY;

ARCHITECTURE behaviour OF scheduler_tb IS

    CONSTANT N_FLOORS_C : integer := 4;

    SIGNAL current_floor : std_logic_vector(1 DOWNTO 0) := "00";
    SIGNAL req_lat       : std_logic_vector(N_FLOORS_C-1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL has_above     : std_logic;
    SIGNAL has_below     : std_logic;
    SIGNAL here_req      : std_logic;

BEGIN

    DUT: ENTITY work.scheduler
        GENERIC MAP (
            N_FLOORS => N_FLOORS_C
        )
        PORT MAP (
            current_floor => current_floor,
            req_lat       => req_lat,
            has_above     => has_above,
            has_below     => has_below,
            here_req      => here_req
        );

    stim_proc : PROCESS
    BEGIN
       
        -- TEST 1: request above current floor, 
        -- therefore should show has_above = 1, has_below and here_req = 0.
        
        current_floor <= "01";        -- Floor 2
        req_lat       <= "1000";      -- request Floor 4 
        WAIT FOR 20 ns;  
            
        -- [TEST 1 ENDED]

        
        -- TEST 2: request below current floor
        -- therefore should show has_below = 1, has_above and here_req = 0.
        
        current_floor <= "10";        -- Floor 3
        req_lat       <= "0001";      -- request Floor 1 
        WAIT FOR 20 ns;
            
        -- [TEST 2 ENDED]
 

        -- TEST 3: request below and above current floor
        -- therefore should show has_below = 1, has_above = 1 and here_req = 0.
        
        current_floor <= "10";        -- Floor 3
        req_lat       <= "1001";      -- request Floor 4 and 1 
        WAIT FOR 20 ns;
            
        -- [TEST 3 ENDED]
        
      
        -- TEST 4: request same floor
        -- therefore should show has_below, has_above = 0 and here_req = 1.
        
        current_floor <= "10";        -- Floor 3
        req_lat       <= "0100";      -- request Floor 3 
        WAIT FOR 20 ns;
            
        -- [TEST 4 ENDED]
        
        
        -- TEST 5: request same floor, floor above and floor below
        -- therefore should show has_below, has_above, here_req = 1.
        
        current_floor <= "10";        -- Floor 3
        req_lat       <= "1101";      -- request Floor 4, 3 and 1
        WAIT FOR 20 ns;
            
        -- [TEST 5 ENDED]

        -- TEST 6: no requests
        -- therefore should show has_below, has_above, here_req = 0.
        
        current_floor <= "10";        -- Floor 3
        req_lat       <= "0000";      -- request no floor
        WAIT FOR 20 ns;
            
        -- [TEST 6 ENDED]

        WAIT; --wait forever
    END PROCESS;

END ARCHITECTURE behaviour;
