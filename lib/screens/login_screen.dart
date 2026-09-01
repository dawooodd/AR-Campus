import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../bloc/login_bloc.dart';
import '../helpers/user_info.dart';
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
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Email format validator
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email tidak boleh kosong';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Format email tidak valid (contoh: user@campus.ac.id)';
    }
    return null;
  }

  // Password length validator (minimum 6 characters)
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  // POST Request Login Handler
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    try {
      final loginResult = await LoginBloc.login(
        email: email,
        password: password,
      );

      if (!mounted) return;

      // Persist Auth Data & Guest status
      if (loginResult.token != null) {
        await UserInfo().setToken(loginResult.token.toString());
      }
      if (loginResult.userID != null) {
        await UserInfo().setUserID(int.tryParse(loginResult.userID.toString()) ?? 0);
      }
      await UserInfo().setGuest(false);

      if (!mounted) return;

      // Update Game Provider State
      final username = email.split('@').first;
      Provider.of<GameProvider>(context, listen: false).login(username);

      // Navigate to Home Screen / Main Navigation
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 10.w),
              const Expanded(
                child: Text(
                  'Email atau password salah. Silakan periksa kembali.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Guest Login Handler
  Future<void> _handleGuestLogin() async {
    setState(() {
      _isLoading = true;
    });

    await UserInfo().setGuest(true);
    if (!mounted) return;

    Provider.of<GameProvider>(context, listen: false).loginAsGuest();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigation()),
    );

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white, // Pure white background (#FFFFFF)
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top Mascot Section: Pixel-art/voxel-art crocodile mascot (233x205px, ellipse crop)
                  Container(
                    width: 233.w,
                    height: 205.h,
                    decoration: BoxDecoration(
                      color: AppColors.softYellow.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30.r),
                      child: Image.asset(
                        'assets/images/crocodile_mascot.jpg',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.pets,
                              size: 100.w,
                              color: AppColors.primaryGreen,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Title: "SELAMAT DATANG" (Inter Semi Bold 24px, #273826)
                  Text(
                    "SELAMAT DATANG",
                    style: AppTheme.heading1.copyWith(
                      fontSize: 24.sp,
                      color: AppColors.primaryGreen,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 8.h),

                  // Subtitle: "Masuk untuk memulai petualanganmu!" (Inter Regular 15px)
                  Text(
                    "Masuk untuk memulai petualanganmu!",
                    style: AppTheme.body.copyWith(
                      fontSize: 15.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // Form Fields (275x60px dimensions)
                  SizedBox(
                    width: 275.w,
                    child: Column(
                      children: [
                        // Email Field (Icon 34x24 + placeholder "Email" 12px, Background: #F6EFEF)
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.lightPinkCream,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: AppColors.neutralGray, width: 1.2),
                          ),
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: AppTheme.body.copyWith(fontSize: 15.sp),
                            validator: _validateEmail,
                            decoration: InputDecoration(
                              hintText: "Email",
                              hintStyle: AppTheme.caption.copyWith(
                                fontSize: 12.sp,
                                color: Colors.grey.shade600,
                              ),
                              prefixIcon: Container(
                                width: 34.w,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.email_outlined,
                                  color: AppColors.primaryGreen,
                                  size: 24,
                                ),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 16.w),
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // Password Field (Icon 34x30 + placeholder "Password" 12px, Background: #F6EFEF)
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.lightPinkCream,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: AppColors.neutralGray, width: 1.2),
                          ),
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: AppTheme.body.copyWith(fontSize: 15.sp),
                            validator: _validatePassword,
                            decoration: InputDecoration(
                              hintText: "Password",
                              hintStyle: AppTheme.caption.copyWith(
                                fontSize: 12.sp,
                                color: Colors.grey.shade600,
                              ),
                              prefixIcon: Container(
                                width: 34.w,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.lock_outline,
                                  color: AppColors.primaryGreen,
                                  size: 24,
                                ),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.grey.shade600,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 16.w),
                            ),
                          ),
                        ),
                        SizedBox(height: 24.h),

                        // "Masuk" (Login) Button (275x60px, #96B55F, Inter Semi Bold 20px white, Pill shape 30r)
                        SizedBox(
                          width: 275.w,
                          height: 56.h,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentGreen, // #96B55F
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.r), // Pill shape
                              ),
                            ),
                            onPressed: _isLoading ? null : _handleLogin,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    "Masuk",
                                    style: AppTheme.heading2.copyWith(
                                      fontSize: 20.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // "Masuk Sebagai Guest" Button (275x60px, #F7FAC7, Inter Semi Bold 20px #273826, Pill shape 30r)
                        SizedBox(
                          width: 275.w,
                          height: 56.h,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: AppColors.softYellow, // #F7FAC7
                              side: const BorderSide(color: AppColors.accentGreen, width: 1.5),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.r), // Pill shape
                              ),
                            ),
                            onPressed: _isLoading ? null : _handleGuestLogin,
                            child: Text(
                              "Masuk Sebagai Guest",
                              style: AppTheme.heading2.copyWith(
                                fontSize: 18.sp,
                                color: AppColors.primaryGreen, // #273826
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
