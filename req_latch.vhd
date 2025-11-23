LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY req_latch IS

    GENERIC (
        N_FLOORS : integer := 4
    );
    PORT (
        clk        : IN  std_logic;
        soft_reset : IN  std_logic;  -- Active-high
        hard_reset : IN  std_logic;  -- Active-high
        req_in     : IN  std_logic_vector(N_FLOORS-1 downto 0);
        clear_req  : IN  std_logic_vector(N_FLOORS-1 downto 0);
        req_lat    : OUT std_logic_vector(N_FLOORS-1 downto 0)
    );
END ENTITY;

ARCHITECTURE LogicFunction OF req_latch IS

    SIGNAL latched_req : std_logic_vector(N_FLOORS-1 downto 0) := (others => '0');

BEGIN
    PROCESS(clk)
    BEGIN
        IF rising_edge(clk) THEN
		  
            IF hard_reset = '1' THEN 	 -- Hard reset clears all latched requests
                latched_req <= (OTHERS => '0');
					 
            ELSIF soft_reset = '1' THEN -- Soft reset does not change the request queue
                latched_req <= latched_req;

            ELSE
                -- Latch new requests, clear served ones
                latched_req <= (latched_req OR req_in) AND (NOT clear_req);
                -- (latched_req OR req_in) adds new floors to the queue
                -- AND (NOT clear_req) clears the served floor from the queue
            END IF;
        END IF;
    END PROCESS;

    req_lat <= latched_req;

END ARCHITECTURE LogicFunction;
