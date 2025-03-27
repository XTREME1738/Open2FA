import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open2fa/crypto.dart';
import 'package:open2fa/i18n.dart';
import 'package:open2fa/main.dart';
import 'package:open2fa/pages/vault.dart';
import 'package:open2fa/pages/setup/password.dart';
import 'package:open2fa/pages/setup/setup.dart';
import 'package:open2fa/prefs.dart';

class SetupAuthPage extends ConsumerStatefulWidget {
  const SetupAuthPage({super.key});

  @override
  ConsumerState<SetupAuthPage> createState() => _SetupAuthPageState();
}

class _SetupAuthPageState extends ConsumerState<SetupAuthPage> {
  @override
  Widget build(BuildContext context) {
    final usingAuth = ref.watch(authEnabledProvider);
    final usingAuthNotifier = ref.read(authEnabledProvider.notifier);
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                t('setup.auth'),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                t('setup.auth_desc'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              RadioListTile(
                title: Text(t('setup.auth_none')),
                value: false,
                groupValue: usingAuth,
                onChanged: (value) {
                  setState(() {
                    usingAuthNotifier.state = value as bool;
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              RadioListTile(
                title: Text(t('setup.auth_password')),
                value: true,
                groupValue: usingAuth,
                onChanged: (value) {
                  setState(() {
                    usingAuthNotifier.state = value as bool;
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                Platform.isAndroid
                    ? t('setup.instructions_auth_android')
                    : t('setup.instructions_auth'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
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
                onPressed: () {
                  Navigator.of(context).pop();
                },
                heroTag: null,
                child: Icon(Icons.arrow_back),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton(
                onPressed: () async {
                  if (usingAuth) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => SetupAuthPasswordPage(),
                      ),
                    );
                  } else {
                    await Crypto.setupNoAuth();
                    await Prefs.setSetupComplete(true);
                    ref.read(vaultLockedProvider.notifier).state = false;
                    if (mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => VaultPage(),
                        ),
                      );
                    }
                  }
                },
                child: Icon(Icons.arrow_forward),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
