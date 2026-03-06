import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class LevelCard extends StatelessWidget {
  final int levelNumber;
  final double progress;
  final bool isLocked;
  final bool isActive;
  final VoidCallback onTap;

  const LevelCard({
    super.key,
    required this.levelNumber,
    required this.progress,
    required this.isLocked,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = isActive ? AppColors.primary : AppColors.textSecondary;
    
    return Opacity(
      opacity: isLocked ? 0.5 : 1.0,
      child: InkWell(
        onTap: isLocked ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              if (isActive)
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
            ],
            border: Border.all(
              color: isActive ? AppColors.primary : Colors.black.withOpacity(0.05),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLocked)
                Icon(Icons.lock_outline_rounded, size: 24, color: color)
              else
                Text(
                  "$levelNumber",
                  style: AppStyles.h2.copyWith(color: color),
                ),
              const SizedBox(height: 8),
              if (!isLocked)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: color.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 4,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
