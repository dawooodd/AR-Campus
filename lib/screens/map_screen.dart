import 'package:flutter/material.dart';
import 'package:flutter_unity_widget/flutter_unity_widget.dart';
import 'package:geolocator/geolocator.dart';
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
  bool _isOutsideCampus = false;
  bool _isGuest = false;
  bool _isUnityLoaded = false;

  // Dummy coordinates for Campus (Example: Monas Jakarta)
  final double campusLat = -6.1753924;
  final double campusLng = 106.8271528;
  final double radiusMeters = 500.0; // 500 meter radius

  @override
  void initState() {
    super.initState();
    _checkLocation();
    _checkGuestStatus();
  }

  Future<void> _checkGuestStatus() async {
    bool guest = await UserInfo().isGuest();
    setState(() {
      _isGuest = guest;
    });
  }

  Future<void> _checkLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return;
    } 

    Position position = await Geolocator.getCurrentPosition();
    double distance = Geolocator.distanceBetween(
      position.latitude, 
      position.longitude, 
      campusLat, 
      campusLng
    );

    setState(() {
      _isOutsideCampus = distance > radiusMeters;
    });
  }

  void onUnityCreated(UnityWidgetController controller) {
    _unityWidgetController = controller;
    setState(() {
      _isUnityLoaded = true;
    });
    // Send mascot info to Unity
    String mascotId = _isGuest ? "Guest_Mascot" : "User_Mascot";
    _unityWidgetController?.postMessage('MascotReceiver', 'SetMascot', mascotId);
  }

  void onUnityMessage(message) {
    debugPrint('Received message from unity: ${message.toString()}');
    // Example: Unity sends "TargetReached:100"
    if (message.toString().startsWith("TargetReached")) {
      List<String> parts = message.toString().split(":");
      if (parts.length > 1) {
        int points = int.tryParse(parts[1]) ?? 0;
        if (points > 0 && !_isGuest) {
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
    return Scaffold(
      body: Stack(
        children: [
          // Loading Indicator for Unity Widget
          if (!_isUnityLoaded)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryGreen),
                  SizedBox(height: 16),
                  Text('Memuat Peta 3D...', style: AppTheme.subtitleStyle),
                ],
              ),
            ),
          
          // Unity Widget (Replacing Google Maps Placeholder)
          UnityWidget(
            onUnityCreated: onUnityCreated,
            onUnityMessage: onUnityMessage,
            useAndroidViewSurface: true,
            fullscreen: false,
          ),
          
          if (_isOutsideCampus)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CustomCard(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning, color: Colors.red, size: 48),
                        SizedBox(height: 16),
                        Text(
                          'Anda berada di luar jangkauan map kampus.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Floating Panel Top
          const FloatingPanel(
            position: PanelPosition.top,
            child: CustomCard(
              child: Row(
                children: [
                  Icon(Icons.explore, color: AppTheme.primaryGreen),
                  SizedBox(width: 12),
                  Text(
                    'Lokasi Saat Ini / Objective',
                    style: AppTheme.bodyStyle,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
