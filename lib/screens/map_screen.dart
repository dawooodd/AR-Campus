import 'dart:async';
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

class _MapScreenState extends State<MapScreen> {
  // Required State Variables
  GoogleMapController? mapController;
  Position? currentPosition;
  bool hasPermission = false;

  // Additional tracking & state management flags
  bool _isCheckingPermission = true;
  bool _isLocationServiceEnabled = true;
  bool _isPermissionDeniedForever = false;
  StreamSubscription<Position>? _positionStreamSubscription;

  // Default Campus Coordinate (Central Campus Plaza / Main Gate)
  static const LatLng defaultCampusCoordinate = LatLng(
    LocationManager.anchorLatitude,
    LocationManager.anchorLongitude,
  );

  @override
  void initState() {
    super.initState();
    _checkAndRequestLocationPermission();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    mapController?.dispose();
    super.dispose();
  }

  // ===========================================================================
  // INITIALIZATION & PERMISSION HANDLING
  // ===========================================================================
  Future<void> _checkAndRequestLocationPermission() async {
    setState(() {
      _isCheckingPermission = true;
    });

    // 1. Verify if device GPS location services are turned on
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

    // 2. Check current location permission status
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

    // Permission granted (whileInUse or always)
    if (mounted) {
      setState(() {
        hasPermission = true;
        _isLocationServiceEnabled = true;
        _isPermissionDeniedForever = false;
        _isCheckingPermission = false;
      });
    }

    // 3. Fetch initial instantaneous user position
    await _fetchInitialPosition();

    // 4. Start live location subscription for continuous tracking
    _startLiveLocationTracking();
  }

  Future<void> _fetchInitialPosition() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (mounted) {
        setState(() {
          currentPosition = position;
        });
        _animateCameraToPosition(position);
      }
    } catch (e) {
      debugPrint('[MapScreen] Failed to retrieve instantaneous GPS: $e');
      // Fallback: try last known position if available
      try {
        Position? lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null && mounted) {
          setState(() {
            currentPosition = lastKnown;
          });
          _animateCameraToPosition(lastKnown);
        }
      } catch (_) {}
    }
  }

  void _startLiveLocationTracking() {
    _positionStreamSubscription?.cancel();
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
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
          });

          // Automatically center camera on the first successful GPS lock
          if (wasNull) {
            _animateCameraToPosition(position);
          }
        }
      },
      onError: (error) {
        debugPrint('[MapScreen] Location stream error: $error');
      },
    );
  }

  void _animateCameraToPosition(Position position) {
    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 17.0,
            tilt: 35.0,
          ),
        ),
      );
    }
  }

  void _handleSafeBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      // Safe fallback when accessed from root/bottom nav
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    }
  }

  // ===========================================================================
  // MAIN BUILD METHOD
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    // 1. Loading State while checking permissions
    if (_isCheckingPermission) {
      return _buildLoadingState();
    }

    // 2. Permission Denied or Location Service Disabled State
    if (!hasPermission || !_isLocationServiceEnabled) {
      return _buildPermissionDeniedState();
    }

    // 3. Fully Functional Live 2D GPS Map View
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Base Layer: Full-screen 2D Google Map
          Positioned.fill(
            child: _buildGoogleMapWidget(),
          ),

          // Foreground Layer: Floating Top Header & Safe Back Button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopOverlay(),
          ),

          // Bottom Action: Recenter on Campus Anchor Point
          Positioned(
            bottom: 30.h,
            left: 20.w,
            child: _buildCampusRecenterButton(),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // GOOGLE MAP WIDGET CONFIGURATION
  // ===========================================================================
  Widget _buildGoogleMapWidget() {
    final LatLng initialTarget = currentPosition != null
        ? LatLng(currentPosition!.latitude, currentPosition!.longitude)
        : defaultCampusCoordinate;

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialTarget,
        zoom: 16.0,
      ),
      myLocationEnabled: true, // Native live location blue dot
      myLocationButtonEnabled: true, // Native recenter button
      zoomControlsEnabled: false, // Clean UI without intrusive zoom buttons
      compassEnabled: true,
      mapToolbarEnabled: false,
      onMapCreated: (GoogleMapController controller) {
        mapController = controller;
        // Dynamically animate to user position once available
        if (currentPosition != null) {
          _animateCameraToPosition(currentPosition!);
        }
      },
      // Campus perimeter geofence polygon visualization
      polygons: {
        Polygon(
          polygonId: const PolygonId('campus_geofence_perimeter'),
          points: LocationManager.campusBoundaryGoogleMaps,
          strokeColor: AppColors.accentGreen,
          strokeWidth: 3,
          fillColor: AppColors.accentGreen.withValues(alpha: 0.18),
        ),
      },
      // Campus Anchor & Points of Interest Markers
      markers: {
        const Marker(
          markerId: MarkerId('campus_anchor_main_gate'),
          position: defaultCampusCoordinate,
          infoWindow: InfoWindow(
            title: 'Gerbang Utama Kampus',
            snippet: 'Titik Acuan Origin Campus Hunto',
          ),
        ),
      },
    );
  }

  // ===========================================================================
  // UI OVERLAY: FLOATING HEADER & SAFE BACK BUTTON
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
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),

            // Custom Floating Status Pill
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: isGpsActive ? AppColors.accentGreen : AppColors.softYellow,
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
                  // Live Pulse Status Dot
                  Container(
                    width: 10.w,
                    height: 10.w,
                    decoration: BoxDecoration(
                      color: isGpsActive ? const Color(0xFF00E676) : AppColors.softYellow,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isGpsActive ? const Color(0xFF00E676) : AppColors.softYellow)
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
                        isGpsActive ? 'GPS Aktif' : 'Mencari Lokasi GPS...',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        isGpsActive
                            ? '${currentPosition!.latitude.toStringAsFixed(5)}, ${currentPosition!.longitude.toStringAsFixed(5)}'
                            : 'Memindai satelit GPS...',
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

  Widget _buildCampusRecenterButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.accentGreen, width: 1.2.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: () {
            mapController?.animateCamera(
              CameraUpdate.newCameraPosition(
                const CameraPosition(
                  target: defaultCampusCoordinate,
                  zoom: 16.5,
                  tilt: 20.0,
                ),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.school_rounded, color: AppColors.softYellow, size: 16),
                SizedBox(width: 6.w),
                Text(
                  'Kampus Pusat',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // ERROR & EMPTY STATES (REQUIREMENT 3)
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
              'Menyiapkan Google Maps SDK untuk Campus Hunto',
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
              // Safe Back Button
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: _handleSafeBack,
              ),

              const Spacer(),

              // Error Illustration / Icon
              Center(
                child: Container(
                  width: 100.w,
                  height: 100.w,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6), width: 2.w),
                  ),
                  child: Icon(
                    isServiceDisabled ? Icons.location_disabled_rounded : Icons.location_off_rounded,
                    color: Colors.redAccent,
                    size: 48.w,
                  ),
                ),
              ),
              SizedBox(height: 24.h),

              // Error Title
              Center(
                child: Text(
                  isServiceDisabled ? 'Layanan Lokasi Mati' : 'Izin Lokasi Diperlukan',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(height: 12.h),

              // Informative Description
              Text(
                isServiceDisabled
                    ? 'GPS / Layanan Lokasi pada perangkat Anda dalam keadaan non-aktif. Harap nyalakan GPS untuk menampilkan posisi Anda secara live pada peta kampus.'
                    : _isPermissionDeniedForever
                        ? 'Izin lokasi telah ditolak secara permanen. Anda perlu membuka Pengaturan Aplikasi dan memberikan izin lokasi secara manual agar peta kampus dapat menampilkan posisi live Anda.'
                        : 'Campus Hunto membutuhkan izin lokasi untuk menampilkan posisi Anda secara live pada Google Maps dan melacak pergerakan di sekitar kampus.\n\nSilakan izinkan akses lokasi untuk melanjutkan.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 13.5.sp,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 32.h),

              // Primary Action: Open Settings
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
                    isServiceDisabled ? 'Nyalakan Layanan GPS' : 'Buka Pengaturan Aplikasi',
                    style: GoogleFonts.inter(
                      color: AppColors.primaryGreen,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),

              // Secondary Action: Coba Lagi
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
