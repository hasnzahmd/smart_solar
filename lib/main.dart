import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/firebase_options.dart'; 

// Auth screens
import 'package:smart_solar/auth/login_screen.dart';
import 'package:smart_solar/auth/signup_screen.dart';
import 'package:smart_solar/auth/verify_email.dart';
import 'package:smart_solar/auth/verified_email.dart';
import 'package:smart_solar/auth/phone_verify.dart';
import 'package:smart_solar/auth/verify_phone.dart';
import 'package:smart_solar/auth/verified_phone.dart';

// Onboarding screens
import 'package:smart_solar/onboard/create_password.dart';
import 'package:smart_solar/onboard/get_user_details.dart';
import 'package:smart_solar/onboard/welcome_screen.dart';

// Main app screens
import 'package:smart_solar/pages/home_screen.dart';
import 'package:smart_solar/pages/service_screen.dart';
import 'package:smart_solar/pages/booking_history.dart';
import 'package:smart_solar/pages/profile_screen.dart';
import 'package:smart_solar/pages/cart_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Get login state from SharedPreferences to determine initial route
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Solar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF00A99D),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00A99D),
          primary: const Color(0xFF00A99D),
        ),
      ),
      initialRoute: isLoggedIn ? '/home' : '/welcome',
      routes: {
        // Auth routes
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignUpScreen(),
        '/verify-email': (context) => VerifyEmailScreen(email: ''),
        '/email-verified': (context) => EmailVerifiedScreen(
          onNext: () => Navigator.pushNamed(context, '/phone-number'),
        ),
        '/phone-number': (context) => PhoneNumberScreen(),
        '/verify-phone': (context) => VerifyPhoneScreen(
          phoneNumber: '',
          verificationId: '',
        ),
        '/phone-verified': (context) => PhoneVerifiedScreen(
          onNext: () => Navigator.pushNamed(context, '/create-password'),
        ),

        // Onboarding routes
        '/welcome': (context) => WelcomeScreen(),
        '/create-password': (context) => CreatePasswordScreen(),
        '/get-user-details': (context) => GetUserDetails(),

        // Main app routes
        '/home': (context) => HomeScreen(),
        '/booking-history': (context) => BookingHistoryScreen(),
        '/service': (context) => ServiceScreen(serviceType: 'Solar System'),
        '/cart': (context) => CartScreen(),
        '/profile': (context) => ProfileScreen(),
      },
    );
  }
}