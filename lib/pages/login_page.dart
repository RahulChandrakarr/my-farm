import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/network_errors.dart';
import '../core/supabase_config.dart';
import '../services/profile_service.dart';
import '../theme/farm_theme.dart';
import 'admin_dashboard.dart';
import 'user_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!SupabaseConfig.isConfigured) {
      setState(() {
        _error =
            'Set SUPABASE_URL and SUPABASE_ANON_KEY (see lib/core/supabase_config.dart)';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      const maxAttempts = 3;
      Object? lastError;
      for (var attempt = 0; attempt < maxAttempts; attempt++) {
        if (attempt > 0) {
          await Future<void>.delayed(Duration(milliseconds: 800 * attempt));
        }
        try {
          await Supabase.instance.client.auth.signInWithPassword(
            email: _email.text.trim(),
            password: _password.text,
          );
          lastError = null;
          break;
        } catch (e) {
          lastError = e;
          if (e is AuthException) rethrow;
          if (!looksLikeNetworkError(e) || attempt == maxAttempts - 1) {
            rethrow;
          }
        }
      }
      if (lastError != null) throw lastError;

      if (!mounted) return;

      final type =
          await ProfileService(Supabase.instance.client).getUserType();
      if (!mounted) return;

      final dest = type == AppUserType.admin
          ? const AdminDashboard()
          : const UserDashboard();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => dest),
      );
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = friendlyNetworkMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: FarmColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    Icon(
                      Icons.eco_rounded,
                      size: 56,
                      color: FarmColors.green,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'My Farm',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to manage your farm',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: FarmColors.black,
                      ),
                    ),
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      style: const TextStyle(color: FarmColors.black),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(
                          Icons.mail_outline_rounded,
                          color: FarmColors.green,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      style: const TextStyle(color: FarmColors.black),
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(
                          Icons.lock_outline_rounded,
                          color: FarmColors.green,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter password';
                        return null;
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFB71C1C),
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: FarmColors.background,
                              ),
                            )
                          : const Text('Sign in'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Green fields, healthy livestock — welcome back.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                        color: FarmColors.blackMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
