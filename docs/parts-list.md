# Parts list

Draft for a **Raspberry Pi Zero 2 W** build. Prices were checked on 2026-10-24.
- "est." marks an estimate that hasn't been checked against a live listing.
- USD prices are converted at about 1.4 CAD per USD, before shipping and duty.

## To buy

| # | Part | Purpose | Candidate | Price (CAD) | Link | Notes |
|---|---|---|---|---|---|---|
| 1 | GPIO header | Connects the HAT to the Pi | 2×20 male pin header, 2.54 mm | ~2 (est.) | | Owner solders it on |
| 2 | CAN HAT | HS-CAN interface + 12 V → 5 V power | **PiCAN FD Zero with 1A SMPS** (SK Pang) | ~98 (US$69.95) | [Copperhill](https://copperhilltech.com/pican-fd-zero-can-fd-hat-for-raspberry-pi-zero-with-1a-smps/) | MCP2518FD, mainline `mcp251xfd` driver, 6–20 V input. A second Copperhill page lists US$84.95, so check at checkout. No Canadian stockist found. |
| 3 | Enclosure | Holds the Pi + one HAT | **UniPiCase Zero – Tall** | 11.95 | [PiShop.ca](https://www.pishop.ca/product-category/raspberry-pi/raspberry-pi-cases/model-zero-and-zero-w/) | Made in Canada. The tall lid leaves room for one HAT. A hole needs drilling for the PiCAN's screw-terminal wires. |
| 4 | OBD-II cable | OBD-II plug to the HAT's screw terminals | 16-pin J1962 male to open wire pigtail, 30–60 cm | ~15–20 (est.) | e.g. iKKEGOL on Amazon.ca | Check pin colours with a multimeter. Uses pins 6/14 (HS-CAN) and 5 (signal ground). |
| 5 | Fuse tap | +12 V only while the ignition is on | Add-a-circuit fuse tap, **Micro2** (likely; confirm) + 2 A fuse | ~10–15 (est.) | [Littelfuse FHM-series](https://littelfuse.com/products/fuse-blocks-fuseholders-and-fuse-accessories/specialty-items/add-a-circuit-mini-carded/fhm20200z.aspx) | Pull a fuse from the interior panel to confirm Micro2 vs. mini. Use a full-height tap, not low-profile. Ground to a chassis point. |
| 6 | Event button | Timestamp intermittent events | Panel-mount momentary button + 2-wire lead | ~5 (est.) | | One GPIO + ground |

**Total: about CA$145, plus shipping from Copperhill.**

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
| OBDLink EX + FORScan | Capture Ford PIDs on a laptop; fallback interface | Only if not already owned |
| High-endurance microSD, 32–64 GB (e.g. SanDisk High Endurance, Samsung PRO Endurance) | Better tolerance of power loss in the car | ~15–25 CAD (est.). Out of scope for now: buy it only if the current card corrupts. The current card then becomes the spare/dev card. |
| Hold-up module: Stubborn Balance Zero (AQEX) | Power for a clean shutdown | ~88 CAD (US$63), [Lectronz](https://lectronz.com/products/aqex-stubborn-balance-zero-ups-hat-rpi-zero-2-wh). Skipped for cost. Only add it if SD corruption shows up in practice. It's a second HAT, so it needs a deeper case. |

## Notes

### Why single-channel HS-CAN

The Zero 2 W only fits Zero-sized HATs, and the dual-channel boards are full Pi size. On the 2017 Explorer the PCM (which also runs the 6F50 transmission) and ABS are on HS-CAN, so every channel in the logging plan is reachable there. MS-CAN carries body and comfort modules and isn't needed for engine and drivetrain health.

### No hold-up module (decided 2026-10-24)

Skipped to keep the project cheap. The supercap modules for the Zero are HATs, so one would need a deeper case and add about CA$90. Instead, sudden power loss is made harmless in software:
- The root filesystem is read-only, so the OS can't be corrupted.
- Each trip is its own file, flushed to disk (`fsync`) every few seconds. Losing power loses at most the last few seconds of a trip.
- At the next boot, any trip left unfinished is closed and summarized.

The cost of skipping it is a small risk of SD-card corruption from losing power mid-write. If that happens in practice, add the hold-up module and a deeper case.

### Power

Switched power, with sync at startup:

1. A fuse tap on a circuit that's live only in RUN feeds the PiCAN FD Zero's 6–20 V input. With the ignition off, the Pi has no power at all, so it can't drain the battery or keep modules awake.
2. At startup (usually while the car warms up in the regular parking spot or on the street out front), the Pi joins home Wi-Fi if it's in range and uploads any trips not yet synced, while it logs the new trip.
3. When the ignition goes off, power is lost at once (no ignition sense or hold-up in v1), so the trip is closed and summarized at the next boot.

Sync is opportunistic. Files stay on the SD card until rclone confirms the upload, so a missed sync just catches up on a later start.

Budget: boot ~20–30 s, Wi-Fi ~5–15 s, rclone ~5 s, upload a few seconds (about 430 KB for an hour of driving before compression).

### Heat

The Pi only runs while the ignition is on, so a hot parked cabin doesn't matter while it's powered off. Keep the case out of direct sun and away from heater vents.
