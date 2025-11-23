import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:weatherapp/Pages/forcast_page2.dart';
import 'package:weatherapp/provider/weather_provider.dart';
import 'package:weatherapp/weather.dart';

class CurrentWeatherPage extends ConsumerWidget {
  const CurrentWeatherPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider);

    final textTheme = GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: weatherAsync.when(
        data: (data) {
          // Defensive parsing
          double? currentTemp = _asDouble(data, [
            "weather",
            "current",
            "temperature_2m",
          ]);
          double? maxTemp =
              _asListDouble(data, [
                "weather",
                "daily",
                "temperature_2m_max",
              ])?.firstOrNull;
          double? minTemp =
              _asListDouble(data, [
                "weather",
                "daily",
                "temperature_2m_min",
              ])?.firstOrNull;
          final location = data["location"]?.toString() ?? "—";

          final hourlyTimes =
              _asListString(data, [
                "weather",
                "hourly",
                "time",
              ])?.take(25).toList() ??
              const [];
          final hourlyTemp =
              _asListDouble(data, [
                "weather",
                "hourly",
                "temperature_2m",
              ])?.take(25).toList() ??
              const [];

          // Formatted date
          final now = DateTime.now();
          final dayLabel = "Today";
          final dateLabel = DateFormat("MMMM, d").format(now); // e.g., July, 21

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0B0D3B), // deep navy blue
                  Color(0xFF3A1F87), // violet
                  Color(0xFF8A2DD8), // purple-pink mix
                  Color(0xFFE45BD8), // soft magenta near bottom
                ],
                begin: Alignment.topCenter,
                end: Alignment(-0.9, 1.7),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Top header illustration + temp block
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // Optional top bar (time/icons are part of OS; we keep spacing)
                        const SizedBox(height: 8),
                        // Weather icon
                        Image.asset(
                          'assets/images/weather_icon.png',
                          height: 120,
                        ),
                        const SizedBox(height: 12),
                        // Temperature
                        Text(
                          currentTemp != null
                              ? "${currentTemp.round()}°"
                              : "—°",
                          style: textTheme.displaySmall?.copyWith(
                            fontSize: 50,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Precipitations",
                          style: textTheme.titleMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Max: ${_fmtDeg(maxTemp)}   Min: ${_fmtDeg(minTemp)}",
                          style: textTheme.titleSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Middle illustration (house)
                        // Replace with your asset; using same as top for placeholder
                        Image.asset(
                          'assets/images/winter_house.png',
                          height: 150,
                        ),
                      ],
                    ),
                  ),

                  // Forecast card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _ForecastCard(
                      leftTitle: dayLabel,
                      rightTitle: dateLabel,
                      hourlyTimes: hourlyTimes,
                      hourlyTemps: hourlyTemp,
                    ),
                  ),

                  const Spacer(),

                  // Bottom pill bar (static visual placeholder)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: _BottomPillBar(),
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
                'Error: $err',
                style: const TextStyle(color: Colors.white),
              ),
            ),
      ),
    );
  }
}

// Forecast card with rounded corners and subtle borders
class _ForecastCard extends StatelessWidget {
  final String leftTitle;
  final String rightTitle;
  final List<String> hourlyTimes;
  final List<double> hourlyTemps;

  const _ForecastCard({
    required this.leftTitle,
    required this.rightTitle,
    required this.hourlyTimes,
    required this.hourlyTemps,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                leftTitle,
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                rightTitle,
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: Colors.white.withOpacity(0.25), height: 1),
          const SizedBox(height: 8),
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _min(hourlyTimes.length, hourlyTemps.length),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final t = _extractHour(hourlyTimes[index]);
                final temp = hourlyTemps[index];
                return _HourlyTile(time: t, temp: temp);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HourlyTile extends StatelessWidget {
  final String time;
  final double temp;

  const _HourlyTile({required this.time, required this.temp});

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme);

    return Container(
      width: 70,
      // decoration: BoxDecoration(
      //   color: Colors.white.withOpacity(0.15),
      //   borderRadius: BorderRadius.circular(16),
      // ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "${temp.round()}°C",
            style: textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          // Placeholder weather glyph (use your own asset or map by code)
          Icon(Icons.cloud, color: Colors.white, size: 24),
          Text(
            time,
            style: textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomPillBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.location_on_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ForecastPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ForecastPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Weather()),
              );
            },
          ),
        ],
      ),
    );
  }
}

// Helpers

String _fmtDeg(double? v) => v == null ? "—°" : "${v.round()}°";

int _min(int a, int b) => a < b ? a : b;

String _extractHour(String iso) {
  // Expecting "YYYY-MM-DDTHH:MM"
  if (iso.contains("T")) {
    final hhmm = iso.split("T").last;
    final parts = hhmm.split(":");
    if (parts.length >= 2) {
      return "${parts[0]}.${parts[1]}";
    }
    return hhmm;
  }
  return iso;
}

// Nested map safe getters
double? _asDouble(Map obj, List path) {
  dynamic cur = obj;
  for (final key in path) {
    if (cur is Map && cur.containsKey(key)) {
      cur = cur[key];
    } else {
      return null;
    }
  }
  if (cur is num) return cur.toDouble();
  if (cur is String) return double.tryParse(cur);
  return null;
}

List<double>? _asListDouble(Map obj, List path) {
  final list = _asList(obj, path);
  if (list == null) return null;
  return list
      .map((e) {
        if (e is num) return e.toDouble();
        if (e is String) return double.tryParse(e) ?? double.nan;
        return double.nan;
      })
      .where((e) => e.isFinite)
      .toList();
}

List<String>? _asListString(Map obj, List path) {
  final list = _asList(obj, path);
  if (list == null) return null;
  return list.map((e) => e.toString()).toList();
}

List? _asList(Map obj, List path) {
  dynamic cur = obj;
  for (final key in path) {
    if (cur is Map && cur.containsKey(key)) {
      cur = cur[key];
    } else {
      return null;
    }
  }
  return cur is List ? cur : null;
}

// Extension for null-safe first
extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
