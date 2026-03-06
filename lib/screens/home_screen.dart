import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../widgets/category_card.dart';
import '../services/progress_service.dart';
import 'level_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProgressService _progressService = ProgressService();
  int _xp = 0;
  double _basicProgress = 0;
  double _advancedProgress = 0;
  double _professionalProgress = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final xp = await _progressService.getXp();
    final basic = await _progressService.getMasteredCount("Basic");
    final advanced = await _progressService.getMasteredCount("Advanced");
    final professional = await _progressService.getMasteredCount("Professional");

    if (mounted) {
      setState(() {
        _xp = xp;
        _basicProgress = basic / 1000; // Assuming 1000 total for Basic
        _advancedProgress = advanced / 500; // Assuming 500 total for Advanced
        _professionalProgress = professional / 200; // Assuming 200 total for Professional
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Welcome Back!", style: AppStyles.subtitle),
                        Text("Language Learner", style: AppStyles.h2),
                      ],
                    ),
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Daily Progress Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt_rounded, color: Colors.white, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Daily Goal Progress",
                              style: AppStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "You've earned $_xp XP so far!",
                              style: AppStyles.subtitle.copyWith(color: Colors.white.withOpacity(0.8)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 48),
                Text("Choose Your\nLearning Path", style: AppStyles.h1.copyWith(height: 1.2)),
                const SizedBox(height: 24),
                
                CategoryCard(
                  title: "Basic",
                  description: "Master the foundations of English",
                  icon: Icons.auto_stories_rounded,
                  progress: _basicProgress,
                  color: Colors.blue,
                  onTap: () => _navigateToLevel("Basic", "vocabBasic.json", 1000),
                ),
                CategoryCard(
                  title: "Advanced",
                  description: "Refine your vocabulary & fluency",
                  icon: Icons.trending_up_rounded,
                  progress: _advancedProgress,
                  color: Colors.orange,
                  onTap: () => _navigateToLevel("Advanced", "vocabAdvanced.json", 500),
                ),
                CategoryCard(
                  title: "Professional",
                  description: "Speak like a native in business",
                  icon: Icons.workspace_premium_rounded,
                  progress: _professionalProgress,
                  color: AppColors.accent,
                  onTap: () => _navigateToLevel("Professional", "vocabProfessional.json", 200),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToLevel(String title, String fileName, int total) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LevelScreen(
          category: title,
          fileName: fileName,
          totalVocabs: total,
        ),
      ),
    ).then((_) => _loadData());
  }
}
