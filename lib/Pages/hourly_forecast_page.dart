// file: hourly_forecast_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class HourlyForecastPage extends StatelessWidget {
  final String location;
  final List<String> hourlyTimes;
  final List<double> hourlyTemps;

  const HourlyForecastPage({
    super.key,
    required this.location,
    required this.hourlyTimes,
    required this.hourlyTemps,
  });

  // Helper function to extract time and date
  String _formatTime(String iso) {
    try {
      final date = DateTime.parse(iso);
      // Format to "10:00 AM"
      return DateFormat('h:mm a').format(date);
    } catch (e) {
      return '—';
    }
  }

  String _formatDate(String iso) {
    try {
      final date = DateTime.parse(iso);
      // Format to "Wed, Nov 23"
      return DateFormat('EEE, MMM d').format(date);
    } catch (e) {
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme);

    // Determine the number of hours to display, limited by the shortest list (max 25)
    final int itemCount = _min(hourlyTimes.length, hourlyTemps.length);

    // Background Gradient (Same as CurrentWeatherPage for consistency)
    const Gradient backgroundGradient = LinearGradient(
      colors: [
        Color(0xFF0B0D3B),
        Color(0xFF3A1F87),
        Color(0xFF8A2DD8),
        Color(0xFFE45BD8),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "24-Hour Forecast",
          style: textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: backgroundGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 16),
                child: Text(
                  location,
                  style: textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    final timeIso = hourlyTimes[index];
                    final temp = hourlyTemps[index];

                    // Determine if it's a new day
                    final bool isNewDay =
                        index > 0 &&
                        _formatDate(timeIso) !=
                            _formatDate(hourlyTimes[index - 1]);

                    return Column(
                      children: [
                        if (index == 0 || isNewDay)
                          _buildDaySeparator(
                            textTheme,
                            _formatDate(timeIso),
                            index == 0,
                          ),
                        _buildHourlyItem(
                          textTheme,
                          _formatTime(timeIso),
                          "${temp.round()}°C",
                          // Placeholder icon and description for the demo
                          "🌧️", // Example icon
                          "Rain Showers", // Example description
                          isCurrentHour: index == 0,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget Builders ---

  Widget _buildDaySeparator(TextTheme textTheme, String date, bool isToday) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: Colors.white.withOpacity(0.3), thickness: 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              isToday ? "TODAY" : date.toUpperCase(),
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Divider(color: Colors.white.withOpacity(0.3), thickness: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyItem(
    TextTheme textTheme,
    String time,
    String temp,
    String icon,
    String description, {
    required bool isCurrentHour,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color:
            isCurrentHour ? Colors.white.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Time
          SizedBox(
            width: 80,
            child: Text(
              isCurrentHour ? "Now ($time)" : time,
              style: textTheme.bodyLarge?.copyWith(
                color: Colors.white,
                fontWeight: isCurrentHour ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          // Weather Icon and Description
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(
                  description,
                  style: textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          // Temperature
          SizedBox(
            width: 60,
            child: Text(
              temp,
              textAlign: TextAlign.right,
              style: textTheme.bodyLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _min(int a, int b) => a < b ? a : b;
}
