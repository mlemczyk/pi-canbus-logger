# CLAUDE.md

An always-on Raspberry Pi data logger that plugs into a car's OBD-II port, logs engine and drivetrain health data on every trip, and syncs the logs over Wi-Fi when the car is parked at home. Built first for the owner's **2017 Ford Explorer** (3.5L Ti-VCT V6, AWD, 6F50 transmission), but meant to be published as a general project.

This repo will be public. Keep personal details (VIN, addresses, email, Wi-Fi or cloud credentials) out of every committed file.

## Status

- Planning stage. No code yet.
- Hardware owned: Raspberry Pi Zero 2 W (no header yet; the owner will solder on a 2×20 male header), 64 GB microSD, plastic case.
- Draft parts list in `docs/parts-list.md` (about CA$70–85): Waveshare RS485 CAN HAT (single-channel HS-CAN), UniPiCase Zero Tall, and a dash-cam hardwire kit on a switched fuse. No supercap. Sync at startup.
- First step is a cheapest-possible prototype (~CA$39): CAN HAT + header from a local electronics shop, CERRXIAN OBD-II cable from Amazon.ca, powered from a 12 V socket USB adapter, with no case. The case, hardwire kit and event button come later.
- No GitHub remote yet; the owner will create the repo later.

## To-do before ordering parts

- [x] (2026-10-24: boots, joins Wi-Fi, SSH works; the first boot is slow) Check that the Pi Zero 2 W works. Flash Raspberry Pi OS Lite (64-bit) with Raspberry Pi Imager, with Wi-Fi and SSH set up in the Imager's settings. Boot it from a USB power supply and log in over SSH. A mini-HDMI cable and a monitor are optional, useful if it doesn't show up on the network.
- [ ] Check the fuse size (Micro2 or mini) in the interior fuse panel.

## Design decisions (agreed 2026-10-24)

- **Connection:** a CAN HAT on the Pi (Waveshare RS485 CAN HAT, MCP2515, single channel; the upgrade path is the Waveshare 2-CH Isolated CAN FD HAT if MS-CAN data is wanted), wired to the OBD-II port. HS-CAN is on pins 6/14; Ford's MS-CAN is on pins 3/11. It uses Linux SocketCAN with `python-can`, `can-isotp` and `udsoncan`. A USB adapter (OBDLink EX / ELM327-class) is the fallback, and it's also used with FORScan on a laptop to capture Ford PIDs.
- **Data:** standard OBD-II mode 01/06, plus Ford extended PIDs over UDS service 0x22. The 0x22 IDs and scaling come from capturing FORScan's requests on the bus and from community lists, checked on the car. The logger only reads: no writes, routines or session changes.
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
- **Sync:** opportunistic, at startup. While the car warms up in the regular parking spot or on the street out front, `rclone` uploads unsynced CSVs to a Google Drive folder if home Wi-Fi is in range. Files stay local until the upload is confirmed. Data arriving days late is fine, because the goal is long-term trends, not daily stats. Claude reads the files from Drive for analysis. An optional Pi hotspot with a small web page allows downloads when away from home.
- **Analysis:** the per-trip summaries feed a Telemetry tab in the owner's maintenance Google Sheet, which lives outside this repo.

## Open questions

- Get an OBDLink EX (not owned, ~CA$85 est.) for FORScan: Ford PID capture and seeing which modules sit on MS-CAN only. Decide later whether MS-CAN is worth the 2-CH HAT upgrade.
- Which fuse to tap (live only in RUN) in the Explorer's panel, and its size (Micro2 or mini).
- Check that home Wi-Fi (2.4 GHz) reaches the regular parking spot and the street out front, from inside the car.
- The owned SD card is a standard 64 GB UHS-I U3 card, not high-endurance. If it corrupts, the fix is a high-endurance card and/or a supercap. Both are out of scope for now.
- Mounting location in the car (sets cable lengths). The enclosure is the UniPiCase Zero Tall, because the owner's plastic case doesn't fit a HAT.
