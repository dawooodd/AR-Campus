import 'dart:convert';
import '../model/leaderboard_user.dart';
import 'api.dart';
import 'api_url.dart';

class LeaderboardRepository {
  // Fetch leaderboard data from API with graceful fallback to campus mock data
  static Future<List<LeaderboardUser>> getLeaderboard() async {
    try {
      final response = await Api().get(ApiUrl.leaderboard);
      if (response != null && response is Map<String, dynamic> && response['data'] is List) {
        final list = response['data'] as List;
        return list.map((item) => LeaderboardUser.fromJson(item as Map<String, dynamic>)).toList();
      } else if (response is List) {
        return response.map((item) => LeaderboardUser.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {
      // Gracefully fall back to local high-fidelity mock data on network error / offline
    }

    return _getFallbackMockData();
  }

  static List<LeaderboardUser> _getFallbackMockData() {
    return const [
      LeaderboardUser(
        rank: 1,
        id: 'u-1',
        name: 'Dimas Arya',
        studyProgram: 'Sistem Informasi',
        points: 184200,
        avatarUrl: null,
      ),
      LeaderboardUser(
        rank: 2,
        id: 'u-2',
        name: 'Siti Nurhaliza',
        studyProgram: 'Ilmu Komputer',
        points: 162800,
        avatarUrl: null,
      ),
      LeaderboardUser(
        rank: 3,
        id: 'u-3',
        name: 'Budi Santoso',
        studyProgram: 'Teknik Elektro',
        points: 147500,
        avatarUrl: null,
      ),
      LeaderboardUser(
        rank: 4,
        id: 'u-4',
        name: 'Nadya Salsabila',
        studyProgram: 'Teknik Informatika',
        points: 139100,
        avatarUrl: null,
      ),
      LeaderboardUser(
        rank: 5,
        id: 'u-5',
        name: 'Reza Pahlevi',
        studyProgram: 'Manajemen Rekayasa',
        points: 128400,
        avatarUrl: null,
      ),
      LeaderboardUser(
        rank: 6,
        id: 'u-6',
        name: 'Amanda Putri',
        studyProgram: 'Desain Komunikasi Visual',
        points: 118900,
        avatarUrl: null,
      ),
      LeaderboardUser(
        rank: 7,
        id: 'u-7',
        name: 'Fajar Pratama',
        studyProgram: 'Teknik Industri',
        points: 112300,
        avatarUrl: null,
      ),
      LeaderboardUser(
        rank: 8,
        id: 'u-8',
        name: 'Kevin Alexander',
        studyProgram: 'Teknik Sipil',
        points: 105700,
        avatarUrl: null,
      ),
      LeaderboardUser(
        rank: 9,
        id: 'u-9',
        name: 'Rina Maulida',
        studyProgram: 'Arsitektur',
        points: 98400,
        avatarUrl: null,
      ),
      LeaderboardUser(
        rank: 10,
        id: 'u-10',
        name: 'Gilang Ramadhan',
        studyProgram: 'Hukum & Bisnis',
        points: 91200,
        avatarUrl: null,
      ),
    ];
  }
}
