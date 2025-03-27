import 'package:base32/base32.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_dropdown/multi_dropdown.dart';
import 'package:open2fa/database.dart';
import 'package:open2fa/i18n.dart';
import 'package:open2fa/main.dart';
import 'package:open2fa/pages/vault.dart';
import 'package:open2fa/structures/account.dart';
import 'package:open2fa/structures/category.dart';
import 'package:otp/otp.dart';

class EditAccountPage extends ConsumerStatefulWidget {
  final Account? account;

  const EditAccountPage({super.key, this.account});

  @override
  ConsumerState<EditAccountPage> createState() => _EditAccountPageState();
}

class _EditAccountPageState extends ConsumerState<EditAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _issuerController = TextEditingController();
  final _secretController = TextEditingController();
  final _intervalController = TextEditingController();
  final _counterController = TextEditingController();
  final _digitsController = TextEditingController();
  final _categoryController = MultiSelectController<String>();
  final _categoryFormKey = GlobalKey<FormState>();
  final _categoryNameController = TextEditingController();
  Algorithm _algorithm = Algorithm.SHA1;
  final _categories = <String>[];
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
    final categories = ref.watch(categoryProvider);
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
              MultiDropdown(
                controller: _categoryController,
                fieldDecoration: FieldDecoration(
                  labelText: t('account.categories'),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
                dropdownDecoration: DropdownDecoration(
                  borderRadius: BorderRadius.circular(4),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  elevation: 10,
                ),
                dropdownItemDecoration: DropdownItemDecoration(
                  selectedBackgroundColor:
                      Theme.of(context).colorScheme.surfaceContainer,
                ),
                chipDecoration: ChipDecoration(
                  backgroundColor: Theme.of(context).colorScheme.surfaceTint,
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  deleteIcon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 16,
                  ),
                ),
                searchEnabled: false,
                items: [
                  ...categories.map(
                    (category) => DropdownItem(
                      value: category.uuid,
                      label: category.name,
                    ),
                  ),
                  DropdownItem(
                    label: t('edit_account.create_category'),
                    value: 'create',
                  ),
                ],
                onSelectionChange: (selected) {
                  if (selected.isNotEmpty &&
                      selected.firstWhere(
                            (element) => element == 'create',
                            orElse: () => '',
                          ) ==
                          'create') {
                    _categoryController.unselectWhere(
                      (element) => element.value == 'create',
                    );
                    _categoryController.closeDropdown();
                    showModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Form(
                                key: _categoryFormKey,
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: _categoryNameController,
                                      decoration: InputDecoration(
                                        labelText: t(
                                          'edit_account.category_name',
                                        ),
                                        border: const OutlineInputBorder(),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return t(
                                            'error.category_name_required',
                                          );
                                        }
                                        if (value.length > 16) {
                                          return t('error.category_name_max');
                                        }
                                        if (value.length < 3) {
                                          return t('error.category_name_min');
                                        }
                                        if (!RegExp(
                                          r'^[a-zA-Z0-9_\- ]+$',
                                        ).hasMatch(value)) {
                                          return t(
                                            'error.category_name_invalid',
                                          );
                                        }
                                        if (categories.any(
                                          (element) =>
                                              element.name.toLowerCase() ==
                                              value.toLowerCase(),
                                        )) {
                                          return t(
                                            'error.category_name_exists',
                                          );
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () async {
                                  if (!_categoryFormKey.currentState!
                                      .validate()) {
                                    return;
                                  }
                                  final category = Category(
                                    name: _categoryNameController.text,
                                    uuid: DateTime.now().toString(),
                                    createdAt: DateTime.now(),
                                    updatedAt: DateTime.now(),
                                  );
                                  try {
                                    await DatabaseManager.addOrUpdateCategory(
                                      category,
                                    );
                                    ref.read(categoryProvider.notifier).state.add(category);
                                    _categoryController.addItem(
                                      DropdownItem(
                                        label: category.name,
                                        value: category.uuid,
                                      ),
                                    );
                                    setState(() {});
                                    if (mounted) {
                                      Navigator.of(context).pop(category);
                                    }
                                  } catch (e) {
                                    logger.e(
                                      t('error.category_create_fail'),
                                      error: e,
                                    );
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text(e.toString())),
                                      );
                                    }
                                  }
                                },
                                child: Text(t('edit_account.create_category')),
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).viewInsets.bottom,
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        );
                      },
                    );
                  }
                  setState(() {
                    _categories.clear();
                    _categories.addAll(selected);
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
              id: widget.account?.id ?? -1,
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
