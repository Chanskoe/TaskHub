import 'package:flutter/material.dart';
import '../theme/theme.dart';

class SidebarSearchBar extends StatelessWidget {
  final ValueChanged<String>? onChanged;

  const SidebarSearchBar({super.key, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.screenBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        onChanged: onChanged,
        cursorWidth: 1,                 
        cursorHeight: 14,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(
          fontSize: AppSizes.search,
          color: AppColors.darkBlue,
        ),
        decoration: const InputDecoration(
          hintText: 'Поиск...',
          hintStyle: TextStyle(
            color: AppColors.darkGray, 
            fontSize: AppSizes.search, 
            fontWeight: AppWeight.extraLightFontWeight,
          ),
          border: InputBorder.none,
          
          // ЭТИ СТРОКИ УБИРАЮТ ЛИШНЮЮ ВЫСОТУ:
          isDense: true, // Делает поле компактным
          contentPadding: EdgeInsets.symmetric(vertical: 4), // Схлопывает дефолтные 12-16px до минимума
          
          icon: Icon(Icons.search, size: 15, color: AppColors.darkGray),
        ),
      ),
    );
  }
}