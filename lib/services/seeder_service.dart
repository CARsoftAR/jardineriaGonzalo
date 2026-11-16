import '../models/cliente_model.dart';
import '../models/servicio_model.dart';
import 'db_service.dart';
import 'notification_service.dart';

/// Servicio encargado de poblar la base de datos local SQLite con datos de prueba realistas.
/// Garantiza la integridad referencial vinculando los servicios con los IDs reales de los clientes,
/// evitando duplicar clientes y programando alarmas para servicios futuros.
class SeederService {
  static final SeederService _instance = SeederService._internal();
  factory SeederService() => _instance;
  SeederService._internal();

  final DbService _db = DbService();
  final NotificationService _notif = NotificationService();

  /// Puebla la base de datos si la tabla de clientes o la tabla de servicios se encuentran vacías.
  /// Si los clientes ya existen pero no hay servicios, inserta los servicios vinculándolos a los clientes existentes.
  Future<bool> poblarBaseDeDatosSiEstaVacia() async {
    try {
      final clientes = await _db.getClientes();
      final pendientes = await _db.getServiciosPendientes();
      final completados = await _db.getServiciosCompletados();

      final bool sinClientes = clientes.isEmpty;
      final bool sinServicios = pendientes.isEmpty && completados.isEmpty;

      if (sinClientes || sinServicios) {
        print(
          'SeederService: Base de datos incompleta detectada '
          '(sinClientes: $sinClientes, sinServicios: $sinServicios). '
          'Iniciando sembrado...',
        );
        await ejecutarSeederCompleto(
          sembrarClientes: sinClientes,
          forzarServicios: sinServicios,
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Advertencia en SeederService.poblarBaseDeDatosSiEstaVacia: $e');
      return false;
    }
  }

  /// Ejecuta el sembrado de datos de prueba.
  /// - [sembrarClientes]: Si es true, crea los 10 clientes si no existen previamente.
  /// - [forzarServicios]: Si es true, siembra los 29 servicios (18 históricos y 11 pendientes)
  ///   incluso si los clientes ya estaban creados.
  Future<Map<String, int>> ejecutarSeederCompleto({
    bool sembrarClientes = true,
    bool forzarServicios = false,
  }) async {
    int clientesCreados = 0;
    int serviciosCompletadosCreados = 0;
    int serviciosPendientesCreados = 0;

    try {
      // 1. Obtener clientes existentes para evitar duplicados y mapear sus IDs
      final clientesExistentes = await _db.getClientes();
      final Map<String, Cliente> mapaClientes = {};
      for (final c in clientesExistentes) {
        mapaClientes[c.nombre.trim().toLowerCase()] = c;
      }

      // Definición de los 10 Clientes de Prueba (5 Abono + 5 Ocasionales)
      final clientesSeed = <Cliente>[
        const Cliente(
          nombre: 'Carlos Gómez',
          telefono: '1145678912',
          direccion: 'Av. Mitre 1250',
          tipoCliente: Cliente.tipoAbono,
          frecuenciaAbono: Cliente.frec1VezMes,
          precioSugerido: 35000.0,
          observacion: 'Perro ovejero alemán en el fondo, llamar antes de entrar.',
        ),
        const Cliente(
          nombre: 'María Elena Rossi',
          telefono: '1123456789',
          direccion: 'Calle 14 N° 450',
          tipoCliente: Cliente.tipoAbono,
          frecuenciaAbono: Cliente.frec2VecesMes,
          precioSugerido: 28000.0,
          observacion: 'Corte de césped delantero y mantenimiento de pileta.',
        ),
        const Cliente(
          nombre: 'Roberto Sánchez',
          telefono: '1198765432',
          direccion: 'Av. 14 y Camino General Belgrano',
          tipoCliente: Cliente.tipoAbono,
          frecuenciaAbono: Cliente.frec3VecesMes,
          precioSugerido: 30000.0,
          observacion: 'Tocar timbre eléctrico fuerte, no funciona el portero.',
        ),
        const Cliente(
          nombre: 'Estudio Jurídico Albarracín',
          telefono: '1155443322',
          direccion: 'Mitre 890 Piso 2',
          tipoCliente: Cliente.tipoAbono,
          frecuenciaAbono: Cliente.frecSemanal,
          precioSugerido: 25000.0,
          observacion: 'Mantenimiento de jardín frontal y patio interno de oficinas.',
        ),
        const Cliente(
          nombre: 'Silvia Benítez',
          telefono: '1166778899',
          direccion: 'Los Pinos 340',
          tipoCliente: Cliente.tipoAbono,
          frecuenciaAbono: Cliente.frec2VecesMes,
          precioSugerido: 27000.0,
          observacion: 'Cuidado con plantas de lavanda delicadas.',
        ),
        const Cliente(
          nombre: 'Juan Carlos Pérez',
          telefono: '1133221100',
          direccion: 'Calle 158 N° 1200',
          tipoCliente: Cliente.tipoOcasional,
          frecuenciaAbono: Cliente.frecNinguna,
          precioSugerido: 45000.0,
          observacion: 'Poda de altura en árbol frutal.',
        ),
        const Cliente(
          nombre: 'Valeria Gómez',
          telefono: '1177889900',
          direccion: 'Diagonal 73 N° 550',
          tipoCliente: Cliente.tipoOcasional,
          frecuenciaAbono: Cliente.frecNinguna,
          precioSugerido: 50000.0,
          observacion: 'Limpieza general de terreno baldío.',
        ),
        const Cliente(
          nombre: 'Marcelo Duarte',
          telefono: '1144332211',
          direccion: 'Belgrano 2100',
          tipoCliente: Cliente.tipoOcasional,
          frecuenciaAbono: Cliente.frecNinguna,
          precioSugerido: 40000.0,
          observacion: 'Colocación de césped en panes.',
        ),
        const Cliente(
          nombre: 'Andrea Roldán',
          telefono: '1122114455',
          direccion: 'San Martín 670',
          tipoCliente: Cliente.tipoOcasional,
          frecuenciaAbono: Cliente.frecNinguna,
          precioSugerido: 35000.0,
          observacion: 'Desmalezado completo.',
        ),
        const Cliente(
          nombre: 'Héctor Navarro',
          telefono: '1188992233',
          direccion: '25 de Mayo 110',
          tipoCliente: Cliente.tipoOcasional,
          frecuenciaAbono: Cliente.frecNinguna,
          precioSugerido: 25000.0,
          observacion: 'Retirar restos de poda acumulados.',
        ),
      ];

      // Insertar clientes si sembrarClientes es true o si no existen
      for (final c in clientesSeed) {
        final key = c.nombre.trim().toLowerCase();
        if (!mapaClientes.containsKey(key)) {
          if (sembrarClientes) {
            final nuevoId = await _db.insertCliente(c);
            final clienteGuardado = c.copyWith(id: nuevoId);
            mapaClientes[key] = clienteGuardado;
            clientesCreados++;
          }
        }
      }

      // 2. Verificar si se deben sembrar servicios
      final pendientesActuales = await _db.getServiciosPendientes();
      final completadosActuales = await _db.getServiciosCompletados();
      final bool hayServiciosEnDb =
          pendientesActuales.isNotEmpty || completadosActuales.isNotEmpty;

      if (!hayServiciosEnDb || forzarServicios) {
        // Función auxiliar para obtener ID y datos actualizados del cliente
        Cliente? obtenerCliente(String nombre) {
          return mapaClientes[nombre.trim().toLowerCase()];
        }

        // 3. Inserción de Servicios Históricos (Septiembre, Octubre y Noviembre 2026)
        final serviciosHistoricos = <Servicio>[
          // --- SEPTIEMBRE 2026 ---
          Servicio(
            clienteId: obtenerCliente('Carlos Gómez')?.id,
            clienteNombre: 'Carlos Gómez',
            telefono: obtenerCliente('Carlos Gómez')?.telefono ?? '1145678912',
            direccion: obtenerCliente('Carlos Gómez')?.direccion ?? 'Av. Mitre 1250',
            fechaServicio: DateTime(2026, 9, 5, 9, 0),
            montoCobrado: 35000.0,
            estado: Servicio.estadoCompletado,
            observacion: 'Corte mensual y perfilado de bordes.',
          ),
          Servicio(
            clienteId: obtenerCliente('Estudio Jurídico Albarracín')?.id,
            clienteNombre: 'Estudio Jurídico Albarracín',
            telefono: obtenerCliente('Estudio Jurídico Albarracín')?.telefono ?? '1155443322',
            direccion: obtenerCliente('Estudio Jurídico Albarracín')?.direccion ?? 'Mitre 890 Piso 2',
            fechaServicio: DateTime(2026, 9, 7, 14, 0),
            montoCobrado: 25000.0,
            estado: Servicio.estadoCompletado,
            observacion: 'Mantenimiento semanal regular.',
          ),
          Servicio(
            clienteId: obtenerCliente('María Elena Rossi')?.id,
            clienteNombre: 'María Elena Rossi',
            telefono: obtenerCliente('María Elena Rossi')?.telefono ?? '1123456789',
            direccion: obtenerCliente('María Elena Rossi')?.direccion ?? 'Calle 14 N° 450',
            fechaServicio: DateTime(2026, 9, 12, 10, 30),
            montoCobrado: 28000.0,
            estado: Servicio.estadoCompletado,
            observacion: 'Limpieza de hojas en perímetro de pileta.',
          ),
          Servicio(
            clienteId: obtenerCliente('Juan Carlos Pérez')?.id,
            clienteNombre: 'Juan Carlos Pérez',
            telefono: obtenerCliente('Juan Carlos Pérez')?.telefono ?? '1133221100',
            direccion: obtenerCliente('Juan Carlos Pérez')?.direccion ?? 'Calle 158 N° 1200',
            fechaServicio: DateTime(2026, 9, 18, 8, 30),
            montoCobrado: 45000.0,
            estado: Servicio.estadoCompletado,
            observacion: 'Poda de altura en nogal y manzano.',
          ),
          Servicio(
            clienteId: obtenerCliente('Estudio Jurídico Albarracín')?.id,
            clienteNombre: 'Estudio Jurídico Albarracín',
            telefono: obtenerCliente('Estudio Jurídico Albarracín')?.telefono ?? '1155443322',
            direccion: obtenerCliente('Estudio Jurídico Albarracín')?.direccion ?? 'Mitre 890 Piso 2',
            fechaServicio: DateTime(2026, 9, 21, 14, 0),
            montoCobrado: 25000.0,
            estado: Servicio.estadoCompletado,
            observacion: 'Poda de canteros y limpieza.',
          ),
          Servicio(
            clienteId: obtenerCliente('Silvia Benítez')?.id,
            clienteNombre: 'Silvia Benítez',
            telefono: obtenerCliente('Silvia Benítez')?.telefono ?? '1166778899',
            direccion: obtenerCliente('Silvia Benítez')?.direccion ?? 'Los Pinos 340',
            fechaServicio: DateTime(2026, 9, 25, 11, 0),
            montoCobrado: 27000.0,
            estado: Servicio.estadoCompletado,
            observacion: 'Cuidado especial en sector lavandas.',
          ),

          // --- OCTUBRE 2026 ---
          Servicio(
            clienteId: obtenerCliente('Carlos Gómez')?.id,
            clienteNombre: 'Carlos Gómez',
            telefono: obtenerCliente('Carlos Gómez')?.telefono ?? '1145678912',
            direccion: obtenerCliente('Carlos Gómez')?.direccion ?? 'Av. Mitre 1250',
            fechaServicio: DateTime(2026, 10, 3, 9, 0),
            montoCobrado: 35000.0,
            estado: Servicio.estadoCompletado,
            observacion: 'Corte mensual de césped.',
          ),
          Servicio(
            clienteId: obtenerCliente('Roberto Sánchez')?.id,
            clienteNombre: 'Roberto Sánchez',
            telefono: obtenerCliente('Roberto Sánchez')?.telefono ?? '1198765432',
            direccion: obtenerCliente('Roberto Sánchez')?.direccion ?? 'Av. 14 y Camino General Belgrano',
            fechaServicio: DateTime(2026, 10, 6, 15, 30),
            montoCobrado: 30000.0,
            estado: Servicio.estadoCompletado,
            observacion: 'Desmalezado de vereda y frente.',
          ),
          Servicio(
            clienteId: obtenerCliente('María Elena Rossi')?.id,
            clienteNombre: 'María Elena Rossi',
            telefono: obtenerCliente('María Elena Rossi')?.telefono ?? '1123456789',
            direccion: obtenerCliente('María Elena Rossi')?.direccion ?? 'Calle 14 N° 450',
            fechaServicio: DateTime(2026, 10, 10, 10, 30),
            montoCobrado: 28000.0,
            estado: Servicio.estadoCompletado,
            observacion: 'Mantenimiento quincenal de abono.',
          ),
          Servicio(
            clienteId: obtenerCliente('Marcelo Duarte')?.id,
            clienteNombre: 'Marcelo Duarte',
            telefono: obtenerCliente('Marcelo Duarte')?.telefono ?? '1144332211',
            direccion: obtenerCliente('Marcelo Duarte')?.direccion ?? 'Belgrano 2100',
            fechaServicio: DateTime(2026, 10, 14, 9, 0),
            montoCobrado: 40000.0,
            estado: Servicio.estadoCompletado,
            observacion: 'Colocación y nivelación de panes de césped.',
          ),
          Servicio(
            clienteId: obtenerCliente('Estudio Jurídico Albarracín')?.id,
            clienteNombre: 'Estudio Jurídico Albarracín',
            telefono: obtenerCliente('Estudio Jurídico Albarracín')?.telefono ?? '1155443322',
            direccion: obtenerCliente('Estudio Jurídico Albarracín')?.direccion ?? 'Mitre 890 Piso 2',
            fechaServicio: DateTime(2026, 10, 19, 14, 0),
            montoCobrado: 25000.0,
            estado: Servicio.estadoCompletado,
            observacion: 'Mantenimiento semanal regular.',
          ),
          Servicio(
            clienteId: obtenerCliente('Silvia Benítez')?.id,
            clienteNombre: 'Silvia Benítez',
            telefono: obtenerCliente('Silvia Benítez')?.telefono ?? '1166778899',
            direccion: obtenerCliente('Silvia Benítez')?.direccion ?? 'Los Pinos 340',
            fechaServicio: DateTime(2026, 10, 24, 11, 0),
            montoCobrado: 27000.0,
            estado: Servicio.estadoCompletado,
            observacion: 'Poda de rosales y lavandas.',
          ),
          Servicio(
            clienteId: obtenerCliente('Valeria Gómez')?.id,
            clienteNombre: 'Valeria Gómez',
            telefono: obtenerCliente('Valeria Gómez')?.telefono ?? '1177889900',
            direccion: obtenerCliente('Valeria Gómez')?.direccion ?? 'Diagonal 73 N° 550',
            fechaServicio: DateTime(2026, 10, 28, 8, 0),
            montoCobrado: 50000.0,
            estado: Servicio.estadoCompletado,
            observacion: 'Desmalezado completo y limpieza de escombros de lote.',
          ),

          // --- NOVIEMBRE 2026 (Principios de mes completados) ---
          Servicio(
            clienteId: obtenerCliente('Carlos Gómez')?.id,
            clienteNombre: 'Carlos Gómez',
            telefono: obtenerCliente('Carlos Gómez')?.telefono ?? '1145678912',
            direccion: obtenerCliente('Carlos Gómez')?.direccion ?? 'Av. Mitre 1250',
            fechaServicio: DateTime(2026, 11, 2, 9, 0),
            montoCobrado: 35000.0,
            estado: Servicio.estadoCompletado,
            observacion: 'Abono mensual noviembre.',
          ),
          Servicio(
            clienteId: obtenerCliente('Estudio Jurídico Albarracín')?.id,
            clienteNombre: 'Estudio Jurídico Albarracín',
            telefono: obtenerCliente('Estudio Jurídico Albarracín')?.telefono ?? '1155443322',
            direccion: obtenerCliente('Estudio Jurídico Albarracín')?.direccion ?? 'Mitre 890 Piso 2',
            fechaServicio: DateTime(2026, 11, 4, 14, 0),
            montoCobrado: 25000.0,
            estado: Servicio.estadoCompletado,
            observacion: 'Mantenimiento primera semana nov.',
          ),
          Servicio(
            clienteId: obtenerCliente('Roberto Sánchez')?.id,
            clienteNombre: 'Roberto Sánchez',
            telefono: obtenerCliente('Roberto Sánchez')?.telefono ?? '1198765432',
            direccion: obtenerCliente('Roberto Sánchez')?.direccion ?? 'Av. 14 y Camino General Belgrano',
            fechaServicio: DateTime(2026, 11, 8, 15, 30),
            montoCobrado: 30000.0,
            estado: Servicio.estadoCompletado,
            observacion: 'Corte de pasto y limpieza de vereda.',
          ),
          Servicio(
            clienteId: obtenerCliente('María Elena Rossi')?.id,
            clienteNombre: 'María Elena Rossi',
            telefono: obtenerCliente('María Elena Rossi')?.telefono ?? '1123456789',
            direccion: obtenerCliente('María Elena Rossi')?.direccion ?? 'Calle 14 N° 450',
            fechaServicio: DateTime(2026, 11, 11, 10, 30),
            montoCobrado: 28000.0,
            estado: Servicio.estadoCompletado,
            observacion: 'Primera visita quincenal de nov.',
          ),
          Servicio(
            clienteId: obtenerCliente('Andrea Roldán')?.id,
            clienteNombre: 'Andrea Roldán',
            telefono: obtenerCliente('Andrea Roldán')?.telefono ?? '1122114455',
            direccion: obtenerCliente('Andrea Roldán')?.direccion ?? 'San Martín 670',
            fechaServicio: DateTime(2026, 11, 13, 9, 30),
            montoCobrado: 35000.0,
            estado: Servicio.estadoCompletado,
            observacion: 'Desmalezado general de patio trasero.',
          ),
        ];

        for (final s in serviciosHistoricos) {
          await _db.insertServicio(s);
          serviciosCompletadosCreados++;
        }

        // 4. Inserción de Servicios Futuros y Actuales (PENDIENTES con alarmas)
        final serviciosPendientes = <Servicio>[
          // Noviembre 2026 (Futuros)
          Servicio(
            clienteId: obtenerCliente('Silvia Benítez')?.id,
            clienteNombre: 'Silvia Benítez',
            telefono: obtenerCliente('Silvia Benítez')?.telefono ?? '1166778899',
            direccion: obtenerCliente('Silvia Benítez')?.direccion ?? 'Los Pinos 340',
            fechaServicio: DateTime(2026, 11, 16, 9, 30),
            montoCobrado: 27000.0,
            minutosAnticipacion: 15,
            estado: Servicio.estadoPendiente,
            observacion: 'Cuidado con plantas de lavanda delicadas.',
          ),
          Servicio(
            clienteId: obtenerCliente('Estudio Jurídico Albarracín')?.id,
            clienteNombre: 'Estudio Jurídico Albarracín',
            telefono: obtenerCliente('Estudio Jurídico Albarracín')?.telefono ?? '1155443322',
            direccion: obtenerCliente('Estudio Jurídico Albarracín')?.direccion ?? 'Mitre 890 Piso 2',
            fechaServicio: DateTime(2026, 11, 18, 14, 0),
            montoCobrado: 25000.0,
            minutosAnticipacion: 60,
            estado: Servicio.estadoPendiente,
            observacion: 'Mantenimiento de jardín frontal y patio interno de oficinas.',
          ),
          Servicio(
            clienteId: obtenerCliente('Andrea Roldán')?.id,
            clienteNombre: 'Andrea Roldán',
            telefono: obtenerCliente('Andrea Roldán')?.telefono ?? '1122114455',
            direccion: obtenerCliente('Andrea Roldán')?.direccion ?? 'San Martín 670',
            fechaServicio: DateTime(2026, 11, 20, 8, 30),
            montoCobrado: 35000.0,
            minutosAnticipacion: 30,
            estado: Servicio.estadoPendiente,
            observacion: 'Desmalezado completo de fondo.',
          ),
          Servicio(
            clienteId: obtenerCliente('Roberto Sánchez')?.id,
            clienteNombre: 'Roberto Sánchez',
            telefono: obtenerCliente('Roberto Sánchez')?.telefono ?? '1198765432',
            direccion: obtenerCliente('Roberto Sánchez')?.direccion ?? 'Av. 14 y Camino General Belgrano',
            fechaServicio: DateTime(2026, 11, 23, 15, 30),
            montoCobrado: 30000.0,
            minutosAnticipacion: 30,
            estado: Servicio.estadoPendiente,
            observacion: 'Tocar timbre eléctrico fuerte, no funciona el portero.',
          ),
          Servicio(
            clienteId: obtenerCliente('María Elena Rossi')?.id,
            clienteNombre: 'María Elena Rossi',
            telefono: obtenerCliente('MaríaElena Rossi')?.telefono ?? '1123456789',
            direccion: obtenerCliente('María Elena Rossi')?.direccion ?? 'Calle 14 N° 450',
            fechaServicio: DateTime(2026, 11, 26, 10, 30),
            montoCobrado: 28000.0,
            minutosAnticipacion: 60,
            estado: Servicio.estadoPendiente,
            observacion: 'Corte de césped delantero y mantenimiento de pileta.',
          ),
          Servicio(
            clienteId: obtenerCliente('Héctor Navarro')?.id,
            clienteNombre: 'Héctor Navarro',
            telefono: obtenerCliente('Héctor Navarro')?.telefono ?? '1188992233',
            direccion: obtenerCliente('Héctor Navarro')?.direccion ?? '25 de Mayo 110',
            fechaServicio: DateTime(2026, 11, 28, 11, 0),
            montoCobrado: 25000.0,
            minutosAnticipacion: 15,
            estado: Servicio.estadoPendiente,
            observacion: 'Retirar restos de poda acumulados.',
          ),

          // Diciembre 2026 (Futuros)
          Servicio(
            clienteId: obtenerCliente('Carlos Gómez')?.id,
            clienteNombre: 'Carlos Gómez',
            telefono: obtenerCliente('Carlos Gómez')?.telefono ?? '1145678912',
            direccion: obtenerCliente('Carlos Gómez')?.direccion ?? 'Av. Mitre 1250',
            fechaServicio: DateTime(2026, 12, 2, 9, 0),
            montoCobrado: 35000.0,
            minutosAnticipacion: 60,
            estado: Servicio.estadoPendiente,
            observacion: 'Perro ovejero alemán en el fondo, llamar antes de entrar.',
          ),
          Servicio(
            clienteId: obtenerCliente('Estudio Jurídico Albarracín')?.id,
            clienteNombre: 'Estudio Jurídico Albarracín',
            telefono: obtenerCliente('Estudio Jurídico Albarracín')?.telefono ?? '1155443322',
            direccion: obtenerCliente('Estudio Jurídico Albarracín')?.direccion ?? 'Mitre 890 Piso 2',
            fechaServicio: DateTime(2026, 12, 5, 14, 0),
            montoCobrado: 25000.0,
            minutosAnticipacion: 60,
            estado: Servicio.estadoPendiente,
            observacion: 'Mantenimiento de jardín frontal y patio interno de oficinas.',
          ),
          Servicio(
            clienteId: obtenerCliente('Silvia Benítez')?.id,
            clienteNombre: 'Silvia Benítez',
            telefono: obtenerCliente('Silvia Benítez')?.telefono ?? '1166778899',
            direccion: obtenerCliente('Silvia Benítez')?.direccion ?? 'Los Pinos 340',
            fechaServicio: DateTime(2026, 12, 10, 9, 30),
            montoCobrado: 27000.0,
            minutosAnticipacion: 30,
            estado: Servicio.estadoPendiente,
            observacion: 'Cuidado con plantas de lavanda delicadas.',
          ),
          Servicio(
            clienteId: obtenerCliente('Juan Carlos Pérez')?.id,
            clienteNombre: 'Juan Carlos Pérez',
            telefono: obtenerCliente('Juan Carlos Pérez')?.telefono ?? '1133221100',
            direccion: obtenerCliente('Juan Carlos Pérez')?.direccion ?? 'Calle 158 N° 1200',
            fechaServicio: DateTime(2026, 12, 14, 8, 30),
            montoCobrado: 45000.0,
            minutosAnticipacion: 60,
            estado: Servicio.estadoPendiente,
            observacion: 'Revisión y curación de árboles frutales.',
          ),
          Servicio(
            clienteId: obtenerCliente('Valeria Gómez')?.id,
            clienteNombre: 'Valeria Gómez',
            telefono: obtenerCliente('Valeria Gómez')?.telefono ?? '1177889900',
            direccion: obtenerCliente('Valeria Gómez')?.direccion ?? 'Diagonal 73 N° 550',
            fechaServicio: DateTime(2026, 12, 18, 10, 0),
            montoCobrado: 50000.0,
            minutosAnticipacion: 30,
            estado: Servicio.estadoPendiente,
            observacion: 'Limpieza y emparejado de tierra negra.',
          ),
        ];

        for (final s in serviciosPendientes) {
          final idGen = await _db.insertServicio(s);
          final servicioConId = s.copyWith(id: idGen);
          serviciosPendientesCreados++;

          // Programar alarma si el servicio está en el futuro (de forma segura)
          if (servicioConId.fechaServicio.isAfter(DateTime.now())) {
            try {
              await _notif.scheduleServicioAlarma(servicioConId);
            } catch (errAlarma) {
              print('Nota: No se pudo programar alarma para servicio ${servicioConId.id}: $errAlarma');
            }
          }
        }
      }

      print(
        'SeederService finalizado: '
        '$clientesCreados clientes nuevos, '
        '$serviciosCompletadosCreados servicios completados, '
        '$serviciosPendientesCreados servicios pendientes creados.',
      );

      return {
        'clientes': clientesCreados,
        'completados': serviciosCompletadosCreados,
        'pendientes': serviciosPendientesCreados,
      };
    } catch (e) {
      print('Advertencia ejecutando SeederService: $e');
      return {
        'clientes': clientesCreados,
        'completados': serviciosCompletadosCreados,
        'pendientes': serviciosPendientesCreados,
      };
    }
  }
}
