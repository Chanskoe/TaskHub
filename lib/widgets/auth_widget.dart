import 'package:flutter/material.dart';
import 'app_text_field.dart';

class AuthWidget extends StatefulWidget {
  final bool isLoginMode;
  const AuthWidget({super.key, required this.isLoginMode});

  @override
  State<AuthWidget> createState() => _AuthWidgetState();
}

class _AuthWidgetState extends State<AuthWidget> {
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        children: [
          ...List.generate(widget.isLoginMode ? 2 : 4, (index) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppTextField(hint: widget.isLoginMode ? "Email/Пароль" : "Поле ввода"),
          )),
          ElevatedButton(onPressed: () {}, child: Text(widget.isLoginMode ? "Войти" : "Зарегистрироваться")),
        ],
      ),
    );
  }
}