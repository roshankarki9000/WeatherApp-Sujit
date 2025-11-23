import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'geolocator.dart'; // Assumes this file contains the getLocation function
import 'package:geocoding/geocoding.dart'; // NEW IMPORT

@immutable
class ApiHelper {
  static const weatherBaseUrl = "https://api.open-meteo.com/v1/forecast";
  static const airQualityBaseUrl =
      "https://air-quality-api.open-meteo.com/v1/air-quality";

  static final dio = Dio();

  static double lat = 0.0;
  static double lon = 0.0;
  // NEW STATIC VARIABLE to hold the location name
  static String locationName = "Loading...";

  // Fetch user location (Coordinates + Name)
  static Future<void> fetchLocation() async {
    final location = await getLocation();
    lat = location.latitude;
    lon = location.longitude;

    // NEW: Get the human-readable location name
    try {
      final placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        // Prioritize country, then locality, otherwise fallback
        locationName = place.country ?? place.locality ?? "Unknown Location";

        // Refine location name for better display (e.g., 'North America' style)
        if (place.locality != null && place.country != null) {
          locationName = "${place.locality}, ${place.country}";
        } else if (place.administrativeArea != null && place.country != null) {
          // Fallback to state/province if locality is missing
          locationName = "${place.administrativeArea}, ${place.country}";
        } else if (place.country != null) {
          locationName = place.country!;
        }
      }
    } catch (e) {
      locationName = "Location Error";
      print("Geocoding Error: $e");
    }
  }

  // ---------------- WEATHER URL ----------------
  static String buildWeatherUrl() {
    return "$weatherBaseUrl?"
        "latitude=$lat&longitude=$lon"
        // current
        "&current=temperature_2m,apparent_temperature,weathercode,uv_index,is_day"
        // HOURLY (We take next 24 hours manually)
        "&hourly=temperature_2m,weathercode,relative_humidity_2m,"
        "precipitation_probability,rain,cloud_cover,uv_index,apparent_temperature"
        // DAILY (7 days)
        "&daily=weathercode,temperature_2m_max,temperature_2m_min,"
        "sunrise,sunset,uv_index_max"
        // IMPORTANT → force full dataset
        "&forecast_days=7"
        "&timezone=auto";
  }

  static Future<Response> fetchWeather() async {
    return dio.get(buildWeatherUrl());
  }

  // ---------------- AQI URL ----------------
  static String buildAqiUrl() {
    return "$airQualityBaseUrl?"
        "latitude=$lat&longitude=$lon"
        "&hourly=pm10,pm2_5,carbon_monoxide,nitrogen_dioxide,"
        "sulphur_dioxide,ozone"
        "&timezone=auto";
  }

  static Future<Response> fetchAqi() async {
    return dio.get(buildAqiUrl());
  }
}
