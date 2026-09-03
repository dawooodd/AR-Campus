import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../helpers/leaderboard_repository.dart';
import '../model/leaderboard_user.dart';
import '../providers/game_provider.dart';
import '../theme/app_colors.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<LeaderboardUser> _leaderboard = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
    });

    final data = await LeaderboardRepository.getLeaderboard();

    if (mounted) {
      setState(() {
        _leaderboard = data;
        _isLoading = false;
      });
    }
  }

  String _formatPoints(int points) {
    return points.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
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
        title: Column(
          children: [
            Text(
              'Papan Peringkat',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Musim 1 • Kampus Utama',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.softYellow,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadLeaderboard,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            )
          : Column(
              children: [
                // Scrollable content: Top 3 Podium + List of 4-10
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadLeaderboard,
                    color: AppColors.primaryGreen,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                      child: Column(
                        children: [
                          // 1. Top 3 Podium View
                          if (_leaderboard.length >= 3)
                            _buildTop3Podium(_leaderboard[0], _leaderboard[1], _leaderboard[2]),
                          SizedBox(height: 24.h),

                          // Header List
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Peringkat 4 – 10',
                                style: GoogleFonts.inter(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                              Text(
                                'Total Poin',
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),

                          // 2. Top 4-10 List View
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _leaderboard.length > 3 ? _leaderboard.length - 3 : 0,
                            separatorBuilder: (context, index) => SizedBox(height: 8.h),
                            itemBuilder: (context, index) {
                              final user = _leaderboard[index + 3];
                              return _buildUserListItem(user);
                            },
                          ),
                          SizedBox(height: 16.h),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Sticky Current User Footer
                _buildCurrentUserStickyFooter(),
              ],
            ),
    );
  }

  // 1. Top 3 Podium Widget
  Widget _buildTop3Podium(LeaderboardUser rank1, LeaderboardUser rank2, LeaderboardUser rank3) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 12.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF7FAC7).withValues(alpha: 0.6),
            const Color(0xFFF6EFEF),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.4), width: 1.5.w),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Rank 2 (Silver)
              Expanded(
                child: _buildPodiumColumn(
                  user: rank2,
                  rank: 2,
                  podiumHeight: 110.h,
                  badgeColor: const Color(0xFFB0BEC5), // Silver
                  accentColor: const Color(0xFF78909C),
                ),
              ),

              // Rank 1 (Gold) - Center & Tallest
              Expanded(
                child: _buildPodiumColumn(
                  user: rank1,
                  rank: 1,
                  podiumHeight: 140.h,
                  badgeColor: const Color(0xFFFFD700), // Gold
                  accentColor: const Color(0xFFFFA000),
                  isChampion: true,
                ),
              ),

              // Rank 3 (Bronze)
              Expanded(
                child: _buildPodiumColumn(
                  user: rank3,
                  rank: 3,
                  podiumHeight: 95.h,
                  badgeColor: const Color(0xFFCD7F32), // Bronze
                  accentColor: const Color(0xFF8D6E63),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumColumn({
    required LeaderboardUser user,
    required int rank,
    required double podiumHeight,
    required Color badgeColor,
    required Color accentColor,
    bool isChampion = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Crown icon for Champion
        if (isChampion)
          Icon(
            Icons.workspace_premium_rounded,
            color: const Color(0xFFFFB300),
            size: 28.w,
          )
        else
          SizedBox(height: 6.h),

        // Avatar with Rank Badge
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: isChampion ? 68.w : 56.w,
              height: isChampion ? 68.w : 56.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: badgeColor,
                  width: isChampion ? 3.5.w : 2.5.w,
                ),
                boxShadow: [
                  BoxShadow(
                    color: badgeColor.withValues(alpha: 0.35),
                    blurRadius: 10.r,
                    offset: Offset(0, 3.h),
                  ),
                ],
              ),
              child: CircleAvatar(
                backgroundColor: AppColors.softYellow,
                child: Text(
                  user.name.substring(0, 1).toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: isChampion ? 24.sp : 18.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            ),
            // Rank Number Badge Pill
            Positioned(
              bottom: -6.h,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: Colors.white, width: 1.5.w),
                ),
                child: Text(
                  '#$rank',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),

        // User Name
        Text(
          user.name,
          style: GoogleFonts.inter(
            fontSize: isChampion ? 13.sp : 12.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryGreen,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 2.h),

        // Points
        Text(
          '${_formatPoints(user.points)} pts',
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.accentGreen,
          ),
        ),
        SizedBox(height: 8.h),

        // Podium Pillar
        Container(
          width: double.infinity,
          height: podiumHeight,
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accentColor.withValues(alpha: 0.25),
                badgeColor.withValues(alpha: 0.45),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12.r),
              topRight: Radius.circular(12.r),
            ),
            border: Border.all(color: badgeColor.withValues(alpha: 0.6), width: 1.5.w),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$rank',
                style: GoogleFonts.inter(
                  fontSize: isChampion ? 32.sp : 26.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryGreen.withValues(alpha: 0.85),
                ),
              ),
              Icon(
                Icons.military_tech_rounded,
                color: accentColor,
                size: 20.w,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 2. Top 4-10 List Item Widget
  Widget _buildUserListItem(LeaderboardUser user) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF6EFEF), // Subtle #F6EFEF background
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.neutralGray.withValues(alpha: 0.5),
          width: 1.w,
        ),
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${user.rank}',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),

          // User Avatar Thumbnail
          CircleAvatar(
            radius: 20.r,
            backgroundColor: AppColors.softYellow,
            child: Text(
              user.name.substring(0, 1).toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
          SizedBox(width: 12.w),

          // Name and Study Program
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  user.studyProgram,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Points
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatPoints(user.points),
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryGreen,
                ),
              ),
              Text(
                'Poin',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.accentGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Sticky Current User Footer
  Widget _buildCurrentUserStickyFooter() {
    return Consumer<GameProvider>(
      builder: (context, provider, child) {
        final currentPoints = provider.totalPoints;
        final isGuest = provider.isGuest;

        // Calculate dynamic rank compared to leaderboard
        int calculatedRank = 11;
        if (!isGuest) {
          for (int i = 0; i < _leaderboard.length; i++) {
            if (currentPoints > _leaderboard[i].points) {
              calculatedRank = i + 1;
              break;
            }
          }
        }

        ImageProvider? avatarImage;
        if (provider.profileImagePath != null && File(provider.profileImagePath!).existsSync()) {
          avatarImage = FileImage(File(provider.profileImagePath!));
        } else {
          avatarImage = const AssetImage('assets/images/crocodile_mascot.jpg');
        }

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen, // Dark Green background for distinct highlight
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 16.r,
                offset: Offset(0, -4.h),
              ),
            ],
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(22.r),
              topRight: Radius.circular(22.r),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                // User Rank Pill
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Text(
                    isGuest ? 'Guest' : '#$calculatedRank',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),

                // User Profile Picture
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accentGreen, width: 2.w),
                  ),
                  child: ClipOval(
                    child: Image(
                      image: avatarImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              provider.fullName,
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                            decoration: BoxDecoration(
                              color: AppColors.softYellow,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              'Kamu',
                              style: GoogleFonts.inter(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        isGuest ? 'Mode Penjelajah Tamu' : provider.studyProgram,
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w400,
                          color: Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Points
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatPoints(currentPoints),
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.softYellow,
                      ),
                    ),
                    Text(
                      'Poin Kamu',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
