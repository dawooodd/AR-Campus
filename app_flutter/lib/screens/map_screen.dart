import 'package:flutter/material.dart';
import '../widgets/floating_panel.dart';
import '../widgets/custom_card.dart';
import '../theme/app_theme.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Placeholder for Google Maps
          Container(
            color: Colors.green.shade100,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 64, color: AppTheme.textGray),
                  SizedBox(height: 16),
                  Text(
                    'Google Maps Placeholder\n(Map Campus)',
                    textAlign: TextAlign.center,
                    style: AppTheme.subtitleStyle,
                  ),
                ],
              ),
            ),
          ),
          
          // Marker Placeholders
          Positioned(
            top: 200,
            left: 150,
            child: Icon(Icons.location_on, color: AppTheme.primaryGreen, size: 48),
          ),
          Positioned(
            top: 400,
            left: 250,
            child: Icon(Icons.location_on, color: AppTheme.textGray, size: 48),
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
