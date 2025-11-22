-- Sheikh Mohammad Sadman Sakib-301604533; Kenny Nguyen-301614035 ; Rodrigo Villalon-301621226

-- Remembers which floor have been requested and holds them until the elevator completes service at each floor

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY RequestLatch IS

    GENERIC (
        N_FLOORS : integer := 4
    );
    PORT (
        clk        : IN  std_logic;
        soft_reset : IN  std_logic;  -- Active-high
        hard_reset : IN  std_logic;  -- Active-high

        req_in     : IN  std_logic_vector(N_FLOORS-1 DOWNTO 0); -- From switches
        clear_req  : IN  std_logic_vector(N_FLOORS-1 DOWNTO 0); 

        req_lat    : OUT std_logic_vector(N_FLOORS-1 DOWNTO 0)  -- Latched requests
    );
END ENTITY RequestLatch;

ARCHITECTURE LogicFunction OF RequestLatch IS

    SIGNAL latched_req : std_logic_vector(N_FLOORS-1 DOWNTO 0) := (OTHERS => '0');
	 
BEGIN
    PROCESS(clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF (soft_reset = '1') OR (hard_reset = '1') THEN
                latched_req <= (OTHERS => '0');
            ELSE   -- Latch new requests, clear served ones
                latched_req <= (latched_req OR req_in) AND (NOT clear_req); -- (latched_req OR req_in) adds new floor to the queue
																									 -- AND (NOT clear_req) clears the served floor from the queue
            END IF;
        END IF;
    END PROCESS;

    req_lat <= latched_req;
END ARCHITECTURE LogicFunction;