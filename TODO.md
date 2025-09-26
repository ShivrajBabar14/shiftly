# Localization Fix TODO

- [ ] Delete lib/l10n/en.arb (redundant duplicate of intl_en.arb)
- [ ] Run `flutter gen-l10n` to regenerate localization files based on l10n.yaml
- [ ] Update lib/main.dart: change import to 'generated/app_localizations.dart' and replace 'S' with 'AppLocalizations'
- [ ] Search codebase for usages of 'S.' and update to 'AppLocalizations.of(context).'
- [ ] Verify new lib/generated/app_localizations.dart has all locales and keys
- [ ] Run `flutter pub get` and build app to test localization
