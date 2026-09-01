import 'dart:math';
import 'package:flutter/material.dart';

class GameProvider extends ChangeNotifier {
  bool _isGuest = false;
  int _totalPoints = 1250; // Starting points from the design
  bool _isRealLocation = false;
  String _userName = "Marrie";
  final int _level = 8;
  
  bool get isGuest => _isGuest;
  int get totalPoints => _totalPoints;
  bool get isRealLocation => _isRealLocation;
  String get userName => _userName;
  int get level => _level;

  void login(String identifier) {
    _isGuest = false;
    final cleanId = identifier.trim();
    if (cleanId.toLowerCase() == "dawood" || cleanId.toLowerCase() == "skakbayu141@gmail.com") {
      _userName = "dawood";
    } else if (cleanId.isNotEmpty) {
      _userName = cleanId.contains('@') ? cleanId.split('@').first : cleanId;
    } else {
      _userName = "dawood";
    }
    
    // Ensure points are initialized for registered users
    if (_totalPoints == 0) {
      _totalPoints = 1250;
    }
    notifyListeners();
  }

  void loginAsGuest() {
    _isGuest = true;
    _userName = "Guest";
    _totalPoints = 0; // Guests don't have points
    notifyListeners();
  }

  void claimPoints(int points) {
    _totalPoints += points;
    notifyListeners();
  }

  // Anti-Cheat Logic: 10% chance to assign a Real Location, 90% Fake Location
  void checkRealLocation() {
    // Generate a random number between 1 and 100
    int chance = Random().nextInt(100) + 1;
    
    // 1-10 means 10% chance
    if (chance <= 10) {
      _isRealLocation = true;
    } else {
      _isRealLocation = false;
    }
    notifyListeners();
  }
  
  // For testing purposes (force to real)
  void forceRealLocation() {
    _isRealLocation = true;
    notifyListeners();
  }
}
