# airInk

A compact ESPHome air-quality monitor built with a Sensirion SEN66, a Seeed Studio XIAO ESP32-C3, and a 1.54-inch black-and-white e-paper display.

The 200×200 black-on-white screen is made to be read from a desk at 30–40 cm. Chueli the cow shows how the air feels, with a status line in Swiss German, and all measurements are exposed to Home Assistant.

## Features

- Big CO₂, temperature, and humidity readings in Atkinson Hyperlegible Next
- Chueli the cow, with one face per air-quality status
- PM2.5 and VOC in the footer; NOx appears there when it is the reason for the status
- PM1.0, PM4.0, PM10, and NOx sent to Home Assistant
- Offline display operation after boot
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

## Statuses

Only one status is shown at a time; the first matching row wins. The thresholds live at the top of [`airink.h`](airink.h).

| Status | When | Chueli |
|---|---|---|
| Chueli wacht uf… | sensor still warming up | snoozing |
| Brännt's öppe? | PM2.5 above 50 µg/m³ | wide-eyed, smoke clouds |
| Fänschter uf! | CO₂ above 1400 ppm | dizzy, bell ringing |
| Raclette-Ziit? | VOC above 200 and PM2.5 above 15 on a November–March evening | licking her lips |
| Hesch gfurzt? | VOC rises by 100 or more within 5 minutes | squinting, stink lines |
| Zürcherstrass! | NOx index above 20 | coughing |
| Bitzeli stickig. | CO₂ 1000–1400 ppm | yawning |
| Z'heiss. | above 25 °C | sweating |
| Pulli aalegge. | below 19 °C | scarf, shivering |
| Hallebad-Luft. | humidity above 65 % | water drops |
| Wie i de Sahara. | humidity below 35 % | tongue out, sun |
| Alles guet. / Tiptop. / Muuh-tastisch. | everything fine (rotates every ten minutes) | happy |

## Chueli images

The faces in `images/chueli/` are generated as 1-bit PNGs from the drawings in [`tools/make_chueli.py`](tools/make_chueli.py). After changing a drawing, regenerate them with:

```bash
brew install librsvg
python tools/make_chueli.py
```

The script needs Pillow, which is already installed in the ESPHome virtual environment.

## Configuration

- Change `rotation: 90` to `rotation: 270` if the display is upside down in your enclosure.
- Change `timezone: Europe/Zurich` to your local timezone.
- If an older display is used, try `model: 1.54in` instead of `1.54inv2`.
- Tune the comfort zone and the other status thresholds in [`airink.h`](airink.h).

The display refreshes once per minute and performs a full refresh every ten updates.

The e-paper RST line is held high by an internal switch instead of being given to the display as `reset_pin`. With `reset_pin`, ESPHome resets the panel before every update, which erases the previous frame that partial refreshes compare against, so old text stays visible under the new one.

## Case

A 3D-printable mini Mac case lives in [case/](case/README.md), with an OpenSCAD source and ready-to-print STL files.

## Design credit

The original dashboard was inspired by [AQAIO](https://github.com/w4ilun/aqaio). airInk uses ESPHome's native SEN6x and Waveshare e-paper components rather than the AQAIO custom component.

## License

[MIT](LICENSE)
