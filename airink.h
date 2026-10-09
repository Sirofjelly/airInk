#pragma once

// Status logic for the airInk display: picks Chueli's mood and the
// Swiss German status line from the current SEN66 readings.

#include <cmath>
#include <cstdint>

#include "esphome/core/hal.h"

namespace airink {

// Thresholds. Comfort zone is 19–25 °C and 35–65 % relative humidity.
constexpr float PM25_SMOKE = 50.0f;        // µg/m³
constexpr float CO2_OPEN_WINDOW = 1400.0f; // ppm
constexpr float CO2_STUFFY = 1000.0f;      // ppm
constexpr float VOC_RACLETTE = 200.0f;     // index
constexpr float PM25_RACLETTE = 15.0f;     // µg/m³
constexpr float VOC_FART_MIN = 150.0f;     // index
constexpr float VOC_FART_JUMP = 100.0f;    // index rise within the window
constexpr uint32_t VOC_FART_WINDOW_MS = 5 * 60 * 1000;
constexpr float NOX_HIGH = 20.0f;          // index
constexpr float TEMP_HOT = 25.0f;          // °C
constexpr float TEMP_COLD = 19.0f;         // °C
constexpr float HUMID_HIGH = 65.0f;        // %
constexpr float HUMID_LOW = 35.0f;         // %

enum class Mood {
  Boot,
  Happy,
  Sleepy,
  Dizzy,
  Stink,
  Smoke,
  Raclette,
  Cough,
  Hot,
  Cold,
  Humid,
  Dry,
};

struct Status {
  Mood mood;
  const char *text;
  bool show_nox;  // footer shows NOx instead of VOC
};

// VOC samples from the last few minutes, used to spot sudden jumps.
// The SEN66 reports every 30 s, so 16 slots cover the 5 minute window.
struct VocSample {
  uint32_t at;
  float value;
};
inline VocSample voc_history[16];
inline uint8_t voc_next = 0;

inline void record_voc(float voc) {
  if (std::isnan(voc))
    return;
  voc_history[voc_next] = {esphome::millis(), voc};
  voc_next = (voc_next + 1) % 16;
}

inline bool voc_jumped(float voc) {
  if (std::isnan(voc) || voc < VOC_FART_MIN)
    return false;
  uint32_t now = esphome::millis();
  float lowest = voc;
  for (const auto &sample : voc_history) {
    if (sample.at != 0 && now - sample.at <= VOC_FART_WINDOW_MS && sample.value < lowest)
      lowest = sample.value;
  }
  return voc - lowest >= VOC_FART_JUMP;
}

inline bool above(float value, float limit) { return !std::isnan(value) && value > limit; }

// month is 1–12, hour 0–23; pass time_valid = false before SNTP has synced.
inline Status pick_status(float co2, float pm25, float voc, float nox, float temp, float humidity,
                          bool time_valid, int month, int hour, int minute) {
  if (std::isnan(co2) || std::isnan(temp) || std::isnan(humidity))
    return {Mood::Boot, "Chueli wacht uf…", false};

  bool winter_evening = time_valid && (month >= 11 || month <= 3) && hour >= 17 && hour <= 22;

  if (above(pm25, PM25_SMOKE))
    return {Mood::Smoke, "Brännt's öppe?", false};
  if (co2 > CO2_OPEN_WINDOW)
    return {Mood::Dizzy, "Fänschter uf!", false};
  // Raclette also makes VOC jump, so it is checked before the fart detector.
  if (winter_evening && above(voc, VOC_RACLETTE) && above(pm25, PM25_RACLETTE))
    return {Mood::Raclette, "Raclette-Ziit?", false};
  if (voc_jumped(voc))
    return {Mood::Stink, "Hesch gfurzt?", false};
  if (above(nox, NOX_HIGH))
    return {Mood::Cough, "Zürcherstrass!", true};
  if (co2 >= CO2_STUFFY)
    return {Mood::Sleepy, "Bitzeli stickig.", false};
  if (temp > TEMP_HOT)
    return {Mood::Hot, "Z'heiss.", false};
  if (temp < TEMP_COLD)
    return {Mood::Cold, "Pulli aalegge.", false};
  if (humidity > HUMID_HIGH)
    return {Mood::Humid, "Hallebad-Luft.", false};
  if (humidity < HUMID_LOW)
    return {Mood::Dry, "Wie i de Sahara.", false};

  // Rotate the good-air line every ten minutes so it stays fresh.
  static const char *const GOOD[] = {"Alles guet.", "Tiptop.", "Muuh-tastisch."};
  return {Mood::Happy, GOOD[time_valid ? (minute / 10) % 3 : 0], false};
}

}  // namespace airink
