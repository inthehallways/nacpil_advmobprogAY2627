import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/custom_text.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  // enhancement 1: splash screen checks saved authentication before routing 
  Future<void> _checkAuthentication() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? prefs.getString('token');
    final loggedIn = token != null && token.isNotEmpty;

    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      loggedIn ? '/home' : '/signin',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFFBF8FF),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Image.asset(
                'assets/images/nubdexchange_logo.png',
                width: 126.w,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 26.h),
              CustomText(
                text: 'NU Bulldogs Exchange',
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
              ),
              SizedBox(height: 8.h),
              CustomText(
                text: 'Loading your session',
                fontSize: 12.sp,
                color: Colors.black54,
              ),
              SizedBox(height: 30.h),
              SizedBox(
                width: 28.w,
                height: 28.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color.fromARGB(255, 18, 82, 25),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
