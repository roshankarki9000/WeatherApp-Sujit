import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import 'package:weatherapp/services/api_helper.dart'; // Ensure this path is correct

// Define the FutureProvider which fetches and combines all weather data
final weatherProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // 1. Fetch Location
  // This step uses geocoding to set ApiHelper.lat, ApiHelper.lon, and ApiHelper.locationName.
  // This must be done first before building the API URLs.
  await ApiHelper.fetchLocation();

  // 2. Prepare API Futures (using the coordinates set above)
  final weatherFuture = ApiHelper.fetchWeather();
  final aqiFuture = ApiHelper.fetchAqi();

  // 3. Wait for both API calls to complete concurrently
  final List<Response> responses;
  try {
    responses = await Future.wait([weatherFuture, aqiFuture]);
  } on DioException catch (e) {
    // Handle network or API errors gracefully
    print('Dio Error: ${e.message}');
    // Throw a user-friendly exception to be handled by weatherAsync.error
    throw Exception(
      'Failed to load weather data. Please check your network connection.',
    );
  }

  final weatherData = responses[0].data;
  final aqiData = responses[1].data;

  // 4. Extract or Calculate AQI Category
  // OpenMeteo AQI gives raw values (pm2_5, pm10), not categories. We must calculate the categories
  // using a helper function to match the data structure expected by ForecastPage.dart.
  Map<String, dynamic> _calculateAqiCategory(Map<String, dynamic> aqiData) {
    // Safely attempt to get the first hourly PM2.5 and PM10 readings
    final pm25List = aqiData['hourly']?['pm2_5'] as List<dynamic>?;
    final pm10List = aqiData['hourly']?['pm10'] as List<dynamic>?;

    // Default to 'Good' if data is unavailable
    String pm25Category = "Good";
    String pm10Category = "Good";

    // --- Simulated Categorization Logic (Based on US EPA AQI) ---
    // This is a simple, non-scientific simulation to ensure the UI doesn't crash.
    // In a production app, you would use a more accurate library or endpoint.
    if (pm25List != null && pm25List.isNotEmpty && pm25List.first is num) {
      final pm25Value = (pm25List.first as num).toDouble();
      if (pm25Value > 150)
        pm25Category = "Unhealthy";
      else if (pm25Value > 50)
        pm25Category = "Moderate";
    }

    if (pm10List != null && pm10List.isNotEmpty && pm10List.first is num) {
      final pm10Value = (pm10List.first as num).toDouble();
      if (pm10Value > 250)
        pm10Category = "Unhealthy";
      else if (pm10Value > 50)
        pm10Category = "Moderate";
    }

    return {
      "pm25Category": {"category": pm25Category},
      "pm10Category": {"category": pm10Category},
    };
  }

  final aqiCategories = _calculateAqiCategory(aqiData);

  // 5. Combine all necessary data into a single map
  // This combined map is what the ForecastPage.dart is watching and consuming.
  return {
    // 1. Location name (from Geocoding)
    "locationName": ApiHelper.locationName,
    // 2. Weather data (contains daily and hourly forecasts)
    "weather": weatherData,
    // 3. AQI categories (Required for Air Quality Card)
    "pm25Category": aqiCategories["pm25Category"],
    "pm10Category": aqiCategories["pm10Category"],
    // You can optionally include the raw AQI data if needed elsewhere
    "aqi": aqiData,
  };
});
