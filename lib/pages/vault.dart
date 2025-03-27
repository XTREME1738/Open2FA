import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open2fa/crypto.dart';
import 'package:open2fa/database.dart';
import 'package:open2fa/i18n.dart';
import 'package:open2fa/main.dart';
import 'package:open2fa/pages/auth.dart';
import 'package:open2fa/pages/edit_account.dart';
import 'package:open2fa/pages/settings/settings.dart';
import 'package:open2fa/prefs.dart';
import 'package:open2fa/structures/account.dart';
import 'package:open2fa/structures/category.dart';
import 'package:open2fa/widgets/account_card.dart';

final categoryProvider = StateProvider((ref) => <Category>[]);
final hideCodesProvider = StateProvider((ref) => false);

class VaultPage extends ConsumerStatefulWidget {
  const VaultPage({super.key});

  @override
  ConsumerState<VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends ConsumerState<VaultPage> {
  final List<Account> accounts = [];
  final _filterController = TextEditingController();
  int _categoryIndex = -1;

  void update2FACodes() {
    for (final account in accounts) {
      account.updateCodes();
    }
    setState(() {});
  }

  void updateAccounts() async {
    try {
      accounts.clear();
      accounts.addAll(await DatabaseManager.getAccounts());
      update2FACodes();
    } catch (e) {
      accounts.clear();
      if (e.runtimeType == StateError) {
        AlertDialog(
          title: Text(t('error')),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(t('ok')),
            ),
          ],
        );
      } else {
        logger.e(t('error.failed_to_get_accounts'), error: e);
        AlertDialog(
          title: Text(t('error')),
          content: Text(t('error.failed_to_get_accounts')),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(t('ok')),
            ),
          ],
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      updateAccounts();
      ref.read(categoryProvider.notifier).state =
          await DatabaseManager.getCategories();
      ref.read(hideCodesProvider.notifier).state = await Prefs.getHideCodes();
    });
  }

  @override
  void dispose() {
    Crypto.lockVault();
    accounts.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usingAuth = ref.watch(usingAuthProvider);
    final categories = ref.watch(categoryProvider);
    final vaultLocked = ref.watch(vaultLockedProvider);
    if (vaultLocked) {
      Future.delayed(const Duration(milliseconds: 150), () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthPage()),
        );
      });
    }
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 1,
        scrolledUnderElevation: 1,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shadowColor: Theme.of(context).colorScheme.shadow,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(72),
          child: Container(
            padding: const EdgeInsets.all(0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _filterController,
                          decoration: InputDecoration(
                            hintText: t('search'),
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      PopupMenuButton(
                        icon: const Icon(Icons.more_vert),
                        itemBuilder: (context) {
                          return [
                            PopupMenuItem(
                              child: Row(
                                children: [
                                  const Icon(Icons.settings_outlined, size: 18),
                                  const SizedBox(width: 8),
                                  Text(t('settings')),
                                ],
                              ),
                              onTap: () {
                                Navigator.of(context)
                                    .push(
                                      MaterialPageRoute(
                                        builder: (context) {
                                          return const SettingsPage();
                                        },
                                      ),
                                    )
                                    .then((value) {
                                      updateAccounts();
                                      setState(() {});
                                    });
                              },
                            ),
                            if (usingAuth)
                              PopupMenuItem(
                                child: Row(
                                  children: [
                                    const Icon(Icons.lock_outline, size: 18),
                                    const SizedBox(width: 8),
                                    Text(t('lock')),
                                  ],
                                ),
                                onTap: () {
                                  Crypto.lockVault();
                                  ref.read(vaultLockedProvider.notifier).state =
                                      true;
                                },
                              ),
                          ];
                        },
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(t('all')),
                        selected: _categoryIndex == -1,
                        onSelected: (selected) {
                          setState(() {
                            _categoryIndex = -1;
                          });
                        },
                      ),
                    ),
                    ...List.generate(categories.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(categories[index].name),
                          selected: _categoryIndex == index,
                          onSelected: (selected) {
                            setState(() {
                              _categoryIndex = selected ? index : -1;
                            });
                          },
                        ),
                      );
                    }),
                    const SizedBox(width: 8),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        children: [
          for (final account in accounts.where(
            (account) =>
                (_categoryIndex != -1 &&
                    account.categories.contains(
                      categories[_categoryIndex].id.toString(),
                    )) &&
                (account.label.toLowerCase().contains(
                      _filterController.text.toLowerCase(),
                    ) ||
                    account.issuer.toLowerCase().contains(
                      _filterController.text.toLowerCase(),
                    )),
          ))
            TwoFactorAccountCard(
              account: account,
              accountCode: account.code,
              accountNextCode: account.nextCode,
              delete: () async {
                DatabaseManager.removeAccount(account.id!);
                updateAccounts();
              },
            ),
          SizedBox(
            height: 78,
          ), // Make sure that the bottom codes do not get covered by the FAB
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (context) {
                    return const EditAccountPage();
                  },
                ),
              )
              .then((value) {
                updateAccounts();
                setState(() {});
              });
        },
        tooltip: t('add_account'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
