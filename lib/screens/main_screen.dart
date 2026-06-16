import 'package:flutter/material.dart';
import 'package:task_hub/screens/task_screen.dart';
import '../../theme/theme.dart';
import '../widgets/registration_form.dart';
import '../widgets/login_form.dart';
import '../widgets/app_header.dart';
import '../widgets/app_footer.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _isLoggedIn = false; 
  bool _showLogin = false; 
  String? _userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            isLoggedIn: _isLoggedIn,
            onLoginTap: () {
              setState(() {
                _showLogin = true;
              });
            },
            onProfileTap: () {
              setState(() { _isLoggedIn = false; _userId = null; });
            },
          ),
          
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const Text("Трекер задач", style: TextStyle(fontSize: AppSizes.title, color: AppColors.darkBlue, fontWeight: AppWeight.normalFontWeight)),
                    const SizedBox(height: 30),
                    FractionallySizedBox(
                      widthFactor: 0.6,
                      child: Text(
                        "Онлайн-платформа для отслеживания задач с возможностью их личного или совместного управления, добавления комментариев, оценки важности и сложности задач, назначения ответственных, группировки задач в проекты",
                        style: TextStyle(fontSize: AppSizes.body, fontWeight: AppWeight.lightFontWeight, color: AppColors.darkBlue),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    _isLoggedIn 
                      ? ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => TaskScreen(userId: _userId ?? '')),
                          );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.red,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(200, 50),
                            shape: const StadiumBorder(),
                          ),
                          child: const Text("Мои задачи", style: TextStyle(fontSize: AppSizes.body, fontWeight: AppWeight.lightFontWeight)),
                        )
                      : _showLogin 
                          ? LoginForm(
                              onSuccessAuth: (uuid) => setState(() { _isLoggedIn = true; _userId = uuid; }),
                              onSwitchToRegister: () => setState(() => _showLogin = false),
                            )
                          : RegistrationForm(
                              onSuccessAuth: (uuid) => setState(() { _isLoggedIn = true; _userId = uuid; }),
                              onSwitchToLogin: () => setState(() => _showLogin = true),
                            ),
                    AppFooter()
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}