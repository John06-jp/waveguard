import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated_waves.dart';
import '../../widgets/shared.dart';
import '../sos/sos_screen.dart';

enum AuthMode { login, register, reset }

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    this.mode = AuthMode.login,
    this.startupMessage,
    super.key,
  });
  final AuthMode mode;
  final String? startupMessage;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true, _busy = false;
  String? _error, _success;
  bool get _login => widget.mode == AuthMode.login;
  bool get _reset => widget.mode == AuthMode.reset;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });
    final auth = context.read<AuthService>();
    try {
      if (_reset) {
        await auth.resetPassword(_email.text.trim());
        if (mounted) {
          setState(
            () => _success =
                'If an account exists for this email, you will receive a password reset link.',
          );
        }
      } else if (_login) {
        await auth.login(_email.text.trim(), _password.text);
      } else {
        await auth.register(_email.text.trim(), _password.text);
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Unable to access your account. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final title = _login
        ? 'Welcome Back'
        : _reset
        ? 'Reset your password'
        : 'Create your account';
    return Scaffold(
      appBar: _login
          ? null
          : AppBar(title: Text(_reset ? 'Forgot password' : 'Create account')),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/onboarding/backgrounds/onboarding_bg4.png',
              fit: BoxFit.cover,
              excludeFromSemantics: true,
              errorBuilder: (_, _, _) =>
                  const ColoredBox(color: SeaColors.ocean),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x30005CA8), Color(0x80002550)],
                ),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 160,
            child: AnimatedWaves(),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                  child: AutofillGroup(
                    child: Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _LoginBrand(),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: const Color(0xF5F6FBFF),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: Colors.white),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x30001E42),
                                  blurRadius: 30,
                                  offset: Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge
                                      ?.copyWith(
                                        color: SeaColors.ink,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _login
                                      ? 'Log in to continue to WaveGuard'
                                      : _reset
                                      ? 'Enter your email to request a reset link.'
                                      : 'Stay connected to regional coastal information.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        color: const Color(0xFF4B6282),
                                      ),
                                ),
                                const SizedBox(height: 24),
                                if (widget.startupMessage != null)
                                  Notice(widget.startupMessage!, warning: true),
                                if (!auth.configured)
                                  const Notice(
                                    'Account access is not connected in this preview. You can explore as a guest.',
                                  ),
                                TextFormField(
                                  controller: _email,
                                  enabled: !_busy,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: _reset
                                      ? TextInputAction.done
                                      : TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  autocorrect: false,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(Icons.mail_outline),
                                  ),
                                  onFieldSubmitted: _reset
                                      ? (_) => _submit()
                                      : null,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Enter your email.';
                                    }
                                    if (!RegExp(
                                      r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                    ).hasMatch(value.trim())) {
                                      return 'Enter a valid email address.';
                                    }
                                    return null;
                                  },
                                ),
                                if (!_reset) ...[
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _password,
                                    enabled: !_busy,
                                    obscureText: _obscure,
                                    textInputAction: TextInputAction.done,
                                    autofillHints: [
                                      _login
                                          ? AutofillHints.password
                                          : AutofillHints.newPassword,
                                    ],
                                    onFieldSubmitted: (_) => _submit(),
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      prefixIcon: const Icon(
                                        Icons.lock_outline,
                                      ),
                                      suffixIcon: IconButton(
                                        tooltip: _obscure
                                            ? 'Show password'
                                            : 'Hide password',
                                        onPressed: () => setState(
                                          () => _obscure = !_obscure,
                                        ),
                                        icon: Icon(
                                          _obscure
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Enter your password.';
                                      }
                                      if (!_login && value.length < 8) {
                                        return 'Use at least 8 characters.';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                                if (_login)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _busy
                                          ? null
                                          : () => Navigator.push(
                                              context,
                                              MaterialPageRoute<void>(
                                                builder: (_) =>
                                                    const AuthScreen(
                                                      mode: AuthMode.reset,
                                                    ),
                                              ),
                                            ),
                                      child: const Text('Forgot password?'),
                                    ),
                                  ),
                                if (_error != null)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child: Semantics(
                                      liveRegion: true,
                                      child: Text(
                                        _error!,
                                        style: const TextStyle(
                                          color: SeaColors.danger,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (_success != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Semantics(
                                      liveRegion: true,
                                      child: Notice(_success!),
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                FilledButton(
                                  onPressed: _busy ? null : _submit,
                                  child: _busy
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                            semanticsLabel: 'Please wait',
                                          ),
                                        )
                                      : Text(
                                          _login
                                              ? 'Login'
                                              : _reset
                                              ? 'Send reset link'
                                              : 'Create account',
                                        ),
                                ),
                                if (_login) ...[
                                  const SizedBox(height: 12),
                                  OutlinedButton(
                                    onPressed: _busy
                                        ? null
                                        : () => Navigator.push(
                                            context,
                                            MaterialPageRoute<void>(
                                              builder: (_) => const AuthScreen(
                                                mode: AuthMode.register,
                                              ),
                                            ),
                                          ),
                                    child: const Text('Create account'),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: _busy
                                        ? null
                                        : context
                                              .read<SessionProvider>()
                                              .enterGuest,
                                    child: const Text('Continue as guest'),
                                  ),
                                  const Divider(height: 28),
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      foregroundColor: SeaColors.danger,
                                    ),
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const SosScreen(standalone: true),
                                      ),
                                    ),
                                    icon: const Icon(Icons.sos),
                                    label: const Text('Emergency assistance'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Know the Waves Before You Go',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 15),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xEDF6FBFF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Attribution(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginBrand extends StatelessWidget {
  const _LoginBrand();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Image.asset(
        'assets/onboarding/icons/wave_logo.png',
        width: 104,
        height: 104,
        excludeFromSemantics: true,
      ),
      const SizedBox(height: 10),
      const Text(
        'WaveGuard',
        style: TextStyle(
          color: Colors.white,
          fontSize: 36,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        'Marine Weather Information System',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontSize: 14),
      ),
      const SizedBox(height: 14),
      const Text(
        'Stay Informed, Stay Safe',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontSize: 17),
      ),
      const SizedBox(height: 10),
      Container(width: 40, height: 2, color: Colors.white54),
    ],
  );
}
