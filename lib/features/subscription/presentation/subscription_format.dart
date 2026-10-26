import 'package:intl/intl.dart';

String rupiah(int amount) => NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 0,
).format(amount);
