# for completeness:
flutter pub pub run intl_generator:extract_to_arb --output-dir=lib/l10n lib/localization.dart
flutter pub pub run intl_generator:generate_from_arb --output-dir=lib/l10n --no-use-deferred-loading lib/localization.dart lib/l10n/intl_*.arb