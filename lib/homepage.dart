import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/weather_icon.png', height: 200),
            Text(
              "19~",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.47,
              ),
            ),
            Text(
              "Precipitations",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.47,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Max: 24",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.47,
                  ),
                ),
                SizedBox(width: 20),
                Text(
                  "Min: 18",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.47,
                  ),
                ),
              ],
            ),
            Image.asset('assets/images/winter_house.png', height: 400),
          ],
        ),
      ),
    );
  }
}
