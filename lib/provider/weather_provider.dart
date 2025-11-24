import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:weatherapp/services/api_helper.dart';

final weatherProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  await ApiHelper.fetchLocation();

  final weatherFuture = ApiHelper.fetchWeather();
  final aqiFuture = ApiHelper.fetchAqi();

  final List<Response> responses;
  try {
    responses = await Future.wait([weatherFuture, aqiFuture]);
  } on DioException catch (e) {
    print('Dio Error: ${e.message}');
    throw Exception('Failed to load weather data. Check network.');
  }

  final weatherData = responses[0].data;
  final aqiData = responses[1].data;

  // AQI categories simulation
  Map<String, dynamic> calculateAqiCategory(Map<String, dynamic> aqiData) {
    final pm25List = aqiData['hourly']?['pm2_5'] as List<dynamic>?;
    final pm10List = aqiData['hourly']?['pm10'] as List<dynamic>?;

    String pm25Category = "Good";
    String pm10Category = "Good";

    if (pm25List != null && pm25List.isNotEmpty && pm25List.first is num) {
      final pm25Value = (pm25List.first as num).toDouble();
      if (pm25Value > 150) {
        pm25Category = "Unhealthy";
      } else if (pm25Value > 50)
        pm25Category = "Moderate";
    }

    if (pm10List != null && pm10List.isNotEmpty && pm10List.first is num) {
      final pm10Value = (pm10List.first as num).toDouble();
      if (pm10Value > 250) {
        pm10Category = "Unhealthy";
      } else if (pm10Value > 50)
        pm10Category = "Moderate";
    }

    return {
      "pm25Category": {"category": pm25Category},
      "pm10Category": {"category": pm10Category},
    };
  }

  final aqiCategories = calculateAqiCategory(aqiData);

  return {
    "locationName": ApiHelper.locationName,
    "weather": weatherData,
    "pm25Category": aqiCategories["pm25Category"],
    "pm10Category": aqiCategories["pm10Category"],
    "aqi": aqiData,
  };
});
