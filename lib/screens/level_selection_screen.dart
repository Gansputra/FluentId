import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/interactive_particle_background.dart';
import 'home_screen.dart';

class LevelSelectionScreen extends StatefulWidget {
  const LevelSelectionScreen({super.key});

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  // Mock progression data - in real app, this should come from local storage
  final int _userScore = 0; 
  final int _scoreToUnlockAdvanced = 500;
  final int _scoreToUnlockProfessional = 1500;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: InteractiveParticleBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Text(
                  "Pilih Levelmu,",
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.deepPurple.shade700,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Text(
                  "Sang Juara 👑",
                  style: TextStyle(
                    fontSize: 32,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Total XP: $_userScore",
                    style: const TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                _buildLevelCard(
                  title: "Basic",
                  subtitle: "Dasar-dasar penting",
                  icon: Icons.school_outlined,
                  color: Colors.blue,
                  fileName: "vocabBasic.json",
                  isLocked: false,
                ),
                _buildLevelCard(
                  title: "Advanced",
                  subtitle: "Level menengah",
                  icon: Icons.trending_up_rounded,
                  color: Colors.orange,
                  fileName: "vocabAdvanced.json",
                  isLocked: _userScore < _scoreToUnlockAdvanced,
                  lockInfo: "Butuh ${_scoreToUnlockAdvanced - _userScore} XP lagi",
                ),
                _buildLevelCard(
                  title: "Professional",
                  subtitle: "Gaya bicara pro",
                  icon: Icons.workspace_premium_rounded,
                  color: Colors.red,
                  fileName: "vocabProfessional.json",
                  isLocked: _userScore < _scoreToUnlockProfessional,
                  lockInfo: "Butuh ${_scoreToUnlockProfessional - _userScore} XP lagi",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String fileName,
    required bool isLocked,
    String? lockInfo,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: InkWell(
        onTap: isLocked 
          ? null 
          : () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(
                  levelName: title,
                  fileName: fileName,
                ),
              ),
            ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isLocked 
                  ? Colors.grey.withOpacity(0.2) 
                  : Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isLocked 
                    ? Colors.grey.withOpacity(0.3) 
                    : color.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isLocked ? Colors.grey.shade300 : color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isLocked ? Icons.lock_rounded : icon,
                      color: isLocked ? Colors.grey : color,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isLocked ? Colors.grey : Colors.black87,
                          ),
                        ),
                        Text(
                          isLocked ? (lockInfo ?? "Terkunci") : subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: isLocked ? Colors.grey.shade600 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLocked)
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.black26, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
