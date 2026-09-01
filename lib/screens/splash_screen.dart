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
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Full-screen Background Illustration
          Image.asset(
            'assets/images/splash_bg.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF63B8FF), Color(0xFFC8E6C9)],
                  ),
                ),
              );
            },
          ),

          // 2. Soft Gradient Overlay for Optimal Text Readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.35),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // 3. Top-Center Logo and Tagline
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: 24.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Campus Hunto 3D Gradient Text Logo
                    _build3DLogo(),
                    SizedBox(height: 10.h),

                    // Tagline Badge: "EXPLORE • LEARN • PLAY"
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
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

          // 4. Mascot Characters Cluster with Fade-in Animation
          Positioned(
            bottom: 155.h,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _mascotFadeAnimation,
              child: SlideTransition(
                position: _mascotSlideAnimation,
                child: _buildMascotsCluster(),
              ),
            ),
          ),

          // 5. Bottom Loading Bar & Story Footer
          Positioned(
            bottom: 40.h,
            left: 28.w,
            right: 28.w,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Loading Status Text dynamically updating 0% -> 100%
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

                // Stylized Progress Bar
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

                // Footer Text
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
    );
  }

  // 3D Playful Text Logo Builder
  Widget _build3DLogo() {
    return Column(
      children: [
        Stack(
          children: [
            // Drop shadow text
            Text(
              "CAMPUS",
              style: GoogleFonts.bungee(
                fontSize: 42.sp,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 6
                  ..color = const Color(0xFF132212),
              ),
            ),
            Text(
              "CAMPUS",
              style: GoogleFonts.bungee(
                fontSize: 42.sp,
                color: AppColors.primaryGreen,
                shadows: const [
                  Shadow(color: Colors.black54, offset: Offset(2, 4), blurRadius: 6),
                ],
              ),
            ),
          ],
        ),
        Transform.translate(
          offset: Offset(0, -12.h),
          child: Stack(
            children: [
              Text(
                "HUNTO",
                style: GoogleFonts.bungee(
                  fontSize: 46.sp,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 6
                    ..color = const Color(0xFF5D4037),
                ),
              ),
              Text(
                "HUNTO",
                style: GoogleFonts.bungee(
                  fontSize: 46.sp,
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

  // 7 Mascot Characters Cluster Display
  Widget _buildMascotsCluster() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildMascotAvatar("🐊", Colors.teal.shade300, 46.w),
          SizedBox(width: 4.w),
          _buildMascotAvatar("🐯", Colors.amber.shade400, 52.w),
          SizedBox(width: 4.w),
          _buildMascotAvatar("🐱", Colors.orange.shade300, 56.w),
          SizedBox(width: 6.w),
          // Center Leader Dragon Mascot
          _buildMascotAvatar("🐉", AppColors.primaryGreen, 74.w, isLeader: true),
          SizedBox(width: 6.w),
          _buildMascotAvatar("🐻", Colors.brown.shade400, 56.w),
          SizedBox(width: 4.w),
          _buildMascotAvatar("🐵", Colors.deepOrange.shade300, 52.w),
          SizedBox(width: 4.w),
          _buildMascotAvatar("🦅", Colors.blueGrey.shade400, 46.w),
        ],
      ),
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
