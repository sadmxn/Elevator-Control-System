# System Limitations and Future Improvements

This document identifies current constraints and proposes enhancements for future iterations.

---

## Current Limitations

### 1. Single Elevator Car
**Limitation**: Design assumes one elevator serving all floors.

**Impact**: 
- Cannot handle multiple simultaneous requests efficiently
- Wait times increase linearly with floor count and request frequency

**Mitigation**: Scheduler policy minimizes unnecessary travel, but scalability is limited.

---

### 2. No Capacity/Overload Detection
**Limitation**: System does not track passenger count or weight.

**Impact**:
- Cannot prevent overloading
- No "car full" indicator to skip pickups
- Safety and comfort compromised in high-traffic scenarios

**Current State**: `led_full` output exists but hardwired to `'0'`.

---

### 3. Uniform Request Priority
**Limitation**: All floor requests treated equally; no distinction between:
- Hall calls (outside elevator) vs. car calls (inside)
- Priority floors (e.g., lobby, emergency evacuation)
- Time-critical requests (e.g., emergency services)

**Impact**:
- Lobby requests may wait excessively if elevator is busy on upper floors
- No emergency override mechanism beyond ESTOP

---

### 4. Fixed Travel Speed
**Limitation**: Travel time per floor is constant regardless of distance.

**Impact**:
- Inefficient for long trips (e.g., floor 0 → floor 10 could use acceleration)
- Realistic elevators accelerate for multi-floor trips

---

### 5. Simplified Floor Position Model
**Limitation**: Floor counter increments/decrements discretely on `travel_done` pulse.

**Impact**:
- No intermediate position tracking (between floors)
- Cannot implement safety features like "emergency stop between floors"
- Door cannot be prevented from opening mid-travel (though FSM logic prevents this)

---

### 6. No Debouncing Logic
**Limitation**: Assumes external debouncing for switches/buttons.

**Impact**:
- Spurious requests possible if board inputs bounce
- May require additional external circuitry or manual care

---

### 7. Single HEX Display
**Limitation**: Only current floor shown; target floor and request queue invisible.

**Impact**:
- Limited user feedback
- Harder to debug on hardware without LEDs

**Note**: DE10 has 6 HEX displays; only 1 currently used.

---

### 8. No Fault Handling
**Limitation**: No provisions for:
- Motor failure detection
- Door obstruction sensors
- Timeout recovery (elevator stuck between floors)

**Impact**:
- Simulation/hardware may require manual reset if FSM enters unexpected state
- Real-world deployment would require watchdog timers

---

## Proposed Future Improvements

### High Priority

#### 1. Capacity Model and Overload Sensor
**Implementation**:
- Add `capacity_model.vhd` module with configurable max passenger count
- Input: passenger enter/exit signals (could simulate with switches)
- Output: `full` signal → FSM skips hall calls when full
- Integration: Wire `full` to `led_full` output

**Benefit**: Realistic load management, improved service quality.

---

#### 2. Hall vs. Car Call Distinction
**Implementation**:
- Separate input ports: `hall_call_up`, `hall_call_down`, `car_call`
- Scheduler prioritizes car calls over hall calls in same direction
- Requires two request latches or multi-dimensional request vector

**Benefit**: Matches real elevator behavior, improves passenger experience.

---

#### 3. Variable Speed / Acceleration Model
**Implementation**:
- Add `variable_speed.vhd` module
- Generic: `ACCEL_TIME`, `MAX_SPEED`, `DECEL_TIME`
- Calculate travel time based on distance: short trips = constant speed, long trips = accel + cruise + decel
- Output: dynamic `travel_time` to replace fixed `TRAVEL_TIME_PER_FLOOR`

**Benefit**: Higher efficiency, more realistic operation.

---

### Medium Priority

#### 4. Predictive Scheduling
**Enhancement**: Upgrade scheduler to anticipate future requests.
- Algorithm: Look-ahead policy (e.g., predict lobby rush hour)
- Machine learning (overkill for FPGA but interesting academic extension)

**Benefit**: Reduced average wait time.

---

#### 5. Multi-Car Coordination
**Implementation**:
- Replicate top-level module N times (one per car)
- Add arbiter module to assign requests to least-busy car
- Shared request latch with per-car claim mechanism

**Benefit**: Scalable to large buildings.

---

#### 6. Enhanced Display
**Implementation**:
- Use HEX1 for target floor
- Use HEX2-HEX5 for request queue visualization (one digit per pending floor)
- Use remaining LEDs for detailed state info (one LED per FSM state)

**Benefit**: Better visibility during testing and demo.

---

### Low Priority

#### 7. Door Obstruction Sensor
**Implementation**:
- Add input: `door_blocked`
- Timer restarts if obstruction detected during `DOOR_CLOSE`
- Timeout after N retries → fault state

**Benefit**: Safety improvement.

---

#### 8. Energy Optimization Mode
**Implementation**:
- Add "sleep" mode when idle for >X seconds (turn off lights, reduce clock frequency)
- Wake on first request
- Generic: `SLEEP_TIMEOUT`

**Benefit**: Power savings (relevant for low-power FPGAs or battery operation).

---

#### 9. Audible Indicators
**Implementation**:
- Use buzzer/speaker on DE10 (if available)
- Tone patterns: arrival chime, door closing warning, error beep

**Benefit**: Accessibility, realism.

---

## Testing and Validation Needs

Current testbenches cover module-level functionality but lack:
- **System-level integration test**: Full `top_elevator` testbench with multiple requests
- **Stress testing**: Rapid-fire requests, boundary conditions, max floor count
- **Randomized testing**: Constrained-random stimulus with coverage tracking
- **Hardware validation**: On-board testing with physical I/O

**Recommendation**: Add `tb_top_elevator.vhd` with comprehensive scenarios.

---

## Synthesis and Resource Utilization

Not yet measured. Future work should include:
- Quartus synthesis report analysis
- FPGA resource usage (LEs, registers, memory)
- Timing analysis (max frequency, slack)
- Power estimation

---

## Documentation Gaps

- No formal timing diagrams for FSM transitions
- No detailed simulation waveforms included in `docs/waveforms/`
- No user manual for hardware operation

**Action Items**:
- Generate and export waveforms from ModelSim/Questa
- Create quick-start guide for DE10 board setup
- Add Quartus project files and build instructions

---

## Conclusion

The current design meets all mandatory requirements and provides a solid foundation. The limitations are intentional simplifications appropriate for a course project. Future enhancements can transform this into a production-grade elevator controller suitable for deployment or further research.

**Priority Ranking for Extensions**:
1. Capacity model (most impactful, moderate effort)
2. Variable speed (high realism gain)
3. Hall/car call distinction (better UX)
4. Multi-car (advanced, requires significant rework)
