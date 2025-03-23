import 'package:base32/base32.dart';
import 'package:flutter/material.dart';
import 'package:open2fa/database.dart';
import 'package:open2fa/i18n.dart';
import 'package:open2fa/structures/account.dart';
import 'package:otp/otp.dart';

class EditAccountPage extends StatefulWidget {
  final Account? account;

  const EditAccountPage({super.key, this.account});

  @override
  State<EditAccountPage> createState() => _EditAccountPageState();
}

class _EditAccountPageState extends State<EditAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _issuerController = TextEditingController();
  final _secretController = TextEditingController();
  final _intervalController = TextEditingController();
  final _counterController = TextEditingController();
  final _digitsController = TextEditingController();
  Algorithm _algorithm = Algorithm.SHA1;
  final List<String> _categories = const [];
  bool _isGoogle = true;
  bool _isTOTP = true;

  @override
  void dispose() {
    _nameController.dispose();
    _issuerController.dispose();
    _secretController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _nameController.text = widget.account!.label;
      _issuerController.text = widget.account!.issuer;
      _secretController.text = widget.account!.secret;
      _intervalController.text = widget.account!.interval.toString();
      _counterController.text = widget.account!.counter.toString();
      _digitsController.text = widget.account!.digits.toString();
      _algorithm = widget.account!.algorithm;
      _isGoogle = widget.account!.isGoogle;
      _isTOTP = widget.account!.isTOTP;
    } else {
      _intervalController.text = '30';
      _counterController.text = '0';
      _digitsController.text = '6';
    }
  }

  bool _showSecret = false;

  void _toggleSecretVisibility() {
    setState(() {
      _showSecret = !_showSecret;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.account != null ? t('edit_account') : t('add_account'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: t('account.label'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return t('error.label_required');
                  }
                  if (value.length > 32) {
                    return t('error.label_max');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _issuerController,
                decoration: InputDecoration(
                  labelText: t('account.issuer'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return t('error.issuer_required');
                  }
                  if (value.length > 32) {
                    return t('error.issuer_max');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _digitsController,
                decoration: InputDecoration(
                  labelText: t('account.digits'),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  if (int.tryParse(value) == null && value.isNotEmpty) {
                    _digitsController.text = _digitsController.text.substring(
                      0,
                      _digitsController.text.length - 1,
                    );
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return t('error.digits_required');
                  }
                  if (int.tryParse(value) == null) {
                    return t('error.digits_invalid');
                  }
                  if (int.parse(value) < 3) {
                    return t('error.digits_min');
                  }
                  if (int.parse(value) > 8) {
                    return t('error.digits_max');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _secretController,
                decoration: InputDecoration(
                  labelText: t('account.secret'),
                  border: const OutlineInputBorder(),
                  suffixIcon: GestureDetector(
                    onTap: () {
                      _toggleSecretVisibility();
                    },
                    child: Icon(
                      _showSecret ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                ),
                obscureText: !_showSecret,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return t('error.secret_required');
                  }
                  if (value.length > 128) {
                    return t('error.secret_max');
                  }
                  try {
                    base32.decodeAsString(value);
                  } catch (e) {
                    return t('error.secret_invalid');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField(
                decoration: InputDecoration(
                  labelText: t('account.algorithm'),
                  border: const OutlineInputBorder(),
                ),
                value: _algorithm,
                items:
                    Algorithm.values
                        .map(
                          (algorithm) => DropdownMenuItem(
                            value: algorithm,
                            child: Text(algorithm.toString().split('.').last),
                          ),
                        )
                        .toList(),
                onChanged: (Algorithm? value) {
                  setState(() {
                    _algorithm = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField(
                decoration: InputDecoration(
                  labelText: t('account.categories'),
                  border: const OutlineInputBorder(),
                ),
                value: _categories.isNotEmpty ? _categories.first : null,
                items:
                    _categories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                        )
                        .toList(),
                onChanged: (String? value) {
                  setState(() {
                    _categories.clear();
                    _categories.add(value!);
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _isTOTP ? _intervalController : _counterController,
                decoration: InputDecoration(
                  labelText:
                      _isTOTP ? t('account.interval') : t('account.counter'),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  final controller =
                      _isTOTP ? _intervalController : _counterController;
                  if (int.tryParse(value) == null && value.isNotEmpty) {
                    controller.text = controller.text.substring(
                      0,
                      controller.text.length - 1,
                    );
                  }
                },
                validator: (value) {
                  if (_isTOTP) {
                    if (value == null || value.isEmpty) {
                      return t('error.interval_required');
                    }
                    if (int.tryParse(value) == null) {
                      return t('error.interval_invalid');
                    }
                    if (int.parse(value) < 1) {
                      return t('error.interval_min');
                    }
                    if (value.length > 3) {
                      return t('error.interval_max');
                    }
                  } else {
                    if (value == null || value.isEmpty) {
                      return t('error.counter_required');
                    }
                    if (int.tryParse(value) == null) {
                      return t('error.counter_invalid');
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                title: Text(t('edit_account.use_google')),
                subtitle: Text(t('edit_account.use_google_desc')),
                value: _isGoogle,
                onChanged: (value) {
                  setState(() {
                    _isGoogle = value;
                  });
                },
              ),
              SwitchListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                title:
                    _isTOTP
                        ? Text(t('edit_account.totp'))
                        : Text(t('edit_account.hotp')),
                subtitle:
                    _isTOTP
                        ? Text(t('edit_account.totp_desc'))
                        : Text(t('edit_account.hotp_desc')),
                value: _isTOTP,
                onChanged: (value) {
                  setState(() {
                    _isTOTP = value;
                  });
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        disabledElevation: 0,
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            final account = Account(
              id: widget.account?.id,
              label: _nameController.text,
              issuer: _issuerController.text,
              secret: _secretController.text,
              algorithm: _algorithm,
              digits: int.parse(_digitsController.text),
              counter: int.parse(_counterController.text),
              interval: int.parse(_intervalController.text),
              isTOTP: _isTOTP,
              isGoogle: _isGoogle,
              categories: _categories,
              updatedAt: DateTime.now(),
              createdAt: widget.account?.createdAt ?? DateTime.now(),
            );
            account
                .encrypt()
                .then((value) {
                  DatabaseManager.addOrUpdateAccount(value);
                  if (mounted) {
                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pop(account);
                  }
                })
                .catchError((e) {
                  ScaffoldMessenger.of(
                    // ignore: use_build_context_synchronously
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                });
          }
        },
        tooltip: t('edit_account.save_account'),
        child: const Icon(Icons.check),
      ),
    );
  }
}
