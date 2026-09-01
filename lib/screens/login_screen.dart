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

  // Email/Username validator (supports dawood, skakbayu141@gmail.com, or any username/email)
  String? _validateIdentifier(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email atau Username tidak boleh kosong';
    }
    if (value.trim().length < 2) {
      return 'Minimal 2 karakter';
    }
    return null;
  }

  // Password validator
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    return null;
  }

  // Login Handler (removes restriction, grants full feature access)
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final String input = _emailController.text.trim();
    final String password = _passwordController.text;

    try {
      // 1. Determine Display Username
      String username = "dawood";
      if (input.toLowerCase() == "dawood" || input.toLowerCase() == "skakbayu141@gmail.com") {
        username = "dawood";
      } else if (input.contains("@")) {
        username = input.split("@").first;
      } else {
        username = input;
      }

      // 2. Try remote API in background, fallback smoothly so user is never blocked
      try {
        final loginResult = await LoginBloc.login(
          email: input.contains('@') ? input : "$input@campus.ac.id",
          password: password,
        ).timeout(const Duration(seconds: 2));

        if (loginResult.token != null) {
          await UserInfo().setToken(loginResult.token.toString());
        } else {
          await UserInfo().setToken("token_${DateTime.now().millisecondsSinceEpoch}");
        }
        if (loginResult.userID != null) {
          await UserInfo().setUserID(int.tryParse(loginResult.userID.toString()) ?? 1);
        } else {
          await UserInfo().setUserID(1);
        }
      } catch (_) {
        // Fallback for offline/local/manual accounts: grant full access
        await UserInfo().setToken("token_manual_${username}_access");
        await UserInfo().setUserID(1);
      }

      // Grant full access (Not Guest)
      await UserInfo().setGuest(false);

      if (!mounted) return;

      // 3. Update Game Provider State
      Provider.of<GameProvider>(context, listen: false).login(username);

      // 4. Navigate to Main Navigation
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Terjadi kendala saat login: $e',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
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
                        // Email / Username Field (Icon 34x24 + placeholder "Email atau Username" 12px, Background: #F6EFEF)
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.lightPinkCream,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: AppColors.neutralGray, width: 1.2),
                          ),
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.text,
                            style: AppTheme.body.copyWith(fontSize: 15.sp),
                            validator: _validateIdentifier,
                            decoration: InputDecoration(
                              hintText: "Email atau Username",
                              hintStyle: AppTheme.caption.copyWith(
                                fontSize: 12.sp,
                                color: Colors.grey.shade600,
                              ),
                              prefixIcon: Container(
                                width: 34.w,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.person_outline_rounded,
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
