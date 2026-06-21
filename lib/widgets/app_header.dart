import 'package:flutter/material.dart';
import 'package:task_hub/services/auth_provider.dart';
import '../../theme/theme.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppHeader extends StatelessWidget {
  final bool isLoggedIn;
  final VoidCallback onLoginTap;
  final VoidCallback onProfileTap;

  const AppHeader({
    super.key, 
    required this.isLoggedIn, 
    required this.onLoginTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final user = AuthProvider().currentUser;
    
    return Container(
      height: kIsWeb || Platform.isMacOS ? 50 : (Platform.isAndroid ? 65 : 90),
      color: AppColors.darkBlue, 
      padding: kIsWeb || Platform.isMacOS? EdgeInsets.symmetric(horizontal: 20) : (Platform.isAndroid ? EdgeInsets.only(top: 25, left: 20, right: 20) : EdgeInsets.only(top: 50, left: 20, right: 20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 48), 
          
          const Text(
            "TaskHub", 
            style: TextStyle(
              fontSize: AppSizes.body, 
              fontWeight:AppWeight.lightFontWeight, 
              color: AppColors.cardBackground,
            ),
          ),
          
          isLoggedIn 
            ? InkWell(
                onTap: onProfileTap,
                child: Text(user?.nickname ?? "Пользователь", style: TextStyle(
              fontSize: AppSizes.search, 
              fontWeight:AppWeight.lightFontWeight, 
              color: AppColors.cardBackground,
              overflow: TextOverflow.ellipsis
            ),),
              )
            : const SizedBox(width: 48), 
        ],
      ),
    );
  }
}