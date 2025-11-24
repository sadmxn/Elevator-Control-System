-- Sheikh Mohammad Sadman Sakib-301604533; Kenny Nguyen-301614035 ; Rodrigo Villalon-301621226

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
--REQ_LATCH_TB

ENTITY req_latch_tb IS
END ENTITY;

ARCHITECTURE behaviour OF req_latch_tb IS

    CONSTANT N_FLOORS_C : integer := 4;  
                                                            --all signals match req_latch's ports
    SIGNAL clk        : std_logic := '0'; -- active high
    SIGNAL soft_reset : std_logic := '0'; -- active high
    SIGNAL hard_reset : std_logic := '0'; -- active high
    SIGNAL req_in     : std_logic_vector(N_FLOORS_C-1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL clear_req  : std_logic_vector(N_FLOORS_C-1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL req_lat    : std_logic_vector(N_FLOORS_C-1 DOWNTO 0);

BEGIN
   
    DUT: ENTITY work.req_latch
        GENERIC MAP (
            N_FLOORS => N_FLOORS_C
        )
        PORT MAP (
            clk        => clk,
            soft_reset => soft_reset,
            hard_reset => hard_reset,
            req_in     => req_in,
            clear_req  => clear_req,
            req_lat    => req_lat
        );

    --- 10 ns period clock
    clkGenerator : PROCESS
    BEGIN
        clk <= '0';
        WAIT FOR 5 ns;
        clk <= '1';
        WAIT FOR 5 ns;
    END PROCESS;

   
    ---stimulus
    stimulus : PROCESS
    BEGIN
        
        -- set hard_reset = 1, everything else = 0.
        hard_reset <= '1';
        soft_reset <= '0';
        req_in     <= (OTHERS => '0');
        clear_req  <= (OTHERS => '0');

        WAIT FOR 40 ns;               --four clock cycles
        hard_reset <= '0';            --release hard reset

        WAIT FOR 20 ns;               -- Wait more to show that that req_lat stays at 0000

    
        -- TEST 1:latch two floors at the same time
        --floors 1 and 3: 0101
        
        req_in <= "0101";
        WAIT FOR 20 ns;               
        req_in <= (OTHERS => '0');    -- remove all of the inputs
        WAIT FOR 40 ns;
            
        -- [TEST 1 ENDED]
       
       
        -- TEST 2: clear floor 1 ONLY using clear_req =0001
      
        clear_req <= "0001";
        WAIT FOR 20 ns;
        clear_req <= (OTHERS => '0');   --req_ latch should be 0100
        WAIT FOR 40 ns;
            
        -- [TEST 2 ENDED]

      
        -- TEST 3: Add extra request while theres a pending request
        -- New request at floor 3: 1000
        
        req_in <= "1000";
        WAIT FOR 20 ns;
        req_in <= (OTHERS => '0'); 

        -- now req_lat should be 1100 , (floors 3 and 4)

        WAIT FOR 40 ns;

        -- [TEST 3 ENDED]
        
        
        -- TEST 4: show that soft_reset clears all latched requests
        
        soft_reset <= '1';  --pulse high for 20ns
        WAIT FOR 20 ns;
        soft_reset <= '0';

        -- After this, req_lat should return to 0000

        WAIT FOR 80 ns;
            
        -- [TEST 4 ENDED]

        WAIT;   --wait forever
    END PROCESS;

END ARCHITECTURE behaviour;
