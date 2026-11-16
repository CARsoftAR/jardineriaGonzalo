import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/servicio_model.dart';
import 'db_service.dart';

/// Función top-level para capturar acciones interactivas en background (Detener / Posponer)
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) async {
  try {
    if (notificationResponse.actionId == 'action_snooze') {
      final id = notificationResponse.id ?? 0;
      await NotificationService().posponerAlarma(id, 15);
    } else if (notificationResponse.actionId == 'action_stop') {
      final id = notificationResponse.id ?? 0;
      await NotificationService().cancelServicioAlarma(id);
    }
  } catch (e) {
    print('Advertencia en acción background de notificación: $e');
  }
}

/// Servicio Singleton para la gestión de alarmas reales y persistentes en Android.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Canal limpio con tono nativo de alarma del sistema
  static const String channelId = 'alarm_channel_v3';

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  String _currentTimeZone = 'UTC';

  String get currentTimeZone => _currentTimeZone;

  /// Inicializa los ajustes de zona horaria real del dispositivo y los canales de alarma.
  Future<void> init() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    // Detección y configuración estricta de la zona horaria real del dispositivo
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      _currentTimeZone = timezoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(_currentTimeZone));
      print('NotificationService: Zona horaria detectada: $_currentTimeZone');
    } catch (e) {
      try {
        _currentTimeZone = DateTime.now().timeZoneName;
        tz.setLocalLocation(tz.getLocation(_currentTimeZone));
      } catch (_) {
        // Fallback seguro a UTC
      }
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );
    } catch (e) {
      print('Advertencia al inicializar notifications plugin: $e');
    }

    // Crear canal de notificación con nivel de Alarma en Android
    if (Platform.isAndroid) {
      try {
        final androidImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidImplementation != null) {
          final vibrationPattern =
              Int64List.fromList([0, 1000, 500, 1000, 500, 1000]);
          const alarmSound =
              UriAndroidNotificationSound('content://settings/system/alarm_alert');

          await androidImplementation.createNotificationChannel(
            AndroidNotificationChannel(
              channelId,
              'Alarmas de Servicios',
              description:
                  'Canal para alarmas críticas de jardinería con sonido de despertador nativo',
              importance: Importance.max,
              playSound: true,
              sound: alarmSound,
              enableVibration: true,
              vibrationPattern: vibrationPattern,
              enableLights: true,
              audioAttributesUsage: AudioAttributesUsage.alarm,
            ),
          );
        }
      } catch (e) {
        print('Advertencia al crear canal de notificaciones en Android: $e');
      }
    }

    _isInitialized = true;
  }

  void _onDidReceiveNotificationResponse(NotificationResponse response) async {
    try {
      if (response.actionId == 'action_snooze') {
        final id = response.id ?? 0;
        await posponerAlarma(id, 15);
      } else if (response.actionId == 'action_stop') {
        final id = response.id ?? 0;
        await cancelServicioAlarma(id);
      }
    } catch (e) {
      print('Advertencia al procesar tap en notificación: $e');
    }
  }

  /// Solicita permisos en Android 13, 14 y 15 de forma segura.
  Future<Map<String, bool>> requestAllPermissions() async {
    await init();
    bool notificaciones = true;
    bool alarmasExactas = true;

    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        try {
          final notifResult =
              await androidImplementation.requestNotificationsPermission();
          notificaciones = notifResult ?? false;
        } catch (e) {
          print('Advertencia solicitando permiso de notificaciones: $e');
        }

        try {
          final exactResult =
              await androidImplementation.requestExactAlarmsPermission();
          alarmasExactas = exactResult ?? false;
        } catch (e) {
          print('Advertencia solicitando permiso de alarmas exactas: $e');
        }
      }
    } catch (e) {
      print('Advertencia general en requestAllPermissions: $e');
    }

    return {
      'notificaciones': notificaciones,
      'alarmasExactas': alarmasExactas,
    };
  }

  /// Configuración de notificación con comportamiento de ALARMA REAL y botones de acción directos.
  NotificationDetails _buildAlarmNotificationDetails() {
    final vibrationPattern =
        Int64List.fromList([0, 1000, 500, 1000, 500, 1000]);
    const alarmSound =
        UriAndroidNotificationSound('content://settings/system/alarm_alert');

    final androidDetails = AndroidNotificationDetails(
      channelId,
      'Alarmas de Servicios',
      channelDescription:
          'Canal para alarmas críticas de jardinería con sonido de despertador nativo',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      sound: alarmSound,
      playSound: true,
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      enableVibration: true,
      vibrationPattern: vibrationPattern,
      additionalFlags: Int32List.fromList(<int>[4]), // FLAG_INSISTENT: Repite el sonido continuamente hasta responder
      enableLights: true,
      visibility: NotificationVisibility.public,
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'action_stop',
          'Detener',
          cancelNotification: true,
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          'action_snooze',
          'Posponer 15m',
          showsUserInterface: false,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  /// Ejecuta zonedSchedule con fallback en cascada:
  /// 1. Primero intenta con [alarmClock] (máxima prioridad de alarma en Android, traspasa Doze en Xiaomi/Samsung).
  /// 2. Si falla, intenta con [exactAllowWhileIdle].
  /// 3. Si ambos fallan, aplica [inexactAllowWhileIdle] de forma segura.
  Future<bool> _zonedScheduleSeguro({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
  }) async {
    // 1. Intento primario: AlarmClock (comportamiento de despertador real en Android)
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      print('Notificación programada con éxito usando AndroidScheduleMode.alarmClock');
      return true;
    } catch (alarmClockError) {
      print('Aviso: alarmClock no admitido ($alarmClockError). Intentando exactAllowWhileIdle...');
    }

    // 2. Intento secundario: Alarma exacta en reposo
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      print('Notificación programada con éxito usando AndroidScheduleMode.exactAllowWhileIdle');
      return true;
    } catch (exactError) {
      print('Aviso: exactAllowWhileIdle rechazado ($exactError). Aplicando fallback inexacto...');
    }

    // 3. Intento de respaldo (Fallback): Inexacto pero tolerante y 100% libre de SecurityException
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      print('Notificación programada con éxito usando fallback inexactAllowWhileIdle');
      return true;
    } catch (fallbackError) {
      print('Error crítico capturado en fallback de notificación: $fallbackError');
      return false;
    }
  }

  /// Pospone una alarma en [minutosPospuesto] (por defecto 15 minutos).
  Future<void> posponerAlarma(int notificationId, [int minutosPospuesto = 15]) async {
    try {
      await init();

      final tzNow = tz.TZDateTime.now(tz.local);
      final tzPospuesta = tzNow.add(Duration(minutes: minutosPospuesto));

      // Verificación estricta de tiempo futuro
      if (!tzPospuesta.isAfter(tzNow)) {
        print('Aviso: Hora pospuesta inválida en el pasado.');
        return;
      }

      await _zonedScheduleSeguro(
        id: notificationId,
        title: '⏰ ALARMA POSPUESTA (${minutosPospuesto}m)',
        body: 'Recordatorio reprogramado para servicio de jardinería.',
        scheduledDate: tzPospuesta,
        notificationDetails: _buildAlarmNotificationDetails(),
      );
    } catch (e) {
      print('Advertencia segura al posponer alarma $notificationId: $e');
    }
  }

  /// Programa una alarma/recordatorio para un servicio según sus [minutosAnticipacion].
  Future<bool> scheduleServicioAlarma(Servicio servicio) async {
    if (servicio.id == null) return false;

    try {
      await init();

      final now = DateTime.now();
      final fechaServicio = servicio.fechaServicio;
      final minutosAnticipacion = servicio.minutosAnticipacion;

      // 1. Cálculo preciso de la fecha de la alarma
      final fechaAlarma =
          fechaServicio.subtract(Duration(minutes: minutosAnticipacion));

      print('=== AUDITORÍA DE ALARMA PARA SERVICIO ${servicio.id} ===');
      print('Cliente: ${servicio.clienteNombre}');
      print('Hora actual del sistema: $now');
      print('Fecha del servicio: $fechaServicio');
      print('Minutos de anticipación: $minutosAnticipacion');
      print('Fecha de alarma calculada: $fechaAlarma');
      print('Zona horaria configurada: $_currentTimeZone');

      // Si el servicio completo ya ocurrió en el pasado, no se agenda alarma
      if (fechaServicio.isBefore(now)) {
        print('Aviso: El servicio ($fechaServicio) ya ocurrió en el pasado respecto a ($now). No se programa alarma.');
        return false;
      }

      // Si la fecha de la alarma calculada ya pasó o es inminente (<= now + 10s),
      // forzar a que suene en 30 segundos en lugar de descartarla silenciosamente.
      DateTime fechaEfectivaAlarma;
      if (!fechaAlarma.isAfter(now.add(const Duration(seconds: 10)))) {
        fechaEfectivaAlarma = now.add(const Duration(seconds: 30));
        print('Aviso: La fecha de anticipación ($fechaAlarma) ya pasó o es inminente. Forzando alarma en 30 segundos ($fechaEfectivaAlarma).');
      } else {
        fechaEfectivaAlarma = fechaAlarma;
        print('Fecha efectiva de alarma programada: $fechaEfectivaAlarma');
      }

      // 2. Conversión a zona horaria local confiable
      final tzNow = tz.TZDateTime.now(tz.local);
      final durationUntilAlarm = fechaEfectivaAlarma.difference(now);

      // Programación basada en el desfase temporal exacto respecto al tzNow
      var tzScheduledDate = tzNow.add(durationUntilAlarm);

      // Validación estricta: tzScheduledDate DEBE ser estrictamente posterior a tzNow (mínimo 3 seg)
      if (!tzScheduledDate.isAfter(tzNow.add(const Duration(seconds: 3)))) {
        tzScheduledDate = tzNow.add(const Duration(seconds: 30));
        print('Ajuste de seguridad TZ: fecha programada forzada a 30s en el futuro: $tzScheduledDate');
      }

      print('tzNow: $tzNow');
      print('tzScheduledDate final: $tzScheduledDate');
      print('Diferencia en segundos hasta disparo: ${tzScheduledDate.difference(tzNow).inSeconds}');

      return await _zonedScheduleSeguro(
        id: servicio.id!,
        title: '🔔 Alarma: Servicio con ${servicio.clienteNombre}',
        body: '${servicio.direccion} • Comienza en ${_formatearMinutos(servicio.minutosAnticipacion)}.',
        scheduledDate: tzScheduledDate,
        notificationDetails: _buildAlarmNotificationDetails(),
      );
    } catch (e) {
      print('Advertencia segura al programar alarma para servicio ${servicio.id}: $e');
      return false;
    }
  }

  /// Programa una ALARMA DE PRUEBA que sonará en 10 segundos para verificar audio, acciones y pantalla bloqueada.
  Future<bool> scheduleAlarmaDePrueba() async {
    try {
      await init();

      final tzNow = tz.TZDateTime.now(tz.local);
      final tzScheduledDate = tzNow.add(const Duration(seconds: 10));

      print('=== PROBANDO ALARMA EN 10 SEGUNDOS ===');
      print('Hora actual: $tzNow');
      print('Hora programada: $tzScheduledDate');

      return await _zonedScheduleSeguro(
        id: 999999,
        title: '⏰ ¡ALARMA DE JARDINERÍA GONZALO!',
        body: 'Sonido y vibración activos. Botones interactivos [Detener] y [Posponer 15m].',
        scheduledDate: tzScheduledDate,
        notificationDetails: _buildAlarmNotificationDetails(),
      );
    } catch (e) {
      print('Advertencia segura al programar alarma de prueba: $e');
      return false;
    }
  }

  /// Cancela la notificación asociada a un servicio de forma segura.
  Future<void> cancelServicioAlarma(int? servicioId) async {
    if (servicioId == null) return;
    try {
      await init();
      await _notificationsPlugin.cancel(servicioId);
    } catch (e) {
      print('Advertencia segura al cancelar alarma $servicioId: $e');
    }
  }

  /// Cancela todas las notificaciones y alarmas programadas en el sistema.
  Future<void> cancelAllNotifications() async {
    try {
      await init();
      await _notificationsPlugin.cancelAll();
      print('NotificationService: Todas las notificaciones del sistema han sido canceladas.');
    } catch (e) {
      print('Advertencia al cancelar todas las notificaciones: $e');
    }
  }

  /// Reprograma todas las alarmas de los servicios pendientes cuya fecha calculada esté en el futuro.
  Future<int> reprogramarAlarmasPendientes() async {
    try {
      await init();
      final dbService = DbService();
      final pendientes = await dbService.getServiciosPendientes();

      int reprogramadas = 0;
      final now = DateTime.now();

      for (final servicio in pendientes) {
        if (servicio.fechaServicio.isAfter(now)) {
          final ok = await scheduleServicioAlarma(servicio);
          if (ok) reprogramadas++;
        }
      }

      return reprogramadas;
    } catch (e) {
      print('Advertencia en reprogramarAlarmasPendientes: $e');
      return 0;
    }
  }

  String _formatearMinutos(int minutos) {
    if (minutos <= 0) return 'el momento del servicio';
    final dias = minutos ~/ 1440;
    final horas = (minutos % 1440) ~/ 60;
    final mins = minutos % 60;

    final partes = <String>[];
    if (dias > 0) partes.add('$dias día${dias > 1 ? 's' : ''}');
    if (horas > 0) partes.add('$horas hora${horas > 1 ? 's' : ''}');
    if (mins > 0) partes.add('$mins min');

    return partes.join(' ');
  }
}
