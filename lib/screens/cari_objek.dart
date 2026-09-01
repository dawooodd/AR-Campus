import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'success_claim_screen.dart';

class CariObjekScreen extends StatefulWidget {
  const CariObjekScreen({super.key});

  @override
  State<CariObjekScreen> createState() => _CariObjekScreenState();
}

class _CariObjekScreenState extends State<CariObjekScreen> with SingleTickerProviderStateMixin {
  // Countdown Timer: 4 minutes 30 seconds (270 seconds)
  Timer? _timer;
  int _remainingSeconds = 270;

  // Hint count
  int _remainingHints = 1;
  bool _isHintActive = false;
  Timer? _hintTimer;

  // Found state
  bool _isObjectFound = false;

  // Animation controller for glowing hint and celebration pulse
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _startCountdown();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hintTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        _handleTimeOut();
      }
    });
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    String minStr = minutes.toString().padLeft(2, '0');
    String secStr = seconds.toString().padLeft(2, '0');
    return "$minStr:$secStr";
  }

  void _handleTimeOut() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            const Icon(Icons.timer_off_rounded, color: AppColors.errorRed),
            SizedBox(width: 8.w),
            const Text("Waktu Habis!"),
          ],
        ),
        content: const Text("Sayang sekali, waktu pencarian telah berakhir. Coba lagi untuk menemukan karakter tersembunyi!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text("Kembali ke Menu"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _remainingSeconds = 270;
                _isObjectFound = false;
                _remainingHints = 1;
              });
              _startCountdown();
            },
            child: const Text("Ulangi", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _useHint() {
    if (_remainingHints > 0 && !_isHintActive) {
      setState(() {
        _remainingHints--;
        _isHintActive = true;
      });

      _hintTimer?.cancel();
      _hintTimer = Timer(const Duration(seconds: 6), () {
        if (mounted) {
          setState(() {
            _isHintActive = false;
          });
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.search_rounded, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text("🔍 Area sekitar target disorot selama 6 detik!"),
              ),
            ],
          ),
          backgroundColor: AppColors.primaryGreen,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        ),
      );
    } else if (_remainingHints == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Kesempatan hint kamu sudah habis."),
          backgroundColor: Colors.grey.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        ),
      );
    }
  }

  void _onTargetTapped() {
    if (_isObjectFound) return;

    _timer?.cancel();
    setState(() {
      _isObjectFound = true;
    });

    Provider.of<GameProvider>(context, listen: false).claimPoints(100);

    // Show found celebration dialog
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
                width: 80.w,
                height: 80.w,
                decoration: const BoxDecoration(
                  color: AppColors.softYellow,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text("✨🐊✨", style: TextStyle(fontSize: 32)),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                "Objek Ditemukan!",
                style: AppTheme.heading1.copyWith(
                  fontSize: 22.sp,
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "Hebat! Kamu berhasil menemukan Buaya tersembunyi.",
                textAlign: TextAlign.center,
                style: AppTheme.body.copyWith(
                  fontSize: 14.sp,
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
                    const Icon(Icons.star_rounded, color: AppColors.accentYellow, size: 22),
                    SizedBox(width: 6.w),
                    Text(
                      "+100 Poin Ditambahkan!",
                      style: AppTheme.body.copyWith(
                        fontSize: 15.sp,
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
                      MaterialPageRoute(builder: (context) => const SuccessClaimScreen()),
                    );
                  },
                  child: Text(
                    "Lanjut",
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

  void _onImageMissTapped(TapDownDetails details) {
    if (_isObjectFound) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.search_off_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text("Coba lagi! Belum tepat di titik tersebut."),
          ],
        ),
        backgroundColor: Colors.grey.shade800,
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
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
                "Cari karakter yang tersembunyi di gambar!",
                style: AppTheme.body.copyWith(
                  fontSize: 15.sp,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 16.h),

              // Info Bar (3 horizontal columns)
              _buildInfoBar(),
              SizedBox(height: 18.h),

              // Search Image Area (Interactive)
              _buildSearchImageArea(),
              SizedBox(height: 18.h),

              // Hint Card (Green #96B55F)
              _buildHintCard(),
              SizedBox(height: 20.h),

              // CTA Button: "🔍 Gunakan Hint (X)"
              _buildHintButton(),
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
        "Misi : Cari Objek",
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

  // Info Bar (3 Horizontal Columns: Target Object, Countdown Timer, Reward Points)
  Widget _buildInfoBar() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.lightPinkCream,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.neutralGray, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Column 1: Objek yang dicari
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Objek yang dicari:",
                  style: AppTheme.caption.copyWith(
                    fontSize: 10.5.sp,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("🐊", style: TextStyle(fontSize: 16)),
                    SizedBox(width: 4.w),
                    Text(
                      "Buaya",
                      style: AppTheme.heading2.copyWith(
                        fontSize: 14.sp,
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(width: 1, height: 35.h, color: AppColors.neutralGray),

          // Column 2: Waktu
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Waktu:",
                  style: AppTheme.caption.copyWith(
                    fontSize: 10.5.sp,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16.w,
                      color: _remainingSeconds <= 30 ? AppColors.errorRed : AppColors.primaryGreen,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      _formatTime(_remainingSeconds),
                      style: AppTheme.heading2.copyWith(
                        fontSize: 14.sp,
                        color: _remainingSeconds <= 30 ? AppColors.errorRed : AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(width: 1, height: 35.h, color: AppColors.neutralGray),

          // Column 3: Poin
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Poin:",
                  style: AppTheme.caption.copyWith(
                    fontSize: 10.5.sp,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.accentYellow, size: 18),
                    SizedBox(width: 2.w),
                    Text(
                      "+100",
                      style: AppTheme.heading2.copyWith(
                        fontSize: 14.sp,
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Interactive Search Image Area
  Widget _buildSearchImageArea() {
    return Container(
      width: double.infinity,
      height: 300.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: AppColors.neutralGray, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21.r),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background campus image with park/fountain
            GestureDetector(
              onTapDown: _onImageMissTapped,
              child: Image.asset(
                'assets/images/splash_bg.jpg',
                fit: BoxFit.cover,
              ),
            ),

            // Hint Highlight Glowing Radar Ring (when Hint is active)
            if (_isHintActive)
              Positioned(
                right: 50.w,
                bottom: 35.h,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 70.w,
                        height: 70.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accentYellow.withValues(alpha: 0.35),
                          border: Border.all(color: AppColors.accentYellow, width: 2.5),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Hidden Crocodile Mascot Target (Near the bushes/benches)
            Positioned(
              right: 62.w,
              bottom: 48.h,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _onTargetTapped,
                child: Container(
                  width: 46.w,
                  height: 46.w,
                  decoration: BoxDecoration(
                    color: _isObjectFound ? AppColors.accentGreen.withValues(alpha: 0.6) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Opacity(
                      opacity: 0.85,
                      child: Image.asset(
                        'assets/images/crocodile_mascot.jpg',
                        width: 38.w,
                        height: 38.w,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Discovered banner overlay
            if (_isObjectFound)
              Container(
                color: Colors.black.withValues(alpha: 0.4),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
                        SizedBox(width: 8.w),
                        Text(
                          "Karakter Berhasil Ditemukan!",
                          style: AppTheme.heading2.copyWith(
                            fontSize: 15.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
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
                  "Perhatikan semak-semak dan area sekitar bangku taman di sisi kanan!",
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

  // CTA Button: "🔍 Gunakan Hint (1)"
  Widget _buildHintButton() {
    final bool canUseHint = _remainingHints > 0 && !_isHintActive && !_isObjectFound;

    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: canUseHint ? AppColors.accentGreen : AppColors.neutralGray,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.r), // Pill shape
          ),
          elevation: canUseHint ? 3 : 0,
        ),
        onPressed: canUseHint ? _useHint : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_rounded, color: Colors.white),
            SizedBox(width: 8.w),
            Text(
              "Gunakan Hint ($_remainingHints)",
              style: AppTheme.heading2.copyWith(
                fontSize: 18.sp,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
