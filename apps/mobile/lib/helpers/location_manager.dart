import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:maps_toolkit/maps_toolkit.dart' as mp;

/// Core Geolocation and Geofencing Engine for Campus Hunto.
/// Handles high-precision GPS tracking, boundary polygon detection,
/// and an anti-flicker debounce buffer when traversing the campus perimeter.
class LocationManager extends ChangeNotifier {
  // Singleton pattern for centralized GPS source of truth
  static final LocationManager _instance = LocationManager._internal();
  factory LocationManager() => _instance;
  LocationManager._internal();

  // ===========================================================================
  // CAMPUS BOUNDARY SPECIFICATION (POLYGON VERTICES)
  // ===========================================================================
  /// Anchor Point representing Unity world origin (0, 0, 0) - Main Gate
  static const double anchorLatitude = -6.1753924;
  static const double anchorLongitude = 106.8271528;
  static const String campusName = 'Campus Central Plaza';

  /// Outer boundary polygon of the campus perimeter (maps_toolkit LatLng for Raycasting)
  static const List<mp.LatLng> campusBoundary = [
    mp.LatLng(-6.17280, 106.82480), // North-West Perimeter (Engineering Sector)
    mp.LatLng(-6.17240, 106.82950), // North-East Perimeter (Science & Tech)
    mp.LatLng(-6.17640, 106.83020), // East Perimeter (Main Library & Plaza)
    mp.LatLng(-6.17820, 106.82860), // South-East Perimeter (Sports Complex)
    mp.LatLng(-6.17850, 106.82560), // South-West Perimeter (Student Center)
    mp.LatLng(-6.17560, 106.82420), // West Perimeter (Main Gate & Administration)
  ];

  /// Google Maps compatible LatLng list for rendering the polygon on 2D map
  static List<gm.LatLng> get campusBoundaryGoogleMaps => campusBoundary
      .map((p) => gm.LatLng(p.latitude, p.longitude))
      .toList();

  // ===========================================================================
  // STATE PROPERTIES
  // ===========================================================================
  Position? _currentPosition;
  double _currentHeading = 0.0;
  bool _isLocationLoaded = false;
  bool _isInsideCampus = false;

  // Anti-flicker hysteresis state
  Timer? _debounceTimer;
  bool? _pendingInsideCampus;
  static const Duration antiFlickerDelay = Duration(seconds: 4);

  // Subscriptions & Stream Controllers
  StreamSubscription<Position>? _positionStreamSubscription;
  final StreamController<bool> _campusStateController = StreamController<bool>.broadcast();
  final StreamController<Position> _positionStreamController = StreamController<Position>.broadcast();

  // Getters
  Position? get currentPosition => _currentPosition;
  double get currentHeading => _currentHeading;
  bool get isLocationLoaded => _isLocationLoaded;
  bool get isInsideCampus => _isInsideCampus;
  bool get isBuffering => _debounceTimer != null && _debounceTimer!.isActive;
  bool? get pendingInsideCampus => _pendingInsideCampus;

  /// Returns current GPS coordinates formatted as comma-separated string: "latitude,longitude"
  String get formattedGPS => _currentPosition != null
      ? '${_currentPosition!.latitude},${_currentPosition!.longitude}'
      : '$anchorLatitude,$anchorLongitude';

  /// Distance from current position to Campus Center / Anchor in meters
  double get distanceToCampusAnchor {
    if (_currentPosition == null) return 0.0;
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      anchorLatitude,
      anchorLongitude,
    );
  }

  Stream<bool> get onCampusStateChanged => _campusStateController.stream;
  Stream<Position> get onPositionChanged => _positionStreamController.stream;

  // ===========================================================================
  // GPS STREAM INITIALIZATION
  // ===========================================================================
  /// Starts high-accuracy GPS stream with real-time geofence calculation
  Future<void> startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('[LocationManager] Location services are disabled.');
      _isLocationLoaded = true;
      notifyListeners();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('[LocationManager] Location permission denied.');
        _isLocationLoaded = true;
        notifyListeners();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('[LocationManager] Location permissions permanently denied.');
      _isLocationLoaded = true;
      notifyListeners();
      return;
    }

    // Get initial instantaneous location
    try {
      Position initialPos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _processPositionUpdate(initialPos, isInitialFix: true);
    } catch (e) {
      debugPrint('[LocationManager] Error retrieving initial position: $e');
      _isLocationLoaded = true;
      notifyListeners();
    }

    // Configure continuous stream with distance filter (e.g., 2 meters)
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 2,
    );

    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      _processPositionUpdate(position, isInitialFix: false);
    });
  }

  // ===========================================================================
  // GEOFENCING & ANTI-FLICKER BUFFER LOGIC
  // ===========================================================================
  /// Checks if given coordinates are inside the campus polygon using maps_toolkit
  bool checkCoordinatesInsideCampus(double latitude, double longitude) {
    final point = mp.LatLng(latitude, longitude);
    return mp.PolygonUtil.containsLocation(point, campusBoundary, true);
  }

  void _processPositionUpdate(Position position, {bool isInitialFix = false}) {
    _currentPosition = position;
    _currentHeading = position.heading.isNaN ? 0.0 : position.heading;
    _isLocationLoaded = true;
    _positionStreamController.add(position);

    final bool rawInside = checkCoordinatesInsideCampus(
      position.latitude,
      position.longitude,
    );

    if (isInitialFix) {
      // First GPS fix sets the state immediately to avoid initial waiting delay
      _isInsideCampus = rawInside;
      _pendingInsideCampus = null;
      _debounceTimer?.cancel();
      _debounceTimer = null;
      _campusStateController.add(_isInsideCampus);
      notifyListeners();
      debugPrint('[LocationManager] Initial GPS fix: isInsideCampus = $_isInsideCampus');
      return;
    }

    // Anti-Flicker Debounce Logic:
    // If raw reading matches confirmed state, cancel any pending toggle
    if (rawInside == _isInsideCampus) {
      if (_debounceTimer != null) {
        debugPrint('[LocationManager] Border jitter neutralized: reverted to confirmed $_isInsideCampus');
        _debounceTimer?.cancel();
        _debounceTimer = null;
        _pendingInsideCampus = null;
        notifyListeners();
      } else {
        notifyListeners();
      }
      return;
    }

    // Raw reading is DIFFERENT from current confirmed state
    if (_pendingInsideCampus == rawInside && _debounceTimer != null && _debounceTimer!.isActive) {
      // Debounce timer is already active for this pending state; keep ticking
      notifyListeners();
      return;
    }

    // Start 4-second anti-flicker delay before toggling the UI
    _debounceTimer?.cancel();
    _pendingInsideCampus = rawInside;
    notifyListeners();

    debugPrint('[LocationManager] Border crossing detected! Buffering for ${antiFlickerDelay.inSeconds}s before switching to $rawInside...');

    _debounceTimer = Timer(antiFlickerDelay, () {
      if (_pendingInsideCampus != null && _pendingInsideCampus != _isInsideCampus) {
        _isInsideCampus = _pendingInsideCampus!;
        _pendingInsideCampus = null;
        _debounceTimer = null;
        debugPrint('[LocationManager] Anti-flicker buffer completed. New confirmed state: isInsideCampus = $_isInsideCampus');
        _campusStateController.add(_isInsideCampus);
        notifyListeners();
      }
    });
  }

  // ===========================================================================
  // MANUAL SIMULATION (FOR TESTING ON EMULATOR/DESKTOP)
  // ===========================================================================
  /// Allows manual position override for deterministic geofence testing
  void simulatePosition(double latitude, double longitude, {bool? isInitialFix}) {
    final bool initial = isInitialFix ?? (_currentPosition == null);
    final simulated = Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      altitude: 10.0,
      altitudeAccuracy: 1.0,
      accuracy: 5.0,
      heading: _currentHeading,
      headingAccuracy: 1.0,
      speed: 1.2,
      speedAccuracy: 0.5,
    );
    _processPositionUpdate(simulated, isInitialFix: initial);
  }

  /// Resets state for isolated unit testing
  @visibleForTesting
  void resetForTesting() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _pendingInsideCampus = null;
    _currentPosition = null;
    _isLocationLoaded = false;
    _isInsideCampus = false;
  }

  // ===========================================================================
  // CLEANUP
  // ===========================================================================
  @override
  void dispose() {
    _debounceTimer?.cancel();
    _positionStreamSubscription?.cancel();
    _campusStateController.close();
    _positionStreamController.close();
    super.dispose();
  }
}
