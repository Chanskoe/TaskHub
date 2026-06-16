import 'package:flutter/material.dart';
import 'package:task_hub/services/auth_provider.dart';
import '../../theme/theme.dart';
import '../services/api_service.dart';

class LoginForm extends StatefulWidget {
  final Function(String uuid) onSuccessAuth;
  final VoidCallback onSwitchToRegister;

  const LoginForm({
    super.key,
    required this.onSuccessAuth,
    required this.onSwitchToRegister,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.darkBlue,
        borderRadius: BorderRadius.circular(24),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900), 
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Войдите", 
              style: TextStyle(fontSize: AppSizes.subHeader, color: AppColors.cardBackground, fontWeight: AppWeight.normalFontWeight)),
            const SizedBox(height: 12),
            const Text("Войдите, чтобы продолжить работу с TaskHub!", 
              style: TextStyle(fontSize: AppSizes.search, fontWeight: AppWeight.lightFontWeight, color: AppColors.cardBackground), textAlign: TextAlign.center),
            const SizedBox(height: 32),

            Wrap(
              spacing: 16, 
              runSpacing: 16, 
              alignment: WrapAlignment.center,
              children: [
                _buildField("Почта", controller: _emailController),
                _buildField("Пароль", isPass: true, controller: _passwordController),
              ],
            ),

            const SizedBox(height: 25),
            
            _isLoading 
              ? const CircularProgressIndicator(color: AppColors.red)
              : Column(
                  children: [
                    TextButton(
                      onPressed: widget.onSwitchToRegister,
                      child: const Text(
                        "Еще нет аккаунта? Зарегистрироваться", 
                        style: TextStyle(color: AppColors.gray, fontWeight: AppWeight.extraLightFontWeight, fontSize: AppSizes.caption),
                      ),
                    ),
                    const SizedBox(height: 1),
                    ElevatedButton(
                      onPressed: () async {
                        final String email = _emailController.text.trim();
                        final String password = _passwordController.text;

                        if (email.isEmpty || password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Заполните все поля!')),
                          );
                          return;
                        }

                        setState(() => _isLoading = true);
                        try {
                          final response = await _apiService.login(email, password);
                          if (response['status'] == 'success') {
                            AuthProvider().authenticate(response['user']);
                            final String uuid = response['user']['id']?.toString() ?? '';
                            widget.onSuccessAuth(uuid);
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                          );
                        } finally {
                          setState(() => _isLoading = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(200, 50),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text("Войти", style: TextStyle(fontSize: AppSizes.body, fontWeight: AppWeight.lightFontWeight)),
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String hint, {bool isPass = false, required TextEditingController controller}) {
    return SizedBox(
      width: 424,
      height: 50, 
      child: TextField(
        controller: controller,
        obscureText: isPass,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.darkGray, fontWeight: AppWeight.extraLightFontWeight),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}