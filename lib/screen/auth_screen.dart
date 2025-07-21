import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback? onSuccess;
  const AuthScreen({Key? key, this.onSuccess}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool rememberMe = true;
  bool obscurePassword = true;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  String? errorText;

  // --- Регистрация ---
  final phoneController = TextEditingController();
  final lastNameController = TextEditingController();
  final firstNameController = TextEditingController();
  final birthDateController = TextEditingController();
  final regEmailController = TextEditingController();
  final regPasswordController = TextEditingController();
  final regPasswordRepeatController = TextEditingController();
  bool regObscurePassword = true;
  bool regObscurePasswordRepeat = true;
  String? regErrorText;
  bool regLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    lastNameController.dispose();
    firstNameController.dispose();
    birthDateController.dispose();
    regEmailController.dispose();
    regPasswordController.dispose();
    regPasswordRepeatController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      isLoading = true;
      errorText = null;
    });
    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      if (res.user != null) {
        widget.onSuccess?.call();
      } else {
        setState(() => errorText = 'Неверный email или пароль');
      }
    } on AuthException catch (e) {
      setState(() => errorText = e.message);
    } catch (e) {
      setState(() => errorText = 'Ошибка входа: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    setState(() {
      isLoading = true;
      errorText = null;
    });
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        emailController.text.trim(),
      );
      setState(() => errorText = 'Письмо для сброса пароля отправлено');
    } on AuthException catch (e) {
      setState(() => errorText = e.message);
    } catch (e) {
      setState(() => errorText = 'Ошибка: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF23232A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Вкладки
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => isLogin = true),
                      child: Column(
                        children: [
                          Text(
                            'Вход',
                            style: TextStyle(
                              color: isLogin ? Colors.white : Colors.white38,
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                            ),
                          ),
                          if (isLogin)
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              height: 3,
                              width: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFF5B5BFF),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    GestureDetector(
                      onTap: () => setState(() => isLogin = false),
                      child: Column(
                        children: [
                          Text(
                            'Регистрация',
                            style: TextStyle(
                              color: !isLogin ? Colors.white : Colors.white38,
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                            ),
                          ),
                          if (!isLogin)
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              height: 3,
                              width: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFF5B5BFF),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (isLogin) _buildLoginForm(),
                if (!isLogin) _buildRegisterForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 17,
              fontWeight: FontWeight.w400,
            ),
            children: [
              const TextSpan(text: 'Для входа используйте свой '),
              TextSpan(
                text: 'email или телефон и пароль сайта silverscreen.by.',
                style: const TextStyle(
                  color: Color(0xFF5B5BFF),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const TextSpan(
                text: '\nЕсли вы новый пользователь – зарегистрируйтесь',
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        TextField(
          controller: emailController,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: InputDecoration(
            hintText: 'Email или номер телефона',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 17),
            filled: true,
            fillColor: Colors.transparent,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.white24, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF5B5BFF), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 18,
            ),
          ),
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
        ),
        const SizedBox(height: 18),
        TextField(
          controller: passwordController,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          obscureText: obscurePassword,
          decoration: InputDecoration(
            hintText: 'Пароль',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 17),
            filled: true,
            fillColor: Colors.transparent,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.white24, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF5B5BFF), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 18,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.white38,
              ),
              onPressed:
                  () => setState(() => obscurePassword = !obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Checkbox(
              value: rememberMe,
              onChanged: (v) => setState(() => rememberMe = v ?? true),
              activeColor: const Color(0xFF5B5BFF),
              checkColor: Colors.white,
              side: const BorderSide(color: Colors.white38, width: 1.5),
            ),
            const Text(
              'Запомнить меня',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _resetPassword,
              child: const Text(
                'Забыли пароль?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        if (errorText != null) ...[
          const SizedBox(height: 10),
          Text(
            errorText!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 16),
          ),
        ],
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B5BFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child:
                isLoading
                    ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Войти',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 10),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 26,
                        ),
                      ],
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Регистрация',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
        const SizedBox(height: 28),
        TextField(
          controller: lastNameController,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: InputDecoration(
            hintText: 'Фамилия',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 17),
            filled: true,
            fillColor: Colors.transparent,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.white24, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF5B5BFF), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 18,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: firstNameController,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: InputDecoration(
            hintText: 'Имя',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 17),
            filled: true,
            fillColor: Colors.transparent,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.white24, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF5B5BFF), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 18,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: birthDateController,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: InputDecoration(
            hintText: 'Дата рождения',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 17),
            filled: true,
            fillColor: Colors.transparent,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.white24, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF5B5BFF), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 18,
            ),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
            String newText = '';
            for (int i = 0; i < digits.length && i < 8; i++) {
              newText += digits[i];
              if (i == 1 || i == 3) {
                newText += '/';
              }
            }
            if (newText != value) {
              birthDateController.value = TextEditingValue(
                text: newText,
                selection: TextSelection.collapsed(offset: newText.length),
              );
            }
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: phoneController,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            letterSpacing: 1.5,
          ),
          decoration: InputDecoration(
            hintText: 'Номер телефона',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 17),
            filled: true,
            fillColor: Colors.transparent,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.white24, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF5B5BFF), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 18,
            ),
          ),
          keyboardType: TextInputType.number,
          onTap: () {
            if (phoneController.text.isEmpty) {
              phoneController.text = '+___(__) ___ __ __';
              phoneController.selection = const TextSelection.collapsed(
                offset: 1,
              );
            }
          },
          onChanged: (value) {
            if (value.length < 1) {
              phoneController.text = '+___(__) ___ __ __';
              phoneController.selection = const TextSelection.collapsed(
                offset: 1,
              );
              return;
            }

            String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
            if (digits.length > 12) {
              digits = digits.substring(0, 12);
            }

            String mask = '+___(__) ___ __ __';
            String newText = mask;
            int digitIndex = 0;

            for (
              int i = 0;
              i < mask.length && digitIndex < digits.length;
              i++
            ) {
              if (mask[i] == '_') {
                newText = newText.replaceRange(i, i + 1, digits[digitIndex]);
                digitIndex++;
              }
            }

            if (newText != value) {
              phoneController.value = TextEditingValue(
                text: newText,
                selection: TextSelection.collapsed(
                  offset:
                      newText.indexOf('_') != -1
                          ? newText.indexOf('_')
                          : newText.length,
                ),
              );
            }
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: regEmailController,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: InputDecoration(
            hintText: 'Email',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 17),
            filled: true,
            fillColor: Colors.transparent,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.white24, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF5B5BFF), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 18,
            ),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: regPasswordController,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          obscureText: regObscurePassword,
          decoration: InputDecoration(
            hintText: 'Придумайте пароль',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 17),
            filled: true,
            fillColor: Colors.transparent,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.white24, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF5B5BFF), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 18,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                regObscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.white38,
              ),
              onPressed:
                  () =>
                      setState(() => regObscurePassword = !regObscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: regPasswordRepeatController,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          obscureText: regObscurePasswordRepeat,
          decoration: InputDecoration(
            hintText: 'Повторите пароль',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 17),
            filled: true,
            fillColor: Colors.transparent,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.white24, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF5B5BFF), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 18,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                regObscurePasswordRepeat
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Colors.white38,
              ),
              onPressed:
                  () => setState(
                    () => regObscurePasswordRepeat = !regObscurePasswordRepeat,
                  ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (regErrorText != null) ...[
          Text(
            regErrorText!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 16),
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: regLoading ? null : _onRegisterSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B5BFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child:
                regLoading
                    ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Зарегистрироваться',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 10),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 26,
                        ),
                      ],
                    ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Нажимая кнопку «Зарегистрироваться», Вы принимаете условия Соглашения об использовании персональных данных и подтверждаете, что ознакомились и согласны с Правилами программы лояльности кинопространств mooon и Silver Screen',
          style: const TextStyle(color: Colors.white38, fontSize: 13),
        ),
      ],
    );
  }

  void _onRegisterSubmit() async {
    setState(() {
      regLoading = true;
      regErrorText = null;
    });
    try {
      // Проверяем пароли
      if (regPasswordController.text != regPasswordRepeatController.text) {
        throw Exception('Пароли не совпадают');
      }

      // Регистрируем пользователя
      final res = await Supabase.instance.client.auth.signUp(
        email: regEmailController.text.trim(),
        password: regPasswordController.text,
      );

      if (res.user == null) throw Exception('Ошибка регистрации');

      // Обновляем профиль пользователя
      await Supabase.instance.client.from('profiles').upsert({
        'id': res.user!.id,
        'email': regEmailController.text.trim(),
        'phone': phoneController.text.trim(),
        'first_name': firstNameController.text.trim(),
        'last_name': lastNameController.text.trim(),
        'birth_date': birthDateController.text.trim(),
      });

      widget.onSuccess?.call();
    } catch (e) {
      setState(() {
        regErrorText = 'Ошибка регистрации: $e';
      });
    } finally {
      setState(() {
        regLoading = false;
      });
    }
  }
}
