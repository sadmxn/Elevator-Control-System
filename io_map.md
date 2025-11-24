# I/O Mapping for Intel DE10-Standard Board

This document maps logical signals in the VHDL design to physical board resources.

---

## Clock Input

| Signal      | Board Resource    | Pin Name   | Description           |
|-------------|-------------------|------------|-----------------------|
| `CLOCK_50`  | 50 MHz oscillator | `PIN_AF14` | Main system clock     |

---

## Reset and Control Inputs

| Signal       | Board Resource | Pin       | Active | Description                       |
|--------------|----------------|-----------|--------|-----------------------------------|
| hard_reset   | KEY[0]         | `PIN_AJ4` | LOW    | Full system reset (floor\u21920)      |
| soft_reset   | KEY[1]         | `PIN_AK4` | LOW    | Clears requests only              |
| estop        | SW[9]          | `PIN_AA30`| HIGH   | Emergency stop                    |

**Note**: Keys inverted in top-level: `hard_reset <= NOT KEY(0)`

---

## Floor Request Inputs

| Signal          | Board Resource | Pins                                   | Description                   |
|-----------------|----------------|----------------------------------------|-------------------------------|
| `req_in(3..0)`  | SW[3:0]        | `PIN_AC30, PIN_AB28, PIN_Y27, PIN_AB30`| Direct floor request (4 bits) |

- Each switch corresponds to one floor (0-3 internal, displayed as 1-4)
- Switch held high latches request until serviced
- Immediate feedback on LEDR(3..0)

---

## HEX Display Outputs

| Signal      | Board Resource | Pins          | Description                         |
|-------------|----------------|---------------|-------------------------------------|
| `HEX0`      | HEX0           | `HEX0[6:0]`   | Current floor (shows 1-4)           |
| `HEX1`      | HEX1           | `HEX1[6:0]`   | Blank                               |
| `HEX2`      | HEX2           | `HEX2[6:0]`   | Status messages (rightmost letter)  |
| `HEX3`      | HEX3           | `HEX3[6:0]`   | Status messages                     |
| `HEX4`      | HEX4           | `HEX4[6:0]`   | Status messages                     |
| `HEX5`      | HEX5           | `HEX5[6:0]`   | Status messages (leftmost letter)   |

**Messages** (HEX5-2, priority order):
1. ESTOP active → **"ESTOP"**
2. Door open → **"OPEN"**
3. Door closing → **"CLOSE"**
4. Moving up → **"UP"** (HEX5-4 only)
5. Moving down → **"down"**
6. Otherwise → **"IdLE"**

**Encoding**: Active-low 7-segment (standard DE10).

---

## LED Status Outputs

### Normal Operation (estop_active='0')

| Signal            | Board Resource | Pin        | Description                  |
|-------------------|----------------|------------|------------------------------|
| `req_lat(0)`      | LEDR[0]        | `PIN_AA24` | Floor 1 requested            |
| `req_lat(1)`      | LEDR[1]        | `PIN_AB23` | Floor 2 requested            |
| `req_lat(2)`      | LEDR[2]        | `PIN_AC23` | Floor 3 requested            |
| `req_lat(3)`      | LEDR[3]        | `PIN_AD24` | Floor 4 requested            |
| `LEDR[4]`         | LEDR[4]        | `PIN_AG25` | Unused (0)                   |
| `dir_down`        | LEDR[5]        | `PIN_AF25` | Moving down indicator        |
| `dir_up`          | LEDR[6]        | `PIN_AE24` | Moving up indicator          |
| `door_closing`    | LEDR[7]        | `PIN_AF24` | Door closing indicator       |
| `door_open`       | LEDR[8]        | `PIN_AB22` | Door open indicator          |
| `estop_active`    | LEDR[9]        | `PIN_AC22` | ESTOP off (0)                |

### Emergency Stop (estop_active='1')

| Signal      | Board Resource  | State       | Description               |
|-------------|-----------------|-------------|---------------------------|
| `LEDR[9:0]` | All red LEDs    | ALL ON      | Visual emergency warning  |

---

## Summary Table

| Category       | Inputs         | Outputs           |
|----------------|----------------|-------------------|
| Control        | 3 (2 KEY, 1 SW)| —                 |
| Requests       | 4 (SW[3:0])    | —                 |
| Status LEDs    | —              | 10 (LEDR)         |
| Display        | —              | 6 HEX digits      |
| **Total**      | **7**          | **16**            |

DE10-Standard resources used efficiently with room for extensions.

---

## Pin Assignment Example (Quartus .qsf)

```tcl
# Clock
set_location_assignment PIN_AF14 -to CLOCK_50

# Resets and ESTOP
set_location_assignment PIN_AA14 -to KEY[0]
set_location_assignment PIN_AA15 -to KEY[1]
set_location_assignment PIN_AB12 -to SW[9]

# Floor Request Switches
set_location_assignment PIN_AB13 -to SW[0]
set_location_assignment PIN_AC12 -to SW[1]
set_location_assignment PIN_AF9  -to SW[2]
set_location_assignment PIN_AF10 -to SW[3]

# HEX Displays (example for HEX0, repeat for HEX1-5)
set_location_assignment PIN_AE26 -to HEX0[0]
set_location_assignment PIN_AE27 -to HEX0[1]
# ... (6 more per display)

# LEDs
set_location_assignment PIN_AA24 -to LEDR[0]
set_location_assignment PIN_AB23 -to LEDR[1]
# ... (8 more)
```

**Warning**: Verify pin assignments against DE10-Standard User Manual.

---

## Clock Input

| Signal         | Board Resource      | Pin Name       | Description                  |
|----------------|---------------------|----------------|------------------------------|
| `clk_50mhz`    | 50 MHz oscillator   | `CLOCK_50`     | Main system clock            |

---

## Reset and Control Inputs

| Signal         | Board Resource      | Suggested Pin   | Description                           |
|----------------|---------------------|-----------------|---------------------------------------|
| `hard_reset`   | KEY[0]              | `PIN_AJ4`       | Active low; full system reset         |
| `soft_reset`   | KEY[1]              | `PIN_AK4`       | Active low; clears requests only      |
| `estop`        | SW[9]               | `PIN_AA30`      | Emergency stop (active high)          |

**Note**: KEY buttons on DE10 are active low; invert in top-level or constraints.

---

## Floor Request Inputs

The design requires a floor number and valid strobe. Two implementation options:

### Option A: Binary Encoding + Strobe Button

| Signal            | Board Resource      | Suggested Pins     | Description                          |
|-------------------|---------------------|--------------------|--------------------------------------|
| `new_req_floor`   | SW[1:0]             | `SW[1]`, `SW[0]`   | 2-bit floor number (0-3 for 4 floors)|
| `new_req_valid`   | KEY[2]              | `KEY[2]`           | Strobe to latch request (active low) |

- User sets floor number on switches SW[1:0]
- Presses KEY[2] to submit request

### Option B: One Button Per Floor

| Signal            | Board Resource      | Suggested Pins                | Description                   |
|-------------------|---------------------|-------------------------------|-------------------------------|
| Floor 0 request   | KEY[2]              | `KEY[2]`                      | Request floor 0 (active low)  |
| Floor 1 request   | SW[0]               | `SW[0]`                       | Request floor 1 (active high) |
| Floor 2 request   | SW[1]               | `SW[1]`                       | Request floor 2 (active high) |
| Floor 3 request   | SW[2]               | `SW[2]`                       | Request floor 3 (active high) |

- Requires input multiplexing logic in top-level wrapper
- More intuitive user interface

**Recommended**: Option A for simplicity; Option B for better UX.

---

## HEX Display Output

| Signal         | Board Resource      | Pins               | Description                          |
|----------------|---------------------|--------------------|--------------------------------------|
| `hex_floor`    | HEX0                | `HEX0[6:0]`        | 7-segment display for current floor  |

**Encoding**: Active-low 7-segment (standard DE10 configuration).

Segments: `gfedcba` (bit 6 = g, bit 0 = a).

Additional HEX displays (HEX1-HEX5) can show:
- Target floor
- Request queue status
- FSM state (for debugging)

---

## LED Status Outputs

| Signal         | Board Resource      | Suggested Pin  | Description                          |
|----------------|---------------------|----------------|--------------------------------------|
| `led_dir_up`   | LEDR[0]             | `LEDR[0]`      | Moving upward indicator              |
| `led_dir_down` | LEDR[1]             | `LEDR[1]`      | Moving downward indicator            |
| `led_idle`     | LEDR[2]             | `LEDR[2]`      | Idle (no motion) indicator           |
| `led_door`     | LEDR[3]             | `LEDR[3]`      | Door open indicator                  |
| `led_estop`    | LEDR[9]             | `LEDR[9]`      | Emergency stop active (red LED)      |
| `led_full`     | LEDR[8]             | `LEDR[8]`      | Capacity full (optional extension)   |

**Note**: LEDR[9] chosen for ESTOP for visibility (rightmost red LED).

Remaining LEDs (LEDR[7:4]) available for:
- Request queue visualization (one LED per floor)
- FSM state indicators
- Debug signals

---

## Example Pin Assignment Snippet (Quartus .qsf)

```tcl
# Clock
set_location_assignment PIN_AF14 -to clk_50mhz

# Resets and Control
set_location_assignment PIN_AA14 -to hard_reset
set_location_assignment PIN_AA15 -to soft_reset
set_location_assignment PIN_AB12 -to estop

# Floor Request (Option A)
set_location_assignment PIN_AB13 -to new_req_floor[0]
set_location_assignment PIN_AC12 -to new_req_floor[1]
set_location_assignment PIN_Y16  -to new_req_valid

# HEX Display
set_location_assignment PIN_AE26 -to hex_floor[0]
set_location_assignment PIN_AE27 -to hex_floor[1]
set_location_assignment PIN_AE28 -to hex_floor[2]
set_location_assignment PIN_AG27 -to hex_floor[3]
set_location_assignment PIN_AF28 -to hex_floor[4]
set_location_assignment PIN_AG28 -to hex_floor[5]
set_location_assignment PIN_AH28 -to hex_floor[6]

# LEDs
set_location_assignment PIN_AA24 -to led_dir_up
set_location_assignment PIN_AB23 -to led_dir_down
set_location_assignment PIN_AC23 -to led_idle
set_location_assignment PIN_AD24 -to led_door
set_location_assignment PIN_AB22 -to led_estop
set_location_assignment PIN_AC22 -to led_full
```

**Warning**: Above pins are examples; verify against DE10-Standard User Manual for correct assignments.

---

## Additional Considerations

### Debouncing
- KEY buttons and switches may require debouncing
- Implement in hardware or use slow 1 Hz tick as implicit debounce

### Active Low Conversion
- KEY buttons are active low; invert before use or adjust logic
- Example: `hard_reset_n <= not KEY[0];`

### Multi-Floor Extension
- For N_FLOORS > 4, expand switch encoding or use external keypad
- BCD encoding supports up to 10 floors with 4 switches

### Visual Feedback
- Use green LEDs for normal operation (dir, idle)
- Use red LED for ESTOP
- Use yellow/orange LED for door (if available)

---

## Summary Table

| Category       | Inputs        | Outputs           |
|----------------|---------------|-------------------|
| Control        | 3 (resets, estop) | —             |
| Requests       | 3 (floor + valid) | —             |
| Status         | —             | 6 LEDs            |
| Display        | —             | 1 HEX digit       |
| **Total**      | **6**         | **7**             |

DE10-Standard provides ample resources:
- 10 switches (SW[9:0])
- 4 pushbuttons (KEY[3:0])
- 10 red LEDs (LEDR[9:0])
- 6 HEX displays (HEX5-HEX0)

Design easily fits with room for extensions.


