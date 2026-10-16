import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'summary_screen.dart';

class QuizQuestion {
  final String question;
  final String hint;
  final String imagePath;
  final List<String> options;
  final int correctIndex;
  final int rewardPoints;

  const QuizQuestion({
    required this.question,
    required this.hint,
    required this.imagePath,
    required this.options,
    required this.correctIndex,
    this.rewardPoints = 20,
  });
}

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with SingleTickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  bool _isAnswerSubmitted = false;
  bool _isHintExpanded = true;
  int _totalCorrect = 0;
  int _earnedPointsSession = 0;

  // 30 seconds timer per question
  Timer? _timer;
  int _remainingSeconds = 30;

  final List<QuizQuestion> _questions = const [
    QuizQuestion(
      question: "Gedung apakah pada gambar berikut?",
      hint: "Gedung ini sering digunakan untuk kegiatan akademik mahasiswa dan perkuliahan umum.",
      imagePath: "assets/images/splash_bg.jpg",
      options: [
        "Perpustakaan Pusat",
        "Gedung Rektorat",
        "Gedung Aula Utama",
        "Laboratorium Terpadu",
      ],
      correctIndex: 1,
      rewardPoints: 20,
    ),
    QuizQuestion(
      question: "Di mana lokasi laboratorium komputer dan sains berada?",
      hint: "Berada di sebelah timur kampus dekat fakultas teknik.",
      imagePath: "assets/images/splash_bg.jpg",
      options: [
        "Gedung Sains & Teknologi",
        "Kantin Utama",
        "Pusat Bahasa",
        "Gedung Student Center",
      ],
      correctIndex: 0,
      rewardPoints: 20,
    ),
    QuizQuestion(
      question: "Fasilitas apa yang terdapat di lantai dasar gedung utama?",
      hint: "Tempat berkumpul mahasiswa untuk meminjam buku dan belajar bersama.",
      imagePath: "assets/images/splash_bg.jpg",
      options: [
        "Perpustakaan Digital",
        "Klinik Kampus",
        "Gymnasium",
        "Koperasi Mahasiswa",
      ],
      correctIndex: 0,
      rewardPoints: 15,
    ),
    QuizQuestion(
      question: "Tahun berapakah universitas ini didirikan pertama kali?",
      hint: "Tertera pada prasasti gerbang masuk utama kampus.",
      imagePath: "assets/images/splash_bg.jpg",
      options: [
        "1985",
        "1992",
        "1964",
        "2001",
      ],
      correctIndex: 2,
      rewardPoints: 20,
    ),
    QuizQuestion(
      question: "Maskot resmi kampus yang melambangkan keberanian dan kecerdasan adalah?",
      hint: "Karakter hijau bersahabat yang memandu kamu di aplikasi ini!",
      imagePath: "assets/images/crocodile_mascot.jpg",
      options: [
        "Garuda Mas",
        "Buaya Cerdas",
        "Harimau Loreng",
        "Gajah Perkasa",
      ],
      correctIndex: 1,
      rewardPoints: 20,
    ),
    QuizQuestion(
      question: "Berapa kapasitas aula serbaguna universitas?",
      hint: "Sering digunakan untuk wisuda dan seminar nasional ribuan orang.",
      imagePath: "assets/images/splash_bg.jpg",
      options: [
        "500 Orang",
        "1.200 Orang",
        "3.000 Orang",
        "5.000 Orang",
      ],
      correctIndex: 2,
      rewardPoints: 20,
    ),
    QuizQuestion(
      question: "Warna utama almamater kampus adalah?",
      hint: "Melambangkan kelestarian alam dan pertumbuhan akademik.",
      imagePath: "assets/images/splash_bg.jpg",
      options: [
        "Hijau Gelap (Forest Green)",
        "Biru Langit",
        "Kuning Emas",
        "Merah Marun",
      ],
      correctIndex: 0,
      rewardPoints: 15,
    ),
    QuizQuestion(
      question: "Apa nama landmark taman terbuka hijau di tengah kampus?",
      hint: "Taman berbentuk melingkar tempat mahasiswa berdiskusi.",
      imagePath: "assets/images/splash_bg.jpg",
      options: [
        "Taman Inspirasi",
        "Plaza Akademik",
        "Boulevard Utama",
        "Taman Rektorat",
      ],
      correctIndex: 0,
      rewardPoints: 20,
    ),
    QuizQuestion(
      question: "Pusat kegiatan mahasiswa (UKM) terpusat di gedung apa?",
      hint: "Gedung dengan berbagai sekretariat organisasi mahasiswa.",
      imagePath: "assets/images/splash_bg.jpg",
      options: [
        "Gedung Student Center",
        "Gedung Pascasarjana",
        "Asrama Mahasiswa",
        "Pusat Olahraga",
      ],
      correctIndex: 0,
      rewardPoints: 20,
    ),
    QuizQuestion(
      question: "Fitur utama apa yang digunakan dalam game Campus Hunto?",
      hint: "Teknologi imersif yang memadukan dunia nyata dengan objek 3D virtual.",
      imagePath: "assets/images/splash_bg.jpg",
      options: [
        "Augmented Reality (AR) & GPS",
        "Virtual Reality Headset",
        "Text Based Adventure",
        "2D Pixel Offline",
      ],
      correctIndex: 0,
      rewardPoints: 25,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = 30;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        if (!_isAnswerSubmitted) {
          _handleAnswerSubmit(isTimeout: true);
        }
      }
    });
  }

  void _handleAnswerSubmit({bool isTimeout = false}) {
    if (_isAnswerSubmitted) return;

    _timer?.cancel();
    final currentQ = _questions[_currentQuestionIndex];
    final bool isCorrect = !isTimeout && _selectedAnswerIndex == currentQ.correctIndex;

    setState(() {
      _isAnswerSubmitted = true;
      if (isCorrect) {
        _totalCorrect++;
        _earnedPointsSession += currentQ.rewardPoints;
      }
    });

    if (isCorrect) {
      Provider.of<GameProvider>(context, listen: false).claimPoints(currentQ.rewardPoints);
    }
  }

  void _handleNextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = null;
        _isAnswerSubmitted = false;
        _isHintExpanded = true;
      });
      _startTimer();
    } else {
      // Finished all 10 questions -> Show feedback and navigate to SummaryScreen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("🎉 Kuis Selesai! Jawaban Benar: $_totalCorrect/${_questions.length} (+$_earnedPointsSession Poin)"),
          backgroundColor: AppColors.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SummaryScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GameProvider>(context);
    final currentQ = _questions[_currentQuestionIndex];
    final double progress = (_currentQuestionIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: _buildAppBar(context, provider.totalPoints),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress and Timer Row
              _buildProgressAndTimerRow(progress),
              SizedBox(height: 12.h),

              // Collapsible Hint Card (#96B55F)
              _buildHintCard(currentQ.hint),
              SizedBox(height: 16.h),

              // Question Image Card
              _buildQuestionImageCard(currentQ),
              SizedBox(height: 16.h),

              // Question Prompt Caption
              Text(
                currentQ.question,
                style: AppTheme.heading1.copyWith(
                  fontSize: 18.sp,
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),

              // 4 Answer Options (A, B, C, D)
              ...List.generate(currentQ.options.length, (index) {
                return _buildOptionTile(
                  optionLetter: String.fromCharCode(65 + index), // A, B, C, D
                  optionText: currentQ.options[index],
                  optionIndex: index,
                  correctIndex: currentQ.correctIndex,
                );
              }),
              SizedBox(height: 24.h),

              // Bottom CTA Button ("Jawab" or "Lanjut")
              _buildCTAButton(),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  // Header AppBar
  PreferredSizeWidget _buildAppBar(BuildContext context, int points) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
        onPressed: () => Navigator.of(context).pop(),
      ),
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("🐯", style: TextStyle(fontSize: 20)),
          SizedBox(width: 6.w),
          Text(
            "QUIZ",
            style: AppTheme.heading1.copyWith(
              fontSize: 20.sp,
              color: Colors.black,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 16.w),
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.softYellow,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: AppColors.accentYellow, width: 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: AppColors.accentYellow, size: 18),
                  SizedBox(width: 4.w),
                  Text(
                    "$points",
                    style: AppTheme.body.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
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

  // Progress Bar and 30s Timer Row
  Widget _buildProgressAndTimerRow(double progress) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Soal ${_currentQuestionIndex + 1}/${_questions.length}",
              style: AppTheme.body.copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryGreen,
              ),
            ),
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 18.w,
                  color: _remainingSeconds <= 5 ? AppColors.errorRed : AppColors.accentGreen,
                ),
                SizedBox(width: 4.w),
                Text(
                  "$_remainingSeconds s",
                  style: AppTheme.body.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: _remainingSeconds <= 5 ? AppColors.errorRed : AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 8.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.lightPinkCream,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
            minHeight: 8.h,
          ),
        ),
      ],
    );
  }

  // Collapsible Hint Card (#96B55F)
  Widget _buildHintCard(String hintText) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.accentGreen, // #96B55F
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGreen.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isHintExpanded = !_isHintExpanded;
              });
            },
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8.w),
                Text(
                  "Petunjuk",
                  style: AppTheme.heading2.copyWith(
                    fontSize: 15.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(
                  _isHintExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: Colors.white,
                  size: 22.w,
                ),
              ],
            ),
          ),
          if (_isHintExpanded) ...[
            SizedBox(height: 6.h),
            Text(
              hintText,
              style: AppTheme.body.copyWith(
                fontSize: 13.sp,
                color: Colors.white,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Question Campus Image
  Widget _buildQuestionImageCard(QuizQuestion q) {
    return Container(
      width: double.infinity,
      height: 180.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.neutralGray, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17.r),
        child: Image.asset(
          q.imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppColors.lightPinkCream,
              child: const Center(
                child: Icon(Icons.business_rounded, size: 60, color: AppColors.primaryGreen),
              ),
            );
          },
        ),
      ),
    );
  }

  // Answer Option Tile
  Widget _buildOptionTile({
    required String optionLetter,
    required String optionText,
    required int optionIndex,
    required int correctIndex,
  }) {
    final bool isSelected = _selectedAnswerIndex == optionIndex;
    final bool isCorrectOption = optionIndex == correctIndex;

    Color borderColor = AppColors.neutralGray;
    Color bgColor = AppColors.white;
    Color textColor = Colors.black87;
    Widget? trailingIcon;

    if (_isAnswerSubmitted) {
      if (isCorrectOption) {
        borderColor = AppColors.accentGreen;
        bgColor = AppColors.softYellow.withValues(alpha: 0.5);
        textColor = AppColors.primaryGreen;
        trailingIcon = const Icon(Icons.check_circle_rounded, color: AppColors.accentGreen, size: 22);
      } else if (isSelected && !isCorrectOption) {
        borderColor = AppColors.errorRed;
        bgColor = Colors.red.shade50;
        textColor = AppColors.errorRed;
        trailingIcon = const Icon(Icons.cancel_rounded, color: AppColors.errorRed, size: 22);
      }
    } else {
      if (isSelected) {
        borderColor = AppColors.accentGreen;
        bgColor = AppColors.softYellow.withValues(alpha: 0.4);
        textColor = AppColors.primaryGreen;
      }
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: _isAnswerSubmitted
              ? null
              : () {
                  setState(() {
                    _selectedAnswerIndex = optionIndex;
                  });
                },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: borderColor, width: isSelected || (_isAnswerSubmitted && isCorrectOption) ? 2.0 : 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Option Letter Badge (A, B, C, D)
                Container(
                  width: 32.w,
                  height: 32.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accentGreen : AppColors.lightPinkCream,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    optionLetter,
                    style: AppTheme.heading2.copyWith(
                      fontSize: 14.sp,
                      color: isSelected ? Colors.white : AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 14.w),

                // Option Label
                Expanded(
                  child: Text(
                    optionText,
                    style: AppTheme.body.copyWith(
                      fontSize: 15.sp,
                      color: textColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),

                if (trailingIcon != null) ...[
                  SizedBox(width: 8.w),
                  trailingIcon,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // CTA Button ("Jawab" or "Lanjut")
  Widget _buildCTAButton() {
    final bool canSubmit = _selectedAnswerIndex != null;

    if (!_isAnswerSubmitted) {
      return SizedBox(
        width: double.infinity,
        height: 54.h,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: canSubmit ? AppColors.accentGreen : AppColors.neutralGray,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.r), // Pill shape
            ),
            elevation: canSubmit ? 3 : 0,
          ),
          onPressed: canSubmit ? () => _handleAnswerSubmit() : null,
          child: Text(
            "Jawab",
            style: AppTheme.heading2.copyWith(
              fontSize: 18.sp,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } else {
      final bool isLast = _currentQuestionIndex == _questions.length - 1;
      return SizedBox(
        width: double.infinity,
        height: 54.h,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.r), // Pill shape
            ),
            elevation: 3,
          ),
          onPressed: _handleNextQuestion,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isLast ? "Lihat Hasil Ringkasan" : "Lanjut ke Soal Berikutnya",
                style: AppTheme.heading2.copyWith(
                  fontSize: 18.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8.w),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            ],
          ),
        ),
      );
    }
  }
}
