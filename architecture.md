# System Architecture

## Block Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                        top_elevator                                 │
│                                                                     │
│  ┌──────────┐                                                       │
│  │ clk_div  │──── tick_1hz ────┐                                    │
│  └──────────┘                  │                                    │
│                                 ▼                                   │
│  ┌──────────────┐    ┌──────────────────┐   ┌──────────────┐        │
│  │  req_latch   │───►│   scheduler      │──►│controller_fsm│        │
│  │(4-bit vector)│    │(summary flags)   │   │(Moore FSM)   │        │
│  └──────────────┘    └──────────────────┘   └──────┬───────┘        │
│        ▲                      ▲                     │               │
│        │                      │                     ├─► clear_req   │
│   clear_req           current_floor                 │   (4-bit)     │
│   (4-bit)                     │                     │               │
│        │                      │              ┌──────▼──────┐        │
│        │                      │              │travel_enable│        │
│        │                      │              └──────┬──────┘        │
│        │                      │                     │               │
│        │                      │              ┌──────▼──────────┐    │
│        │                      │              │   timers        │    │
│        │                      │              │ (travel_timer)  │    │
│        │                      │              └──────┬──────────┘    │
│        │                      │                     │travel_done    │
│        │                      │                     │(pulse)        │
│        │                      │              ┌──────▼──────────┐    │
│        │                      │              │   timers        │    │
│        │                      │              │  (door_timer)   │    │
│        │                      │              └──────┬──────────┘    │
│        │                      │                     │door_done      │
│        │                      │                     │(pulse)        │
│        │                      ▼                     ▼               │
│        │              ┌──────────────────────────────────┐          │
│        └──────────────│    display_driver                │          │
│                       │(HEX0-5, LEDR)                    │          │
│                       └──────────────────────────────────┘          │ 
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Module Hierarchy

### 1. `top_elevator` (Top Level)
**Purpose**: Integrates all subsystems for DE10-Standard board.

**Constants**:
- `N_FLOORS`: Number of floors (4)
- `TRAVEL_TIME_PER_FLOOR`: Seconds per floor (3)
- `DOOR_OPEN_TIME`: Seconds door open (4)
- `DOOR_CLOSE_TIME`: Seconds door close (4)

**Ports**:
- Inputs: `CLOCK_50`, `SW(9..0)`, `KEY(1..0)`
- Outputs: `HEX0`, `HEX1`, `HEX2-5` (messages), `LEDR(9..0)`

**Board Mapping**:
- `KEY(0)` → hard_reset (active-low)
- `KEY(1)` → soft_reset (active-low)
- `SW(9)` → estop
- `SW(3..0)` → floor requests (one bit per floor)
- `HEX0` → current floor (displayed as 1-4 for internal 0-3)
- `HEX5-2` → status messages (STOP/OPEN/UP/down)
- `LEDR` → status indicators

**Internal Logic**:
- Wiring between all modules
- No internal floor counter (managed by controller_fsm)

---

### 2. `clk_div`
**Purpose**: Generates 1 Hz tick from 50 MHz input clock.

**Generics**: `CLK_FREQ_HZ` (50000000), `TICK_FREQ_HZ` (1)

**Method**: Counter wraps at `(CLK_FREQ_HZ/TICK_FREQ_HZ)-1`, outputs single-cycle pulse.

**Synthesizable**: Yes (simple counter logic).

---

### 3. `req_latch`
**Purpose**: Latches floor requests until serviced.

**Behavior**:
- Combinational logic: `latched_req <= (latched_req OR req_in) AND (NOT clear_req)`
- `req_in` from switches (one bit per floor, latched on rising edge)
- `clear_req` from FSM (4-bit vector, one per floor)
- Only hard_reset clears all latched requests (soft_reset preserves requests)

**Ports**: `req_in(3..0)`, `clear_req(3..0)`, `req_lat(3..0)`

---

### 4. `scheduler`
**Purpose**: Provides summary flags for FSM decision-making.

**Implementation**:
- Pure combinational process
- Scans all `req_lat` bits against `current_floor`
- Outputs three summary flags:
  - `has_above='1'` if any request above current floor
  - `has_below='1'` if any request below current floor  
  - `here_req='1'` if request at current floor

**FSM uses these flags** to decide: open door / move up / move down / idle

**Combinational**: Zero latency.

---

### 5. `controller_fsm`
**Purpose**: Main control FSM managing state transitions.

**States**:
- `IDLE`: Waiting for requests
- `MOVE_UP`: Ascending (increments floor on travel_done)
- `MOVE_DOWN`: Descending (decrements floor on travel_done)
- `ARRIVE`: Just arrived at a floor (1-cycle transition)
- `DOOR_OPEN_STATE`: Door opening phase
- `DOOR_WAIT`: Door held open (timer running)
- `DOOR_CLOSE_STATE`: Door closing, clears request
- `ESTOP_STATE`: Emergency stop

**FSM Type**: **Moore** (outputs depend on state only).

**Internal Floor Tracking**: `current_floor_int` (0..3) managed internally, output as 2-bit vector.

**Direction Tracking**: Internal enum `dir_type` (DIR_IDLE_ST, DIR_UP_ST, DIR_DOWN_ST).

**Key Outputs**:
- `travel_enable`, `door_enable`, `door_close_enable`: Enable timers
- `clear_req(3..0)`: 4-bit vector (clears one floor at a time)
- `current_floor(1..0)`: Position
- `door_open`, `door_closing`, `dir_up`, `dir_down`, `estop_active`: Status

---

### 6. `timers` (Generic Timer Module)
**Purpose**: Counts ticks until reaching `MAX_COUNT`.

**Generic**: `MAX_COUNT` (e.g., 2 for travel, 3 for door)

**Operation**:
- Counts `tick_1hz` pulses while `enable='1'`
- Outputs single-cycle `done` pulse when count reaches `MAX_COUNT-1` on next tick
- Saturates at `MAX_COUNT` (no auto-restart)
- Resets on `hard_reset OR soft_reset` OR when `enable='0'`

**Instantiated Twice in top_elevator**:
- `travel_timer_inst`: MAX_COUNT=TRAVEL_TIME_PER_FLOOR
- `door_timer_inst`: MAX_COUNT=DOOR_OPEN_TIME

**Key Fix**: `done` is now a **single-cycle pulse** to prevent multi-floor jumps.

---

### 7. `display_driver`
**Purpose**: Converts internal signals to HEX/LED outputs.

**HEX Outputs**:
- `HEX0`: Current floor (internal 0-3 displayed as 1-4)
- `HEX5-2`: Status messages with priority:
  1. ESTOP → "STOP"
  2. Door open → "OPEN"
  3. Moving up → "UP"
  4. Moving down → "down"
  5. Otherwise → blank
- `HEX1`: Blank

**LED Outputs (LEDR)**:
- When `estop_active='1'`: All LEDs on
- Otherwise:
  - LEDR(3..0) = req_lat (pending requests)
  - LEDR(9) = 0 (estop off)
  - LEDR(8) = door_open
  - LEDR(7) = dir_up
  - LEDR(6) = dir_down
  - LEDR(5..4) = unused

**Combinational**: Pure output logic, no state.

---

## FSM State Diagram

```
              hard_reset
                  │
                  ▼
             ┌────────┐       soft_reset returns here
      ┌──────│  IDLE  │◄────────────────────┐
      │      └────┬────┘                       │
      │           │                            │
  no pending   has_above/                         │
   requests    has_below/                         │
      │        here_req                          │
      │           │                            │
      │      ┌────┼────────┐                     │
      │  ┌───│MOVE_UP/DOWN│────┐                │
      │  │   └────┬────────┘    │                │
      │  │        │travel_done   │                │
      │  │        ▼               │ clear_req      │
      │  │   ┌─────────┐      │   asserted      │
      │  │   │  ARRIVE  │      │      ┌────────────┐
      │  │   └────┬────┘      └──────►│ DOOR_CLOSE │
      │  │        │here_req=1         └─────┬──────┘
      │  │        ▼                             │
      │  │  ┌────────────────┐                    │
      │  │  │ DOOR_OPEN_STATE│                    │
      │  │  └───────┬────────┘                    │
      │  │         │auto                           │
      │  │         ▼                               │
      │  │  ┌────────────┐                       │
      │  │  │  DOOR_WAIT  │                       │
      │  │  └──────┬──────┘                       │
      │  │         │door_done                      │
      │  └─────────┼──────────────────────────────┘
      │            │
      │    has_above/below
      │       decides next
      │            │
      └────────────┘

   ESTOP_STATE: entered from any state when estop='1'
   Exit to IDLE only when estop cleared (FSM must self-check)
```

---

## Signal Flow Summary

1. **Request Entry**: SW(3..0) → `req_latch` → `req_lat` vector (4-bit)
2. **Scheduling**: `req_lat` + `current_floor` → `scheduler` → `has_above/has_below/here_req` flags
3. **Motion Control**: Scheduler flags → `controller_fsm` → `travel_enable`, `door_enable`, `clear_req`
4. **Timing**: `travel_enable` + `tick_1hz` → `travel_timer` → `travel_done` (pulse) → FSM increments floor
5. **Door Cycle**: `door_enable` + `tick_1hz` → `door_timer` → `door_done` (pulse) → FSM
6. **Request Clearance**: FSM (in DOOR_CLOSE_STATE) → `clear_req(current_floor_int)` → `req_latch`
7. **Display**: FSM outputs + `req_lat` → `display_driver` → HEX/LEDR

---

## Design Rationale

- **Modular decomposition** allows independent verification and reuse
- **Explicit FSM** provides clear state management and debugging visibility
- **Parameterization** supports various building sizes without code changes
- **Synchronous design** ensures reliable timing on FPGA
- **Combinational scheduler** enables immediate response to request changes

---

## Reset Behavior (Detailed)

| Component        | Soft Reset Effect                            | Hard Reset Effect                                 |
|------------------|----------------------------------------------|---------------------------------------------------|
| `req_latch`      | Clears all pending requests                  | Clears all pending requests                       |
| `controller_fsm` | State forced to IDLE; floor + direction kept | State to IDLE; floor→0; direction cleared          |
| `timers`         | Counter cleared                              | Counter cleared                                   |
| `clk_div`        | No effect                                    | Counter cleared                                   |
| Display outputs  | Update to show IDLE + preserved floor        | Reset to floor 1 (internal 0)                     |

Soft reset clears the request queue and returns FSM to IDLE but preserves floor position and direction memory. Hard reset returns the entire system to initial state (floor 0, direction idle).
