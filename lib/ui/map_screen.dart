import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_colors.dart';
import 'custom_bottom_nav.dart';
import 'qr_scanner_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      if (mounted) {
        Provider.of<GameProvider>(context, listen: false).checkRealLocation();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin lokasi diperlukan untuk bermain!')),
        );
      }
    }
  }

  void _onPilihTantangan() {
    final provider = Provider.of<GameProvider>(context, listen: false);
    
    if (provider.isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Guest hanya dapat melihat peta. Login untuk bermain!',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (provider.isRealLocation) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const QrScannerScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Coba lagi di tempat lain',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC8E6C9), // Light green fallback for map background
      bottomNavigationBar: const CustomBottomNav(currentIndex: 1),
      body: Stack(
        children: [
          // UnityWidgetPlaceholder goes here
          Positioned.fill(
            child: Container(
              color: const Color(0xFFB9DFB3), // Placeholder for 3D Map
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map, size: 80.w, color: Colors.white54),
                    SizedBox(height: 10.h),
                    Text(
                      "[Unity 3D Map Placeholder]",
                      style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
            ),
          ),
          // Markers placeholder
          Positioned(
            top: 250.h,
            left: 100.w,
            child: _buildPin(Icons.book, "Perpustakaan", Colors.blue),
          ),
          Positioned(
            top: 350.h,
            right: 120.w,
            child: _buildPin(Icons.star, "Aula", Colors.purple),
          ),

          // Top Header - Peta Kampus
          Positioned(
            top: 60.h,
            left: 20.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: AppColors.primaryGreen, size: 24.w),
                  SizedBox(width: 12.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Peta Kampus",
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Temukan lokasi dan selesaikan\ntantanganmu!",
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),

          // Top Right Filter
          Positioned(
            top: 60.h,
            right: 20.w,
            child: Column(
              children: [
                _buildFloatingButton(Icons.my_location),
                SizedBox(height: 12.h),
                _buildFloatingButton(Icons.filter_alt_outlined, label: "Filter"),
              ],
            ),
          ),

          // Bottom Progress Card
          Positioned(
            bottom: 100.h,
            left: 20.w,
            child: Container(
              width: 220.w,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: const Center(child: Icon(Icons.pets, color: Colors.orange)),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                "Progress Hari Ini",
                                style: GoogleFonts.inter(
                                  color: AppColors.textPrimary,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              "4 / 10 Lokasi",
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                fontSize: 10.sp,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        LinearProgressIndicator(
                          value: 0.4,
                          backgroundColor: AppColors.borderCard,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                          minHeight: 6.h,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),

          // Bottom Right Location Button
          Positioned(
            bottom: 100.h,
            right: 20.w,
            child: _buildFloatingButton(Icons.my_location, label: "Lokasi Saya"),
          ),

          // Pilih Tantangan Button
          Positioned(
            bottom: 20.h,
            left: 20.w,
            right: 20.w,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.r),
                ),
              ),
              onPressed: _onPilihTantangan,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flag, color: Colors.white, size: 24.w),
                  SizedBox(width: 8.w),
                  Text(
                    "Pilih Tantangan",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton(IconData icon, {String? label}) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textPrimary, size: 24.w),
          if (label != null) SizedBox(height: 4.h),
          if (label != null)
            Text(
              label,
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPin(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Icon(icon, color: Colors.white, size: 20.w),
        ),
        SizedBox(height: 4.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 10.sp),
          ),
        )
      ],
    );
  }
}
