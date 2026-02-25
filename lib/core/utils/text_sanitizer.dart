import 'package:html_unescape/html_unescape.dart';

final _unescape = HtmlUnescape();

String cleanText(String text) {
  return _unescape.convert(text).trim();
}
