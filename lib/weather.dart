import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:weatherapp/homepage.dart';

class Weather extends StatelessWidget {
  const Weather({super.key});

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
            Image.asset('assets/images/weather_icon.png', height: 300),
            const SizedBox(height: 40),
            Text(
              "Weather",
              style: GoogleFonts.poppins(
                fontSize: 45,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.37,
                height: 1.2,
              ),
            ),

            Text(
              "ForeCasts",
              style: GoogleFonts.poppins(
                fontSize: 38,
                fontWeight: FontWeight.w500,
                color: const Color.fromRGBO(221, 177, 48, 1),
                letterSpacing: -0.37,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Homepage()),
                );
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFDDB230),
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 42),
              ),
              child: Text(
                "Get Start",
                style: GoogleFonts.openSans(
                  color: Color.fromARGB(255, 54, 42, 132),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
