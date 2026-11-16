import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'views/home_navigation_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización de soporte de fechas localizadas en español
  await initializeDateFormatting('es', null);

  // Inicialización del servicio de alarmas con zona horaria real y solicitud de permisos completos
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.requestAllPermissions();

  // Cancelación de alarmas previas huérfanas
  await notificationService.cancelAllNotifications();

  // Reprogramación automática de alarmas pendientes
  await notificationService.reprogramarAlarmasPendientes();

  runApp(const JardineriaApp());
}

class JardineriaApp extends StatelessWidget {
  const JardineriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jardinería Gonzalo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeNavigationView(),
    );
  }
}
