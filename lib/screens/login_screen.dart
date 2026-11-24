import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/auth_api.dart';
import '../data/result.dart';
import '../models/library_model.dart';
import '../models/sessions_model.dart';
import '../models/user_model.dart';

import '../theme/app_theme.dart';
import '../widgets/duo_button.dart';

/// Экран 1. Вход / регистрация.
/// L5: форма связана с backend-ом (AuthApi), token — в shared_preferences.
/// L3: локальная валидация (Form + validator) и context.go после входа —
/// login уходит из стека, «назад» в него не ведёт.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController(); // L5: register требует name
  bool _isRegister = false; // режим формы: вход / регистрация
  bool _busy = false; // запрос «летит» — кнопка гаснет (двойной submit)
  bool _showPassword = false; // эфемерное состояние экрана → setState

  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _emailCtrl.dispose(); // кто создаёт, тот освобождает
    _nameCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Введите e-mail';
    if (!v.contains('@') || !_emailRe.hasMatch(v)) return 'Неверный формат e-mail';
    return null; // null = ВАЛИДНО
  }

  String? _validatePassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Введите пароль';
    if (v.length < 6) return 'Пароль — минимум 6 символов';
    return null;
  }

  /// Валидный submit бьёт по серверу; вердикт → навигация или SnackBar.
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return; // валидация L3, нетронута
    final auth = context.read<AuthApi>();
    setState(() => _busy = true);
    final result = _isRegister
        ? await auth.register(_emailCtrl.text.trim(), _passCtrl.text, _nameCtrl.text.trim())
        : await auth.login(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return; // экран может умереть, пока запрос летит
    setState(() => _busy = false);
    switch (result) {
      case Ok():
        // token сохранён — данные нового пользователя загружаются заново
        context.read<LibraryModel>().load();
        context.read<SessionsModel>().load();
        context.read<UserModel>().load();
        context.go('/decks'); // go, НЕ push: login уходит из стека
      case Err(:final msg):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final duo = context.duo;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              children: [
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(28),
                      border: Border(bottom: BorderSide(color: duo.greenShadow, width: 6)),
                    ),
                    child: Icon(Icons.style_rounded, size: 56, color: scheme.onPrimary),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'StudyCards',
                  textAlign: TextAlign.center,
                  style: text.headlineMedium?.copyWith(color: scheme.primary),
                ),
                const SizedBox(height: 6),
                Text(
                  'Запоминай термины и формулы по 5 минут в день',
                  textAlign: TextAlign.center,
                  style: text.bodyLarge?.copyWith(color: duo.muted),
                ),
                const SizedBox(height: 32),
                if (_isRegister) ...[
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: 'Имя',
                      prefixIcon: Icon(Icons.person_rounded),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Введите имя' : null,
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    hintText: 'E-mail',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: !_showPassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: 'Пароль',
                    prefixIcon: const Icon(Icons.lock_rounded),
                    suffixIcon: IconButton(
                      tooltip: _showPassword ? 'Скрыть пароль' : 'Показать пароль',
                      icon: Icon(
                        _showPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      ),
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 24),
                DuoButton(
                  label: _busy ? 'Подождите…' : (_isRegister ? 'Создать аккаунт' : 'Войти'),
                  onPressed: _busy ? null : _submit,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _busy ? null : () => setState(() => _isRegister = !_isRegister),
                  child: Text(
                    _isRegister ? 'Уже есть аккаунт? Войдите' : 'Нет аккаунта? Зарегистрируйтесь',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
