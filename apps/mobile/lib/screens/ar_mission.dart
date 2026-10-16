import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'success_screen.dart';

class ArMissionScreen extends StatefulWidget {
  const ArMissionScreen({super.key});

  @override
  State<ArMissionScreen> createState() => _ArMissionScreenState();
}

class _ArMissionScreenState extends State<ArMissionScreen> with TickerProviderStateMixin {
  late MobileScannerController _scannerController;
  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isMarkerDetected = false;
  bool _isCaptured = false;
  Timer? _detectionTimer;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    // Laser line scanning animation
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );

    // 3D Object Floating Animation
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Glow pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Simulate smart AR image marker detection after 2.5 seconds
    _startMarkerDetection();
  }

  void _startMarkerDetection() {
    _detectionTimer?.cancel();
    _detectionTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted && !_isCaptured) {
        setState(() {
          _isMarkerDetected = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _scannerController.dispose();
    _laserController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (!_isMarkerDetected && !_isCaptured) {
      setState(() {
        _isMarkerDetected = true;
      });
    }
  }

  void _refreshTracking() {
    setState(() {
      _isMarkerDetected = false;
      _isCaptured = false;
    });
    _scannerController.start();
    _startMarkerDetection();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.refresh_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text("🔄 Kalibrasi sensor AR berhasil disegarkan."),
          ],
        ),
        backgroundColor: AppColors.primaryGreen,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      ),
    );
  }

  void _showMissionClues() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            const Icon(Icons.map_outlined, color: AppColors.primaryGreen),
            SizedBox(width: 8.w),
            const Text("Petunjuk Lokasi Marker"),
          ],
        ),
        content: const Text(
          "Marker fisik AR tersebar di beberapa titik kampus:\n"
          "1. Poster Gerbang Kampus Utama\n"
          "2. Prasasti Rektorat Lantai 1\n"
          "3. Banner Student Center Plaza\n\n"
          "Arahkan kamera ke gambar marker untuk memunculkan maskot 3D!",
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Mengerti", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _onModelCaptured() {
    if (_isCaptured) return;

    setState(() {
      _isCaptured = true;
    });

    Provider.of<GameProvider>(context, listen: false).claimPoints(250);

    // Show celebratory capture overlay and navigate to Success Screen
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 85.w,
                height: 85.w,
                decoration: const BoxDecoration(
                  color: AppColors.softYellow,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text("✨🐊✨", style: TextStyle(fontSize: 36)),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                "3D Mascot Captured!",
                style: AppTheme.heading1.copyWith(
                  fontSize: 22.sp,
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "Luar biasa! Kamu berhasil menangkap maskot AR 3D di koordinat marker fisik.",
                textAlign: TextAlign.center,
                style: AppTheme.body.copyWith(
                  fontSize: 13.5.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.softYellow,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.accentYellow, width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars_rounded, color: AppColors.accentYellow, size: 24),
                    SizedBox(width: 6.w),
                    Text(
                      "+250 Poin Ditambahkan!",
                      style: AppTheme.body.copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.r)),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const SuccessScreen()),
                    );
                  },
                  child: Text(
                    "Buka Hadiah",
                    style: AppTheme.heading2.copyWith(
                      fontSize: 18.sp,
                      color: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: _buildAppBar(context, provider.totalPoints),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subtitle
              Text(
                "Point your camera to find hidden markers and complete the hardest mission!",
                style: AppTheme.body.copyWith(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 16.h),

              // AR Camera Viewfinder (Main Area)
              _buildARCameraViewfinder(),
              SizedBox(height: 16.h),

              // Hint Card (Green #96B55F)
              _buildHintCard(),
              SizedBox(height: 16.h),

              // CTA Action Buttons (Refresh AR Tracking / View Mission Clues)
              _buildActionButtons(),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  // Header AppBar
  PreferredSizeWidget _buildAppBar(BuildContext context, int points) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
        onPressed: () => Navigator.of(context).pop(),
      ),
      centerTitle: true,
      title: Text(
        "AR Mission",
        style: AppTheme.heading1.copyWith(
          fontSize: 20.sp,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 16.w),
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.softYellow,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: AppColors.accentYellow, width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: AppColors.accentYellow, size: 18),
                  SizedBox(width: 4.w),
                  Text(
                    "$points",
                    style: AppTheme.body.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // AR Camera Viewfinder with Corner Brackets, Laser Scanner, and 3D Anchor
  Widget _buildARCameraViewfinder() {
    return Container(
      width: double.infinity,
      height: 330.h,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Live Mobile Scanner / Camera
            MobileScanner(
              controller: _scannerController,
              onDetect: _onBarcodeDetected,
              errorBuilder: (context, error) {
                return Container(
                  color: Colors.black87,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined, color: Colors.white54, size: 50.w),
                        SizedBox(height: 8.h),
                        Text(
                          "AR Camera Tracking Active",
                          style: TextStyle(color: Colors.white70, fontSize: 13.sp),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Subtle Camera Grid / Reticle
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
            ),

            // Scanning Laser Line (Active when searching for markers)
            if (!_isMarkerDetected)
              AnimatedBuilder(
                animation: _laserAnimation,
                builder: (context, child) {
                  return Positioned(
                    top: 30.h + (_laserAnimation.value * 270.h),
                    left: 30.w,
                    right: 30.w,
                    child: Container(
                      height: 3.h,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.accentGreen,
                            Colors.white,
                            AppColors.accentGreen,
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentGreen.withValues(alpha: 0.8),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            // 4 Green Corner Brackets (#96B55F)
            Positioned(
              top: 24.h,
              left: 24.w,
              child: _buildCornerBracket(isTop: true, isLeft: true),
            ),
            Positioned(
              top: 24.h,
              right: 24.w,
              child: _buildCornerBracket(isTop: true, isLeft: false),
            ),
            Positioned(
              bottom: 24.h,
              left: 24.w,
              child: _buildCornerBracket(isTop: false, isLeft: true),
            ),
            Positioned(
              bottom: 24.h,
              right: 24.w,
              child: _buildCornerBracket(isTop: false, isLeft: false),
            ),

            // Active Marker Tracking / 3D Animated Object
            if (_isMarkerDetected)
              AnimatedBuilder(
                animation: _floatAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _floatAnimation.value),
                    child: child,
                  );
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _onModelCaptured,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Glowing Aura Pulse Ring
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 120.w,
                              height: 120.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.accentGreen.withValues(alpha: 0.25),
                                border: Border.all(color: AppColors.accentYellow, width: 2.5),
                              ),
                              child: child,
                            ),
                          );
                        },
                        child: Center(
                          child: Container(
                            width: 85.w,
                            height: 85.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.softYellow.withValues(alpha: 0.8),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/crocodile_mascot.jpg',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 14.h),

                      // Interactive Tap Prompt Banner
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: AppColors.accentYellow, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.touch_app_rounded, color: AppColors.accentYellow, size: 20),
                            SizedBox(width: 6.w),
                            Text(
                              "3D Object Found! Tap to capture!",
                              style: AppTheme.heading2.copyWith(
                                fontSize: 13.5.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Top Status Overlay
            Positioned(
              top: 14.h,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isMarkerDetected ? AppColors.accentGreen : AppColors.accentYellow,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      _isMarkerDetected ? "MARKER LOCKED • 3D ACTIVE" : "SCANNING FOR AR MARKERS...",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Corner Bracket Overlay Element (#96B55F)
  Widget _buildCornerBracket({required bool isTop, required bool isLeft}) {
    const double size = 32.0;
    const double thickness = 4.0;
    const Color color = AppColors.accentGreen;

    return SizedBox(
      width: size.w,
      height: size.w,
      child: Stack(
        children: [
          // Horizontal bar
          Positioned(
            top: isTop ? 0 : null,
            bottom: !isTop ? 0 : null,
            left: 0,
            right: 0,
            child: Container(
              height: thickness.h,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          // Vertical bar
          Positioned(
            left: isLeft ? 0 : null,
            right: !isLeft ? 0 : null,
            top: 0,
            bottom: 0,
            child: Container(
              width: thickness.w,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Hint Card (#96B55F)
  Widget _buildHintCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.accentGreen, // #96B55F
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGreen.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_rounded, color: Colors.white, size: 22),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Petunjuk",
                  style: AppTheme.heading2.copyWith(
                    fontSize: 15.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  "Find hidden physical markers spread around the campus to reveal moving 3D characters and earn massive points!",
                  style: AppTheme.body.copyWith(
                    fontSize: 13.sp,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // CTA Action Buttons
  Widget _buildActionButtons() {
    return Column(
      children: [
        // Primary Button: "🔄 Refresh AR Tracking"
        SizedBox(
          width: double.infinity,
          height: 54.h,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.r), // Pill shape
              ),
              elevation: 3,
            ),
            onPressed: _refreshTracking,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            label: Text(
              "Refresh AR Tracking",
              style: AppTheme.heading2.copyWith(
                fontSize: 17.sp,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: 12.h),

        // Secondary Button: "🗺️ View Mission Clues"
        SizedBox(
          width: double.infinity,
          height: 50.h,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.lightPinkCream,
              side: const BorderSide(color: AppColors.accentGreen, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.r),
              ),
            ),
            onPressed: _showMissionClues,
            icon: const Icon(Icons.explore_outlined, color: AppColors.primaryGreen),
            label: Text(
              "Lihat Petunjuk Marker",
              style: AppTheme.heading2.copyWith(
                fontSize: 16.sp,
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
