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
        ? 'Know the coast.\nPlan with care.'
        : _reset
        ? 'Reset your password'
        : 'Create your account';
    return Scaffold(
      appBar: _login
          ? null
          : AppBar(title: Text(_reset ? 'Forgot password' : 'Create account')),
      body: Stack(
        children: [
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
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: AutofillGroup(
                    child: Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Brand(),
                          ),
                          const SizedBox(height: 36),
                          Text(
                            title,
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _login
                                ? 'Regional coastal advisories for Lianga, Surigao del Sur.'
                                : _reset
                                ? 'Enter your email to request a reset link.'
                                : 'Stay connected to regional coastal information.',
                            style: Theme.of(context).textTheme.bodyLarge,
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
                            onFieldSubmitted: _reset ? (_) => _submit() : null,
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
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  tooltip: _obscure
                                      ? 'Show password'
                                      : 'Hide password',
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
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
                                          builder: (_) => const AuthScreen(
                                            mode: AuthMode.reset,
                                          ),
                                        ),
                                      ),
                                child: const Text('Forgot password?'),
                              ),
                            ),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
                                  : context.read<SessionProvider>().enterGuest,
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
                          const Attribution(),
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
