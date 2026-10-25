# Parts list

Draft for a **Raspberry Pi Zero 2 W** build. Prices were checked on 2026-10-24.
- "est." marks an estimate that hasn't been checked against a live listing.
- USD prices are converted at about 1.4 CAD per USD, before shipping and duty.

## To buy

| # | Part | Purpose | Candidate | Price (CAD) | Link | Notes |
|---|---|---|---|---|---|---|
| 1 | GPIO header | Connects the HAT to the Pi | 2×20 male pin header, 2.54 mm | ~2 (est.) | | Owner solders it on |
| 2 | CAN HAT | HS-CAN interface | **Waveshare RS485 CAN HAT** | 20.00 | a local electronics shop (local pickup, 5 in stock on 2026-10-24); or [PiShop.ca](https://www.pishop.ca/product/rs485-can-hat-for-raspberry-pi/) at 19.95 + shipping | Uses GPIO 8–11 (SPI0, CS = CE0), 25 (CAN interrupt), 14/15 (RS485 UART) and 4 (RS485 direction): keep the event button off these pins. Overlay: `mcp2515-can0` with `interrupt=25`. MCP2515 + SN65HVD230, Zero-sized (65 × 30 mm), 3.3 V. The RS485 side goes unused. Check the crystal (8 or 12 MHz) for the `mcp2515` overlay. Check whether a 120 Ω terminator is fitted: the car's bus is already terminated. |
| 3 | Enclosure | Holds the Pi + either HAT, cables, later the button | **Hammond 1591XXESFLBK** ABS box, black, flanged lid, 193 × 113 × 58 mm outside | 12.50 | a local electronics shop, 6 in stock on 2026-10-24 | Chosen 2026-10-24. Plastic, so Wi-Fi gets out. Plenty of room for the full-size 2-CH HAT too, but large: check it fits the mounting spot under the dash. The flanged lid has screw tabs for mounting. Add M2.5 nylon standoffs, a cable grommet and vent holes. Smaller option: UniPiCase Zero – Tall, CA$11.95 at [PiShop.ca](https://www.pishop.ca/product-category/raspberry-pi/raspberry-pi-cases/model-zero-and-zero-w/) (fits the Pi + RS485 HAT only). |
| 4 | OBD-II cable | OBD-II plug to the HAT's screw terminals | **CERRXIAN** 16-pin J1962 male to open pigtail, 1.5 m, all 16 pins wired | 16.99 | [Amazon.ca](https://www.amazon.ca/dp/B0CXHLG31Q) | Chosen for its length: the box can mount away from the OBD port. Listed pin map: 5 yellow, 6 green, 14 brown/white (still check with a multimeter). Not chosen: the local shop 30 cm cable (CA$10, out of stock on 2026-10-24). |
| 5 | Power | Switched +12 V → 5 V into the Pi's micro-USB power port | **EWAY dash-cam hardwire kit**, 2-wire, 12–24 V in, 5 V/2 A out, mini-USB plug + mini-to-micro adapter, fuse taps in all 4 sizes (LP mini, mini, ATO, Micro2) | 19.99 | [Amazon.ca](https://www.amazon.ca/dp/B0D54C6CK3) | 2 A is plenty (Pi Zero 2 W + HAT draw under 1 A). Having all four tap sizes means the fuse size doesn't need checking first. Secure the micro-USB adapter (heat-shrink or tape) against vibration. Tap a fuse that is live only in RUN; ground to a chassis point. Alternative: [3 A kit with micro + mini plugs](https://www.amazon.ca/dp/B07YBDMD8V), CA$23.99, 640 ratings, fuse tap types not listed. |
| 6 | Event button | Timestamp intermittent events | Panel-mount momentary button + 2-wire lead | ~5 (est.) | | One GPIO + ground |

**Full build total: about CA$70–85, all from Canadian sellers.**

### Prototype order (cheapest first step, decided 2026-10-24)

Buy only what's needed to read the car's CAN bus on the desk and in the car. The case (#3), power kit (#5) and event button (#6) wait until the prototype works.

| Part | Where | CAD |
|---|---|---|
| #2 RS485 CAN HAT | a local electronics shop (in store) | 20.00 |
| #1 2×20 male header, 2.54 mm | a local electronics shop (stock not checked) | ~2 (est.) |
| #4 CERRXIAN OBD-II cable, 1.5 m | Amazon.ca | 16.99 |
| **Total** | | **~39** |

Prototype power: a 12 V socket USB adapter, unplugged when the car is off (see "Testing setup" below). Run the Pi without a case: keep it off metal surfaces, for example in an anti-static bag or on a piece of cardboard.

## Already owned

| Part | Notes |
|---|---|
| Raspberry Pi Zero 2 W | No header yet. Onboard Wi-Fi is 2.4 GHz only. |
| 64 GB microSDXC, UHS-I U3 | A standard card, not high-endurance. Fine for development and a first build: the logger writes under 1 MB per driving hour. |
| Plastic case | Doesn't fit a HAT. Replaced by #3. |
| Soldering iron | |

## Later / optional

| Part | Purpose | Notes |
|---|---|---|
| Accelerometer (LIS3DH or MPU-6050 breakout, I²C) | Detect jolts | Later phase |
| FORScan adapter + OBD Y-splitter (optional) | One-time discovery of Ford PID names/scaling by sniffing FORScan; shows which modules sit on MS-CAN | Only if community-list PIDs can't be confirmed. Adapter ~CA$40–85 (e.g. [OBDLink EX](https://www.obdlink.com/products/obdlink-ex/), US$60), Y-splitter ~CA$15. A phone with FORScan Lite can replace the laptop. |
| Waveshare 2-CH Isolated CAN HAT (MCP2515 + SN65HVD230) | Upgrade: adds MS-CAN (TPMS, battery monitoring, cluster data) + isolation, TVS and ESD protection | CA$44.99, [Amazon.ca](https://www.amazon.ca/dp/B087RJ6XGG). Same driver and software as the RS485 HAT. Full-size HAT (65 × 56 mm), overhangs the Zero, so it needs a custom case. Both channels on SPI0 (interrupts likely GPIO 23/25, 16 MHz crystal: confirm on the board). The CAN FD version (CA$65.80, PiShop.ca) isn't needed: the car uses classic CAN. |
| High-endurance microSD, 32–64 GB (e.g. SanDisk High Endurance, Samsung PRO Endurance) | Better tolerance of power loss in the car | ~15–25 CAD (est.). Out of scope for now: buy it only if the current card corrupts. The current card then becomes the spare/dev card. |
| Hold-up module: Stubborn Balance Zero (AQEX) | Power for a clean shutdown | ~88 CAD (US$63), [Lectronz](https://lectronz.com/products/aqex-stubborn-balance-zero-ups-hat-rpi-zero-2-wh). Skipped for cost. Only add it if SD corruption shows up in practice. It's a second HAT, so it needs a deeper case. |

## Notes

### Why single-channel HS-CAN

The single-channel RS485 CAN HAT is Zero-sized and cheap. Dual-channel boards are full Pi size and cost over twice as much. On the 2017 Explorer the PCM (which also runs the 6F50 transmission) and ABS are on HS-CAN, so every channel in the logging plan is reachable there. MS-CAN carries body and comfort modules and isn't needed for engine and drivetrain health. It could add TPMS and battery-monitor data, but on these Fords some modules bridge both buses, so that data may be on HS-CAN too. Check before upgrading: a FORScan module list, or a Pi with the 2-CH HAT listening on MS-CAN, shows what's there.

### No hold-up module (decided 2026-10-24)

Skipped to keep the project cheap. The supercap modules for the Zero are HATs, so one would need a deeper case and add about CA$90. Instead, sudden power loss is made harmless in software:
- The root filesystem is read-only, so the OS can't be corrupted.
- Each trip is its own file, flushed to disk (`fsync`) every few seconds. Losing power loses at most the last few seconds of a trip.
- At the next boot, any trip left unfinished is closed and summarized.

The cost of skipping it is a small risk of SD-card corruption from losing power mid-write. If that happens in practice, add the hold-up module and a deeper case.

### Power

Switched power, with sync at startup:

1. A dash-cam hardwire kit, tapped into a fuse that's live only in RUN, feeds 5 V to the Pi's micro-USB power port. With the ignition off, the Pi has no power at all, so it can't drain the battery or keep modules awake.
2. At startup (usually while the car warms up in the regular parking spot or on the street out front), the Pi joins home Wi-Fi if it's in range and uploads any trips not yet synced, while it logs the new trip.
3. When the ignition goes off, power is lost at once (no ignition sense or hold-up in v1), so the trip is closed and summarized at the next boot.

Sync is opportunistic. Files stay on the SD card until rclone confirms the upload, so a missed sync just catches up on a later start.

Budget: boot ~20–30 s, Wi-Fi ~5–15 s, rclone ~5 s, upload a few seconds (about 430 KB for an hour of driving before compression).

### Testing setup (before the fuse tap)

For first tests, power the Pi from a 12 V socket USB adapter (≥2.4 A port) with a micro-USB cable, and unplug it when the car is turned off. This defers part #5 and brings the first order down to about CA$55–60.
- Before the read-only root is set up, shut down from SSH (`sudo shutdown now`) before unplugging, to protect the SD card.
- Some 12 V sockets stay live after the ignition is off. The logger stops polling when the CAN bus goes quiet, so a forgotten Pi won't keep modules awake, but it will still draw a little power.

### Heat

The Pi only runs while the ignition is on, so a hot parked cabin doesn't matter while it's powered off. Keep the case out of direct sun and away from heater vents.
