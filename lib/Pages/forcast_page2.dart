// file: forecast_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:weatherapp/provider/weather_provider.dart';
import 'package:weatherapp/weather.dart';

List _getNestedList(Map data, List<String> path) {
  dynamic current = data;
  for (final key in path) {
    if (current is Map && current.containsKey(key)) {
      current = current[key];
    } else {
      return [];
    }
  }
  return current is List ? current : [];
}

String getWeatherIcon(int code) {
  if (code >= 60 && code <= 69) return '🌧️';
  if (code >= 70 && code <= 79) return '🌨️';
  if (code >= 95) return '🌩️';
  if (code >= 3) return '☁️';
  if (code >= 1 && code <= 2) return '🌤️';
  return '☀️';
}

String getAirQualityRiskText(String pm25Category, String pm10Category) {
  const Map<String, int> categoryPriority = {
    "Hazardous": 6,
    "Very Unhealthy": 5,
    "Unhealthy": 4,
    "Unhealthy for Sensitive Groups": 3,
    "Moderate": 2,
    "Good": 1,
  };
  final pm25Priority = categoryPriority[pm25Category] ?? 0;
  final pm10Priority = categoryPriority[pm10Category] ?? 0;
  final maxPriority = pm25Priority > pm10Priority ? pm25Priority : pm10Priority;

  switch (maxPriority) {
    case 6:
      return "6-Severe Health Risk";
    case 5:
      return "5-Very High Health Risk";
    case 4:
      return "4-High Health Risk";
    case 3:
      return "3-Low Health Risk";
    case 2:
      return "2-Minimal Health Risk";
    case 1:
      return "1-Excellent Air Quality";
    default:
      return "— Air Quality Unavailable";
  }
}

String getUVIndexDescription(double uvIndex) {
  if (uvIndex < 3) return "Low";
  if (uvIndex < 6) return "Moderate";
  if (uvIndex < 8) return "High";
  if (uvIndex < 11) return "Very High";
  return "Extreme";
}

extension FirstOrNullExtension on List {
  dynamic get firstOrNull => isNotEmpty ? first : null;
}

class ForecastPage extends ConsumerWidget {
  const ForecastPage({super.key});

  String getDayOfWeek(int index) {
    final date = DateTime.now().add(Duration(days: index));
    return DateFormat('E').format(date);
  }

  String _fmtDeg(num? v) => v == null ? "—°" : "${v.round()}°";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider);

    const Gradient backgroundGradient = LinearGradient(
      colors: [
        Color(0xFF0B0D3B),
        Color(0xFF3A1F87),
        Color(0xFF8A2DD8),
        Color(0xFFE45BD8),
      ],
      begin: Alignment.topCenter,
      end: Alignment(-0.9, 1.7),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: backgroundGradient),
        child: weatherAsync.when(
          data: (data) {
            // 7-day forecast lists
            final sevenDayMax =
                _getNestedList(data, [
                  "weather",
                  "daily",
                  "temperature_2m_max",
                ]).map((e) => (e as num).toInt()).toList();
            final sevenDayMin =
                _getNestedList(data, [
                  "weather",
                  "daily",
                  "temperature_2m_min",
                ]).map((e) => (e as num).toInt()).toList();
            final sevenDayWeatherCodes =
                _getNestedList(data, [
                  "weather",
                  "daily",
                  "weathercode",
                ]).map((e) => (e as num).toInt()).toList();

            // Sunrise, sunset, UV index
            final sunriseRaw =
                _getNestedList(data, [
                  "weather",
                  "daily",
                  "sunrise",
                ]).firstOrNull;
            final sunsetRaw =
                _getNestedList(data, [
                  "weather",
                  "daily",
                  "sunset",
                ]).firstOrNull;
            final uvIndexRaw =
                _getNestedList(data, [
                  "weather",
                  "daily",
                  "uv_index_max",
                ]).firstOrNull;

            final sunriseTime = sunriseRaw?.toString().split("T")[1] ?? "—";
            final sunsetTime = sunsetRaw?.toString().split("T")[1] ?? "—";
            final double uvIndex =
                uvIndexRaw is num ? uvIndexRaw.toDouble() : 0.0;

            // AQI categories
            final pm25Category =
                (data["pm25Category"] as Map?)?["category"] ?? "Unknown";
            final pm10Category =
                (data["pm10Category"] as Map?)?["category"] ?? "Unknown";
            final airQualityRisk = getAirQualityRiskText(
              pm25Category,
              pm10Category,
            );

            // Location
            final dynamicLocation =
                data["locationName"] as String? ?? "Unknown";

            // Today’s max/min temp
            final locationMaxTemp = sevenDayMax.firstOrNull ?? 24;
            final locationMinTemp = sevenDayMin.firstOrNull ?? 18;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLocationHeader(
                      dynamicLocation,
                      locationMaxTemp,
                      locationMinTemp,
                      context,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "7-Days Forecast",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Forecast list fills remaining height
                    Expanded(
                      child: _buildForecastList(
                        context,
                        sevenDayMax,
                        sevenDayMin,
                        sevenDayWeatherCodes,
                      ),
                    ),
                    const SizedBox(height: 25),
                    _buildAirQualityCard(airQualityRisk),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            title: "SUNRISE",
                            mainText: sunriseTime,
                            subText: "Sunset: $sunsetTime",
                            icon: Icons.wb_sunny_outlined,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildInfoCard(
                            title: "UV INDEX",
                            mainText:
                                uvIndex == 0.0
                                    ? "—"
                                    : uvIndex.toInt().toString(),
                            subText:
                                uvIndex == 0.0
                                    ? "Unavailable"
                                    : getUVIndexDescription(uvIndex),
                            icon: Icons.filter_vintage_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 50),
                    Center(
                      child: IconButton(
                        icon: const Icon(
                          Icons.menu_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Weather()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading:
              () => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
          error:
              (err, stack) => Center(
                child: Text(
                  "Error: $err",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildLocationHeader(
    String location,
    int maxTemp,
    int minTemp,
    BuildContext context,
  ) {
    return Column(
      children: [
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                location,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          "Max: ${_fmtDeg(maxTemp)}   Min: ${_fmtDeg(minTemp)}",
          style:
              Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ) ??
              TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
              ),
        ),
      ],
    );
  }

  Widget _buildForecastList(
    BuildContext context,
    List<int> maxTemps,
    List<int> minTemps,
    List<int> weatherCodes,
  ) {
    final int itemCount = [
      maxTemps.length,
      minTemps.length,
      weatherCodes.length,
      7,
    ].reduce((a, b) => a < b ? a : b);

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final day = index == 0 ? "Today" : getDayOfWeek(index);

        final maxTemp = maxTemps[index];
        final minTemp = minTemps[index];
        final icon = getWeatherIcon(weatherCodes[index]);
        final bool isActive = index == 0;
        final double opacity = isActive ? 1.0 : 0.7;

        return Container(
          width: 80,
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color:
                isActive
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                icon,
                style: TextStyle(
                  fontSize: 28,
                  color: Colors.white.withValues(alpha: opacity),
                ),
              ),
              Text(
                "$maxTemp° / $minTemp°",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: opacity),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                day,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: opacity * 0.8),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAirQualityCard(String riskText) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.wb_twilight_outlined, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Text(
                "AIR QUALITY",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                riskText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Row(
                children: [
                  Text(
                    "See more",
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  SizedBox(width: 5),
                  Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String mainText,
    required String subText,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            mainText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subText,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
