import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'geolocator.dart';

@immutable
class ApiHelper {
  static const weatherBaseUrl = "https://api.open-meteo.com/v1/forecast";
  static const airQualityBaseUrl =
      "https://air-quality-api.open-meteo.com/v1/air-quality";
  static const reverseGeocodeUrl =
      "https://geocoding-api.open-meteo.com/v1/reverse";

  static final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );

  static double lat = 0.0;
  static double lon = 0.0;
  static String locationName = "Loading...";
  static bool _locationFetched = false;

  /// Fetch device location and resolve city name
  static Future<void> fetchLocation() async {
    if (_locationFetched) return;

    try {
      print("Fetching GPS coordinates...");
      final location = await getLocation();
      lat = location.latitude;
      lon = location.longitude;
      print("Coordinates: lat=$lat, lon=$lon");

      // --- OPEN-METEO REVERSE GEOCODER ---
      try {
        final response = await dio.get(
          reverseGeocodeUrl,
          queryParameters: {"latitude": lat, "longitude": lon, "count": 1},
        );

        final results = response.data['results'];
        if (results != null && results.isNotEmpty) {
          final first = results[0];

          final city = first['name'];
          final admin1 = first['admin1'];
          final admin2 = first['admin2'];
          final country = first['country'];

          locationName =
              city ?? admin2 ?? admin1 ?? country ?? "Unknown Location";

          print("Resolved location: $locationName");
        } else {
          print("Open-Meteo returned empty results.");
        }
      } catch (e) {
        print("Open-Meteo geocode failed: $e");
      }

      // --- FALLBACK GEOCODER (NEVER RETURNS EMPTY) ---
      if (locationName == "Unknown Location" ||
          locationName == "Loading..." ||
          locationName.isEmpty) {
        try {
          print("Trying fallback reverse-geocoding...");

          final fallbackResponse = await dio.get(
            "https://api.bigdatacloud.net/data/reverse-geocode-client",
            queryParameters: {
              "latitude": lat,
              "longitude": lon,
              "localityLanguage": "en",
            },
          );

          final city = fallbackResponse.data["city"];
          final locality = fallbackResponse.data["locality"];
          final subdivision = fallbackResponse.data["principalSubdivision"];
          final country = fallbackResponse.data["countryName"];

          locationName =
              city ?? locality ?? subdivision ?? country ?? "Unknown Location";

          print("Fallback resolved location: $locationName");
        } catch (e) {
          print("Fallback geocoder failed: $e");
        }
      }
    } catch (e) {
      locationName = "Unknown Location";
      print("Error fetching location: $e");
    }

    _locationFetched = true;
  }

  static String buildWeatherUrl() {
    return "$weatherBaseUrl?"
        "latitude=$lat&longitude=$lon"
        "&current=temperature_2m,apparent_temperature,weathercode,uv_index,is_day"
        "&hourly=temperature_2m,weathercode,relative_humidity_2m,"
        "precipitation_probability,rain,cloud_cover,uv_index,apparent_temperature"
        "&daily=weathercode,temperature_2m_max,temperature_2m_min,"
        "sunrise,sunset,uv_index_max"
        "&forecast_days=7"
        "&timezone=auto";
  }

  static Future<Response> fetchWeather() => dio.get(buildWeatherUrl());

  static String buildAqiUrl() {
    return "$airQualityBaseUrl?"
        "latitude=$lat&longitude=$lon"
        "&hourly=pm10,pm2_5,carbon_monoxide,nitrogen_dioxide,"
        "sulphur_dioxide,ozone"
        "&timezone=auto";
  }

  static Future<Response> fetchAqi() => dio.get(buildAqiUrl());
}
