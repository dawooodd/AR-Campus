import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Strongly-typed Quest Marker representation for 3D Campus POIs
class QuestMarker {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radius; // Interaction radius in meters (e.g., 25.0)
  final String questType; // 'cari_objek', 'quiz', 'ar_mission'
  final int points;

  const QuestMarker({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radius = 25.0,
    required this.questType,
    required this.points,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'questType': questType,
      'points': points,
    };
  }

  factory QuestMarker.fromJson(Map<String, dynamic> json) {
    return QuestMarker(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radius: (json['radius'] as num?)?.toDouble() ?? 25.0,
      questType: json['questType'] as String? ?? 'cari_objek',
      points: (json['points'] as num?)?.toInt() ?? 100,
    );
  }
}

/// Bi-directional communication bridge between Flutter and the Unity 3D Engine
/// Target GameObject: "UnityBridgeReceiver" in Unity Scene
class UnityBridge {
  static final UnityBridge _instance = UnityBridge._internal();
  factory UnityBridge() => _instance;
  UnityBridge._internal();

  static const String unityReceiverObject = "UnityBridgeReceiver";
  static const MethodChannel _platformChannel = MethodChannel('com.campus.ar/unity_bridge');

  // Callback hooks for Flutter UI
  void Function(String markerId, String questType)? onMarkerTapped;
  void Function(String rawMessage)? onMessageReceived;
  void Function(bool isReady)? onUnityEngineLoaded;

  bool _isUnityLoaded = false;
  bool get isUnityLoaded => _isUnityLoaded;

  // Attached native controller reference (dynamic to stay decoupled if flutter_unity_widget is compiled)
  dynamic _unityController;

  void attachController(dynamic controller) {
    _unityController = controller;
    _isUnityLoaded = true;
    onUnityEngineLoaded?.call(true);
    debugPrint('[UnityBridge] Native Unity controller attached successfully.');
  }

  void detachController() {
    _unityController = null;
    _isUnityLoaded = false;
    onUnityEngineLoaded?.call(false);
    debugPrint('[UnityBridge] Native Unity controller detached.');
  }

  // ==========================================
  // FLUTTER -> UNITY MESSAGES
  // ==========================================

  /// Streams real-time GPS coordinates directly to Unity PlayerController as "latitude,longitude"
  Future<void> updateGPSPosition(double latitude, double longitude) async {
    final gpsString = '$latitude,$longitude';
    debugPrint('[UnityBridge -> Unity] PlayerController.UpdateGPSPosition: $gpsString');
    if (_unityController != null) {
      try {
        _unityController.postMessage('PlayerController', 'UpdateGPSPosition', gpsString);
      } catch (e) {
        debugPrint('[UnityBridge] postMessage to PlayerController failed: $e');
      }
    }
  }

  /// Streams real-time GPS coordinates and compass heading to Unity to update the 3D player avatar position
  Future<void> setUserLocation({
    required double latitude,
    required double longitude,
    required double heading,
  }) async {
    // Send 1:1 GPS string to PlayerController
    await updateGPSPosition(latitude, longitude);

    final payload = {
      'latitude': latitude,
      'longitude': longitude,
      'heading': heading,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    final jsonStr = jsonEncode(payload);

    debugPrint('[UnityBridge -> Unity] SetUserLocation: $jsonStr');
    await _postMessageToUnity('SetUserLocation', jsonStr);
  }

  /// Sends the selected active mascot ID ('Crocodile', 'Dragon', 'Tiger', 'Cat') to instantiate or switch 3D models
  Future<void> setActiveMascot(String mascotId) async {
    final payload = {
      'mascotId': mascotId,
      'modelFile': 'hyuvi.fbx', // Default campus hero character asset in Assets/3Dobject/
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    final jsonStr = jsonEncode(payload);

    debugPrint('[UnityBridge -> Unity] SetActiveMascot: $jsonStr');
    await _postMessageToUnity('SetActiveMascot', jsonStr);
  }

  /// Sends the list of active campus POI / quest markers with coordinates and interaction radii
  Future<void> spawnCampusQuests(List<QuestMarker> markers) async {
    final payload = {
      'markers': markers.map((m) => m.toJson()).toList(),
      'count': markers.length,
    };
    final jsonStr = jsonEncode(payload);

    debugPrint('[UnityBridge -> Unity] SpawnCampusQuests (${markers.length} POIs): $jsonStr');
    await _postMessageToUnity('SpawnCampusQuests', jsonStr);
  }

  /// Low-level dispatcher to Unity GameObject receiver
  Future<void> _postMessageToUnity(String methodName, String message) async {
    if (_unityController != null) {
      try {
        // If controller implements postMessage(gameObject, method, message)
        _unityController.postMessage(unityReceiverObject, methodName, message);
        return;
      } catch (e) {
        debugPrint('[UnityBridge] postMessage via controller failed: $e');
      }
    }

    // Platform channel fallback
    try {
      await _platformChannel.invokeMethod('postToUnity', {
        'gameObject': unityReceiverObject,
        'methodName': methodName,
        'message': message,
      });
    } catch (_) {
      // Gracefully handled if Unity native engine is running in mock/pre-export mode
    }
  }

  // ==========================================
  // UNITY -> FLUTTER INBOUND MESSAGES
  // ==========================================

  /// Dispatches incoming message from Unity to Flutter event listeners
  void handleInboundMessage(String message) {
    debugPrint('[Unity -> Flutter] Inbound message: $message');
    onMessageReceived?.call(message);

    try {
      final Map<String, dynamic> data = jsonDecode(message) as Map<String, dynamic>;
      final event = data['event']?.toString();

      if (event == 'OnMarkerTapped') {
        final markerId = data['markerId']?.toString() ?? '';
        final questType = data['questType']?.toString() ?? 'cari_objek';
        onMarkerTapped?.call(markerId, questType);
      } else if (event == 'OnEngineReady') {
        _isUnityLoaded = true;
        onUnityEngineLoaded?.call(true);
      }
    } catch (e) {
      // Handle raw string messages like "OnMarkerTapped:checkpoint_1:quiz"
      if (message.startsWith('OnMarkerTapped:')) {
        final parts = message.split(':');
        if (parts.length >= 3) {
          onMarkerTapped?.call(parts[1], parts[2]);
        }
      }
    }
  }
}
