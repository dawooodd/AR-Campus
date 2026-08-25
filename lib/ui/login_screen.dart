import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';

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
        MaterialPageRoute(builder: (context) => const HomeScreen()),
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
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  void _loginAsGuest() {
    Provider.of<GameProvider>(context, listen: false).loginAsGuest();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
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
                style: GoogleFonts.inter(
                  color: Colors.black,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "Masuk untuk memulai petualangmu!",
                style: GoogleFonts.inter(
                  color: Colors.black87,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 40.h),
              
              // Email / NIM Field
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.borderCard),
                ),
                child: TextField(
                  controller: _identifierController,
                  decoration: InputDecoration(
                    hintText: "Email / NIM",
                    hintStyle: GoogleFonts.inter(color: Colors.grey),
                    prefixIcon: Icon(Icons.email_outlined, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16.h),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              
              // Kirim OTP Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.outlineGreen, // Lighter green from the design
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _loginAsStudent,
                child: Text(
                  "Kirim Kode OTP ke Email",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Text("atau", style: GoogleFonts.inter(color: Colors.grey)),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              SizedBox(height: 24.h),
              
              // Login with Google Button
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _loginWithGoogle,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Placeholder for Google Icon (using generic icon since flutter standard doesn't have G logo)
                    Icon(Icons.g_mobiledata, color: Colors.blue, size: 28.w),
                    SizedBox(width: 8.w),
                    Text(
                      "Login with Google",
                      style: GoogleFonts.inter(
                        color: Colors.black87,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 40.h),
              
              // Masuk Sebagai Guest Button
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  backgroundColor: AppColors.cardBackground,
                  side: BorderSide(color: AppColors.outlineGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _loginAsGuest,
                child: Text(
                  "Masuk Sebagai Guest",
                  style: GoogleFonts.inter(
                    color: AppColors.outlineGreen,
                    fontSize: 16.sp,
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
