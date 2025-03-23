import 'package:flutter/material.dart';
import 'package:open2fa/crypto.dart';
import 'package:open2fa/i18n.dart';
import 'package:open2fa/pages/vault.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _showPassword = false;
  bool _biometricsEnabled = false;
  bool _unlocking = false;
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    () async {
      try {
        _biometricsEnabled = await Crypto.areBiometricsEnabled();
        setState(() {});
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 78),
              Text(
                t('auth.unlock'),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(t('auth.password_desc'), style: TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      enabled: !_unlocking,
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: t('auth.enter_password'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.visibility),
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: !_showPassword,
                    ),
                    if (_biometricsEnabled) ...[
                      const SizedBox(height: 16),
                      TextButton(
                        style: ButtonStyle(
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        onPressed:
                            _unlocking
                                ? null
                                : () async {
                                  _unlocking = true;
                                  setState(() {});
                                  try {
                                    await Crypto.unlockVaultWithBiometrics();
                                    if (mounted) {
                                      // ignore: use_build_context_synchronously
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                          builder: (context) => VaultPage(),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    _unlocking = false;
                                    setState(() {});
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        // ignore: use_build_context_synchronously
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text(e.toString())),
                                      );
                                    }
                                  }
                                },
                        child: Text(t('auth.use_biometrics')),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            _unlocking
                ? null
                : () async {
                  _unlocking = true;
                  setState(() {});
                  try {
                    await Crypto.unlockVaultWithPassword(
                      _passwordController.text,
                    );
                    if (mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => VaultPage()),
                      );
                    }
                  } catch (e) {
                    _unlocking = false;
                    setState(() {});
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  }
                },
        tooltip: t('auth.unlock'),
        child: Icon(Icons.lock_open_outlined),
      ),
    );
  }
}
