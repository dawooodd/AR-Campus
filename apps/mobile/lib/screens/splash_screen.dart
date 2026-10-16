import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../helpers/user_info.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';
import 'main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  late AnimationController _mascotController;
  late Animation<double> _mascotFadeAnimation;
  late Animation<Offset> _mascotSlideAnimation;

  @override
  void initState() {
    super.initState();

    // 18 seconds simulated progress (strictly between 15 - 20 seconds)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    )..addListener(() {
        setState(() {});
      });

    // Mascot fade-in & float-up animation
    _mascotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _mascotFadeAnimation = CurvedAnimation(
      parent: _mascotController,
      curve: Curves.easeOut,
    );

    _mascotSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mascotController,
      curve: Curves.easeOutBack,
    ));

    _mascotController.forward();

    // Trigger navigation strictly AFTER 100% completion
    _progressController.forward().then((_) {
      _handleNavigation();
    });
  }

  // Check authentication state after 100% progress and route accordingly
  Future<void> _handleNavigation() async {
    if (!mounted) return;

    final String? token = await UserInfo().getToken();
    final bool isGuest = await UserInfo().isGuest();

    if (!mounted) return;

    if (token != null && token.isNotEmpty && !isGuest) {
      // User is already authenticated -> Navigate to MainNavigation
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    } else {
      // Not logged in or guest -> Navigate to LoginScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _mascotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int progressPercent = (_progressAnimation.value * 100).clamp(0, 100).toInt();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Full-screen cartoon illustration background from Figma
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/splash_bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Soft Gradient Overlay for Optimal Text Contrast & Readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.15),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.40),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // 2. Top-Center Logo and Tagline (Protected by SafeArea from status bar overlap)
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: 20.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Campus Hunto 3D Playful Text Logo
                      _build3DLogo(),
                      SizedBox(height: 8.h),

                      // Tagline Badge: "EXPLORE • LEARN • PLAY"
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 7.h),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          borderRadius: BorderRadius.circular(24.r),
                          border: Border.all(color: AppColors.softYellow, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Text(
                          "EXPLORE • LEARN • PLAY",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Mascot Characters Cluster (Wrapped in FittedBox to eliminate right overflow)
            Positioned(
              bottom: 145.h,
              left: 16.w,
              right: 16.w,
              child: FadeTransition(
                opacity: _mascotFadeAnimation,
                child: SlideTransition(
                  position: _mascotSlideAnimation,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: _buildMascotsCluster(),
                  ),
                ),
              ),
            ),

            // 4. Bottom Loading Bar & Story Footer
            Positioned(
              bottom: 36.h,
              left: 24.w,
              right: 24.w,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Live dynamic text: "MEMUAT PETUALANGAN.. [X]%"
                  Text(
                    "MEMUAT PETUALANGAN.. $progressPercent%",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      shadows: const [
                        Shadow(color: Colors.black87, blurRadius: 8, offset: Offset(0, 2)),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),

                  // Stylized Green Progress Bar (Synced with percentage)
                  Container(
                    height: 18.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.primaryGreen, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.r),
                      child: Stack(
                        children: [
                          FractionallySizedBox(
                            widthFactor: _progressAnimation.value.clamp(0.0, 1.0),
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.accentGreen, Color(0xFF689F38)],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),

                  // Footer Story Text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: AppColors.accentYellow, size: 16),
                      SizedBox(width: 6.w),
                      Text(
                        "Setiap langkahmu, adalah cerita baru!",
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          shadows: const [
                            Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 1)),
                          ],
                        ),
                      ),
                      SizedBox(width: 6.w),
                      const Icon(Icons.star, color: AppColors.accentYellow, size: 16),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3D Playful Text Logo Builder
  Widget _build3DLogo() {
    return Column(
      children: [
        Stack(
          children: [
            // Drop shadow stroke
            Text(
              "CAMPUS",
              style: GoogleFonts.bungee(
                fontSize: 40.sp,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 6
                  ..color = const Color(0xFF132212),
              ),
            ),
            Text(
              "CAMPUS",
              style: GoogleFonts.bungee(
                fontSize: 40.sp,
                color: AppColors.primaryGreen,
                shadows: const [
                  Shadow(color: Colors.black54, offset: Offset(2, 4), blurRadius: 6),
                ],
              ),
            ),
          ],
        ),
        Transform.translate(
          offset: Offset(0, -10.h),
          child: Stack(
            children: [
              Text(
                "HUNTO",
                style: GoogleFonts.bungee(
                  fontSize: 44.sp,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 6
                    ..color = const Color(0xFF5D4037),
                ),
              ),
              Text(
                "HUNTO",
                style: GoogleFonts.bungee(
                  fontSize: 44.sp,
                  color: AppColors.accentYellow,
                  shadows: const [
                    Shadow(color: Colors.black54, offset: Offset(2, 4), blurRadius: 6),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 7 Mascot Characters Cluster Display (Proportionally sized with Center Leader Dragon)
  Widget _buildMascotsCluster() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildMascotAvatar("🐊", Colors.teal.shade300, 44.w),
        SizedBox(width: 4.w),
        _buildMascotAvatar("🐯", Colors.amber.shade400, 50.w),
        SizedBox(width: 4.w),
        _buildMascotAvatar("🐱", Colors.orange.shade300, 54.w),
        SizedBox(width: 6.w),
        // Center Leader Dragon Mascot (Larger)
        _buildMascotAvatar("🐉", AppColors.primaryGreen, 72.w, isLeader: true),
        SizedBox(width: 6.w),
        _buildMascotAvatar("🐻", Colors.brown.shade400, 54.w),
        SizedBox(width: 4.w),
        _buildMascotAvatar("🐵", Colors.deepOrange.shade300, 50.w),
        SizedBox(width: 4.w),
        _buildMascotAvatar("🦅", Colors.blueGrey.shade400, 44.w),
      ],
    );
  }

  Widget _buildMascotAvatar(String emoji, Color bgColor, double size, {bool isLeader = false}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: isLeader ? AppColors.softYellow : Colors.white,
          width: isLeader ? 3.5 : 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: isLeader ? 10 : 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(fontSize: size * 0.55),
        ),
      ),
    );
  }
}
