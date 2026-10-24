# Parts list

Draft for a **Raspberry Pi Zero 2 W** build. Prices are not filled in yet; check current listings before buying.

| # | Part | Purpose | Candidate | Price (CAD) | Link | Notes |
|---|---|---|---|---|---|---|
| 1 | Raspberry Pi | Logger computer | Raspberry Pi Zero 2 W (owned, no header) | owned | | |
| 1a | GPIO header | Connects the HAT to the Pi | 2×20 male pin header, 2.54 mm, soldered on (owner solders) | | | Chosen over a hammer header because it holds up better to vibration |
| 2 | microSD card | OS (read-only root) + log partition | 64 GB card (owned) | owned | | A high-endurance card is preferred; the read-only root limits wear either way |
| 3 | CAN HAT | HS-CAN interface | **PiCAN FD Zero with 1A SMPS** (SK Pang / Copperhill) | | [Copperhill](https://copperhilltech.com/pican-fd-zero-can-fd-hat-for-raspberry-pi-zero-with-1a-smps/) | MCP2518FD (mainline `mcp251xfd` driver), works on classic 500 kbit/s CAN. Onboard 6–20 V SMPS powers the Pi from 12 V. Single channel. |
| 3a | CAN HAT (budget alternative) | HS-CAN interface | Waveshare RS485 CAN HAT | | [Waveshare wiki](https://www.waveshare.com/wiki/RS485_CAN_HAT) | MCP2515 + 65HVD230, Zero-sized (65 × 30 mm). No 12 V input, so it needs a separate 12 V → 5 V supply. |
| 4 | OBD-II cable | OBD-II plug to HAT screw terminals | OBD-II male to open wires | | | Pins 6/14 HS-CAN, 5 signal ground. Pin 16 not used for power. MS-CAN (3/11) not wired in this build. |
| 5 | Switched power | +12 V only while the ignition is on | Add-a-circuit fuse tap + inline fuse | | | Match the fuse type in the Explorer's panel. Pick a fuse that is live only in RUN (check with a multimeter). Ground to a chassis point. |
| 5a | Ignition-off sense | Tells the Pi the 12 V feed dropped | Optocoupler (e.g. PC817) + resistor on the switched line → GPIO | | | Or use the hold-up module's power-fail output, if it has one |
| 6 | Hold-up | 10–20 s of power for a clean shutdown after ignition off | Supercap module on the 5 V rail | TBD | | Needs ~1.5 W for ~20 s. Must not back-feed the 12 V side. |
| 7 | Wi-Fi | Home sync / hotspot | Onboard (2.4 GHz only) | built in | | The home network must offer 2.4 GHz |
| 8 | Event button | Timestamp intermittent events | Panel-mount momentary button | | | One GPIO + ground |
| 9 | Accelerometer (optional) | Detect jolts | TBD (I²C, e.g. an LIS3DH or MPU-6050 breakout) | | | Later phase |
| 10 | Enclosure | Mounting, heat | Plastic case (owned) | owned | | Check that the Pi + HAT stack fits; see notes |
| 11 | USB OBD adapter | FORScan PID capture on a laptop; fallback interface | OBDLink EX | | | |

## Notes

### Why single-channel HS-CAN

The Zero 2 W only fits Zero-sized HATs, and the dual-channel boards are full Pi size. On the 2017 Explorer the PCM (which also runs the 6F50 transmission) and ABS are on HS-CAN, so every channel in the logging plan is reachable there. MS-CAN carries body and comfort modules and isn't needed for engine and drivetrain health.

### Power

Switched power, with sync at startup:

1. A fuse tap on a circuit that's live only in RUN feeds the PiCAN FD Zero's 6–20 V input. With the ignition off, the Pi has no power at all, so it can't drain the battery or keep modules awake. No timed cutoff or low-voltage cutoff is needed.
2. At startup (usually while the car warms up in the regular parking spot or on the street out front), the Pi joins home Wi-Fi if it's in range and uploads any trips not yet synced, while it logs the new trip.
3. When the ignition goes off, the opto input sees the 12 V feed drop. The Pi closes the trip file, writes the summary and shuts down on supercap power.

Sync is opportunistic. Files stay on the SD card until rclone confirms the upload, so a missed or interrupted sync just catches up on a later start. Data can arrive days late, which is fine for long-term trends.

Budget: boot ~20–30 s, Wi-Fi ~5–15 s, rclone ~5 s, upload a few seconds (about 430 KB for an hour of driving before compression).

### Heat

The Zero 2 W only runs while driving, so a parked, hot cabin doesn't matter while it's powered off. Keep the case out of direct sun and away from heater vents.
