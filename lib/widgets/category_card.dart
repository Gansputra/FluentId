import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class CategoryCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final double progress;
  final VoidCallback onTap;
  final Color color;
  final bool isLocked;

  const CategoryCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.progress,
    required this.onTap,
    required this.color,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLocked ? null : onTap,
          borderRadius: BorderRadius.circular(24),
          child: Opacity(
            opacity: isLocked ? 0.6 : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: isLocked ? Colors.black.withOpacity(0.05) : color.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: isLocked ? Colors.grey.withOpacity(0.2) : color.withOpacity(0.1),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isLocked ? Colors.grey.withOpacity(0.1) : color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
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
                          style: AppStyles.h2.copyWith(
                            color: isLocked ? Colors.grey : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isLocked ? "Complete previous level to unlock" : description,
                          style: AppStyles.subtitle,
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: (isLocked ? Colors.grey : color).withOpacity(0.05),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isLocked ? Colors.grey.withOpacity(0.3) : color,
                            ),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    isLocked ? Icons.lock_outline_rounded : Icons.chevron_right_rounded,
                    color: isLocked ? Colors.grey : color.withOpacity(0.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

