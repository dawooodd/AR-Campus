import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';
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

class _MapScreenState extends State<MapScreen> {
  UnityWidgetController? _unityWidgetController;
  GoogleMapController? _googleMapController;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;

  bool _isOutsideCampus = true;
  bool _isLocationLoaded = false;
  bool _isGuest = false;
  bool _isUnityLoaded = false;

  // Campus Center Coordinates (Example: Monas Jakarta / Campus Area)
  final double campusLat = -6.1753924;
  final double campusLng = 106.8271528;
  final double radiusMeters = 500.0; // 500 meter radius

  @override
  void initState() {
    super.initState();
    _checkGuestStatus();
    _initLocationTracking();
  }

  @override
  void dispose() {
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
        _isOutsideCampus = outside;
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

  void onUnityCreated(UnityWidgetController controller) {
    _unityWidgetController = controller;
    if (mounted) {
      setState(() {
        _isUnityLoaded = true;
      });
    }
    // Send mascot info to Unity
    String mascotId = _isGuest ? "Guest_Mascot" : "User_Mascot";
    _unityWidgetController?.postMessage('MascotReceiver', 'SetMascot', mascotId);
  }

  void onUnityMessage(message) {
    debugPrint('Received message from unity: ${message.toString()}');
    if (message.toString().startsWith("TargetReached")) {
      List<String> parts = message.toString().split(":");
      if (parts.length > 1) {
        int points = int.tryParse(parts[1]) ?? 0;
        if (points > 0 && !_isGuest && mounted) {
          Provider.of<GameProvider>(context, listen: false).claimPoints(points);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Selamat! Anda mendapatkan $points Poin!')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocationLoaded) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryGreen),
              SizedBox(height: 16),
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

        // Prominent Warning Banner overlay for Global Map mode
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Container(
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
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Anda berada di luar area kampus. Saat ini anda memakai map global.',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCampusUnityAR() {
    return Stack(
      children: [
        if (!_isUnityLoaded)
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppTheme.primaryGreen),
                SizedBox(height: 16),
                Text('Memuat Peta 3D Kampus...', style: AppTheme.subtitleStyle),
              ],
            ),
          ),
        
        UnityWidget(
          onUnityCreated: onUnityCreated,
          onUnityMessage: onUnityMessage,
          useAndroidViewSurface: true,
          fullscreen: false,
        ),

        const FloatingPanel(
          position: PanelPosition.top,
          child: CustomCard(
            child: Row(
              children: [
                Icon(Icons.explore, color: AppTheme.primaryGreen),
                SizedBox(width: 12),
                Text(
                  'Area Kampus - Mode AR 3D Aktif',
                  style: AppTheme.bodyStyle,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
