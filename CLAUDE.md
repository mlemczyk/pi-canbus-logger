# CLAUDE.md

An always-on Raspberry Pi data logger that plugs into a car's OBD-II port, logs engine and drivetrain health data on every trip, and syncs the logs over Wi-Fi when the car is parked at home. Built first for the owner's **2017 Ford Explorer** (3.5L Ti-VCT V6, AWD, 6F50 transmission), but meant to be published as a general project.

This repo is public. Keep personal details (VIN, addresses, email, Wi-Fi or cloud credentials) out of every committed file.

The GitHub repo went **public** on 2026-10-28 as a work in progress, with a note at the top of the README. Every commit and its history is public, so the same rules apply to every commit. Build photos:
- Strip EXIF/GPS metadata before committing.
- Resize to about 1600 px on the long side.
- Check them for a VIN, licence plate, house or street, or a screen showing personal info.

## Status

- Pi prepared, no logger code yet (2026-10-24):
  - Raspberry Pi Zero 2 W: slimmed, CAN tools and Python libraries installed, SPI on, key-based SSH.
  - rclone to Google Drive tested.
  - Config backed up outside the repo.
  - Wi-Fi survey done. See `docs/pi-setup.md`.
- **Next step: the owner is saving up to order the first parts** (~CA$101 + tax, list in `docs/parts-list.md` → "First order"):
  - 2-CH Isolated CAN HAT, OBD-II cable and hardwire kit from Amazon.ca
  - Male header, box and standoffs from a local electronics shop
- Then: solder the male header to the Pi and the HAT's stacking socket to the HAT, enable the `mcp2515` overlays (check the HAT's crystal and interrupt pins), and run a first `candump` in the car.
- Hardware owned: Pi Zero 2 W (no header yet; the owner will solder a 2×20 male header), 64 GB microSD, an old plastic case (doesn't fit a HAT).
  - Also from the owner's Arduino parts (found 2026-10-26, chips not yet confirmed): a ZS-042 RTC (DS3231) and a GY-521 accelerometer/gyro (MPU-6050). Both go on I²C. Wiring and setup are in `docs/parts-list.md` → "Clock and accelerometer (I²C)".
- GitHub: [mlemczyk/pi-canbus-logger](https://github.com/mlemczyk/pi-canbus-logger), created 2026-10-24, **public** since 2026-10-28. The local folder is named `pi-can-logger`.

## To-do before ordering parts

- [x] (2026-10-24: boots, joins Wi-Fi, SSH works; the first boot is slow) Check that the Pi Zero 2 W works.
- [x] Fuse size no longer blocks the order: the EWAY hardwire kit includes taps in all four sizes. Still find a fuse that's live only in RUN before installing.

## To-do once telemetry works

- [ ] (added 2026-10-28) **Driving score per driver.** A web page or a tab in the maintenance Google Sheet showing an aggregate "driving score". The owner says which days they drove, to tell the two household drivers apart, and Claude correlates those days with the trip summaries.
  - Score parts: fuel economy, and smoothness of acceleration, braking and turning. More can be added later.
  - Keep the day-to-driver list out of this public repo, for example in the Sheet.
  - Needs, decided before the logger code is written, because raw trip files are usually not kept:
    - A fuel-flow channel for economy: MAF (PID 0x10) or engine fuel rate (PID 0x5E, if the PCM supports it), with distance from speed.
    - Smoothness numbers in the per-trip summary: harsh acceleration and braking counts (from speed change and the MPU-6050's longitudinal axis), lateral-g peaks and counts from the MPU-6050 for turning, and idle time.
    - Normalize per km or per hour, and compare like with like (city vs. highway, cold vs. warm start), so a short winter trip doesn't look like bad driving.
- [ ] (added 2026-10-28) **RTC health check.** At each boot, read the DS3231's oscillator-stop flag (OSF) and log it. When Wi-Fi connects, log the RTC's drift against NTP in the sync log. A set OSF flag or a big jump means the coin cell is dead and needs replacing.

## Design decisions (agreed 2026-10-24)

- **Connection:** a CAN HAT on the Pi, wired to the OBD-II port: the Waveshare 2-CH Isolated CAN HAT (2× MCP2515, isolated, TVS/ESD protection).
  - Changed 2026-10-26 from the single-channel RS485 CAN HAT, for its pass-through pins (for I²C), protection and a free MS-CAN channel.
  - Stack: plain 2×20 male header soldered to the Pi; the HAT's included stacking socket soldered to the HAT; screwed together with all four standoffs.
  - Solder the I²C wires to the long pin tips above the HAT, because loose Dupont jumpers can work free with vibration. See `docs/parts-list.md` → "Header stack and vibration".
  - Set both 120R jumpers to OFF and the VIO jumper to 3V3. HS-CAN is on pins 6/14; Ford's MS-CAN is on pins 3/11. It uses Linux SocketCAN with `python-can`, `can-isotp` and `udsoncan`. A laptop or phone with FORScan is optional, not part of the core plan.
- **Data:** standard OBD-II mode 01/06, plus Ford extended PIDs over UDS service 0x22.
  - Standard PIDs need no discovery: RPM, speed, load, throttle, coolant, fuel trims, module voltage, mode 06 misfire counts.
  - The Ford-only channels (transmission temperature, cam timing desired/actual, knock, battery state of charge, fan duty) take their 0x22 IDs and scaling from community lists, each checked on the car with sanity tests.
  - A read-only 0x22 ID scan from the Pi can show which IDs the PCM supports.
  - FORScan is optional: only if some channels stay unconfirmed, for one session sniffing its requests with `candump` through an OBD Y-splitter.
  - The logger only reads: no writes, routines or session changes.
- **Logging strategy: automatic but thin.**
  - Every trip is logged at 1 Hz on 10 to 15 channels.
  - The Pi writes a one-line summary per trip.
  - The raw trip file is kept only when a threshold is crossed or the event button is pressed.
  - Channels:
    - coolant temperature
    - transmission fluid temperature
    - long-term and short-term fuel trims per bank
    - misfire counts per cylinder
    - Ti-VCT cam timing, desired vs. actual
    - knock
    - charging voltage and battery state of charge
    - RPM, speed, load, throttle
    - fan duty, if available
- **Event button:** a GPIO button, optionally with an accelerometer, to timestamp intermittent events (for example a driveline "klunk") for later correlation.
  - The accelerometer is the owned MPU-6050 (GY-521) on I²C. Its INT pin can flag jolts on a free GPIO, for example GPIO17.
- **Clock (added 2026-10-26):** a DS3231 RTC (the owned ZS-042 board) on I²C, so timestamps are right on cold starts with no Wi-Fi, such as where the car is usually parked. The Pi has no clock of its own, and with the read-only root, fake-hwclock can't save the time.
  - Setup: `dtoverlay=i2c-rtc,ds3231`, remove `fake-hwclock`, then run `hwclock -w` once the Pi has synced over NTP.
  - Remove the ZS-042's charging resistor, then fit a non-rechargeable cell: a CR2032, or a heat-rated BR2032 (about −30 to +85 °C) if one is easy to find. Not a LIR2032: at 3.3 V, after the diode drop, the board can't charge it.
  - No bigger rechargeable pack (decided 2026-10-28). The DS3231 draws only ~1–3 µA from its cell, about 10–25 mAh a year, so a ~220 mAh coin cell lasts several years even with heat. A LiPo would need a charger and protection board, can't be charged safely above ~45 °C, and is a fire risk in a hot parked car. Replace the coin cell only when the logger reports it's low or the clock lost time.
- **I²C bus:** shared by both boards, on 3.3 V only. The DS3231 and the MPU-6050 both default to 0x68, so tie the MPU's AD0 to 3.3 V to move it to 0x69. Expected addresses: 0x57 (EEPROM), 0x68 (RTC), 0x69 (MPU). Keep INT and the button off the HAT's pins (GPIO 7–11, plus its interrupts, likely 23 and 25).
- **Power (agreed 2026-10-24, kept simple):**
  - A dash-cam hardwire kit (≥2 A, micro-USB), tapped into a fuse that is live only in RUN, powers the Pi. OBD pin 16 is not used for power.
  - With the ignition off the Pi has no power, so it can't drain the battery or poll the bus. No timed or low-voltage cutoff is needed.
  - No ignition-sense optocoupler and no supercap hold-up module, to keep the project cheap. Trip files are flushed every few seconds, and unfinished trips are closed and summarized at the next boot.
- **Storage:** a read-only root filesystem (overlayfs), with logs on a separate partition or USB stick.
- **Sync:** opportunistic. Whenever home Wi-Fi is in range, `rclone` uploads unsynced CSVs to a Google Drive folder in the background while logging continues. Files stay local until the upload is confirmed. Data arriving days late is fine, because the goal is long-term trends, not daily stats. Claude reads the files from Drive for analysis. An optional Pi hotspot with a small web page allows downloads when away from home.
  - **Where:** only on the street out front. The car's usual parking spot has no Wi-Fi (survey 2026-10-24, see `docs/pi-setup.md`). Under the driver's seat out front gets ~−75 dBm with no dropouts.
  - **When:** the car stops out front about 3 times a week. The Pi is already running from the drive, so it only needs ~20 s to rejoin Wi-Fi plus a few seconds to upload: **~30 s with the ignition on after stopping**. A cold start out front needs ~1 min, because boot adds ~35 s. Passing the usual parking spot is too brief.
  - **Logger requirements:**
    - Start a sync the moment Wi-Fi connects; don't wait for the trip to end.
    - Uploads cut off by the ignition must be safe to retry. Drive discards partial uploads, and local files stay until confirmed.
    - Write a sync log line per attempt (time, signal dBm, success/fail, files and bytes sent), uploaded with the data.
  - **Review after ~2 weeks of driving.** If uploads keep missing, add the phone hotspot as a second, lower-priority network (the owner types its password on the Pi), so uploads also happen while driving. Other fallbacks: a Wi-Fi extender at a street-facing window, or a USB Wi-Fi adapter with its antenna up near the windshield.
- **Analysis:** the per-trip summaries feed a Telemetry tab in the owner's maintenance Google Sheet, which lives outside this repo.

## Open questions

- FORScan (optional, decided 2026-10-24): only needed if community-list Ford PIDs can't be confirmed on the car, or to see which modules sit on MS-CAN only. Borrow or buy an adapter (~CA$40–85) plus an OBD Y-splitter then. The 2-CH HAT can listen on MS-CAN directly.
- Which fuse to tap (live only in RUN) in the Explorer's panel. The kit has all four tap sizes.
- The owned SD card is a standard 64 GB UHS-I U3 card, not high-endurance. If it corrupts, the fix is a high-endurance card and/or a supercap. Both are out of scope for now.
- Mounting: **under the driver's seat** (decided 2026-10-24 from the Wi-Fi survey: ~−75 dBm out front, connected without dropouts, closest to the OBD port). Raise the box off the carpet, leave cable slack for seat travel, keep clear of airbag/seat wiring. The enclosure is a Hammond 1591XXESFLBK (193 × 113 × 58 mm) from a local electronics shop; check it fits under the seat.
