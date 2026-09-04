import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../helpers/location_manager.dart';
import '../helpers/permission_helper.dart';
import '../helpers/unity_bridge.dart';
import '../helpers/user_info.dart';
import '../providers/game_provider.dart';
import '../theme/app_colors.dart';
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
  // Location Manager & Controllers
  final LocationManager _locationManager = LocationManager();
  GoogleMapController? _googleMapController;
  UnityWidgetController? _unityWidgetController;

  // Local state
  bool _isUnityLoaded = false;
  bool _isGuest = false;

  // Animation controller for Pokemon GO-style sonar radar pulses
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

    // Listen to continuous location & geofencing updates
    _locationManager.addListener(_onLocationManagerUpdated);
    _initTracking();
  }

  @override
  void dispose() {
    _locationManager.removeListener(_onLocationManagerUpdated);
    _pulseAnimController.dispose();
    _googleMapController?.dispose();
    _unityWidgetController?.dispose();
    super.dispose();
  }

  Future<void> _initTracking() async {
    // Request permission if needed
    final hasPermission = await PermissionHelper.hasLocationPermission();
    if (!hasPermission && mounted) {
      await PermissionHelper.requestAppPermissions(context);
    }
    await _locationManager.startLocationTracking();
  }

  void _setupUnityBridge() {
    final bridge = UnityBridge();

    // Listen to incoming tap events from Unity 3D engine
    bridge.onMarkerTapped = (markerId, questType) {
      _handleMarkerTapped(markerId, questType);
    };

    bridge.onUnityEngineLoaded = (isReady) {
      if (mounted) {
        setState(() {
          _isUnityLoaded = isReady;
        });
      }
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      bridge.spawnCampusQuests(_campusQuests);
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      bridge.setActiveMascot(gameProvider.selectedCharacter);
    });
  }

  Future<void> _checkGuestStatus() async {
    bool guest = await UserInfo().isGuest();
    if (mounted) {
      setState(() {
        _isGuest = guest;
      });
    }
  }

  // ===========================================================================
  // FLUTTER ⇄ UNITY COMMUNICATION BRIDGE & GPS INJECTION
  // ===========================================================================
  void _onLocationManagerUpdated() {
    if (!mounted) return;
    setState(() {});

    final pos = _locationManager.currentPosition;
    if (pos == null) return;

    // Requirement 4:
    // When the UnityWidget is active, Flutter must act as the GPS source of truth.
    // On every valid GPS update, format coordinates as "latitude,longitude".
    // Inject via _unityWidgetController.postMessage('PlayerController', 'UpdateGPSPosition', gpsString)
    if (_locationManager.isInsideCampus && _unityWidgetController != null) {
      final gpsString = '${pos.latitude},${pos.longitude}';
      try {
        _unityWidgetController!.postMessage(
          'PlayerController',
          'UpdateGPSPosition',
          gpsString,
        );
        debugPrint('[MapScreen -> Unity] Injected GPS: PlayerController.UpdateGPSPosition($gpsString)');
      } catch (e) {
        debugPrint('[MapScreen] postMessage error: $e');
      }
    }

    // Sync legacy bridge payload
    UnityBridge().setUserLocation(
      latitude: pos.latitude,
      longitude: pos.longitude,
      heading: _locationManager.currentHeading,
    );
  }

  void _onUnityCreated(UnityWidgetController controller) {
    debugPrint('[MapScreen] UnityWidget created successfully.');
    _unityWidgetController = controller;
    UnityBridge().attachController(controller);

    // Immediately inject current GPS position upon engine initialization
    final pos = _locationManager.currentPosition;
    if (pos != null) {
      final gpsString = '${pos.latitude},${pos.longitude}';
      controller.postMessage('PlayerController', 'UpdateGPSPosition', gpsString);
    }
  }

  void _onUnityMessage(dynamic message) {
    debugPrint('[MapScreen <- Unity] Inbound Unity message: $message');
    UnityBridge().handleInboundMessage(message.toString());
  }

  void _onUnitySceneLoaded(SceneLoaded? scene) {
    debugPrint('[MapScreen] Unity Scene Loaded: ${scene?.name}');
    setState(() {
      _isUnityLoaded = true;
    });
  }

  void _handleMarkerTapped(String markerId, String questType) {
    if (!mounted) return;

    final quest = _campusQuests.firstWhere(
      (q) => q.id == markerId,
      orElse: () => QuestMarker(
        id: markerId,
        name: 'Misi Kampus',
        latitude: LocationManager.anchorLatitude,
        longitude: LocationManager.anchorLongitude,
        questType: questType,
        points: 100,
      ),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _buildQuestBriefingSheet(quest),
    );
  }

  void _recenterPlayer() {
    final pos = _locationManager.currentPosition;
    if (pos == null) return;

    if (_locationManager.isInsideCampus) {
      // Re-align Unity 3D character position
      final gpsString = '${pos.latitude},${pos.longitude}';
      _unityWidgetController?.postMessage('PlayerController', 'UpdateGPSPosition', gpsString);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pusat Unity 3D disesuaikan ke posisi GPS'),
          duration: Duration(seconds: 1),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    } else {
      _googleMapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(pos.latitude, pos.longitude),
            zoom: 17.5,
            tilt: 45.0,
          ),
        ),
      );
    }
  }

  // ===========================================================================
  // DYNAMIC UI RENDERING (REQUIREMENT 3)
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    if (!_locationManager.isLocationLoaded) {
      return _buildLoadingScreen();
    }

    // Dynamic toggle with smooth cross-fade animation
    // If isInsideCampus == false: Google Maps 2D
    // If isInsideCampus == true: Unity 3D Engine
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ----------------------------------------------------
          // LAYER 1: DYNAMIC RENDERING (CROSS-FADE ANIMATION)
          // ----------------------------------------------------
          Positioned.fill(
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 650),
              firstCurve: Curves.easeInOutCubic,
              secondCurve: Curves.easeInOutCubic,
              sizeCurve: Curves.easeInOutCubic,
              crossFadeState: _locationManager.isInsideCampus
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: _buildGoogleMapsLayer(),
              secondChild: _buildUnity3DLayer(),
              layoutBuilder: (topChild, topChildKey, bottomChild, bottomChildKey) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(key: bottomChildKey, child: bottomChild),
                    Positioned.fill(key: topChildKey, child: topChild),
                  ],
                );
              },
            ),
          ),

          // ----------------------------------------------------
          // LAYER 2: NON-BLOCKING FLUTTER HUD OVERLAY
          // ----------------------------------------------------
          Positioned.fill(
            child: _buildForegroundHUD(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.accentGreen),
            SizedBox(height: 18.h),
            Text(
              'Menghubungkan GPS & Geofence...',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Sinkronisasi perimeter batas Campus Hunto',
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

  // ===========================================================================
  // 1. OUTSIDE CAMPUS: 2D GOOGLE MAPS LAYER
  // ===========================================================================
  Widget _buildGoogleMapsLayer() {
    final pos = _locationManager.currentPosition;
    final LatLng target = pos != null
        ? LatLng(pos.latitude, pos.longitude)
        : const LatLng(LocationManager.anchorLatitude, LocationManager.anchorLongitude);

    return GoogleMap(
      key: const ValueKey('google_maps_2d'),
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
      polygons: {
        Polygon(
          polygonId: const PolygonId('campus_geofence_boundary'),
          points: LocationManager.campusBoundaryGoogleMaps,
          strokeColor: AppColors.accentGreen,
          strokeWidth: 3,
          fillColor: AppColors.accentGreen.withValues(alpha: 0.20),
        ),
      },
      markers: {
        // Campus Anchor / Main Gate Marker
        const Marker(
          markerId: MarkerId('campus_anchor_main_gate'),
          position: LatLng(LocationManager.anchorLatitude, LocationManager.anchorLongitude),
          infoWindow: InfoWindow(
            title: LocationManager.campusName,
            snippet: 'Origin 3D (0,0,0) - Gerbang Utama',
          ),
        ),
        // Active Quest Checkpoints
        ..._campusQuests.map(
          (q) => Marker(
            markerId: MarkerId(q.id),
            position: LatLng(q.latitude, q.longitude),
            infoWindow: InfoWindow(
              title: q.name,
              snippet: '+${q.points} Pts • ${q.questType}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              q.questType == 'quiz' ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueAzure,
            ),
          ),
        ),
      },
    );
  }

  // ===========================================================================
  // 2. INSIDE CAMPUS: 3D UNITY GAME ENVIRONMENT LAYER
  // ===========================================================================
  Widget _buildUnity3DLayer() {
    return Stack(
      key: const ValueKey('unity_3d_world'),
      children: [
        // Native Unity 3D Engine Surface
        Positioned.fill(
          child: UnityWidget(
            onUnityCreated: _onUnityCreated,
            onUnityMessage: _onUnityMessage,
            onUnitySceneLoaded: _onUnitySceneLoaded,
            fullscreen: false,
          ),
        ),

        // Fallback / Pre-loading Isometric Radar HUD (visible while Unity initializes or in dev mock)
        if (!_isUnityLoaded)
          Positioned.fill(
            child: _buildIsometricFallbackLayer(),
          ),
      ],
    );
  }

  /// Isometric 3D Radar fallback for instant visual preview & graceful degradation
  Widget _buildIsometricFallbackLayer() {
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
                  // Sonar Pulse Rings
                  Container(
                    width: 320.w + (val * 40.w),
                    height: 320.w + (val * 40.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.accentGreen.withValues(
                          alpha: (0.25 - (val * 0.20)).clamp(0.01, 1.0),
                        ),
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

                  // 3D Campus Terrain Grid
                  CustomPaint(
                    size: const Size(double.infinity, double.infinity),
                    painter: _Campus3DGridPainter(pulseValue: val),
                  ),

                  // 3D Quest Checkpoint Markers
                  ..._build3DQuestMarkers(),

                  // Center 3D Player Avatar
                  Transform.translate(
                    offset: Offset(0, -12.h + (math.sin(val * 2 * math.pi) * 8.h)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 100.w,
                          height: 100.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.accentGreen, width: 3.w),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentGreen.withValues(alpha: 0.55),
                                blurRadius: 28.r,
                                spreadRadius: 5.r,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              assetPath,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.smart_toy_rounded,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(color: AppColors.accentGreen, width: 1.w),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.directions_run_rounded, color: AppColors.softYellow, size: 14.w),
                              SizedBox(width: 4.w),
                              Text(
                                '$activeMascot • Unity UaaL Active',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 11.sp,
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
    final offsets = [
      const Offset(-110, -160),
      const Offset(115, -130),
      const Offset(-105, 140),
      const Offset(110, 160),
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
          questColor = const Color(0xFFFFA000);
          break;
        case 'cari_objek':
          questIcon = Icons.search_rounded;
          questColor = const Color(0xFF00E676);
          break;
        case 'ar_mission':
        default:
          questIcon = Icons.view_in_ar_rounded;
          questColor = const Color(0xFF00B0FF);
          break;
      }

      markers.add(
        Transform.translate(
          offset: Offset(offset.dx.w, offset.dy.h),
          child: GestureDetector(
            onTap: () {
              UnityBridge().handleInboundMessage(
                '{"event":"OnMarkerTapped","markerId":"${quest.id}","questType":"${quest.questType}"}',
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(9.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    shape: BoxShape.circle,
                    border: Border.all(color: questColor, width: 2.w),
                    boxShadow: [
                      BoxShadow(
                        color: questColor.withValues(alpha: 0.6),
                        blurRadius: 16.r,
                        spreadRadius: 2.r,
                      ),
                    ],
                  ),
                  child: Icon(questIcon, color: Colors.white, size: 20.w),
                ),
                SizedBox(height: 4.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: questColor.withValues(alpha: 0.5), width: 1.w),
                  ),
                  child: Text(
                    quest.name,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                    ),
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

  // ===========================================================================
  // 3. FOREGROUND FLUTTER HUD OVERLAY
  // ===========================================================================
  Widget _buildForegroundHUD() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top HUD Row: Geofence Status Pill + Compass + Mini Mascot Profile
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildGpsStatusPill(),
                Row(
                  children: [
                    _buildCompassWidget(),
                    SizedBox(width: 8.w),
                    _buildMiniProfileWidget(),
                  ],
                ),
              ],
            ),

            // Anti-Flicker Buffer Alert Badge
            if (_locationManager.isBuffering) ...[
              SizedBox(height: 10.h),
              _buildAntiFlickerBadge(),
            ],

            const Spacer(),

            // Bottom HUD Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Geofence Simulation Tester (allows live toggle for testing)
                _buildGeofenceSimTester(),

                // Recenter FAB
                FloatingActionButton(
                  heroTag: 'fab_recenter_campus',
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
    final isInside = _locationManager.isInsideCampus;
    final distKm = (_locationManager.distanceToCampusAnchor / 1000).toStringAsFixed(1);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isInside ? AppColors.accentGreen : Colors.lightBlueAccent,
          width: 1.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9.w,
            height: 9.w,
            decoration: BoxDecoration(
              color: isInside ? const Color(0xFF00E676) : Colors.lightBlueAccent,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isInside ? '3D Campus World (Unity)' : 'Peta GPS 2D (Maps)',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                isInside
                    ? 'Zona Kampus • 1:1 Scale GPS'
                    : '$distKm km dari Kampus • Masuki Zona',
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

  Widget _buildAntiFlickerBadge() {
    final nextState = _locationManager.pendingInsideCampus == true ? '3D Unity' : '2D Maps';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: const Color(0xFFD97706).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.amberAccent, width: 1.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6.r,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
          SizedBox(width: 8.w),
          Text(
            'Stabilisasi Garis Batas: Beralih ke $nextState dalam 4s...',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
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
          angle: -(_locationManager.currentHeading * (math.pi / 180.0)),
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

  Widget _buildGeofenceSimTester() {
    final isInside = _locationManager.isInsideCampus;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(25.r),
        border: Border.all(color: AppColors.accentGreen, width: 1.5.w),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSimButton(
            label: 'Di Dalam (3D)',
            icon: Icons.view_in_ar_rounded,
            isSelected: isInside,
            onTap: () {
              // Simulate coordinates strictly INSIDE campus boundary
              _locationManager.simulatePosition(-6.1753924, 106.8271528);
            },
          ),
          _buildSimButton(
            label: 'Di Luar (2D)',
            icon: Icons.map_rounded,
            isSelected: !isInside,
            onTap: () {
              // Simulate coordinates OUTSIDE campus boundary (e.g., 2km away)
              _locationManager.simulatePosition(-6.1950000, 106.8500000);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSimButton({
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
