import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _pickProfileImage(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null && context.mounted) {
        Provider.of<GameProvider>(context, listen: false).updateProfileImage(image.path);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Foto profil berhasil diperbarui! 📸',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            backgroundColor: AppColors.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih foto: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          'Profil',
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<GameProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Editable Profile Picture
                _buildAvatarSection(context, provider),
                SizedBox(height: 12.h),

                // Name & Role Tag
                Text(
                  provider.fullName,
                  style: GoogleFonts.inter(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryGreen,
                  ),
                ),
                SizedBox(height: 4.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.softYellow,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: AppColors.accentGreen.withOpacity(0.5)),
                  ),
                  child: Text(
                    'Level ${provider.level} • Penjelajah Kampus',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
                SizedBox(height: 28.h),

                // 2. User Information Cards
                _buildUserInfoSection(context, provider),
                SizedBox(height: 28.h),

                // 3. 3D Character Selector (Map Mission Avatar)
                _buildCharacterSelectorSection(context, provider),
                SizedBox(height: 30.h),
              ],
            ),
          );
        },
      ),
    );
  }

  // 1. Editable Avatar Section
  Widget _buildAvatarSection(BuildContext context, GameProvider provider) {
    ImageProvider? imageProvider;
    if (provider.profileImagePath != null && File(provider.profileImagePath!).existsSync()) {
      imageProvider = FileImage(File(provider.profileImagePath!));
    } else {
      imageProvider = const AssetImage('assets/images/crocodile_mascot.jpg');
    }

    return Center(
      child: Stack(
        children: [
          // Circular Avatar Container
          Container(
            width: 110.w,
            height: 110.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.softYellow,
              border: Border.all(
                color: AppColors.accentGreen,
                width: 3.5.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGreen.withOpacity(0.12),
                  blurRadius: 16.r,
                  offset: Offset(0, 6.h),
                ),
              ],
            ),
            child: ClipOval(
              child: Image(
                image: imageProvider,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.person_rounded,
                    size: 60.w,
                    color: AppColors.primaryGreen,
                  );
                },
              ),
            ),
          ),

          // Edit / Camera Button Overlay
          Positioned(
            bottom: 2.h,
            right: 2.w,
            child: GestureDetector(
              onTap: () => _pickProfileImage(context),
              child: Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: AppColors.accentGreen,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2.5.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  size: 18.w,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. User Information Cards
  Widget _buildUserInfoSection(BuildContext context, GameProvider provider) {
    final infoItems = [
      {
        'label': 'Nama Lengkap',
        'value': provider.fullName,
        'icon': Icons.badge_outlined,
      },
      {
        'label': 'NIM',
        'value': provider.nim,
        'icon': Icons.credit_card_rounded,
      },
      {
        'label': 'Program Studi',
        'value': provider.studyProgram,
        'icon': Icons.school_outlined,
      },
      {
        'label': 'Email',
        'value': provider.email,
        'icon': Icons.email_outlined,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 12.h),
          child: Text(
            'Informasi Pengguna',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryGreen,
            ),
          ),
        ),
        ...infoItems.map((item) => _buildInfoCard(
              label: item['label'] as String,
              value: item['value'] as String,
              icon: item['icon'] as IconData,
            )),
      ],
    );
  }

  Widget _buildInfoCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF6EFEF), // Figma token #F6EFEF
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.neutralGray.withOpacity(0.5),
          width: 1.w,
        ),
      ),
      child: Row(
        children: [
          // Icon Box
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryGreen,
              size: 22.w,
            ),
          ),
          SizedBox(width: 16.w),

          // Label & Value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.lock_outline_rounded,
            size: 16.w,
            color: AppColors.neutralGray,
          ),
        ],
      ),
    );
  }

  // 3. 3D Character Selector (Map Mission Avatar)
  Widget _buildCharacterSelectorSection(BuildContext context, GameProvider provider) {
    final characters = [
      {
        'id': 'Dragon',
        'name': 'Dragon',
        'title': 'Naga Perkasa',
        'asset': 'assets/images/dragon_mascot.jpg',
      },
      {
        'id': 'Tiger',
        'name': 'Tiger',
        'title': 'Harimau Juara',
        'asset': 'assets/images/tiger_mascot.jpg',
      },
      {
        'id': 'Cat',
        'name': 'Cat',
        'title': 'Kucing Cerdik',
        'asset': 'assets/images/cat_mascot.jpg',
      },
      {
        'id': 'Crocodile',
        'name': 'Crocodile',
        'title': 'Buaya Kampus',
        'asset': 'assets/images/crocodile_mascot.jpg',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 6.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Karakter Misi Peta',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600, // Inter Semi Bold 16px as required
                  color: AppColors.primaryGreen,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF96B55F).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  'Aktif: ${provider.selectedCharacter}',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 12.h),
          child: Text(
            'Pilih karakter 3D untuk menemani misi pencarian AR di peta kampus.',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ),

        // Horizontally Scrollable Row
        SizedBox(
          height: 140.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: characters.length,
            separatorBuilder: (context, index) => SizedBox(width: 14.w),
            itemBuilder: (context, index) {
              final char = characters[index];
              final isSelected = provider.selectedCharacter.toLowerCase() == (char['id'] as String).toLowerCase();

              return GestureDetector(
                onTap: () {
                  provider.selectCharacter(char['id'] as String);
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Karakter "${char['name']}" dipilih untuk misi peta!',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                      ),
                      duration: const Duration(seconds: 2),
                      backgroundColor: AppColors.primaryGreen,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                    ),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 105.w,
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFF7FAC7) : const Color(0xFFF6EFEF),
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF96B55F) : AppColors.neutralGray.withOpacity(0.5),
                      width: isSelected ? 3.5.w : 1.5.w,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF96B55F).withOpacity(0.35),
                              blurRadius: 10.r,
                              offset: Offset(0, 4.h),
                            )
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4.r,
                              offset: Offset(0, 2.h),
                            )
                          ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Thumbnail Image
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12.r),
                              child: Image.asset(
                                char['asset'] as String,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: AppColors.softYellow,
                                    child: Icon(
                                      Icons.pets_rounded,
                                      size: 36.w,
                                      color: AppColors.primaryGreen,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: 6.h),
                          // Character Name
                          Text(
                            char['name'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected ? AppColors.primaryGreen : AppColors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),

                      // Checkmark Badge overlay when selected
                      if (isSelected)
                        Positioned(
                          top: -4.h,
                          right: -4.w,
                          child: Container(
                            padding: EdgeInsets.all(3.w),
                            decoration: const BoxDecoration(
                              color: Color(0xFF96B55F),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                )
                              ],
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size: 14.w,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
