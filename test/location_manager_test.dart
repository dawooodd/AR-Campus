import 'package:flutter_test/flutter_test.dart';
import 'package:campus_ar/helpers/location_manager.dart';

void main() {
  group('LocationManager & Geofencing Tests', () {
    late LocationManager locationManager;

    setUp(() {
      locationManager = LocationManager();
      locationManager.resetForTesting();
    });

    test('Campus boundary polygon contains Anchor Point', () {
      expect(LocationManager.campusBoundary.length, greaterThanOrEqualTo(4));
      expect(LocationManager.campusBoundaryGoogleMaps.length, equals(LocationManager.campusBoundary.length));

      // Anchor Point (-6.1753924, 106.8271528) should be inside campus polygon
      final isAnchorInside = locationManager.checkCoordinatesInsideCampus(
        LocationManager.anchorLatitude,
        LocationManager.anchorLongitude,
      );
      expect(isAnchorInside, isTrue);
    });

    test('Coordinates far outside campus return false', () {
      // Monas / far coordinate (-6.1950, 106.8500) is outside
      final isOutside = locationManager.checkCoordinatesInsideCampus(-6.1950000, 106.8500000);
      expect(isOutside, isFalse);
    });

    test('Formatted GPS coordinates string complies with "latitude,longitude" protocol', () {
      // Default formatted GPS returns comma-separated anchor string
      expect(locationManager.formattedGPS, contains(','));
      final parts = locationManager.formattedGPS.split(',');
      expect(parts.length, equals(2));
      expect(double.tryParse(parts[0]), isNotNull);
      expect(double.tryParse(parts[1]), isNotNull);
    });

    test('Simulated position updates and anti-flicker hysteresis', () async {
      // 1. Initial simulation inside campus
      locationManager.simulatePosition(
        LocationManager.anchorLatitude,
        LocationManager.anchorLongitude,
      );

      // Verify immediate confirmed state on initial fix
      expect(locationManager.isInsideCampus, isTrue);
      expect(locationManager.isBuffering, isFalse);

      // 2. User moves outside campus (e.g., crossing boundary)
      locationManager.simulatePosition(-6.1950000, 106.8500000);

      // Anti-flicker buffer should be active immediately to prevent flickering
      expect(locationManager.isBuffering, isTrue);
      expect(locationManager.pendingInsideCampus, isFalse);
      // Confirmed state should still remain true during the 4-second buffer window!
      expect(locationManager.isInsideCampus, isTrue);

      // 3. User steps back inside campus before buffer window expires
      locationManager.simulatePosition(
        LocationManager.anchorLatitude,
        LocationManager.anchorLongitude,
      );

      // Buffer should be cancelled and neutralized
      expect(locationManager.isBuffering, isFalse);
      expect(locationManager.isInsideCampus, isTrue);
    });
  });
}
