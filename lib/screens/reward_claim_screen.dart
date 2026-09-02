import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_colors.dart';

class RewardClaimScreen extends StatefulWidget {
  const RewardClaimScreen({super.key});

  @override
  State<RewardClaimScreen> createState() => _RewardClaimScreenState();
}

class _RewardClaimScreenState extends State<RewardClaimScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedWallet; // 'DANA', 'GoPay', 'ShopeePay'
  bool _isProcessing = false;

  // Formatting helper: 100000 -> "100.000"
  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // Validation rule:
  // 1. Points >= 100,000
  // 2. Phone number not empty (and minimum 9 digits)
  // 3. E-wallet selected
  bool _isFormValid(int userPoints) {
    final phone = _phoneController.text.trim();
    return userPoints >= 100000 &&
        phone.isNotEmpty &&
        phone.length >= 9 &&
        _selectedWallet != null &&
        !_isProcessing;
  }

  void _handleRedeem(GameProvider provider) async {
    final phone = _phoneController.text.trim();
    final wallet = _selectedWallet;

    if (!_isFormValid(provider.totalPoints) || wallet == null) return;

    setState(() {
      _isProcessing = true;
    });

    // Simulate quick network processing
    await Future.delayed(const Duration(milliseconds: 600));

    // Deduct 100,000 points
    final success = provider.deductPoints(100000);

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });

      if (success) {
        // Reset form
        _phoneController.clear();
        setState(() {
          _selectedWallet = null;
        });

        // Show Success AlertDialog
        _showSuccessDialog(wallet, phone);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Poin kamu tidak mencukupi untuk melakukan penukaran.',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(String wallet, String phone) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          backgroundColor: Colors.white,
          titlePadding: EdgeInsets.only(top: 24.h, left: 20.w, right: 20.w),
          contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          actionsPadding: EdgeInsets.only(bottom: 20.h, left: 20.w, right: 20.w),
          title: Column(
            children: [
              Container(
                width: 70.w,
                height: 70.w,
                decoration: BoxDecoration(
                  color: AppColors.softYellow,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accentGreen, width: 2.5.w),
                ),
                child: Center(
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.accentGreen,
                    size: 46.w,
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                'Penukaran Berhasil!',
                style: GoogleFonts.inter(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryGreen,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Permintaan penukaran saldo E-Wallet kamu sedang diproses.',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6EFEF),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.neutralGray.withOpacity(0.6)),
                ),
                child: Column(
                  children: [
                    _buildReceiptRow('Nominal Saldo', 'Rp 50.000', isBold: true),
                    const Divider(height: 18),
                    _buildReceiptRow('Metode E-Wallet', wallet),
                    SizedBox(height: 6.h),
                    _buildReceiptRow('Nomor Tujuan', phone),
                    SizedBox(height: 6.h),
                    _buildReceiptRow('Poin Digunakan', '100.000 Poin'),
                    SizedBox(height: 6.h),
                    _buildReceiptRow('Estimasi', 'Maks. 1x24 Jam Kerja'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                ),
                child: Text(
                  'Selesai',
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: isBold ? AppColors.primaryGreen : AppColors.black,
          ),
        ),
      ],
    );
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
          'Tukar Poin',
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
          final userPoints = provider.totalPoints;
          final canRedeem = _isFormValid(userPoints);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Current Balance Card
                _buildBalanceCard(userPoints),
                SizedBox(height: 16.h),

                // 2. Conversion Info Banner
                _buildConversionBanner(),
                SizedBox(height: 24.h),

                // 3. E-Wallet Selection
                Text(
                  'Pilih Metode E-Wallet',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Pilih salah satu akun dompet digital yang aktif.',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 14.h),
                _buildEWalletSelection(),
                SizedBox(height: 24.h),

                // 4. Target Account Input
                Text(
                  'Nomor Handphone (E-Wallet)',
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),
                SizedBox(height: 8.h),
                _buildPhoneInput(),
                SizedBox(height: 8.h),

                // Helper note if points are insufficient
                if (userPoints < 100000) ...[
                  Padding(
                    padding: EdgeInsets.only(left: 4.w, top: 4.h),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 14.w,
                          color: AppColors.errorRed,
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            'Poin kamu belum mencukupi (minimal 100.000 poin).',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: AppColors.errorRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 32.h),

                // 5. CTA Button: "Tukar Sekarang"
                _buildCtaButton(canRedeem, () => _handleRedeem(provider)),
                SizedBox(height: 24.h),
              ],
            ),
          );
        },
      ),
    );
  }

  // 1. Current Balance Top Banner
  Widget _buildBalanceCard(int totalPoints) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: AppColors.softYellow, // #F7FAC7
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.accentGreen.withOpacity(0.4),
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.08),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        children: [
          // Star Icon Container
          Container(
            width: 54.w,
            height: 54.w,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.stars_rounded,
                color: const Color(0xFFFFB300), // Gold Star
                size: 38.w,
              ),
            ),
          ),
          SizedBox(width: 16.w),

          // Balance Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saldo Poin Kamu',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _formatNumber(totalPoints),
                      style: GoogleFonts.inter(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryGreen,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'Poin',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentGreen,
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

  // 2. Conversion Info Banner
  Widget _buildConversionBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF6EFEF),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFF96B55F).withOpacity(0.5),
          width: 1.5.w,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: const Color(0xFF96B55F).withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.currency_exchange_rounded,
              color: AppColors.primaryGreen,
              size: 20.w,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              '⭐ 100.000 Poin = Rp 50.000 Saldo E-Wallet',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. E-Wallet Options (DANA, GoPay, ShopeePay)
  Widget _buildEWalletSelection() {
    final wallets = [
      {
        'id': 'DANA',
        'name': 'DANA',
        'color': const Color(0xFF118EEA), // Blue
        'icon': Icons.account_balance_wallet_rounded,
      },
      {
        'id': 'GoPay',
        'name': 'GoPay',
        'color': const Color(0xFF00AA13), // Green
        'icon': Icons.payments_rounded,
      },
      {
        'id': 'ShopeePay',
        'name': 'ShopeePay',
        'color': const Color(0xFFEE4D2D), // Orange
        'icon': Icons.shopping_bag_rounded,
      },
    ];

    return Row(
      children: wallets.map((wallet) {
        final isSelected = _selectedWallet == wallet['id'];
        final color = wallet['color'] as Color;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedWallet = wallet['id'] as String;
              });
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.08) : const Color(0xFFF6EFEF),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isSelected ? color : AppColors.neutralGray.withOpacity(0.6),
                  width: isSelected ? 2.5.w : 1.w,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.25),
                          blurRadius: 8.r,
                          offset: Offset(0, 3.h),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 44.w,
                        height: 44.w,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.16),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          wallet['icon'] as IconData,
                          color: color,
                          size: 24.w,
                        ),
                      ),
                      if (isSelected)
                        Positioned(
                          top: -2.h,
                          right: -2.w,
                          child: Container(
                            padding: EdgeInsets.all(2.w),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 12.w,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    wallet['name'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? color : AppColors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // 4. Phone Number Input
  Widget _buildPhoneInput() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6EFEF), // Figma token #F6EFEF
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.neutralGray.withOpacity(0.6),
          width: 1.w,
        ),
      ),
      child: TextField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        style: GoogleFonts.inter(
          fontSize: 15.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
        decoration: InputDecoration(
          hintText: 'Contoh: 081234567890',
          hintStyle: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            color: AppColors.neutralGray,
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.phone_android_rounded,
                  color: AppColors.primaryGreen,
                  size: 20.w,
                ),
                SizedBox(width: 6.w),
                Text(
                  '+62',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  width: 1.w,
                  height: 18.h,
                  color: AppColors.neutralGray,
                ),
              ],
            ),
          ),
          suffixIcon: _phoneController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    size: 18.w,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    _phoneController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        ),
      ),
    );
  }

  // 5. Full-width Pill-shaped CTA Button
  Widget _buildCtaButton(bool isEnabled, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF96B55F), // Accent Green #96B55F
          disabledBackgroundColor: const Color(0xFFD9D9D9), // Neutral Gray
          elevation: isEnabled ? 3 : 0,
          shadowColor: const Color(0xFF96B55F).withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26.r), // Pill shaped
          ),
        ),
        child: _isProcessing
            ? SizedBox(
                width: 22.w,
                height: 22.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Tukar Sekarang',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: isEnabled ? Colors.white : const Color(0xFF888888),
                ),
              ),
      ),
    );
  }
}
