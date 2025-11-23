class AqiHelper {
  /// Returns AQI category based on PM2.5 or PM10 value
  static Map<String, dynamic> getAqiCategory(
    double value, {
    String type = "pm2_5",
  }) {
    // PM2.5 breakpoints
    if (type == "pm2_5") {
      if (value <= 12) {
        return {"category": "Good", "color": 0xFF00E400};
      }
      if (value <= 35.4) {
        return {"category": "Moderate", "color": 0xFFFFFF00};
      }
      if (value <= 55.4) {
        return {
          "category": "Unhealthy for Sensitive Groups",
          "color": 0xFFFF7E00,
        };
      }
      if (value <= 150.4) {
        return {"category": "Unhealthy", "color": 0xFFFF0000};
      }
      if (value <= 250.4) {
        return {"category": "Very Unhealthy", "color": 0xFF99004C};
      }
      return {"category": "Hazardous", "color": 0xFF7E0023};
    }

    // PM10 breakpoints
    if (type == "pm10") {
      if (value <= 54) {
        return {"category": "Good", "color": 0xFF00E400};
      }
      if (value <= 154) {
        return {"category": "Moderate", "color": 0xFFFFFF00};
      }
      if (value <= 254) {
        return {
          "category": "Unhealthy for Sensitive Groups",
          "color": 0xFFFF7E00,
        };
      }
      if (value <= 354) {
        return {"category": "Unhealthy", "color": 0xFFFF0000};
      }
      if (value <= 424) {
        return {"category": "Very Unhealthy", "color": 0xFF99004C};
      }
      return {"category": "Hazardous", "color": 0xFF7E0023};
    }

    // Default fallback
    return {"category": "Unknown", "color": 0xFF808080};
  }
}
