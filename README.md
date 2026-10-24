# pi-can-logger

An always-on Raspberry Pi logger for a car's OBD-II / CAN bus, built for long-term health and maintenance tracking rather than performance tuning.

- Starts and stops with the ignition, and is safe for the car's battery.
- Logs every trip at a low rate, writes a per-trip summary, and keeps the raw data only for unusual trips.
- Reads standard OBD-II PIDs plus manufacturer extended PIDs over UDS. Ford is first: it was developed on a 2017 Explorer 3.5L.
- Syncs logs over Wi-Fi when the car is parked at home.

**Status:** planning. See [docs/parts-list.md](docs/parts-list.md).

## Safety

The logger only reads data. It never writes to modules, runs routines or changes diagnostic sessions. Use it at your own risk: you're connecting hardware to your car's network.
