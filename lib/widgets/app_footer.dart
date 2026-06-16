import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text("Контакты", style: TextStyle(color: AppColors.darkBlue, fontWeight: AppWeight.lightFontWeight, fontSize: AppSizes.subHeader)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.link)),
              IconButton(onPressed: () {}, icon: const Icon(Icons.link)),
              IconButton(onPressed: () {}, icon: const Icon(Icons.link)),
            ],
          ),
        ],
      ),
    );
  }
  
}