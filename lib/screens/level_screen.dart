import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../widgets/level_card.dart';
import '../services/progress_service.dart';
import 'quiz_screen.dart';

class LevelScreen extends StatefulWidget {
  final String category;
  final String fileName;
  final int totalVocabs;

  const LevelScreen({
    super.key,
    required this.category,
    required this.fileName,
    required this.totalVocabs,
  });

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  final ProgressService _progressService = ProgressService();
  final int quizzesPerLevel = 25;
  Map<int, double> levelProgress = {};
  int masteredCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final count = await _progressService.getMasteredCount(widget.category);
    final int levels = (widget.totalVocabs / quizzesPerLevel).ceil();
    
    Map<int, double> progressMap = {};
    for (int i = 0; i < levels; i++) {
        int start = i * quizzesPerLevel;
        int end = (i + 1) * quizzesPerLevel;
        int currentMastered = await _progressService.getMasteredCountInRange(widget.category, start, end);
        progressMap[i + 1] = currentMastered / quizzesPerLevel;
    }

    if (mounted) {
      setState(() {
        masteredCount = count;
        levelProgress = progressMap;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final int levelsCount = (widget.totalVocabs / quizzesPerLevel).ceil();
    final double overallProgress = masteredCount / widget.totalVocabs;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(overallProgress),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(24),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: levelsCount,
                  itemBuilder: (context, index) {
                    final int levelNum = index + 1;
                    final double progress = levelProgress[levelNum] ?? 0.0;
                    
                    // Logic for locked: Level 1 is always unlocked. 
                    // Others unlock if previous level is somewhat complete.
                    // For now, let's say unlock if xp > 0 or just keep it simple.
                    bool isLocked = index > 0 && (levelProgress[index] ?? 0.0) < 0.5;
                    bool isActive = !isLocked && progress < 1.0;

                    return LevelCard(
                      levelNumber: levelNum,
                      progress: progress,
                      isLocked: isLocked,
                      isActive: isActive,
                      onTap: () => _startQuiz(levelNum),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double progress) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
          ),
          const SizedBox(height: 16),
          Text("${widget.category} Path Progress", style: AppStyles.h2),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 12,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                "${(progress * 100).toInt()}%",
                style: AppStyles.body.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _startQuiz(int levelNum) {
    int start = (levelNum - 1) * quizzesPerLevel;
    int end = levelNum * quizzesPerLevel - 1;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(
          levelName: "Level $levelNum",
          category: widget.category,
          fileName: widget.fileName,
          startIndex: start,
          endIndex: end,
        ),
      ),
    ).then((_) => _loadProgress());
  }
}
