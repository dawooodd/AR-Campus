import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../widgets/floating_panel.dart';
import '../widgets/custom_card.dart';
import '../theme/app_theme.dart';
import '../helpers/user_info.dart';
import '../providers/game_provider.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  GoogleMapController? _googleMapController;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;

  bool _isOutsideCampus = true;
  bool _isLocationLoaded = false;
  bool _isGuest = false;
  bool _isManualSimulation = false;
  double _distanceToCampus = 0.0;

  // Campus Center Coordinates (Example: Monas Jakarta / Campus Area)
  final double campusLat = -6.1753924;
  final double campusLng = 106.8271528;
  final double radiusMeters = 500.0; // 500 meter radius

  // Animation controller for AR 3D Simulation
  late AnimationController _arAnimController;

  @override
  void initState() {
    super.initState();
    _arAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _checkGuestStatus();
    _initLocationTracking();
  }

  @override
  void dispose() {
    _arAnimController.dispose();
    _positionStreamSubscription?.cancel();
    _googleMapController?.dispose();
    super.dispose();
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
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          _isOutsideCampus = true;
          _isLocationLoaded = true;
        });
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _isOutsideCampus = true;
            _isLocationLoaded = true;
          });
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _isOutsideCampus = true;
          _isLocationLoaded = true;
        });
      }
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _updatePosition(position);
    } catch (e) {
      debugPrint('Error getting initial position: $e');
      if (mounted) {
        setState(() {
          _isOutsideCampus = true;
          _isLocationLoaded = true;
        });
      }
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      _updatePosition(position);
    });
  }

  void _updatePosition(Position position) {
    double distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      campusLat,
      campusLng,
    );

    bool outside = distance > radiusMeters;
    if (mounted) {
      setState(() {
        _currentPosition = position;
        _distanceToCampus = distance;
        if (!_isManualSimulation) {
          _isOutsideCampus = outside;
        }
        _isLocationLoaded = true;
      });

      if (_googleMapController != null && outside) {
        _googleMapController?.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );
      }
    }
  }

  void _simulateArClaimPoints(int points, String checkpointName) {
    if (_isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mode Guest: Masuk dengan akun Anda untuk menyimpan poin.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Provider.of<GameProvider>(context, listen: false).claimPoints(points);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.stars, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text('Misi Checkpoint!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline, color: Colors.amber, size: 50),
            ),
            const SizedBox(height: 16),
            Text(
              'Anda berhasil mencapai checkpoint:\n$checkpointName',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              '+$points Poin',
              style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Klaim Poin', style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocationLoaded) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppTheme.primaryGreen),
              const SizedBox(height: 16),
              Text('Mendeteksi Lokasi GPS...', style: AppTheme.subtitleStyle),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: _isOutsideCampus ? _buildGlobalGoogleMap() : _buildCampusUnityAR(),
    );
  }

  Widget _buildGlobalGoogleMap() {
    LatLng initialTarget = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : LatLng(campusLat, campusLng);

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialTarget,
            zoom: 15.0,
          ),
          onMapCreated: (GoogleMapController controller) {
            _googleMapController = controller;
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
          compassEnabled: true,
          mapToolbarEnabled: true,
          circles: {
            Circle(
              circleId: const CircleId('campus_boundary'),
              center: LatLng(campusLat, campusLng),
              radius: radiusMeters,
              fillColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
              strokeColor: AppTheme.primaryGreen,
              strokeWidth: 2,
            ),
          },
          markers: {
            Marker(
              markerId: const MarkerId('campus_center'),
              position: LatLng(campusLat, campusLng),
              infoWindow: const InfoWindow(
                title: 'Kampus AR Zone',
                snippet: 'Masuk area ini untuk mengaktifkan 3D AR',
              ),
            ),
          },
        ),

        // Prominent Warning Banner overlay for Global Map mode + Mode Switcher for demo
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE65100), // Rich amber/orange
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Anda berada di luar area kampus.',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              _distanceToCampus > 0
                                  ? 'Jarak ke kampus: ${_distanceToCampus > 1000 ? "${(_distanceToCampus / 1000).toStringAsFixed(1)} km" : "${_distanceToCampus.toStringAsFixed(0)} m"}'
                                  : 'Menggunakan Peta Global GPS',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Simulator Switch Button for Developer/Demo Testing
                InkWell(
                  onTap: () {
                    setState(() {
                      _isManualSimulation = true;
                      _isOutsideCampus = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.view_in_ar, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Simulasi Masuk Kampus (Mode AR 3D)',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCampusUnityAR() {
    final mascotType = _isGuest ? "Guest Mascot (Explorer)" : "Campus Hero (Customized)";

    return Stack(
      children: [
        // 3D Campus AR Interactive Visualizer
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                Color(0xFF1E293B),
                Color(0xFF0F172A),
                Color(0xFF020617),
              ],
            ),
          ),
          child: AnimatedBuilder(
            animation: _arAnimController,
            builder: (context, child) {
              final val = _arAnimController.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  // 3D Isometric Grid Circles (Sonar Radar)
                  Container(
                    width: 320 + (val * 30),
                    height: 320 + (val * 30),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryGreen.withValues(alpha: (0.15 - (val * 0.10)).clamp(0.01, 1.0)),
                        width: 2,
                      ),
                    ),
                  ),
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                  ),

                  // 3D Campus Buildings Mockup Grid
                  Positioned(
                    top: 160,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.account_balance, color: AppTheme.primaryGreen, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Gedung Utama Rektorat (Zona AR)',
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Center 3D Mascot Object Avatar
                  Transform.translate(
                    offset: Offset(0, -10 + (val * 20)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF047857)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryGreen.withValues(alpha: 0.5),
                                blurRadius: 25,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.smart_toy_rounded,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.primaryGreen),
                          ),
                          child: Text(
                            mascotType,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Interactive Checkpoint 1 (Perpustakaan Pusat)
                  Positioned(
                    left: 40,
                    bottom: 220,
                    child: _buildInteractiveCheckpoint(
                      title: 'Perpus Kampus',
                      points: 100,
                      icon: Icons.menu_book,
                    ),
                  ),

                  // Interactive Checkpoint 2 (Laboratorium AR)
                  Positioned(
                    right: 40,
                    bottom: 220,
                    child: _buildInteractiveCheckpoint(
                      title: 'Lab Inovasi AR',
                      points: 150,
                      icon: Icons.biotech,
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // Top Floating Status Panel
        FloatingPanel(
          position: PanelPosition.top,
          child: CustomCard(
            child: Row(
              children: [
                const Icon(Icons.explore, color: AppTheme.primaryGreen),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Area Kampus - Mode AR 3D Aktif',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                // Toggle back to GPS
                IconButton(
                  icon: const Icon(Icons.map_outlined, color: Colors.blueAccent),
                  tooltip: 'Kembali ke Map Global',
                  onPressed: () {
                    setState(() {
                      _isManualSimulation = false;
                      _isOutsideCampus = true;
                    });
                  },
                ),
              ],
            ),
          ),
        ),

        // Bottom Controls Banner
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryGreen,
                  child: Icon(Icons.touch_app, color: Colors.white),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Interaksi Checkpoint 3D',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        'Ketuk checkpoint di sekitar Anda untuk klaim poin!',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInteractiveCheckpoint({
    required String title,
    required int points,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: () => _simulateArClaimPoints(points, title),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.indigo.shade600,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.indigoAccent.withValues(alpha: 0.6),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.indigoAccent),
            ),
            child: Text(
              '$title (+$points)',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
