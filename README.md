# airInk

A compact ESPHome air-quality monitor built with a Sensirion SEN66, a Seeed Studio XIAO ESP32-C3, and a 1.54-inch black-and-white e-paper display.

The 200×200 interface uses an inverted, two-column dashboard for horizontal mounting and exposes all measurements to Home Assistant.

## Features

- Temperature and relative humidity
- CO₂ concentration
- VOC and NOx indices
- PM1.0, PM2.5, PM4.0, and PM10
- Offline display operation after boot
- Happy/sad air-quality indicator
- Home Assistant native API
- USB logging and ESPHome OTA updates
- Periodic full refresh to limit e-paper ghosting

## Hardware

- Sensirion SEN66
- Seeed Studio XIAO ESP32-C3
- Waveshare-compatible 1.54-inch, 200×200 black-and-white e-paper module

The display configuration currently targets ESPHome's `1.54inv2` model.

## Wiring

| XIAO pin | GPIO | SEN66 | E-paper |
|---|---:|---|---|
| D4 | 6 | SDA | — |
| D5 | 7 | SCL | — |
| D8 | 8 | — | CLK/SCL |
| D10 | 10 | — | DIN/SDA |
| D2 | 4 | — | RST/RES |
| D1 | 3 | — | DC |
| D0 | 2 | — | CS |
| D7 | 20 | — | BUSY |
| 3V3 | — | VDD | VCC |
| GND | — | GND | GND |

On the display, `SCL` and `SDA` are SPI clock and data labels; they are not an I²C bus.

Use 3.3 V power and logic. Add 4.7–10 kΩ pull-ups from SEN66 SDA and SCL to 3.3 V if they are not already present on your cable or breakout. GPIO2 and GPIO8 are ESP32-C3 strapping pins, so attached hardware must not force them to an invalid level during boot.

## Build and install

Install ESPHome in a Python virtual environment:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install esphome
```

Create your local secrets file:

```bash
cp secrets.example.yaml secrets.yaml
```

Edit `secrets.yaml`, then validate and install:

```bash
esphome config sen66-air-monitor.yaml
esphome run sen66-air-monitor.yaml
```

For the first USB installation, put the XIAO into its bootloader if necessary by holding **BOOT** while connecting USB.

## Configuration

- Change `rotation: 90` to `rotation: 270` if the display is upside down in your enclosure.
- Change `timezone: Europe/Zurich` to your local timezone.
- If an older display is used, try `model: 1.54in` instead of `1.54inv2`.
- If a newer e-paper driver board does not reset correctly, try adding `reset_duration: 2ms` under `display:`.

The display refreshes once per minute and performs a full refresh every ten updates.

## Design credit

The visual direction is inspired by [AQAIO](https://github.com/w4ilun/aqaio). airInk uses ESPHome's native SEN6x and Waveshare e-paper components rather than the AQAIO custom component.

## License

[MIT](LICENSE)
