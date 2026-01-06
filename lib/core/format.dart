import 'package:intl/intl.dart';

class Fmt {
  static final _money = NumberFormat.currency(
    locale: 'es_UY',
    symbol: '\$',
    decimalDigits: 2,
  );

  static String money(num v) => _money.format(v);

  static String shortId(String id) => id.length <= 6 ? id : id.substring(0, 6);
}
