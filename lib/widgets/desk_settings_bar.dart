import 'package:flutter/material.dart';
import '../theme/theme.dart';

class DeskSettingsBar extends StatelessWidget {
  final String currentBoardName;
  final String selectedView; 
  final ValueChanged<String> onViewChanged;
  final VoidCallback onSettingsPressed;

  const DeskSettingsBar({
    super.key,
    required this.currentBoardName,
    required this.selectedView,
    required this.onViewChanged,
    required this.onSettingsPressed,
  });

  String _smallDeskName(String deskName) {
    final maxChars = 20;
    final truncated = deskName.length > maxChars 
      ? '${deskName.substring(0, maxChars)}...' 
      : deskName;
    return truncated;
  }

  @override
  Widget build(BuildContext context) {
    final List<String> views = ['Неделя', 'Список', 'Канбан', 'Календарь'];
    final bool isMobile = MediaQuery.of(context).size.width < 1100; 

    if (isMobile) {
      return _buildMobileBar(context, views);
    }

    return _buildDesktopBar(context, views);
  }

  Widget _buildMobileBar(BuildContext context, List<String> views) {
    final List<String> allOptions = [...views, 'Настройки'];

    return Align(
      alignment: Alignment.centerRight,
      child: PopupMenuButton<String>(
        borderRadius: BorderRadius.circular(20),
        offset: const Offset(0, 45),
        tooltip: 'Виды представления и настройки',
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: AppColors.cardBackground,
        onSelected: (value) {
          if (value == 'Настройки') {
            onSettingsPressed();
          } else {
            onViewChanged(value);
          }
        },
        itemBuilder: (context) => allOptions.map((option) {
          final bool isSelected = option == selectedView;
          return PopupMenuItem<String>(
            value: option,
            child: Text(
              option,
              style: TextStyle(
                fontSize: AppSizes.body,
                fontWeight: isSelected ? AppWeight.normalFontWeight : AppWeight.lightFontWeight,
                color: isSelected ? AppColors.darkBlue : AppColors.mediumBlue,
              ),
            ),
          );
        }).toList(),
        child: Container(
          height: 35,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.olive,
            borderRadius: BorderRadius.circular(23),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.folder, size: 18, color: AppColors.mediumBlue),
              const SizedBox(width: 12),
              Text(
                _smallDeskName(currentBoardName),
                style: const TextStyle(
                  fontSize: AppSizes.body,
                  fontWeight: AppWeight.lightFontWeight,
                  color: AppColors.darkBlue,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.keyboard_arrow_down, color: AppColors.darkBlue, size: 15),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopBar(BuildContext context, List<String> views) {
    final bool isSettingsSelected = selectedView == 'Настройки';

    return Container(
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.olive,
        borderRadius: BorderRadius.circular(23),
      ),
      child: Row(
        children: [
          const Icon(Icons.folder, size: 18, color: AppColors.mediumBlue),
          const SizedBox(width: 24),
          Text(
            _smallDeskName(currentBoardName),
            style: const TextStyle(
              fontSize: AppSizes.body,
              fontWeight: AppWeight.lightFontWeight,
              color: AppColors.darkBlue,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 10, top: 10, bottom: 10, left: 24),
            child: VerticalDivider(color: AppColors.darkGray, thickness: 1),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: views.map((view) {
                  final bool isSelected = view == selectedView;
                  return GestureDetector(
                    onTap: () => onViewChanged(view),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppColors.accentBrown : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        view,
                        style: TextStyle(
                          fontSize: AppSizes.body,
                          fontWeight: AppWeight.lightFontWeight,
                          color: isSelected ? AppColors.darkBlue : AppColors.mediumBlue,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 3, right: 12, top: 10, bottom: 10),
            child: VerticalDivider(color: AppColors.darkGray, thickness: 1),
          ),
          GestureDetector(
            onTap: onSettingsPressed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSettingsSelected ? AppColors.accentBrown : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Text(
                'Настройки',
                style: TextStyle(
                  fontSize: AppSizes.body,
                  fontWeight: AppWeight.lightFontWeight,
                  color: isSettingsSelected ? AppColors.darkBlue : AppColors.mediumBlue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}