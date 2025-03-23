import 'package:open2fa/i18n.dart';
import 'package:otp/otp.dart';

class KeyUri {
  final String type;
  final String label;
  final String secret;
  final String issuer;
  final Algorithm algorithm;
  final int digits;
  final int counter;
  final int period;

  KeyUri({
    required this.type,
    required this.label,
    required this.secret,
    required this.issuer,
    required this.algorithm,
    required this.digits,
    required this.counter,
    required this.period,
  });

  // Basic Key URI parser for TOTP and HOTP
  // https://github.com/google/google-authenticator/wiki/Key-Uri-Format
  static KeyUri? parse(String uri) {
    final uriData = Uri.parse(uri);
    final type = uriData.scheme.toLowerCase();
    final hasPathIssuer = uriData.pathSegments.first.split(':').length > 1;
    final label =
        hasPathIssuer ? uriData.pathSegments.first : uriData.pathSegments.first;
    final query = uriData.queryParameters;
    final supportedAlgorithm = Algorithm.values.any(
      (e) =>
          e.toString() ==
          'Algorithm.${(query['algorithm']?.toUpperCase() ?? 'SHA1')}',
    );

    if (type != 'totp' && type != 'hotp') {
      throw ArgumentError(t('error.unsupported_type', args: [type]));
    }

    if (!supportedAlgorithm) {
      throw ArgumentError(
        t('error.unsupported_algorithm', args: [query['algorithm']]),
      );
    }

    if (type == 'hotp') {
      if (query['counter'] == null || query['counter']!.isEmpty) {
        throw ArgumentError(t('error.counter_required'));
      }
    } else {
      if (query['period'] == null || query['period']!.isEmpty) {
        throw ArgumentError(t('error.interval_required'));
      }
    }

    final secret = query['secret'];
    if (secret == null || secret.isEmpty) {
      throw ArgumentError(t('error.secret_required'));
    }
    final issuer =
        query['issuer'] ?? (hasPathIssuer ? label.split(':').first : null);
    if (issuer == null || issuer.isEmpty) {
      throw ArgumentError(t('error.issuer_required'));
    }
    final algorithm = Algorithm.values.firstWhere(
      (e) =>
          e.toString() ==
          'Algorithm.${(query['algorithm']?.toUpperCase() ?? 'SHA1')}',
    );
    final digits = int.tryParse(query['digits'] ?? '6');
    final counter = int.tryParse(query['counter'] ?? '0');
    final period = int.tryParse(query['period'] ?? '30');

    if (digits == null) {
      throw ArgumentError(t('error.digits_invalid'));
    } else if (digits < 3) {
      throw ArgumentError(t('error.digits_min'));
    } else if (digits > 8) {
      throw ArgumentError(t('error.digits_max'));
    }

    if (type == 'hotp') {
      if (counter == null) {
        throw ArgumentError(t('error.counter_invalid'));
      } else if (counter < 0) {
        throw ArgumentError(t('error.counter_min'));
      }
    } else {
      if (period == null) {
        throw ArgumentError(t('error.interval_invalid'));
      } else if (period < 1) {
        throw ArgumentError(t('error.interval_min'));
      } else if (query['period']!.length > 3) {
        throw ArgumentError(t('error.interval_max'));
      }
    }

    return KeyUri(
      type: type,
      label: label.split(':').sublist(1).join(':'),
      secret: secret,
      issuer: issuer,
      algorithm: algorithm,
      digits: digits,
      counter: counter!,
      period: period!,
    );
  }
}
