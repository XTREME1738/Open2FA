import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:open2fa/crypto.dart';
import 'package:open2fa/i18n.dart';
import 'package:open2fa/main.dart';
import 'package:open2fa/pages/vault.dart';
import 'package:open2fa/prefs.dart';

class SetupAuthPasswordPage extends ConsumerStatefulWidget {
  const SetupAuthPasswordPage({super.key});

  @override
  ConsumerState<SetupAuthPasswordPage> createState() =>
      _SetupAuthPasswordPageState();
}

class _SetupAuthPasswordPageState extends ConsumerState<SetupAuthPasswordPage> {
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _bioAuthEnabled = false;
  bool _isFinishing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                t('setup.auth_password'),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                t('setup.auth_password_desc'),
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      enabled: !_isFinishing,
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: t('setup.auth_enter_password'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return t('error.password_required');
                        }
                        if (value.length < 8) {
                          return t('error.password_min');
                        }
                        if (value.length > 128) {
                          return t('error.password_max');
                        }
                        if (!RegExp(
                          r'[!@#$%^&*(),.?":{}|<>]',
                        ).hasMatch(value)) {
                          return t('error.password_requires_special');
                        }
                        if (!RegExp(r'[0-9]').hasMatch(value)) {
                          return t('error.password_requires_number');
                        }
                        if (!RegExp(r'[A-Z]').hasMatch(value)) {
                          return t('error.password_requires_uppercase');
                        }
                        if (!RegExp(r'[a-z]').hasMatch(value)) {
                          return t('error.password_requires_lowercase');
                        }
                        return null;
                      },
                      obscureText: !_showPassword,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      enabled: !_isFinishing,
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: t('setup.auth_enter_password_confirm'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _showConfirmPassword = !_showConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return t('error.password_required');
                        }
                        if (value != _passwordController.text) {
                          return t('error.password_no_match');
                        }
                        return null;
                      },
                      obscureText: !_showConfirmPassword,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text(t('settings.auth_use_biometrics')),
                subtitle: Text(t('settings.auth_use_biometrics_desc')),
                value: _bioAuthEnabled,
                onChanged: _isFinishing ? null : (value) async {
                  if (!value) {
                    setState(() {
                      _bioAuthEnabled = false;
                    });
                    return;
                  }
                  try {
                    await Crypto.checkBiometricsAvailable();
                    final localAuth = LocalAuthentication();
                    final authenticated = await localAuth.authenticate(
                      localizedReason: t('settings.auth_enable_biometrics'),
                      options: AuthenticationOptions(
                        sensitiveTransaction: true,
                        stickyAuth: true,
                        biometricOnly: true,
                      ),
                    );
                    setState(() {
                      _bioAuthEnabled = authenticated;
                    });
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(
                        // ignore: use_build_context_synchronously
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  }
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.bottomLeft,
              child: FloatingActionButton(
                onPressed: _isFinishing ? null : () {
                  Navigator.of(context).pop();
                },
                heroTag: null,
                child: Icon(Icons.arrow_back),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton(
                onPressed: _isFinishing ? null : () async {
                  if (_formKey.currentState!.validate()) {
                    _isFinishing = true;
                    setState(() {});
                    await Crypto.setupPasswordAuth(_passwordController.text);
                    await Crypto.setBiometricsEnabled(_bioAuthEnabled);
                    await Prefs.setSetupComplete(true);
                    await Crypto.unlockVaultWithPassword(_passwordController.text);
                    ref.read(usingAuthProvider.notifier).state = true;
                    ref.read(vaultLockedProvider.notifier).state = false;
                    if (mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) {
                            return VaultPage();
                          },
                        ),
                      );
                    }
                  }
                },
                heroTag: null,
                child: Icon(Icons.arrow_forward),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
