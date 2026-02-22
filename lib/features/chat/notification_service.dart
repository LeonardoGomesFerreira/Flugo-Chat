import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Serviço de notificações locais para novas mensagens do chat.
/// Funciona em Android e iOS sem Firebase Cloud Messaging (FCM).
class NotificationService {
  static final NotificationService _i = NotificationService._();
  factory NotificationService() => _i;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(settings);

    // Solicita permissão no Android 13+
    final android13 = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android13?.requestNotificationsPermission();
  }

  /// Mostra notificação de nova mensagem.
  /// [inForeground] = app está visível → usa snackbar em vez de notificação do SO.
  Future<void> showMessage({
    required String title,
    required String body,
    bool inForeground = true,
  }) async {
    if (inForeground) return; // Snackbar é mostrado pelo chat_page quando em foreground

    const androidDetails = AndroidNotificationDetails(
      'flugo_chat',
      'Mensagens',
      channelDescription: 'Novas mensagens do Flugo Chat',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }
}

/// Widget que mostra um SnackBar estilizado quando chega mensagem nova
/// enquanto o app está em foreground.
class InAppNotificationOverlay extends StatefulWidget {
  final Widget child;
  const InAppNotificationOverlay({super.key, required this.child});

  @override
  State<InAppNotificationOverlay> createState() => InAppNotificationOverlayState();

  static InAppNotificationOverlayState? of(BuildContext context) =>
      context.findAncestorStateOfType<InAppNotificationOverlayState>();
}

class InAppNotificationOverlayState extends State<InAppNotificationOverlay> {
  @override
  Widget build(BuildContext context) => widget.child;

  void show(BuildContext ctx, {required String sender, required String text}) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: const Color(0xFF243044),
        content: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF1E3A2F),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_rounded,
                color: Color(0xFF4ADE80), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(sender,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF4ADE80))),
                  Text(text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Color(0xFFF1F5F9))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
