import 'package:flutter/material.dart';
import 'package:open2fa/i18n.dart';
import 'package:open2fa/pages/setup/theme.dart';

class SetupLanguagePage extends StatefulWidget {
  const SetupLanguagePage({super.key});

  @override
  State<SetupLanguagePage> createState() => _SetupLanguagePageState();
}

class _SetupLanguagePageState extends State<SetupLanguagePage> {
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
                t('setup.select_language'),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                t('setup.select_language_desc'),
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: 150, maxHeight: 580),
                child: ListView(
                  scrollDirection: Axis.vertical,
                  physics: BouncingScrollPhysics(),
                  shrinkWrap: true,
                  children: [
                    for (final language in I18n.languages.keys)
                      RadioListTile(
                        title: Text(I18n.languages[language]!),
                        value: language,
                        groupValue: I18n.currentLanguage,
                        onChanged: (value) {
                          setState(() {
                            I18n.load(language);
                          });
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                  ],
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
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        return SetupThemePage();
                      },
                    ),
                  );
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
