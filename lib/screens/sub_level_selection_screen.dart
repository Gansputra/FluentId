import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fluentid/services/progress_service.dart';
import '../widgets/interactive_particle_background.dart';
import 'home_screen.dart';

class SubLevelSelectionScreen extends StatefulWidget {
  final String parentLevelName;
  final String fileName;
  final int totalVocabs;
  final int vocabsPerLevel;

  const SubLevelSelectionScreen({
    super.key,
    required this.parentLevelName,
    required this.fileName,
    required this.totalVocabs,
    this.vocabsPerLevel = 25,
  });

  @override
  State<SubLevelSelectionScreen> createState() => _SubLevelSelectionScreenState();
}

class _SubLevelSelectionScreenState extends State<SubLevelSelectionScreen> {
  final ProgressService _progressService = ProgressService();
  Map<int, int> _levelProgress = {};

  @override
  void initState() {
    super.initState();
    _loadAllSubLevelProgress();
  }

  Future<void> _loadAllSubLevelProgress() async {
    Map<int, int> progress = {};
    int numLevels = (widget.totalVocabs / widget.vocabsPerLevel).ceil();
    
    for (int i = 0; i < numLevels; i++) {
      int start = i * widget.vocabsPerLevel;
      int end = start + widget.vocabsPerLevel;
      // Note: we use parentLevelName as the category key in ProgressService
      int count = await _progressService.getMasteredCountInRange(widget.parentLevelName, start, end + 1);
      progress[i + 1] = count;
    }

    if (mounted) {
      setState(() {
        _levelProgress = progress;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int numLevels = (widget.totalVocabs / widget.vocabsPerLevel).ceil();

    return Scaffold(
      body: InteractiveParticleBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.deepPurple),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.parentLevelName,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.deepPurple.shade300,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Text(
                          "Pilih Sub-Level",
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: numLevels,
                  itemBuilder: (context, index) {
                    int levelNumber = index + 1;
                    return _buildSubLevelCard(levelNumber);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubLevelCard(int levelNumber) {
    int mastered = _levelProgress[levelNumber] ?? 0;
    double progressValue = mastered / widget.vocabsPerLevel;
    
    // Unlock logic: level 1 is always unlocked, 
    // others if the previous one has at least some progress or if it's the current "Basic" logic.
    // For now, let's just make level 1 unlocked, and others unlocked if mastered > 0 in previous.
    // Simplifying: let's unlock all for now but show progress.
    bool isUnlocked = true; 
    
    return InkWell(
      onTap: !isUnlocked ? null : () {
        int start = (levelNumber - 1) * widget.vocabsPerLevel;
        int end = start + widget.vocabsPerLevel;
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              levelName: "${widget.parentLevelName} - Lvl $levelNumber",
              fileName: widget.fileName,
              startIndex: start,
              endIndex: end,
            ),
          ),
        ).then((_) => _loadAllSubLevelProgress());
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: isUnlocked ? Colors.white.withOpacity(0.4) : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isUnlocked ? Colors.deepPurple.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isUnlocked ? Colors.deepPurple.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    "$levelNumber",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked ? Colors.deepPurple : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "$mastered/${widget.vocabsPerLevel}",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isUnlocked ? Colors.deepPurple.withOpacity(0.7) : Colors.grey,
                  ),
                ),
                const Spacer(),
                if (isUnlocked)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    child: LinearProgressIndicator(
                      value: progressValue,
                      backgroundColor: Colors.deepPurple.withOpacity(0.05),
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple.withOpacity(0.6)),
                      minHeight: 6,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
