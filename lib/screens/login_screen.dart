import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'main_navigation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _identifierController = TextEditingController();

  void _loginAsStudent() {
    if (_identifierController.text.isNotEmpty) {
      Provider.of<GameProvider>(context, listen: false).login(_identifierController.text);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi Email / NIM')),
      );
    }
  }

  void _loginWithGoogle() {
    // Simulated Google Login
    Provider.of<GameProvider>(context, listen: false).login("google_user");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigation()),
    );
  }

  void _loginAsGuest() {
    Provider.of<GameProvider>(context, listen: false).loginAsGuest();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigation()),
    );
  }

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20.h),
              // Mascot Image Placeholder
              Icon(Icons.pets, size: 120.w, color: AppColors.primaryGreen),
              SizedBox(height: 24.h),
              
              Text(
                "SELAMAT DATANG",
                style: AppTheme.heading1.copyWith(
                  fontSize: 24.sp,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "Masuk untuk memulai petualangmu!",
                style: AppTheme.body.copyWith(
                  fontSize: 15.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 40.h),
              
              // Email / NIM Field with Light Pink/Cream background (#F6EFEF)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.lightPinkCream,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.neutralGray),
                ),
                child: TextField(
                  controller: _identifierController,
                  style: AppTheme.body.copyWith(fontSize: 15.sp),
                  decoration: InputDecoration(
                    hintText: "Email / NIM",
                    hintStyle: AppTheme.caption.copyWith(fontSize: 12.sp, color: Colors.grey.shade600),
                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primaryGreen),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              
              // Kirim OTP Button (Heading 2, Accent Green)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen, // #96B55F
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _loginAsStudent,
                child: Text(
                  "Masuk",
                  style: AppTheme.heading2.copyWith(
                    fontSize: 20.sp,
                    color: Colors.white,
                  ),
                ),
              ),
              
              SizedBox(height: 24.h),
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.neutralGray)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Text("atau", style: AppTheme.caption.copyWith(fontSize: 12.sp)),
                  ),
                  const Expanded(child: Divider(color: AppColors.neutralGray)),
                ],
              ),
              SizedBox(height: 24.h),
              
              // Login with Google Button
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  side: const BorderSide(color: AppColors.neutralGray),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _loginWithGoogle,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.g_mobiledata, color: Colors.blue, size: 28.w),
                    SizedBox(width: 8.w),
                    Text(
                      "Login with Google",
                      style: AppTheme.body.copyWith(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24.h),
              
              // Masuk Sebagai Guest Button
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  backgroundColor: AppColors.softYellow,
                  side: const BorderSide(color: AppColors.accentGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _loginAsGuest,
                child: Text(
                  "Masuk Sebagai Guest",
                  style: AppTheme.body.copyWith(
                    color: AppColors.primaryGreen,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
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
