import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open2fa/i18n.dart';
import 'package:open2fa/main.dart';
import 'package:open2fa/structures/export.dart';

class SettingsEncryptedExportPage extends ConsumerStatefulWidget {
  final bool encryptedExport;
  const SettingsEncryptedExportPage({
    super.key,
    this.encryptedExport = false
  });

  @override
  ConsumerState<SettingsEncryptedExportPage> createState() =>
      _SettingsEncryptedExportPageState();
}

class _SettingsEncryptedExportPageState
    extends ConsumerState<SettingsEncryptedExportPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.encryptedExport ? t('settings.export_encrypted') : t('settings.import_encrypted'))),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text(
                      widget.encryptedExport ? t('settings.export_password_desc') : t('settings.import_password_desc'),
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        labelText: t('settings.export_password'),
                        suffixIcon: IconButton(
                          icon:
                              _showPassword
                                  ? Icon(Icons.visibility)
                                  : Icon(Icons.visibility_off),
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
                        if (widget.encryptedExport) {
                          if (value.length < 8) {
                            return t('error.password_min');
                          }
                          if (value.length > 128) {
                            return t('error.password_max');
                          }
                          if (!value.contains(RegExp(r'[A-Z]'))) {
                            return t('error.password_requires_upper');
                          }
                          if (!value.contains(RegExp(r'[a-z]'))) {
                            return t('error.password_requires_lower');
                          }
                          if (!value.contains(RegExp(r'[0-9]'))) {
                            return t('error.password_requires_number');
                          }
                          if (!value.contains(
                            RegExp(r'[!@#$%^&*()_+{}|:<>?]'),
                          )) {
                            return t('error.password_requires_special');
                          }
                          if (value != _confirmPasswordController.text) {
                            return t('error.password_no_match');
                          }
                        }
                        return null;
                      },
                      obscureText: !_showPassword,
                    ),
                    if (widget.encryptedExport) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          labelText: t('settings.export_password_confirm'),
                          suffixIcon: IconButton(
                            icon:
                                _showConfirmPassword
                                    ? Icon(Icons.visibility)
                                    : Icon(Icons.visibility_off),
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
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextButton(
                      style: ButtonStyle(
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) {
                          return;
                        }
                        if (widget.encryptedExport) {
                          try {
                            final export = await EncryptedExport.generate(
                              _passwordController.text,
                            );
                            String?
                            outputFile = await FilePicker.platform.saveFile(
                              allowedExtensions: ['json'],
                              type: FileType.custom,
                              fileName:
                                  '${t('app_title')}_${DateTime.now().toIso8601String()}.json',
                              initialDirectory: '/storage/emulated/0',
                              bytes: export.toJsonBytes(),
                            );
                            if (mounted && outputFile != null) {
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(t('settings.export_success')),
                                ),
                              );
                              // ignore: use_build_context_synchronously
                              Navigator.of(context).pop();
                            }
                          } catch (e) {
                            logger.e(t('error.export_fail'), error: e);
                            if (mounted) {
                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(t('error.export_fail'))),
                              );
                            }
                          }
                        } else {
                          if (mounted) {
                            Navigator.of(context).pop(_passwordController.text);
                          }
                        }
                      },
                      child: Text(widget.encryptedExport ? t('settings.export_encrypted_finish') : t('settings.import_encrypted_start')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
