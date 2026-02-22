import 'package:intl/intl.dart';

String formatTimeFromMillis(int millis) {
  final dt = DateTime.fromMillisecondsSinceEpoch(millis);
  return DateFormat('HH:mm').format(dt);
}