import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;
  const CustomBottomNav({super.key, required this.currentIndex, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white, // White background from Figma specification
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 63.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                activeIcon: Icons.home_rounded,
                inactiveIcon: Icons.home_outlined,
                label: "Home",
                index: 0,
              ),
              _buildNavItem(
                activeIcon: Icons.map_rounded,
                inactiveIcon: Icons.map_outlined,
                label: "Peta",
                index: 1,
              ),
              _buildNavItem(
                activeIcon: Icons.stars_rounded,
                inactiveIcon: Icons.stars_outlined,
                label: "Reward",
                index: 2,
              ),
              _buildNavItem(
                activeIcon: Icons.person_rounded,
                inactiveIcon: Icons.person_outline_rounded,
                label: "Profile",
                index: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData activeIcon,
    required IconData inactiveIcon,
    required String label,
    required int index,
  }) {
    bool isSelected = currentIndex == index;
    Color itemColor = isSelected ? AppColors.primaryGreen : AppColors.primaryGreen.withValues(alpha: 0.45);
    IconData icon = isSelected ? activeIcon : inactiveIcon;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (onTap != null) {
            onTap!(index);
          }
        },
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: itemColor,
                size: 26.w,
              ),
              SizedBox(height: 3.h),
              Text(
                label,
                style: AppTheme.navLabel.copyWith(
                  fontSize: 13.sp,
                  color: itemColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
