// email_verified_screen.dart

import 'package:flutter/material.dart';
import 'package:smart_solar/onboard/create_password.dart';

class PhoneVerifiedScreen extends StatelessWidget {
  final VoidCallback onNext;

  const PhoneVerifiedScreen({
    Key? key,
    required this.onNext,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Spacer to push content to center
              Expanded(
                flex: 1,
                child: SizedBox(),
              ),

              // Success icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Color(0xFF00A99D),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              SizedBox(height: 24),

              // Title
              Text(
                'Phone Number Verified',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8),

              // Subtitle
              Text(
                'Your phone has been verified successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),

              // Spacer to push button to bottom
              Expanded(
                flex: 2,
                child: SizedBox(),
              ),

              // Next button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to the next screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CreatePasswordScreen(), // Replace 'NextScreen' with your target screen

                      ),);},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF00A99D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'Next',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}