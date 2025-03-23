import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open2fa/i18n.dart';
import 'package:open2fa/pages/edit_account.dart';
import 'package:open2fa/pages/vault.dart';
import 'package:open2fa/structures/account.dart';
import 'package:open2fa/widgets/twofactor_circular_progress.dart';

class TwoFactorAccountCard extends ConsumerStatefulWidget {
  const TwoFactorAccountCard({
    super.key,
    required this.account,
    required this.accountCode,
    required this.accountNextCode,
    required this.delete,
  });

  final Account account;
  final String accountCode;
  final String accountNextCode;
  final void Function() delete;

  @override
  ConsumerState<TwoFactorAccountCard> createState() =>
      _TwoFactorAccountCardState();
}

class _TwoFactorAccountCardState extends ConsumerState<TwoFactorAccountCard> {
  Color? _cardTint;

  @override
  Widget build(BuildContext context) {
    final cardTapTint = Theme.of(
      context,
    ).colorScheme.secondary.withValues(alpha: 0x33);
    final hideCodes = ref.watch(hideCodesProvider);
    return GestureDetector(
      onTapDown:
          (_) => setState(() {
            _cardTint = cardTapTint;
          }),
      onTapUp:
          (_) => setState(() {
            _cardTint = null;
          }),
      onTapCancel:
          () => setState(() {
            _cardTint = null;
          }),
      onLongPressStart:
          (_) => setState(() {
            _cardTint = cardTapTint;
          }),
      onLongPressCancel:
          () => setState(() {
            _cardTint = null;
          }),
      onLongPressUp:
          () => setState(() {
            _cardTint = null;
          }),
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          builder: (context) {
            final navigationBarHeight = MediaQuery.of(context).padding.bottom;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(t('account.issuer')),
                  subtitle: Text(
                    widget.account.issuer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ListTile(
                  title: Text(t('account.label')),
                  subtitle: Text(
                    widget.account.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.copy),
                        label: Text(t('account.copy_code')),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: widget.accountCode),
                          );
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.copy),
                        label: Text(t('account.copy_next_code')),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: widget.accountNextCode),
                          );
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.edit),
                        label: Text(t('edit')),
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context)
                              .push<Account?>(
                                MaterialPageRoute(
                                  builder: (context) {
                                    return EditAccountPage(
                                      account: widget.account,
                                    );
                                  },
                                ),
                              )
                              .then((value) {
                                if (value != null) {
                                  setState(() {
                                    widget.account.updateCodes();
                                  });
                                }
                              });
                        },
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text(t('account.delete_confirm')),
                                content: Text(t('account.delete_confirm_desc')),
                                actions: [
                                  TextButton(
                                    child: Text(t('cancel')),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  TextButton(
                                    child: Text(
                                      t('account.delete'),
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    onPressed: () {
                                      widget.delete();
                                      Navigator.of(context).pop(widget.account);
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: navigationBarHeight),
              ],
            );
          },
        );
      },
      onTap: () {
        Clipboard.setData(ClipboardData(text: widget.accountCode));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t('account.code_copied'))));
      },
      child: Card(
        surfaceTintColor: _cardTint,
        margin: const EdgeInsets.all(8),
        elevation: 1,
        child: Column(
          children: [
            ListTile(
              leading: Stack(
                alignment: Alignment.center,
                children: [
                  TwoFactorCircularProgressIndicator(
                    onRestart: () {
                      setState(() {
                        widget.account.updateCodes();
                      });
                    },
                  ),
                  Icon(Icons.public), // Temporary, I will add icons later
                ],
              ),
              title: Text(
                widget.account.issuer,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                widget.account.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: OverflowBar(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        hideCodes ? '******' : widget.accountCode,
                        style: const TextStyle(
                          fontSize: 18,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        hideCodes ? '******' : widget.accountNextCode,
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
