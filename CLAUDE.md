# CLAUDE.md

An always-on Raspberry Pi data logger that plugs into a car's OBD-II port, logs engine and drivetrain health data on every trip, and syncs the logs over Wi-Fi when the car is parked at home. Built first for the owner's **2017 Ford Explorer** (3.5L Ti-VCT V6, AWD, 6F50 transmission), but meant to be published as a general project.

This repo will be public. Keep personal details (VIN, addresses, email, Wi-Fi or cloud credentials) out of every committed file.

The GitHub repo stays **private** until the logger works, then goes public. Git history becomes public too, so the same rules apply to every commit now. Build photos:
- Strip EXIF/GPS metadata before committing.
- Resize to about 1600 px on the long side.
- Check them for a VIN, licence plate, house or street, or a screen showing personal info.

## Status

- Planning stage. No code yet.
- Hardware owned: Raspberry Pi Zero 2 W (no header yet; the owner will solder on a 2×20 male header), 64 GB microSD, plastic case.
- Draft parts list in `docs/parts-list.md` (about CA$70–85): Waveshare RS485 CAN HAT (single-channel HS-CAN), Hammond 1591XXESFLBK box (the local shop), and a dash-cam hardwire kit on a switched fuse. No supercap. Sync at startup.
- First step is a cheapest-possible prototype (~CA$39): CAN HAT + header from a local electronics shop, CERRXIAN OBD-II cable from Amazon.ca, powered from a 12 V socket USB adapter, with no case. The case, hardwire kit and event button come later.
- No GitHub remote yet; the owner will create the repo later.

## To-do before ordering parts

- [x] (2026-10-24: boots, joins Wi-Fi, SSH works; the first boot is slow) Check that the Pi Zero 2 W works. Flash Raspberry Pi OS Lite (64-bit) with Raspberry Pi Imager, with Wi-Fi and SSH set up in the Imager's settings. Boot it from a USB power supply and log in over SSH. A mini-HDMI cable and a monitor are optional, useful if it doesn't show up on the network.
- [ ] Check the fuse size (Micro2 or mini) in the interior fuse panel.

## Design decisions (agreed 2026-10-24)

- **Connection:** a CAN HAT on the Pi (Waveshare RS485 CAN HAT, MCP2515, single channel; the upgrade path is the Waveshare 2-CH Isolated CAN HAT (MCP2515) if MS-CAN data is wanted), wired to the OBD-II port. HS-CAN is on pins 6/14; Ford's MS-CAN is on pins 3/11. It uses Linux SocketCAN with `python-can`, `can-isotp` and `udsoncan`. A laptop or phone with FORScan is optional, not part of the core plan.
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
- **Power (agreed 2026-10-24, kept simple):**
  - A dash-cam hardwire kit (≥2 A, micro-USB), tapped into a fuse that is live only in RUN, powers the Pi. OBD pin 16 is not used for power.
  - With the ignition off the Pi has no power, so it can't drain the battery or poll the bus. No timed or low-voltage cutoff is needed.
  - No ignition-sense optocoupler and no supercap hold-up module, to keep the project cheap. Trip files are flushed every few seconds, and unfinished trips are closed and summarized at the next boot.
- **Storage:** a read-only root filesystem (overlayfs), with logs on a separate partition or USB stick.
- **Sync:** opportunistic. Whenever home Wi-Fi is in range, `rclone` uploads unsynced CSVs to a Google Drive folder in the background while logging continues. In practice that's when the car is parked or warming up on the street out front: the regular parking spot has no Wi-Fi (survey 2026-10-24, see docs/pi-setup.md). Files stay local until the upload is confirmed. Data arriving days late is fine, because the goal is long-term trends, not daily stats. Claude reads the files from Drive for analysis. An optional Pi hotspot with a small web page allows downloads when away from home.
- **Analysis:** the per-trip summaries feed a Telemetry tab in the owner's maintenance Google Sheet, which lives outside this repo.

## Open questions

- FORScan (optional, decided 2026-10-24): only needed if community-list Ford PIDs can't be confirmed on the car, or to see which modules sit on MS-CAN only. Borrow or buy an adapter (~CA$40–85) plus an OBD Y-splitter then. Decide later whether MS-CAN is worth the 2-CH HAT upgrade.
- Which fuse to tap (live only in RUN) in the Explorer's panel, and its size (Micro2 or mini).
- The owned SD card is a standard 64 GB UHS-I U3 card, not high-endurance. If it corrupts, the fix is a high-endurance card and/or a supercap. Both are out of scope for now.
- Mounting: **under the driver's seat** (decided 2026-10-24 from the Wi-Fi survey: ~−75 dBm out front, connected without dropouts, closest to the OBD port). Raise the box off the carpet, leave cable slack for seat travel, keep clear of airbag/seat wiring. The enclosure is a Hammond 1591XXESFLBK (193 × 113 × 58 mm) from a local electronics shop; check it fits under the seat.
