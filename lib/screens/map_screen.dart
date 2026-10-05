import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../helpers/location_manager.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';
import 'main_navigation.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  // Required State Variables
  GoogleMapController? mapController;
  Position? currentPosition;
  bool hasPermission = false;

  // Tracking & State Management
  bool _isCheckingPermission = true;
  bool _isLocationServiceEnabled = true;
  bool _isPermissionDeniedForever = false;
  bool _isSimulatedOnLaptop = false;
  bool _showLaptopHelpBanner = false;
  StreamSubscription<Position>? _positionStreamSubscription;

  // Custom User Location Marker Icon for guaranteed rendering on laptops/desktops
  BitmapDescriptor? _userLocationMarkerIcon;

  // Animation controller for pulsing user location halo
  late AnimationController _pulseController;

  // Default Campus Coordinate: Universitas Merdeka Pasuruan (UNMER Pasuruan)
  // Jl. Ir. H. Juanda No. 68, Tapaan, Bugul Kidul, Pasuruan, Jawa Timur
  static const LatLng unmerPasuruanCoordinate = LatLng(
    LocationManager.anchorLatitude,
    LocationManager.anchorLongitude,
  );

  // Points of Interest inside Universitas Merdeka Pasuruan
  final List<Map<String, dynamic>> _unmerCheckpoints = [
    {
      'id': 'gerbang_unmer',
      'title': 'Gerbang Utama UNMER',
      'snippet': 'Jl. Ir. H. Juanda No. 68, Pasuruan',
      'lat': -7.64910,
      'lng': 112.91927,
      'type': 'gate',
    },
    {
      'id': 'rektorat_unmer',
      'title': 'Gedung Rektorat UNMER Pasuruan',
      'snippet': 'Pusat Administrasi & Rektorat',
      'lat': -7.64960,
      'lng': 112.91910,
      'type': 'admin',
    },
    {
      'id': 'perpus_unmer',
      'title': 'Perpustakaan UNMER Pasuruan',
      'snippet': 'Ruang Baca & Perpustakaan Digital',
      'lat': -7.64940,
      'lng': 112.91965,
      'type': 'library',
    },
    {
      'id': 'fakultas_unmer',
      'title': 'Gedung Perkuliahan & Lab',
      'snippet': 'Fakultas Hukum, Ekonomi, dan Pertanian',
      'lat': -7.65020,
      'lng': 112.91980,
      'type': 'faculty',
    },
    {
      'id': 'lapangan_unmer',
      'title': 'Student Center & Lapangan Kampus',
      'snippet': 'Area Kegiatan Mahasiswa & Olahraga',
      'lat': -7.65045,
      'lng': 112.91890,
      'type': 'sports',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _generateCustomBlueDotIcon();
    _checkAndRequestLocationPermission();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _positionStreamSubscription?.cancel();
    mapController?.dispose();
    super.dispose();
  }

  // ===========================================================================
  // GUARANTEED VISIBLE BLUE DOT MARKER FOR LAPTOPS & PHONES
  // ===========================================================================
  /// Generates a Google Maps-style glowing blue dot marker with a crisp white rim.
  /// This ensures the live location is ALWAYS drawn on screen, even on Windows
  /// laptops, web browsers, or emulators where native 'myLocationEnabled' fails.
  Future<void> _generateCustomBlueDotIcon() async {
    try {
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      const double size = 64.0;

      // Outer soft blue halo
      final Paint glowPaint = Paint()
        ..color = const Color(0x552196F3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, glowPaint);

      // Clean white ring
      final Paint whiteRingPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(const Offset(size / 2, size / 2), (size / 2) - 8, whiteRingPaint);

      // Deep Google Maps royal blue core
      final Paint blueCorePaint = Paint()
        ..color = const Color(0xFF1976D2)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(const Offset(size / 2, size / 2), (size / 2) - 13, blueCorePaint);

      final ui.Image image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null && mounted) {
        setState(() {
          _userLocationMarkerIcon = BitmapDescriptor.bytes(byteData.buffer.asUint8List());
        });
      }
    } catch (e) {
      debugPrint('[MapScreen] Fallback to default azure marker: $e');
      _userLocationMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    }
  }

  // ===========================================================================
  // INITIALIZATION & RESILIENT PERMISSION / GPS HANDLING
  // ===========================================================================
  Future<void> _checkAndRequestLocationPermission() async {
    setState(() {
      _isCheckingPermission = true;
    });

    // 1. Check if location services are enabled on the OS
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          _isLocationServiceEnabled = false;
          _isCheckingPermission = false;
          hasPermission = false;
        });
      }
      return;
    }

    // 2. Check and request app permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          hasPermission = false;
          _isPermissionDeniedForever = true;
          _isCheckingPermission = false;
        });
      }
      return;
    }

    if (permission == LocationPermission.denied) {
      if (mounted) {
        setState(() {
          hasPermission = false;
          _isPermissionDeniedForever = false;
          _isCheckingPermission = false;
        });
      }
      return;
    }

    // Permission granted
    if (mounted) {
      setState(() {
        hasPermission = true;
        _isLocationServiceEnabled = true;
        _isPermissionDeniedForever = false;
        _isCheckingPermission = false;
      });
    }

    // 3. Multi-tier GPS acquisition (laptop-resilient)
    await _fetchInitialPositionWithFallback();

    // 4. Start live location subscription for continuous mobile/laptop updates
    _startLiveLocationTracking();
  }

  /// Multi-tier location retrieval:
  /// Laptops don't have satellite GPS chips, so high accuracy may timeout.
  /// We try High -> Low/Medium (Wi-Fi positioning) -> Last Known Position.
  Future<void> _fetchInitialPositionWithFallback() async {
    Position? position;

    // Tier 1: Try high accuracy with a 4s timeout
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      debugPrint('[MapScreen] High accuracy GPS failed or timed out: $e');
    }

    // Tier 2: Try medium/low accuracy (works with Windows Location / Wi-Fi SSID lookup)
    if (position == null) {
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 4),
          ),
        );
      } catch (e) {
        debugPrint('[MapScreen] Low accuracy GPS failed: $e');
      }
    }

    // Tier 3: Last known cached position
    if (position == null) {
      try {
        position = await Geolocator.getLastKnownPosition();
      } catch (_) {}
    }

    if (position != null && mounted) {
      setState(() {
        currentPosition = position;
        _isSimulatedOnLaptop = false;
      });
      _animateCameraToPosition(position);
    } else if (mounted) {
      // If hardware GPS returns null (common on Windows laptops indoors),
      // show helpful banner explaining laptop GPS behavior
      setState(() {
        _showLaptopHelpBanner = true;
      });
    }
  }

  void _startLiveLocationTracking() {
    _positionStreamSubscription?.cancel();
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.medium,
      distanceFilter: 2, // Update every 2 meters of movement
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        if (mounted) {
          final wasNull = currentPosition == null;
          setState(() {
            currentPosition = position;
            _isSimulatedOnLaptop = false;
            _showLaptopHelpBanner = false;
          });

          if (wasNull) {
            _animateCameraToPosition(position);
          }
        }
      },
      onError: (error) {
        debugPrint('[MapScreen] Location stream update: $error');
      },
    );
  }

  void _animateCameraToPosition(Position position) {
    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 17.5,
            tilt: 30.0,
          ),
        ),
      );
    }
  }

  void _animateCameraToCampus() {
    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          const CameraPosition(
            target: unmerPasuruanCoordinate,
            zoom: 17.5,
            tilt: 25.0,
          ),
        ),
      );
    }
  }

  // ===========================================================================
  // LAPTOP SIMULATION & MANUAL TEST ENGINE
  // ===========================================================================
  /// Sets current user position directly to Universitas Merdeka Pasuruan.
  /// Solves the issue where laptops lack hardware satellite GPS chips.
  void _simulateLocationAtUnmer({double latOffset = 0.0, double lngOffset = 0.0}) {
    final double targetLat = unmerPasuruanCoordinate.latitude + latOffset;
    final double targetLng = unmerPasuruanCoordinate.longitude + lngOffset;

    final simulated = Position(
      latitude: targetLat,
      longitude: targetLng,
      timestamp: DateTime.now(),
      altitude: 12.0,
      altitudeAccuracy: 1.0,
      accuracy: 5.0, // High simulated accuracy
      heading: 0.0,
      headingAccuracy: 1.0,
      speed: 1.2,
      speedAccuracy: 0.5,
    );

    setState(() {
      currentPosition = simulated;
      _isSimulatedOnLaptop = true;
      _showLaptopHelpBanner = false;
    });

    _animateCameraToPosition(simulated);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📍 Posisi disimulasikan di Universitas Merdeka Pasuruan'),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  void _handleSafeBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    }
  }

  // ===========================================================================
  // MAIN BUILD
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    if (_isCheckingPermission) {
      return _buildLoadingState();
    }

    if (!hasPermission || !_isLocationServiceEnabled) {
      return _buildPermissionDeniedState();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Google Map Full-Screen Layer
          Positioned.fill(
            child: _buildGoogleMapWidget(),
          ),

          // 2. Floating Top Header & Status Pill
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopOverlay(),
          ),

          // 3. Laptop Helpful Explanation Banner (if GPS not locking on laptop)
          if (_showLaptopHelpBanner && currentPosition == null)
            Positioned(
              top: 90.h,
              left: 16.w,
              right: 16.w,
              child: _buildLaptopHelpBanner(),
            ),

          // 4. Laptop Simulation Controller & UNMER Recenter FABs
          Positioned(
            bottom: 24.h,
            left: 16.w,
            right: 16.w,
            child: _buildBottomControls(),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // GOOGLE MAP WIDGET & MARKERS CONFIGURATION
  // ===========================================================================
  Widget _buildGoogleMapWidget() {
    final LatLng initialTarget = currentPosition != null
        ? LatLng(currentPosition!.latitude, currentPosition!.longitude)
        : unmerPasuruanCoordinate;

    // Assemble dynamic markers
    final Set<Marker> markers = {};

    // 1. UNMER Pasuruan Checkpoint & Building Markers
    for (final cp in _unmerCheckpoints) {
      markers.add(
        Marker(
          markerId: MarkerId(cp['id'] as String),
          position: LatLng(cp['lat'] as double, cp['lng'] as double),
          infoWindow: InfoWindow(
            title: cp['title'] as String,
            snippet: cp['snippet'] as String,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            cp['type'] == 'gate'
                ? BitmapDescriptor.hueGreen
                : cp['type'] == 'admin'
                    ? BitmapDescriptor.hueRed
                    : BitmapDescriptor.hueOrange,
          ),
        ),
      );
    }

    // 2. GUARANTEED BLUE DOT USER LOCATION MARKER
    // Renders custom glowing blue dot so it is 100% visible on laptop/desktop/phone
    if (currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_live_blue_dot'),
          position: LatLng(currentPosition!.latitude, currentPosition!.longitude),
          anchor: const Offset(0.5, 0.5), // Center dot directly on position
          zIndexInt: 999, // Always render above polygons and building markers
          icon: _userLocationMarkerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
            title: _isSimulatedOnLaptop
                ? 'Titik Anda (Mode Simulasi UNMER)'
                : 'Lokasi Anda Saat Ini',
            snippet:
                '${currentPosition!.latitude.toStringAsFixed(5)}, ${currentPosition!.longitude.toStringAsFixed(5)}',
          ),
        ),
      );
    }

    // Assemble dynamic accuracy circles
    final Set<Circle> circles = {};
    if (currentPosition != null) {
      circles.add(
        Circle(
          circleId: const CircleId('user_accuracy_halo'),
          center: LatLng(currentPosition!.latitude, currentPosition!.longitude),
          radius: (currentPosition!.accuracy > 5 && currentPosition!.accuracy < 100)
              ? currentPosition!.accuracy
              : 25.0,
          fillColor: const Color(0x302196F3),
          strokeColor: const Color(0x992196F3),
          strokeWidth: 2,
        ),
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialTarget,
        zoom: 17.0,
      ),
      myLocationEnabled: true, // Native layer on mobile
      myLocationButtonEnabled: false, // Replaced by our custom responsive FAB
      zoomControlsEnabled: false,
      compassEnabled: true,
      mapToolbarEnabled: false,
      onMapCreated: (GoogleMapController controller) {
        mapController = controller;
        if (currentPosition != null) {
          _animateCameraToPosition(currentPosition!);
        } else {
          _animateCameraToCampus();
        }
      },
      polygons: {
        // UNMER Pasuruan Campus Perimeter Boundary
        Polygon(
          polygonId: const PolygonId('unmer_pasuruan_perimeter'),
          points: LocationManager.campusBoundaryGoogleMaps,
          strokeColor: AppColors.accentGreen,
          strokeWidth: 3,
          fillColor: AppColors.accentGreen.withValues(alpha: 0.16),
        ),
      },
      markers: markers,
      circles: circles,
      onTap: (LatLng tappedPoint) {
        // Tap on map allows setting location when testing on laptop
        if (kDebugMode || _isSimulatedOnLaptop) {
          final latOffset = tappedPoint.latitude - unmerPasuruanCoordinate.latitude;
          final lngOffset = tappedPoint.longitude - unmerPasuruanCoordinate.longitude;
          _simulateLocationAtUnmer(latOffset: latOffset, lngOffset: lngOffset);
        }
      },
    );
  }

  // ===========================================================================
  // FOREGROUND OVERLAYS: HEADER, STATUS PILL & BACK BUTTON
  // ===========================================================================
  Widget _buildTopOverlay() {
    final bool isGpsActive = currentPosition != null;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Safe Back Button to return to HomeScreen
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _handleSafeBack,
                borderRadius: BorderRadius.circular(22.r),
                child: Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.92),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accentGreen, width: 1.5.w),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 10.r,
                        offset: Offset(0, 3.h),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),

            // Live Floating Status Pill
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: isGpsActive
                      ? (_isSimulatedOnLaptop ? Colors.lightBlueAccent : AppColors.accentGreen)
                      : AppColors.softYellow,
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
                  // Status Indicator Dot
                  Container(
                    width: 10.w,
                    height: 10.w,
                    decoration: BoxDecoration(
                      color: isGpsActive
                          ? (_isSimulatedOnLaptop ? Colors.lightBlueAccent : const Color(0xFF00E676))
                          : AppColors.softYellow,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isGpsActive
                                  ? (_isSimulatedOnLaptop ? Colors.lightBlueAccent : const Color(0xFF00E676))
                                  : AppColors.softYellow)
                              .withValues(alpha: 0.6),
                          blurRadius: 6.r,
                          spreadRadius: 2.r,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isGpsActive
                            ? (_isSimulatedOnLaptop ? 'Simulasi Laptop (UNMER)' : 'GPS Aktif')
                            : 'Mencari Lokasi GPS...',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        isGpsActive
                            ? '${currentPosition!.latitude.toStringAsFixed(5)}, ${currentPosition!.longitude.toStringAsFixed(5)}'
                            : 'Memindai sinyal lokasi laptop...',
                        style: GoogleFonts.inter(
                          color: AppColors.softYellow,
                          fontSize: 9.5.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLaptopHelpBanner() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.7), width: 1.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10.r,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.laptop_chromebook_rounded, color: Colors.amberAccent, size: 22),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Catatan Pengujian di Laptop:',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'Laptop umumnya tidak memiliki antena GPS satelit seperti smartphone. Gunakan tombol "Simulasi di UNMER" di bawah untuk langsung memunculkan titik biru Anda!',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 11.sp,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 18),
            onPressed: () => setState(() => _showLaptopHelpBanner = false),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BOTTOM CONTROLS: UNMER RECENTER & LAPTOP TESTING TOOLBAR
  // ===========================================================================
  Widget _buildBottomControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Quick Action 1: Recenter to UNMER Pasuruan Campus Center
        Container(
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(color: AppColors.accentGreen, width: 1.2.w),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 8.r,
                offset: Offset(0, 3.h),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22.r),
              onTap: _animateCameraToCampus,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.school_rounded, color: AppColors.softYellow, size: 18),
                    SizedBox(width: 8.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'UNMER Pasuruan',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Jl. Ir. H. Juanda No. 68',
                          style: GoogleFonts.inter(
                            color: AppColors.softYellow,
                            fontSize: 9.5.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Action 2 & 3 Right Buttons: Laptop Simulator + User Recenter
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Laptop Simulation Button (instantly creates the blue dot at UNMER Pasuruan)
            FloatingActionButton.small(
              heroTag: 'fab_simulate_unmer',
              backgroundColor: const Color(0xFF1E293B),
              elevation: 4,
              tooltip: 'Simulasi Titik Lokasi di UNMER',
              onPressed: () => _simulateLocationAtUnmer(),
              child: const Icon(Icons.touch_app_rounded, color: Colors.lightBlueAccent),
            ),
            SizedBox(width: 10.w),

            // Recenter to Current User Position (Blue Dot)
            FloatingActionButton(
              heroTag: 'fab_recenter_user',
              backgroundColor: AppColors.primaryGreen,
              elevation: 6,
              onPressed: () {
                if (currentPosition != null) {
                  _animateCameraToPosition(currentPosition!);
                } else {
                  // If laptop has not acquired GPS, provide simulation option
                  _simulateLocationAtUnmer();
                }
              },
              child: const Icon(Icons.my_location_rounded, color: Colors.white),
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // ERROR & LOADING STATES
  // ===========================================================================
  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.accentGreen),
            SizedBox(height: 18.h),
            Text(
              'Memeriksa Izin GPS & Lokasi...',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Memuat Peta Universitas Merdeka Pasuruan',
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

  Widget _buildPermissionDeniedState() {
    final bool isServiceDisabled = !_isLocationServiceEnabled;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: _handleSafeBack,
              ),
              const Spacer(),
              Center(
                child: Container(
                  width: 90.w,
                  height: 90.w,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6), width: 2.w),
                  ),
                  child: Icon(
                    isServiceDisabled ? Icons.location_disabled_rounded : Icons.location_off_rounded,
                    color: Colors.redAccent,
                    size: 42.w,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Center(
                child: Text(
                  isServiceDisabled ? 'Layanan Lokasi Non-Aktif' : 'Izin Lokasi Diperlukan',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                isServiceDisabled
                    ? 'GPS atau Layanan Lokasi pada laptop/perangkat Anda dalam keadaan non-aktif. Nyalakan layanan lokasi di Pengaturan Windows/Android agar posisi Anda terdeteksi.'
                    : _isPermissionDeniedForever
                        ? 'Izin lokasi telah ditolak secara permanen. Buka Pengaturan Aplikasi dan berikan izin lokasi agar peta Universitas Merdeka Pasuruan dapat menampilkan posisi Anda.'
                        : 'Campus Hunto membutuhkan izin lokasi untuk menampilkan posisi Anda secara live pada peta kampus UNMER Pasuruan.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 13.5.sp,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 28.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreen,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                  ),
                  onPressed: () async {
                    if (isServiceDisabled) {
                      await Geolocator.openLocationSettings();
                    } else {
                      await Geolocator.openAppSettings();
                    }
                  },
                  child: Text(
                    isServiceDisabled ? 'Nyalakan Layanan Lokasi' : 'Buka Pengaturan Aplikasi',
                    style: GoogleFonts.inter(
                      color: AppColors.primaryGreen,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white30),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                  ),
                  onPressed: _checkAndRequestLocationPermission,
                  child: Text(
                    'Coba Lagi',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
