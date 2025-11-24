import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:weatherapp/provider/weather_provider.dart';

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
          final currentTemp = _asDouble(data, [
            "weather",
            "current",
            "temperature_2m",
          ]);
          final maxTemp =
              _asListDouble(data, [
                "weather",
                "daily",
                "temperature_2m_max",
              ])?.firstOrNull;
          final minTemp =
              _asListDouble(data, [
                "weather",
                "daily",
                "temperature_2m_min",
              ])?.firstOrNull;

          // Hourly arrays (full lists from API)
          final hourlyTimesAll =
              _asListString(data, ["weather", "hourly", "time"]) ?? const [];
          final hourlyTempsAll =
              _asListDouble(data, ["weather", "hourly", "temperature_2m"]) ??
              const [];
          final hourlyCodesAll =
              _asListInt(data, ["weather", "hourly", "weathercode"]) ??
              const [];

          // Build a 24-hour window starting from now
          final now = DateTime.now();
          final startIndex = _indexOfClosestHour(hourlyTimesAll, now) ?? 0;
          final endIndex = (startIndex + 12).clamp(
            0,
            _min3(
              hourlyTimesAll.length,
              hourlyTempsAll.length,
              hourlyCodesAll.length,
            ),
          );

          final hourlyTimes = hourlyTimesAll.sublist(startIndex, endIndex);
          final hourlyTemps = hourlyTempsAll.sublist(startIndex, endIndex);
          final hourlyCodes = hourlyCodesAll.sublist(startIndex, endIndex);

          final dayLabel = "Today";
          final dateLabel = DateFormat("MMMM, d").format(now); // e.g., July, 21

          // For the header icon use current weathercode if available, else first hourly
          final currentCode =
              _asInt(data, ["weather", "current", "weathercode"]) ??
              (hourlyCodes.isNotEmpty ? hourlyCodes.first : null);
          final currentAsset = assetForWmoCode(
            currentCode ?? 0,
            isNight: isNightNow(now),
          );

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0B0D3B),
                  Color(0xFF3A1F87),
                  Color(0xFF8A2DD8),
                  Color(0xFFE45BD8),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
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
                        const SizedBox(height: 8),
                        // Weather icon (based on current weather)
                        Image.asset(currentAsset, height: 120),
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
                            color: Colors.white.withValues(alpha: 0.9),
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
                      hourlyTemps: hourlyTemps,
                      hourlyCodes: hourlyCodes,
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
  final List<int> hourlyCodes;

  const _ForecastCard({
    required this.leftTitle,
    required this.rightTitle,
    required this.hourlyTimes,
    required this.hourlyTemps,
    required this.hourlyCodes,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme);

    final count = _min3(
      hourlyTimes.length,
      hourlyTemps.length,
      hourlyCodes.length,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
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
          Divider(color: Colors.white.withValues(alpha: 0.25), height: 1),
          const SizedBox(height: 8),
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: count,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final iso = hourlyTimes[index];
                final temp = hourlyTemps[index];
                final code = hourlyCodes[index];

                final dt = DateTime.tryParse(iso) ?? DateTime.now();
                final timeLabel = DateFormat('HH:mm').format(dt);
                final asset = assetForWmoCode(code, isNight: isNightNow(dt));

                return _HourlyTile(
                  time: timeLabel,
                  temp: temp,
                  assetPath: asset,
                );
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
  final String assetPath;

  const _HourlyTile({
    required this.time,
    required this.temp,
    required this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme);

    return Container(
      width: 78,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
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
          Image.asset(assetPath, width: 28, height: 28),
          Text(
            time,
            style: textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
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
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.location_on_outlined, color: Colors.white),
          Icon(Icons.add_circle_outline_rounded, color: Colors.white),
          Icon(Icons.menu_rounded, color: Colors.white),
        ],
      ),
    );
  }
}

// Helpers

String _fmtDeg(double? v) => v == null ? "—°" : "${v.round()}°";

int _min(int a, int b) => a < b ? a : b;
int _min3(int a, int b, int c) => _min(_min(a, b), c);

// Find index of the hour in hourlyTimes that is >= now, fallback to closest past hour
int? _indexOfClosestHour(List<String> hourlyIso, DateTime now) {
  if (hourlyIso.isEmpty) return null;

  // Parse all once
  final dts = hourlyIso.map((s) => DateTime.tryParse(s)).toList();
  // Find first index >= now
  for (int i = 0; i < dts.length; i++) {
    final dt = dts[i];
    if (dt != null && !dt.isBefore(now)) {
      return i;
    }
  }
  // If none in future, find last past
  for (int i = dts.length - 1; i >= 0; i--) {
    final dt = dts[i];
    if (dt != null && !dt.isAfter(now)) {
      return i;
    }
  }
  return 0;
}

String _extractHour(String iso) {
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

// Weather code -> asset mapper (WMO)
String assetForWmoCode(int code, {bool isNight = false}) {
  final night = isNight ? "_night" : "_day";

  if ({0}.contains(code)) return "assets/icons/clear$night.png"; // Clear sky
  if ({1, 2}.contains(code)) return "assets/icons/partly_cloudy$night.png";
  if ({3}.contains(code)) return "assets/icons/cloudy$night.png";
  if ({45, 48}.contains(code)) return "assets/icons/fog$night.png";
  if ({51, 53, 55, 56, 57}.contains(code)) {
    return "assets/icons/drizzle$night.png";
  }
  if ({61, 63, 65}.contains(code)) return "assets/icons/rain$night.png";
  if ({66, 67}.contains(code)) return "assets/icons/freezing_rain$night.png";
  if ({71, 73, 75}.contains(code)) return "assets/icons/snow$night.png";
  if ({77}.contains(code)) return "assets/icons/snow_grains$night.png";
  if ({80, 81, 82}.contains(code)) return "assets/icons/rain_shower$night.png";
  if ({85, 86}.contains(code)) return "assets/icons/snow_shower$night.png";
  if ({95}.contains(code)) return "assets/icons/thunder$night.png";
  if ({96, 99}.contains(code)) return "assets/icons/thunder_hail$night.png";
  return "assets/icons/unknown$night.png";
}

bool isNightNow(DateTime dt, {int nightStartHour = 19, int nightEndHour = 6}) {
  final h = dt.hour;
  return h >= nightStartHour || h < nightEndHour;
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

int? _asInt(Map obj, List path) {
  dynamic cur = obj;
  for (final key in path) {
    if (cur is Map && cur.containsKey(key)) {
      cur = cur[key];
    } else {
      return null;
    }
  }
  if (cur is int) return cur;
  if (cur is num) return cur.toInt();
  if (cur is String) return int.tryParse(cur);
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

List<int>? _asListInt(Map obj, List path) {
  final list = _asList(obj, path);
  if (list == null) return null;
  return list
      .map((e) {
        if (e is int) return e;
        if (e is num) return e.toInt();
        if (e is String) return int.tryParse(e) ?? -999999;
        return -999999;
      })
      .where((e) => e != -999999)
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
