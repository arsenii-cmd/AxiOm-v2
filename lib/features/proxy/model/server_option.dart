import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';

/// Parsed Arco VPN server entry from selector group items.
class ServerOption {
  ServerOption({
    required this.country,
    required this.transport,
    required this.rawTag,
    required this.delay,
  });

  final String country;
  final String transport;
  final String rawTag;
  final int delay;

  /// Sentinel for the auto (fastest server + transport) selector mode.
  static const String autoCountryKey = '__auto__';

  static bool isValidDelay(int delay) => delay > 0 && delay < 65000;

  // Server tags look like "<Country> (<username>) [<transport>]" where the
  // parenthetical is the subscription account name (varies per user), so it
  // must not be hard-coded to a specific value.
  static final RegExp _displayPattern = RegExp(
    r'^(.*?)\s*\([^)]*\)\s*\[(ws|tcp)\]\s*$',
    caseSensitive: false,
  );

  static ServerOption? tryParseDisplay(String tagDisplay, {required String rawTag, int delay = 0}) {
    final match = _displayPattern.firstMatch(tagDisplay.trim());
    if (match == null) return null;
    final country = match.group(1)!.trim();
    if (country.isEmpty) return null;
    return ServerOption(
      country: country,
      transport: match.group(2)!.toLowerCase(),
      rawTag: rawTag,
      delay: delay,
    );
  }

  static List<ServerOption> parse(OutboundGroup group) {
    final options = <ServerOption>[];
    for (final item in group.items) {
      if (item.isGroup) continue;
      final parsed = tryParseDisplay(
        item.tagDisplay,
        rawTag: item.tag,
        delay: item.urlTestDelay,
      );
      if (parsed != null) options.add(parsed);
    }
    return options;
  }

  static Set<String> countries(List<ServerOption> options) {
    return options.map((o) => o.country).toSet();
  }

  static List<String> transportsFor(List<ServerOption> options, String country) {
    return options
        .where((o) => o.country == country)
        .map((o) => o.transport)
        .toSet()
        .toList()
      ..sort();
  }

  static ServerOption? find(List<ServerOption> options, String country, String transport) {
    for (final o in options) {
      if (o.country == country && o.transport == transport) return o;
    }
    return null;
  }

  static int? bestDelayForCountry(List<ServerOption> options, String country) {
    final delays = options
        .where((o) => o.country == country && isValidDelay(o.delay))
        .map((o) => o.delay);
    if (delays.isEmpty) return null;
    return delays.reduce((a, b) => a < b ? a : b);
  }

  /// Fastest server among all country + transport combinations (by url-test delay).
  static ServerOption? fastest(List<ServerOption> options) {
    ServerOption? best;
    for (final option in options) {
      if (!isValidDelay(option.delay)) continue;
      if (best == null || option.delay < best.delay) best = option;
    }
    return best;
  }

  static String transportLabel(String transport) => switch (transport.toLowerCase()) {
    'ws' => 'WebSocket',
    'tcp' => 'Reality (TCP)',
    _ => transport,
  };

  static String countryFlagEmoji(String country) {
    final iso = _countryNameToIso[country.trim().toLowerCase()];
    if (iso == null || iso.length != 2) return '🏳️';
    final upper = iso.toUpperCase();
    return String.fromCharCodes(upper.codeUnits.map((c) => c + 127397));
  }

  static const Map<String, String> _countryNameToIso = {
    'netherlands': 'NL',
    'france': 'FR',
    'russia': 'RU',
    'poland': 'PL',
    'germany': 'DE',
    'united states': 'US',
    'usa': 'US',
    'united kingdom': 'GB',
    'uk': 'GB',
    'finland': 'FI',
    'sweden': 'SE',
    'norway': 'NO',
    'turkey': 'TR',
    'japan': 'JP',
    'singapore': 'SG',
    'canada': 'CA',
    'italy': 'IT',
    'spain': 'ES',
    'switzerland': 'CH',
    'austria': 'AT',
    'belgium': 'BE',
    'czechia': 'CZ',
    'czech republic': 'CZ',
    'romania': 'RO',
    'ukraine': 'UA',
    'kazakhstan': 'KZ',
    'hong kong': 'HK',
    'taiwan': 'TW',
    'south korea': 'KR',
    'korea': 'KR',
    'india': 'IN',
    'brazil': 'BR',
    'australia': 'AU',
    'israel': 'IL',
    'uae': 'AE',
    'united arab emirates': 'AE',
    'ireland': 'IE',
    'denmark': 'DK',
    'portugal': 'PT',
    'hungary': 'HU',
    'bulgaria': 'BG',
    'serbia': 'RS',
    'latvia': 'LV',
    'lithuania': 'LT',
    'estonia': 'EE',
    'moldova': 'MD',
    'georgia': 'GE',
    'armenia': 'AM',
    'azerbaijan': 'AZ',
  };
}
