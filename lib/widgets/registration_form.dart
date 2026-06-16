import 'package:flutter/material.dart';
import 'package:task_hub/services/auth_provider.dart';
import '../../theme/theme.dart';
import '../services/api_service.dart';

class RegistrationForm extends StatefulWidget {
  final ValueChanged<String> onSuccessAuth;
  final VoidCallback onSwitchToLogin;

  const RegistrationForm({
    super.key, 
    required this.onSuccessAuth,
    required this.onSwitchToLogin,
  });

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateForm(String name, String email, String password, String confirm) {
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      return 'Заполните все обязательные поля!';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Введите корректный Email адрес!';
    }
    if (password.length < 6) {
      return 'Пароль должен быть не менее 6 символов!';
    }
    if (password != confirm) {
      return 'Пароли не совпадают!';
    }
    return null;
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
            const Text("Регистрация", 
              style: TextStyle(fontSize: AppSizes.subHeader, color: AppColors.cardBackground, fontWeight: AppWeight.normalFontWeight)),
            const SizedBox(height: 12),
            const Text("Зарегистрируйтесь, чтобы начать работу с TaskHub!", 
              style: TextStyle(fontSize: AppSizes.search, fontWeight: AppWeight.lightFontWeight, color: AppColors.cardBackground), textAlign: TextAlign.center), 
            const SizedBox(height: 32),

            Wrap(
              spacing: 16, 
              runSpacing: 16, 
              alignment: WrapAlignment.center,
              children: [
                _buildField("Уникальный никнейм", controller: _nameController),
                _buildField("Почта", controller: _emailController),
                _buildField("Пароль", isPass: true, controller: _passwordController),
                _buildField("Повторите пароль", isPass: true, controller: _confirmPasswordController),
              ],
            ),

            const SizedBox(height: 25),
            
            _isLoading 
              ? const CircularProgressIndicator(color: AppColors.red)
              : Column(
                  children: [
                    TextButton(
                      onPressed: widget.onSwitchToLogin,
                      child: const Text(
                        "Уже есть аккаунт?", 
                        style: TextStyle(color: AppColors.gray, fontWeight: AppWeight.extraLightFontWeight, fontSize: AppSizes.caption),
                      ),
                    ),
                    const SizedBox(height: 1),
                    ElevatedButton(
                      onPressed: () async {
                        final name = _nameController.text.trim();
                        final email = _emailController.text.trim();
                        final password = _passwordController.text;
                        final confirm = _confirmPasswordController.text;

                        final error = _validateForm(name, email, password, confirm);
                        if (error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                          return;
                        }

                        setState(() => _isLoading = true);
                        try {
                          await _apiService.register(name, email, password);
                          final loginRes = await _apiService.login(email, password);
                          
                          if (loginRes['status'] == 'success') {
                            AuthProvider().authenticate(loginRes['user']);
                            final String realUserId = loginRes['user']['id'].toString();
                            widget.onSuccessAuth(realUserId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Регистрация прошла успешно!')),
                            );
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
                      child: const Text("Зарегистрироваться", style: TextStyle(fontSize: AppSizes.body, fontWeight: AppWeight.lightFontWeight)),
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