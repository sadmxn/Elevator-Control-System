# Elevator Control System - Project Report

**Course:** ENSC 252 Final Project  
**Date:** November 20, 2025  
**Project:** Elevator Control System for Intel DE10-Standard Board

---

## Executive Summary

This project implements a complete elevator control system in VHDL targeting the Intel DE10-Standard FPGA board. The design supports a configurable number of floors (default 4), directional scheduling policy, and full state management including movement, door control, emergency stop, and reset behaviors.

---

## System Overview

### Purpose
The elevator controller manages:
- Floor requests from users
- Directional movement (up/down/idle)
- Travel timing between adjacent floors
- Door open/close cycles
- Emergency stop (ESTOP) functionality
- Soft and hard reset capabilities

### Key Features
- **Parameterized Design**: Configurable floor count, travel time, and door timing
- **Directional Scheduling**: Serves all requests in current direction before reversing
- **Safety**: ESTOP halts all operations; resets preserve state appropriately
- **Modular Architecture**: Hierarchical design with reusable components
- **Complete Testbenches**: Standalone verification for each module

---

## Design Requirements Met

1. ✅ Clock divider: 50 MHz to 1 Hz tick generation
2. ✅ Support for 4+ floors (parameterized via `N_FLOORS`)
3. ✅ Direction outputs: UP, DOWN, IDLE
4. ✅ Floor memory tracking current position and pending requests
5. ✅ Soft reset: clears FSM state only; retains current floor, direction, AND latched requests; timers reset
6. ✅ Hard reset: full system reset (floor→0, direction cleared, timers/counters reset)
7. ✅ HEX display: shows current floor
8. ✅ LED indicators: DOOR, DIR_UP, DIR_DOWN, IDLE, ESTOP
9. ✅ ESTOP: halts system until cleared
10. ✅ Modular hierarchy with explicit FSM

---

## Assumptions and Design Choices

### Assumptions
- The 50 MHz board clock is stable and available
- Physical switches/keys are debounced externally or by board circuitry
- Floor requests are edge-triggered and do not require hold time
- Single elevator car (no multi-car coordination)

### Design Choices
- **Moore FSM**: Outputs depend only on current state for predictable timing
- **Nearest-first idle policy**: When idle, choose closest pending request to minimize travel
- **Directional continuity**: Once moving, serve all requests in that direction first
- **Simple floor position model**: Floor increments/decrements on `travel_done` pulse
- **Single-cycle door close**: Simplified; can be extended with timer if needed

---

## Operational Behavior

### Normal Operation & Resets
1. System starts at floor 0 after hard reset
2. User presses floor request button → latched in `req_latch`
3. Scheduler determines target floor and direction
4. FSM transitions to MOVE_UP or MOVE_DOWN
5. Timer counts travel time; FSM monitors `travel_done`
6. Upon arrival, FSM enters ARRIVE → DOOR_OPEN
7. Door timer counts down; FSM waits for `door_done`
8. FSM enters DOOR_CLOSE, clears the serviced request, returns to IDLE
9. Scheduler checks for next request; cycle repeats
10. Soft reset at any time: request latch cleared; movement & timers unaffected; direction memory retained.
11. Hard reset at any time: all modules reinitialized (requests cleared, floor set to 0, direction cleared, timers zeroed).

#### Reset Behavior Summary
| Reset Type | Requests | Current Floor | Direction | Timers | Notes |
|-----------:|----------|---------------|-----------|--------|-------|
| Soft       | Retained | Retained      | Retained  | Reset  | FSM→IDLE, keeps position/requests/direction |
| Hard       | Cleared  | Set to 0      | Cleared   | Reset  | Full re-initialization |

### Edge Cases Handled
- **Request at current floor**: Immediately opens door (if idle)
- **Multiple requests**: Queued in request latch, served by scheduler policy
- **New request while moving**: Latched without disrupting current motion
- **Boundary floors**: Movement clamped to [0, N_FLOORS-1]
- **ESTOP during motion**: Immediate halt; position retained; cleared by reset
- **Reset during door cycle**: Aborts cycle cleanly

---

## Future Enhancements

See `limitations.md` for detailed discussion of:
- Capacity/overload sensor
- Hall vs. car call distinction
- Variable speed based on distance
- Multi-car coordination
- Predictive scheduling algorithms

---

## Conclusion

This elevator control system demonstrates a complete, modular VHDL design suitable for FPGA implementation. All mandatory requirements are satisfied with synthesizable, well-commented code and comprehensive testbenches. The parameterized architecture allows easy adaptation to different building configurations.

---

## References

- ENSC 252 Final Project Specification
- Intel DE10-Standard User Manual
- IEEE 1076-2008 VHDL Standard
