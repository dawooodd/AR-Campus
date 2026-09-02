import 'dart:math';
import 'package:flutter/material.dart';

class GameProvider extends ChangeNotifier {
  bool _isGuest = false;
  int _totalPoints = 125000; // Starting points (sufficient for reward testing)
  bool _isRealLocation = false;
  String _userName = "Marrie";
  final int _level = 8;

  // Profile data
  String _fullName = "Marrie Dawood";
  String _nim = "2201010045";
  String _studyProgram = "Teknik Informatika";
  String _email = "marrie.dawood@campus.ac.id";
  String? _profileImagePath;

  // 3D Map Mission Mascot
  String _selectedCharacter = "Dragon"; // Options: Dragon, Tiger, Cat, Crocodile

  bool get isGuest => _isGuest;
  int get totalPoints => _totalPoints;
  bool get isRealLocation => _isRealLocation;
  String get userName => _userName;
  int get level => _level;

  String get fullName => _fullName;
  String get nim => _nim;
  String get studyProgram => _studyProgram;
  String get email => _email;
  String? get profileImagePath => _profileImagePath;
  String get selectedCharacter => _selectedCharacter;

  void selectCharacter(String character) {
    _selectedCharacter = character;
    notifyListeners();
  }

  void updateProfileImage(String path) {
    _profileImagePath = path;
    notifyListeners();
  }

  void updateProfileInfo({
    String? fullName,
    String? nim,
    String? studyProgram,
    String? email,
  }) {
    if (fullName != null) _fullName = fullName;
    if (nim != null) _nim = nim;
    if (studyProgram != null) _studyProgram = studyProgram;
    if (email != null) _email = email;
    notifyListeners();
  }

  bool deductPoints(int points) {
    if (_totalPoints >= points) {
      _totalPoints -= points;
      notifyListeners();
      return true;
    }
    return false;
  }

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
