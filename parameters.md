# System Parameters

This document defines configurable parameters, their default values, valid ranges, and justifications.

---

## Parameter Definitions

### 1. `N_FLOORS`

**Description**: Number of floors served by the elevator.

**Type**: Positive integer

**Default**: `4`

**Valid Range**: `2` to `10` (limited by practical considerations and I/O resources)

**Constraints**:
- Must be ≥ 2 (minimum meaningful elevator)
- Board I/O limits display and request input options
- Scheduler efficiency may degrade with very large values (>10)

**Justification**:
- 4 floors is typical for small/medium buildings
- Fits comfortably within DE10 switch and HEX resources
- Provides sufficient complexity for demonstration without excessive simulation time

**Usage**:
- Passed as generic to all modules requiring floor indexing
- Determines width of `requests` vector in `req_latch`
- Controls range of `current_floor` and `target_floor` signals

---

### 2. `TRAVEL_TIME_PER_FLOOR`

**Description**: Number of 1 Hz ticks required to travel between adjacent floors.

**Type**: Positive integer

**Default**: `3`

**Valid Range**: `1` to `60`

**Constraints**:
- Minimum 1 tick (instantaneous travel, unrealistic but valid for testing)
- Maximum ~60 ticks (1 minute per floor, excessively slow)

**Justification**:
- Default of 3 seconds per floor is realistic for moderate-speed elevators
- Real-world elevators: 1-5 seconds per floor typical
- Allows reasonable simulation time while being observable on hardware

**Usage**:
- Generic parameter for `timer_floor`
- Controls how long `move_enable` must remain asserted before `travel_done` pulses

**Scaling**:
- For faster simulation: reduce to 1 or 2
- For realistic demo: 3-5 seconds
- For tall buildings: could extend to 10+ but update `timer_floor` counter width if needed

---

### 3. `DOOR_OPEN_TIME`

**Description**: Number of 1 Hz ticks the door remains open.

**Type**: Positive integer

**Default**: `4`

**Valid Range**: `1` to `60`

**Constraints**:
- Minimum 1 tick (unrealistic but valid)
- Maximum ~60 ticks (1 minute door open time)

**Justification**:
- 4 seconds provides sufficient time for passenger loading/unloading
- Real-world elevators: 3-10 seconds typical depending on building type
- Balances user experience with throughput

**Usage**:
- Generic parameter for `timer_door`
- Determines duration of `DOOR_OPEN` state in FSM

**Extensions**:
- Could vary by floor (lobby gets longer time)
- Could respond to sensor input (hold door button)

---

### 4. `DOOR_CLOSE_TIME`

**Description**: Number of 1 Hz ticks for the door closing phase.

**Type**: Positive integer

**Default**: `4`

**Valid Range**: `1` to `60`

**Constraints**:
- Minimum 1 tick (unrealistic but valid)
- Maximum ~60 ticks (1 minute door close time)

**Justification**:
- 4 seconds allows visual confirmation of door closing on HEX displays
- Provides time for request clearing and state transitions
- Simulates realistic door closing mechanism timing

**Usage**:
- Generic parameter for `door_close_timer`
- Determines duration of `DOOR_CLOSE_STATE` in FSM
- Request is cleared at end of DOOR_WAIT, then door closes for this duration

**Extensions**:
- Could include safety sensor checks during closing
- Could vary based on door type or floor

---

u_clk_div : entity work.clk_div
### 5. `CLK_FREQ_HZ`

**Description**: Input clock frequency driving the system.

**Type**: Positive integer (Hz)

**Default**: `50000000` (DE10-Standard 50 MHz oscillator)

**Valid Range**: Board-dependent (typical 10–200 MHz). Design assumes integer math fits in 32-bit.

**Justification**:
- Explicit frequency improves clarity vs implicit divisor.
- Enables reuse if board clock changes without recomputing large divisors.

**Usage**:
- Generic parameter for `clk_div`.
- Used with `TICK_FREQ_HZ` to derive internal counter terminal count: `MAX_COUNT = (CLK_FREQ_HZ / TICK_FREQ_HZ) - 1`.

---

### 6. `TICK_FREQ_HZ`

**Description**: Desired tick pulse frequency output from `clk_div`.

**Type**: Positive integer (Hz)

**Default**: `1`

**Valid Range**: `1` to `CLK_FREQ_HZ` (must divide evenly into `CLK_FREQ_HZ`).

**Constraints**:
- `CLK_FREQ_HZ mod TICK_FREQ_HZ = 0` (integer division requirement).
- Counter size must accommodate `(CLK_FREQ_HZ / TICK_FREQ_HZ) - 1`.

**Justification**:
- 1 Hz tick makes higher-level timing parameters intuitive (seconds).
- For simulation, higher tick frequency speeds execution.

**Usage**:
- Generic parameter for `clk_div`.
- Sets real-time granularity of travel and door timers.

**Simulation Note**:
```vhdl
-- Fast simulation configuration example:
clk_div_inst : ENTITY work.clk_div
	GENERIC MAP (
		CLK_FREQ_HZ  => 100,  -- synthetic small frequency for sim cycles
		TICK_FREQ_HZ => 10    -- tick every 10 cycles
	)
	PORT MAP (...);
```

---

## Parameter Summary Table

| Parameter               | Default   | Min | Max       | Units       | Module(s) Affected                     |
|-------------------------|-----------|-----|-----------|-------------|----------------------------------------|
| `N_FLOORS`              | 4         | 2   | 10        | floors      | All                                    |
| `TRAVEL_TIME_PER_FLOOR` | 3         | 1   | 60        | seconds     | `timer_floor`, FSM timing              |
| `DOOR_OPEN_TIME`        | 4         | 1   | 60        | seconds     | `timer_door`, FSM timing               |
| `DOOR_CLOSE_TIME`       | 4         | 1   | 60        | seconds     | `door_close_timer`, FSM timing         |
| `CLK_FREQ_HZ`           | 50000000  | 1   | board max | Hz          | `clk_div`                              |
| `TICK_FREQ_HZ`          | 1         | 1   | CLK_FREQ_HZ | Hz        | `clk_div`, timers                      |

---

## Changing Parameters

### Compile-Time (Generic Override)

In `top_elevator` instantiation or top-level entity:

```vhdl
entity top_elevator is
  generic(
    N_FLOORS              : positive := 6;  -- 6-floor building
    TRAVEL_TIME_PER_FLOOR : positive := 4;  -- 4 seconds per floor
    DOOR_OPEN_TIME        : positive := 7;  -- 7 seconds door open
    CLK_FREQ_HZ           : integer := 50000000;
    TICK_FREQ_HZ          : integer := 1
  );
  -- ...
end entity;
```

### Simulation Override

Pass different generics to DUT in testbench:

```vhdl
dut : entity work.top_elevator
  generic map(
    N_FLOORS              => 4,
    TRAVEL_TIME_PER_FLOOR => 2,      -- Fast travel for sim
    DOOR_OPEN_TIME        => 3,      -- Short door time for sim
    CLK_FREQ_HZ           => 10,     -- Synthetic sim frequency
    TICK_FREQ_HZ          => 1       -- Tick every 10 cycles
  )
  port map(...);
```

---

## Impact Analysis

### Increasing `N_FLOORS`:
- **Pros**: Supports taller buildings
- **Cons**: 
  - Larger `requests` vector (more flip-flops)
  - Scheduler complexity increases (more comparisons)
  - Requires wider floor encoding for display (BCD for >10 floors)

### Increasing `TRAVEL_TIME_PER_FLOOR`:
- **Pros**: More realistic for slow/large elevators
- **Cons**: 
  - Longer wait times
  - Slower system response
  - May require wider counter in `timer_floor` for very large values

### Increasing `DOOR_OPEN_TIME`:
- **Pros**: Better accessibility (more time for passengers)
- **Cons**: 
  - Reduced throughput
  - Longer service time per floor

### Increasing `CLK_FREQ_HZ`:
- **Pros**: Finer timing resolution (if `TICK_FREQ_HZ` also increased)
- **Cons**: Larger counter values; potential timing closure challenges at very high frequencies

### Increasing `TICK_FREQ_HZ`:
- **Pros**: Faster system responsiveness (travel/door timers decrement more often)
- **Cons**: Less human-readable timing unless parameters adjusted; higher toggle activity

### Simulation Adjustment (`CLK_FREQ_HZ` / `TICK_FREQ_HZ`):
- Use small synthetic values to achieve rapid tick pulses.
- Ensure division is exact to avoid mismatch in `MAX_COUNT` computation.

---

## Validation Checklist

Before changing parameters, verify:

- ✅ `N_FLOORS` ≥ 2
- ✅ All timing parameters ≥ 1
- ✅ Counter widths sufficient (16-bit unsigned supports up to 65535 ticks)
- ✅ HEX display can represent all floor numbers (0-9 for single digit)
- ✅ I/O mapping accommodates new floor count
- ✅ Testbenches updated with new parameter values

---

## Recommended Presets

### Preset 1: Fast Simulation
```vhdl
N_FLOORS              => 4
TRAVEL_TIME_PER_FLOOR => 1
DOOR_OPEN_TIME        => 2
DIVISOR_50MHZ_TO_1HZ  => 10
```

### Preset 2: Realistic Demo (Hardware)
```vhdl
N_FLOORS              => 4
TRAVEL_TIME_PER_FLOOR => 3
DOOR_OPEN_TIME        => 5
DIVISOR_50MHZ_TO_1HZ  => 50000000
```

### Preset 3: Tall Building
```vhdl
N_FLOORS              => 8
TRAVEL_TIME_PER_FLOOR => 4
DOOR_OPEN_TIME        => 6
DIVISOR_50MHZ_TO_1HZ  => 50000000
```

### Preset 4: High-Speed Elevator
```vhdl
N_FLOORS              => 10
TRAVEL_TIME_PER_FLOOR => 2
DOOR_OPEN_TIME        => 4
DIVISOR_50MHZ_TO_1HZ  => 50000000
```
