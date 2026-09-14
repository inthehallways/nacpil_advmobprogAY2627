import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

// services
import '../services/user_service.dart';

// providers
import '../providers/theme_provider.dart';

// widgets
import '../widgets/custom_text.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final userService = UserService();
    await userService.signOut();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: 'Settings',
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          children: [
            // Light/Dark mode toggle switch
            SwitchListTile(
              secondary: Icon(
                themeProvider.isDark ? Icons.dark_mode : Icons.light_mode,
                size: 28.sp,
              ),
              title: CustomText(
                text: themeProvider.isDark ? 'Dark Mode' : 'Light Mode',
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
              value: themeProvider.isDark,
              onChanged: (_) {
                context.read<ThemeProvider>().toggleTheme();
              },
            ),
            const Spacer(),
            // Logout button in settings -> back to login
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5B4D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                onPressed: () => _logout(context),
                icon: Icon(Icons.logout, size: 18.sp),
                label: CustomText(
                  text: 'Log Out',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}