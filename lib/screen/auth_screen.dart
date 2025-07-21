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
  int registerStep = 0; // 0: телефон, 1: код, 2: форма
  final phoneController = TextEditingController();
  String phoneDigits = '';
  final TextEditingController phoneInputController = TextEditingController();
  final FocusNode phoneFocusNode = FocusNode();
  bool phoneMaskInserted = false;
  final smsCodeController = TextEditingController();
  final lastNameController = TextEditingController();
  final firstNameController = TextEditingController();
  final birthDateController = TextEditingController();
  final regEmailController = TextEditingController();
  final regPasswordController = TextEditingController();
  final regPasswordRepeatController = TextEditingController();
  bool regObscurePassword = true;
  bool regObscurePasswordRepeat = true;
  String? regErrorText;
  bool regPhoneError = false;
  bool regLoading = false;
  String? phoneSessionId;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    phoneInputController.dispose();
    phoneFocusNode.dispose();
    smsCodeController.dispose();
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

  Future<void> _register() async {
    setState(() {
      isLoading = true;
      errorText = null;
    });
    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      if (res.user != null) {
        // После регистрации сразу логиним
        await _login();
      } else {
        setState(() => errorText = 'Ошибка регистрации');
      }
    } on AuthException catch (e) {
      setState(() => errorText = e.message);
    } catch (e) {
      setState(() => errorText = 'Ошибка регистрации: $e');
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
                if (!isLogin) _buildRegisterSteps(),
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
            onPressed:
                isLoading
                    ? null
                    : () {
                      _login();
                    },
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
                      children: [
                        Text(
                          'Войти',
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
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

  Widget _buildRegisterSteps() {
    if (registerStep == 0) {
      // Маска появляется сразу при фокусе, ввод возможен сразу
      phoneFocusNode.addListener(() {
        if (phoneFocusNode.hasFocus && !phoneMaskInserted) {
          setState(() {
            phoneInputController.text = '+___(__) ___ __ __';
            phoneDigits = '';
            phoneMaskInserted = true;
            phoneInputController.selection = const TextSelection.collapsed(
              offset: 1,
            );
          });
        }
      });
      // Шаг 1: Ввод телефона
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
          _CustomPhoneField(
            digits: phoneDigits,
            error: regPhoneError,
            focusNode: phoneFocusNode,
            showMask: phoneFocusNode.hasFocus,
            controller: phoneInputController,
            onChanged: (digits) {
              setState(() {
                phoneDigits = digits;
                // Формируем маску с цифрами
                String masked = buildPhoneMaskWithDigits(digits);
                phoneInputController.text = masked;
                // Курсор после последней цифры
                int cursorPos = masked.indexOf('_');
                if (cursorPos == -1) cursorPos = masked.length;
                phoneInputController.selection = TextSelection.collapsed(
                  offset: cursorPos,
                );
              });
            },
          ),
          if (regPhoneError) ...[
            const SizedBox(height: 10),
            Text(
              'Введите номер телефона в формате +375(XX) XXX XX XX',
              style: const TextStyle(color: Colors.redAccent, fontSize: 16),
            ),
          ] else if (regErrorText != null) ...[
            const SizedBox(height: 10),
            Text(
              regErrorText!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 16),
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed:
                  regLoading
                      ? null
                      : () {
                        final phone = phoneDigits;
                        // Проверяем, что введено 12 цифр (375XXYYYYYYY)
                        if (phone.length != 12 || !phone.startsWith('375')) {
                          setState(() {
                            regPhoneError = true;
                            regErrorText =
                                'Введите номер в формате 375(XX) XXX XX XX';
                          });
                          return;
                        }
                        // Проверяем код в скобках
                        final code = phone.substring(3, 5);
                        if (!(code == '29' ||
                            code == '33' ||
                            code == '44' ||
                            code == '25')) {
                          setState(() {
                            regPhoneError = true;
                            regErrorText =
                                'Код оператора должен быть 29, 33, 44 или 25';
                          });
                          return;
                        }
                        // Проверяем, что после кода 7 цифр
                        final rest = phone.substring(5);
                        if (rest.length != 7 ||
                            !RegExp(r'^\d{7}$').hasMatch(rest)) {
                          setState(() {
                            regPhoneError = true;
                            regErrorText =
                                'После кода оператора должно быть 7 цифр';
                          });
                          return;
                        }
                        setState(() {
                          regPhoneError = false;
                          regErrorText = null;
                        });
                        _onSendSmsCode();
                      },
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
                            'Получить код по SMS',
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
    } else if (registerStep == 1) {
      // Шаг 2: Ввод кода из SMS
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
            controller: smsCodeController,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: InputDecoration(
              hintText: 'Введите код из SMS',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 17),
              filled: true,
              fillColor: Colors.transparent,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.white24, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF5B5BFF),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 18,
              ),
            ),
            keyboardType: TextInputType.number,
          ),
          if (regErrorText != null) ...[
            const SizedBox(height: 10),
            Text(
              regErrorText!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 16),
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: regLoading ? null : _onVerifySmsCode,
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
                            'Далее',
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
            'Отправить код повторно или изменить номер телефона можно будет через 89 сек',
            style: const TextStyle(color: Colors.white38, fontSize: 15),
          ),
        ],
      );
    } else {
      // Шаг 3: Форма регистрации
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
                borderSide: const BorderSide(
                  color: Color(0xFF5B5BFF),
                  width: 2,
                ),
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
                borderSide: const BorderSide(
                  color: Color(0xFF5B5BFF),
                  width: 2,
                ),
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
                borderSide: const BorderSide(
                  color: Color(0xFF5B5BFF),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 18,
                horizontal: 18,
              ),
            ),
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
                borderSide: const BorderSide(
                  color: Color(0xFF5B5BFF),
                  width: 2,
                ),
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
                borderSide: const BorderSide(
                  color: Color(0xFF5B5BFF),
                  width: 2,
                ),
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
                    () => setState(
                      () => regObscurePassword = !regObscurePassword,
                    ),
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
                borderSide: const BorderSide(
                  color: Color(0xFF5B5BFF),
                  width: 2,
                ),
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
                      () =>
                          regObscurePasswordRepeat = !regObscurePasswordRepeat,
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
  }

  // --- Методы для регистрации ---
  void _onSendSmsCode() async {
    setState(() {
      regLoading = true;
      regErrorText = null;
    });
    try {
      final supabasePhone = '+$phoneDigits';
      final res = await SupabaseService.signUpWithPhone(
        phone: supabasePhone,
        password: regPasswordController.text,
      );
      if (res.user != null) {
        // SMS отправлено, переходим к шагу 2
        setState(() {
          registerStep = 1;
        });
      } else {
        setState(() {
          regErrorText = 'Ошибка отправки кода';
        });
      }
    } on AuthException catch (e) {
      setState(() {
        regErrorText = e.message;
      });
    } catch (e) {
      setState(() {
        regErrorText = 'Ошибка отправки кода: $e';
      });
    } finally {
      setState(() {
        regLoading = false;
      });
    }
  }

  void _onVerifySmsCode() async {
    setState(() {
      regLoading = true;
      regErrorText = null;
    });
    try {
      await SupabaseService.verifyPhoneOtp(
        phone: phoneController.text.trim(),
        token: smsCodeController.text.trim(),
        type: 'sms',
      );
      setState(() {
        registerStep = 2;
      });
    } on AuthException catch (e) {
      setState(() {
        regErrorText = e.message;
      });
    } catch (e) {
      setState(() {
        regErrorText = 'Неверный код';
      });
    } finally {
      setState(() {
        regLoading = false;
      });
    }
  }

  void _onRegisterSubmit() async {
    setState(() {
      regLoading = true;
      regErrorText = null;
    });
    try {
      // Обновляем профиль пользователя (email, имя, фамилия и т.д.)
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Пользователь не найден');
      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'email': regEmailController.text.trim(),
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

// Формирует маску с цифрами для поля телефона
String buildPhoneMaskWithDigits(String input) {
  String mask = '+___(__) ___ __ __';
  int inputIndex = 0;
  StringBuffer result = StringBuffer();
  for (int i = 0; i < mask.length; i++) {
    if (mask[i] == '_') {
      if (inputIndex < input.length) {
        result.write(input[inputIndex]);
        inputIndex++;
      } else {
        result.write('_');
      }
    } else {
      result.write(mask[i]);
    }
  }
  return result.toString();
}

class _CustomPhoneField extends StatelessWidget {
  final String digits;
  final bool error;
  final FocusNode? focusNode;
  final bool showMask;
  final TextEditingController? controller;
  final ValueChanged<String> onChanged;
  const _CustomPhoneField({
    required this.digits,
    required this.error,
    this.focusNode,
    required this.showMask,
    this.controller,
    required this.onChanged,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      focusNode: focusNode,
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        letterSpacing: 1.5,
      ),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        hintText: 'Номер телефона',
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 17),
        filled: true,
        fillColor: Colors.transparent,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: error ? Colors.redAccent : Colors.white24,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: error ? Colors.redAccent : Color(0xFF5B5BFF),
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 18,
        ),
      ),
      onChanged: (value) {
        // Оставляем только цифры, которые заменяют подчёркивания
        String mask = '+___(__) ___ __ __';
        String digits = '';
        int maskIndex = 0;
        for (int i = 0; i < value.length && maskIndex < mask.length; i++) {
          if (mask[maskIndex] == '_') {
            if (RegExp(r'\d').hasMatch(value[i])) {
              digits += value[i];
              maskIndex++;
            }
          } else {
            if (value[i] == mask[maskIndex]) {
              maskIndex++;
            }
          }
        }
        onChanged(digits);
      },
    );
  }
}
