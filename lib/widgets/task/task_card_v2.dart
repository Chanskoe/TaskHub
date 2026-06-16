import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class CalendarTaskTile extends StatelessWidget {
  final String title;
  final String time;
  final Color markerColor;
  final VoidCallback? onTap;

  const CalendarTaskTile({
    super.key,
    required this.title,
    required this.time,
    required this.markerColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.gray.withValues(alpha: 0.2), width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 4,
                color: markerColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: AppWeight.lightFontWeight,
                          color: AppColors.darkBlue,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: AppWeight.lightFontWeight,
                          color: AppColors.darkGray,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}