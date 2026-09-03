import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../helpers/permission_helper.dart';
import '../helpers/unity_bridge.dart';
import '../helpers/user_info.dart';
import '../providers/game_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'ar_mission.dart';
import 'cari_objek.dart';
import 'profile_screen.dart';
import 'quiz_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  // Navigation & Location controllers
  GoogleMapController? _googleMapController;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;

  // View mode: 3D Unity Campus World vs 2D Global Map
  bool _is3DWorldMode = true;
  bool _isOutsideCampus = false;
  bool _isLocationLoaded = false;
  bool _isGuest = false;
  double _distanceToCampus = 0.0;
  double _currentHeading = 0.0; // Compass heading in degrees

  // Campus Center Coordinates (Example: Central Campus Plaza)
  final double campusLat = -6.1753924;
  final double campusLng = 106.8271528;
  final double campusRadiusMeters = 600.0;

  // Animation controller for Pokemon GO-style pulses and 3D radar
  late AnimationController _pulseAnimController;

  // Active Campus Quests list
  final List<QuestMarker> _campusQuests = [
    const QuestMarker(
      id: 'perpus_pusat',
      name: 'Perpustakaan Kampus',
      latitude: -6.17510,
      longitude: 106.82680,
      radius: 25.0,
      questType: 'quiz',
      points: 100,
    ),
    const QuestMarker(
      id: 'lab_inovasi_ar',
      name: 'Lab Inovasi AR',
      latitude: -6.17565,
      longitude: 106.82750,
      radius: 30.0,
      questType: 'cari_objek',
      points: 150,
    ),
    const QuestMarker(
      id: 'gedung_rektorat',
      name: 'Gedung Rektorat 3D',
      latitude: -6.17490,
      longitude: 106.82740,
      radius: 35.0,
      questType: 'ar_mission',
      points: 200,
    ),
    const QuestMarker(
      id: 'plaza_mahasiswa',
      name: 'Plaza Mahasiswa',
      latitude: -6.17580,
      longitude: 106.82690,
      radius: 25.0,
      questType: 'quiz',
      points: 120,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _setupUnityBridge();
    _checkGuestStatus();
    _initLocationTracking();
  }

  @override
  void dispose() {
    _pulseAnimController.dispose();
    _positionStreamSubscription?.cancel();
    _googleMapController?.dispose();
    super.dispose();
  }

  void _setupUnityBridge() {
    final bridge = UnityBridge();

    // Listen to incoming tap events from Unity 3D engine
    bridge.onMarkerTapped = (markerId, questType) {
      _handleMarkerTapped(markerId, questType);
    };

    // Send initial quest markers to Unity
    WidgetsBinding.instance.addPostFrameCallback((_) {
      bridge.spawnCampusQuests(_campusQuests);
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      bridge.setActiveMascot(gameProvider.selectedCharacter);
    });
  }

  void _handleMarkerTapped(String markerId, String questType) {
    if (!mounted) return;

    final quest = _campusQuests.firstWhere(
      (q) => q.id == markerId,
      orElse: () => QuestMarker(
        id: markerId,
        name: 'Misi Kampus',
        latitude: campusLat,
        longitude: campusLng,
        questType: questType,
        points: 100,
      ),
    );

    // Show quest briefing bottom sheet and launch challenge
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _buildQuestBriefingSheet(quest),
    );
  }

  Future<void> _checkGuestStatus() async {
    bool guest = await UserInfo().isGuest();
    if (mounted) {
      setState(() {
        _isGuest = guest;
      });
    }
  }

  Future<void> _initLocationTracking() async {
    // Audit permissions with PermissionHelper
    bool hasPermission = await PermissionHelper.hasLocationPermission();
    if (!hasPermission) {
      if (mounted) {
        await PermissionHelper.requestAppPermissions(context);
      }
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          _isLocationLoaded = true;
        });
      }
      return;
    }

    try {
      Position initialPos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _updatePosition(initialPos);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLocationLoaded = true;
        });
      }
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3, // Stream every 3 meters for smooth 3D character movement
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      _updatePosition(position);
    });
  }

  void _updatePosition(Position position) {
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      campusLat,
      campusLng,
    );

    final outside = distance > campusRadiusMeters;
    final heading = position.heading.isNaN ? 0.0 : position.heading;

    if (mounted) {
      setState(() {
        _currentPosition = position;
        _distanceToCampus = distance;
        _isOutsideCampus = outside;
        _currentHeading = heading;
        _isLocationLoaded = true;
      });
    }

    // Bi-directional bridge: Stream real-time GPS location to Unity
    UnityBridge().setUserLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      heading: heading,
    );
  }

  void _recenterPlayer() {
    if (_is3DWorldMode) {
      // Re-align 3D world view to current location
      if (_currentPosition != null) {
        UnityBridge().setUserLocation(
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          heading: _currentHeading,
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pusat peta disesuaikan ke posisi pemain'),
          duration: Duration(seconds: 1),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    } else {
      if (_googleMapController != null && _currentPosition != null) {
        _googleMapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              zoom: 17.5,
              tilt: 45.0,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocationLoaded) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.accentGreen),
              SizedBox(height: 18.h),
              Text(
                'Menghubungkan GPS & Dunia 3D...',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Sinkronisasi engine Unity AR-Campus',
                style: GoogleFonts.inter(
                  color: Colors.white60,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ----------------------------------------------------
          // 1. BACKGROUND / ENGINE LAYER: 3D Unity World / Maps
          // ----------------------------------------------------
          Positioned.fill(
            child: _is3DWorldMode ? _build3DUnityEngineLayer() : _buildGoogleMapsLayer(),
          ),

          // ----------------------------------------------------
          // 2. FOREGROUND FLUTTER OVERLAY LAYER: Non-blocking HUD
          // ----------------------------------------------------
          Positioned.fill(
            child: _buildForegroundHUD(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 1. BACKGROUND ENGINE LAYER (Unity 3D / Isometric Simulation)
  // ============================================================
  Widget _build3DUnityEngineLayer() {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        final activeMascot = gameProvider.selectedCharacter;
        String assetPath;
        switch (activeMascot.toLowerCase()) {
          case 'tiger':
            assetPath = 'assets/images/tiger_mascot.jpg';
            break;
          case 'cat':
            assetPath = 'assets/images/cat_mascot.jpg';
            break;
          case 'crocodile':
            assetPath = 'assets/images/crocodile_mascot.jpg';
            break;
          case 'dragon':
          default:
            assetPath = 'assets/images/dragon_mascot.jpg';
            break;
        }

        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.3,
              colors: [
                Color(0xFF1E293B),
                Color(0xFF0F172A),
                Color(0xFF020617),
              ],
            ),
          ),
          child: AnimatedBuilder(
            animation: _pulseAnimController,
            builder: (context, child) {
              final val = _pulseAnimController.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Terrain Radar Rings (Sonar GPS Pulse)
                  Container(
                    width: 320.w + (val * 40.w),
                    height: 320.w + (val * 40.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.accentGreen.withValues(alpha: (0.25 - (val * 0.20)).clamp(0.01, 1.0)),
                        width: 2.w,
                      ),
                    ),
                  ),
                  Container(
                    width: 200.w,
                    height: 200.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.accentGreen.withValues(alpha: 0.35),
                        width: 1.5.w,
                      ),
                    ),
                  ),

                  // 3D Campus Environment Grid Lines
                  CustomPaint(
                    size: const Size(double.infinity, double.infinity),
                    painter: _Campus3DGridPainter(pulseValue: val),
                  ),

                  // 3D Quest Checkpoint Markers
                  ..._build3DQuestMarkers(),

                  // Center 3D Player Avatar (hyuvi.fbx representation)
                  Transform.translate(
                    offset: Offset(0, -12.h + (math.sin(val * 2 * math.pi) * 8.h)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 3D Avatar Glow
                        Container(
                          width: 110.w,
                          height: 110.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.accentGreen, width: 3.5.w),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentGreen.withValues(alpha: 0.55),
                                blurRadius: 30.r,
                                spreadRadius: 6.r,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              assetPath,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.smart_toy_rounded,
                                size: 55,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),

                        // Active Hero Tag
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(color: AppColors.accentGreen, width: 1.5.w),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.directions_run_rounded, color: AppColors.softYellow, size: 14.w),
                              SizedBox(width: 5.w),
                              Text(
                                '$activeMascot Hero (hyuvi.fbx)',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  List<Widget> _build3DQuestMarkers() {
    // Relative positions in 3D isometric plane for campus POIs
    final offsets = [
      const Offset(-110, -160), // Perpustakaan (Top Left)
      const Offset(115, -130),  // Lab AR (Top Right)
      const Offset(-105, 140),  // Gedung Rektorat (Bottom Left)
      const Offset(110, 160),   // Plaza Mahasiswa (Bottom Right)
    ];

    List<Widget> markers = [];
    for (int i = 0; i < _campusQuests.length && i < offsets.length; i++) {
      final quest = _campusQuests[i];
      final offset = offsets[i];

      IconData questIcon;
      Color questColor;
      switch (quest.questType) {
        case 'quiz':
          questIcon = Icons.help_outline_rounded;
          questColor = const Color(0xFFFFA000); // Amber
          break;
        case 'cari_objek':
          questIcon = Icons.search_rounded;
          questColor = const Color(0xFF00E676); // Neon Green
          break;
        case 'ar_mission':
        default:
          questIcon = Icons.view_in_ar_rounded;
          questColor = const Color(0xFF00B0FF); // Sky Blue
          break;
      }

      markers.add(
        Transform.translate(
          offset: Offset(offset.dx.w, offset.dy.h),
          child: GestureDetector(
            onTap: () {
              // Trigger bi-directional message contract
              UnityBridge().handleInboundMessage(
                '{"event":"OnMarkerTapped","markerId":"${quest.id}","questType":"${quest.questType}"}',
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing Quest Pin
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    shape: BoxShape.circle,
                    border: Border.all(color: questColor, width: 2.5.w),
                    boxShadow: [
                      BoxShadow(
                        color: questColor.withValues(alpha: 0.6),
                        blurRadius: 18.r,
                        spreadRadius: 3.r,
                      ),
                    ],
                  ),
                  child: Icon(questIcon, color: Colors.white, size: 22.w),
                ),
                SizedBox(height: 6.h),

                // Quest Label
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: questColor.withValues(alpha: 0.6), width: 1.w),
                  ),
                  child: Column(
                    children: [
                      Text(
                        quest.name,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '+${quest.points} pts',
                        style: GoogleFonts.inter(
                          color: AppColors.softYellow,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return markers;
  }

  Widget _buildGoogleMapsLayer() {
    LatLng target = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : LatLng(campusLat, campusLng);

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: target,
        zoom: 16.5,
        tilt: 30.0,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      compassEnabled: false,
      zoomControlsEnabled: false,
      onMapCreated: (controller) {
        _googleMapController = controller;
      },
      circles: {
        Circle(
          circleId: const CircleId('campus_geofence'),
          center: LatLng(campusLat, campusLng),
          radius: campusRadiusMeters,
          fillColor: AppColors.accentGreen.withValues(alpha: 0.15),
          strokeColor: AppColors.accentGreen,
          strokeWidth: 2,
        ),
      },
    );
  }

  // ============================================================
  // 2. FOREGROUND FLUTTER OVERLAY LAYER (Lightweight, Non-blocking HUD)
  // ============================================================
  Widget _buildForegroundHUD() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top HUD Row: GPS Pill + Compass + Mini Mascot Profile
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // GPS Status Pill
                _buildGpsStatusPill(),

                // Right group: Compass & Mini Profile
                Row(
                  children: [
                    // Compass indicator
                    _buildCompassWidget(),
                    SizedBox(width: 10.w),

                    // Mini Profile Widget (displays active mascot from profile_screen.dart)
                    _buildMiniProfileWidget(),
                  ],
                ),
              ],
            ),

            const Spacer(),

            // Bottom Floating Controls: Recenter, Mode Switcher, & Proximity Alert
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Mode Toggle Button (3D World ⇄ 2D Map)
                _buildModeToggleButton(),

                // Recenter GPS Action Button
                FloatingActionButton(
                  heroTag: 'fab_recenter',
                  backgroundColor: AppColors.primaryGreen,
                  elevation: 6,
                  onPressed: _recenterPlayer,
                  child: const Icon(Icons.my_location_rounded, color: Colors.white),
                ),
              ],
            ),
            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }

  Widget _buildGpsStatusPill() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.accentGreen, width: 1.5.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Live pulse dot
          Container(
            width: 8.w,
            height: 8.w,
            decoration: const BoxDecoration(
              color: Color(0xFF00E676),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _is3DWorldMode ? '3D Campus World' : 'Peta GPS 2D',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _isOutsideCampus
                  ? '${(_distanceToCampus / 1000).toStringAsFixed(1)} km dari Kampus'
                  : 'Zona Kampus • Akurasi Tinggi',
                style: GoogleFonts.inter(
                  color: AppColors.softYellow,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompassWidget() {
    return Container(
      width: 44.w,
      height: 44.w,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.9),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.accentGreen, width: 1.5.w),
      ),
      child: Center(
        child: Transform.rotate(
          angle: -(_currentHeading * (math.pi / 180.0)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.navigation_rounded, color: Colors.redAccent, size: 20.w),
              Text(
                'N',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniProfileWidget() {
    return Consumer<GameProvider>(
      builder: (context, provider, _) {
        final mascot = provider.selectedCharacter;
        String asset;
        switch (mascot.toLowerCase()) {
          case 'tiger':
            asset = 'assets/images/tiger_mascot.jpg';
            break;
          case 'cat':
            asset = 'assets/images/cat_mascot.jpg';
            break;
          case 'crocodile':
            asset = 'assets/images/crocodile_mascot.jpg';
            break;
          case 'dragon':
          default:
            asset = 'assets/images/dragon_mascot.jpg';
            break;
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(color: AppColors.accentGreen, width: 1.5.w),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 14.r,
                  backgroundColor: AppColors.softYellow,
                  backgroundImage: AssetImage(asset),
                ),
                SizedBox(width: 8.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      mascot,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Lvl ${provider.level}',
                      style: GoogleFonts.inter(
                        color: AppColors.softYellow,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w600,
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

  Widget _buildModeToggleButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(25.r),
        border: Border.all(color: AppColors.accentGreen, width: 1.5.w),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleOption(
            label: '3D World',
            icon: Icons.view_in_ar_rounded,
            isSelected: _is3DWorldMode,
            onTap: () => setState(() => _is3DWorldMode = true),
          ),
          _buildToggleOption(
            label: '2D Map',
            icon: Icons.map_rounded,
            isSelected: !_is3DWorldMode,
            onTap: () => setState(() => _is3DWorldMode = false),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16.w,
              color: isSelected ? AppColors.primaryGreen : Colors.white70,
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primaryGreen : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestBriefingSheet(QuestMarker quest) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        border: Border.all(color: AppColors.accentGreen, width: 1.5.w),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 18.h),

            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.accentGreen),
                  ),
                  child: const Icon(Icons.location_on_rounded, color: AppColors.softYellow, size: 28),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quest.name,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Checkpoint Kampus Terdeteksi',
                        style: GoogleFonts.inter(
                          color: AppColors.accentGreen,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            Text(
              'Anda telah memasuki radius interaksi 3D (${quest.radius.toInt()} meter). Selesaikan tantangan untuk mengklaim poin reward!',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 13.sp, height: 1.4),
            ),
            if (_isGuest) ...[
              SizedBox(height: 10.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.amber, size: 16),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Mode Tamu: Poin dari misi ini tidak akan tersimpan permanen.',
                        style: GoogleFonts.inter(color: Colors.amber[200], fontSize: 11.sp),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 20.h),

            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: AppColors.softYellow.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: AppColors.softYellow),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: AppColors.softYellow, size: 18),
                      SizedBox(width: 6.w),
                      Text(
                        '+${quest.points} Poin',
                        style: GoogleFonts.inter(
                          color: AppColors.softYellow,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGreen,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _launchQuestScreen(quest.questType);
                    },
                    child: Text(
                      'Mulai Misi',
                      style: GoogleFonts.inter(
                        color: AppColors.primaryGreen,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _launchQuestScreen(String questType) {
    Widget targetScreen;
    switch (questType) {
      case 'quiz':
        targetScreen = const QuizScreen();
        break;
      case 'cari_objek':
        targetScreen = const CariObjekScreen();
        break;
      case 'ar_mission':
      default:
        targetScreen = const ArMissionScreen();
        break;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => targetScreen),
    );
  }
}

/// Custom painter to render isometric grid lines for Pokemon GO-style terrain
class _Campus3DGridPainter extends CustomPainter {
  final double pulseValue;
  _Campus3DGridPainter({required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF334155).withValues(alpha: 0.25)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    const double spacing = 45.0;

    // Draw isometric grid lines
    for (double r = spacing; r < size.width; r += spacing) {
      canvas.drawCircle(center, r, paint);
    }

    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4);
      final p2 = Offset(
        center.dx + math.cos(angle) * size.width,
        center.dy + math.sin(angle) * size.width,
      );
      canvas.drawLine(center, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _Campus3DGridPainter oldDelegate) =>
      oldDelegate.pulseValue != pulseValue;
}
