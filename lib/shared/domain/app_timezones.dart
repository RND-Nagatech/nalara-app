/// Stable IANA values, shared by account settings and new schedule forms.
abstract final class AppTimezones {
  static const jakarta = 'Asia/Jakarta';
  static const labels = {
    jakarta: 'WIB · Jakarta (UTC+7)',
    'Asia/Makassar': 'WITA · Makassar (UTC+8)',
    'Asia/Jayapura': 'WIT · Jayapura (UTC+9)',
  };
  static bool supports(String value) => labels.containsKey(value);
  static String label(String value) => labels[value] ?? value;
  static String abbreviation(String value) => switch (value) {
    jakarta => 'WIB',
    'Asia/Makassar' => 'WITA',
    'Asia/Jayapura' => 'WIT',
    _ => value,
  };
}
