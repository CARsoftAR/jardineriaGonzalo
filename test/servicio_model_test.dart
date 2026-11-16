import 'package:test/test.dart';
import 'package:jardineria_gonzalo/models/servicio_model.dart';

void main() {
  group('Servicio Model Tests', () {
    final now = DateTime(2026, 11, 15, 10, 30);

    test('Instanciación con valores por defecto', () {
      final servicio = Servicio(
        clienteNombre: 'Carlos Mendez',
        direccion: 'Calle Los Pinos 450',
        fechaServicio: now,
      );

      expect(servicio.id, isNull);
      expect(servicio.clienteNombre, 'Carlos Mendez');
      expect(servicio.telefono, isNull);
      expect(servicio.tieneTelefono, isFalse);
      expect(servicio.direccion, 'Calle Los Pinos 450');
      expect(servicio.fechaServicio, now);
      expect(servicio.montoCobrado, 0.0);
      expect(servicio.estado, Servicio.estadoPendiente);
      expect(servicio.minutosAnticipacion, 60);
      expect(servicio.observacion, isNull);
      expect(servicio.tieneObservacion, isFalse);
      expect(servicio.isPendiente, isTrue);
      expect(servicio.isCompletado, isFalse);
    });

    test('Cálculo correcto de fechaAlarma', () {
      final servicio = Servicio(
        clienteNombre: 'Ana Lopez',
        direccion: 'Av. Las Palmas 12',
        fechaServicio: now,
        minutosAnticipacion: 300, // 5 horas antes
      );

      final fechaAlarmaEsperada = now.subtract(const Duration(minutes: 300));
      expect(servicio.fechaAlarma, equals(fechaAlarmaEsperada));
    });

    test('Serialización toMap() y deserialización fromMap() con teléfono y observación', () {
      final servicioOriginal = Servicio(
        id: 1,
        clienteNombre: 'Valeria Rossi',
        telefono: '+56912345678',
        direccion: 'Pasaje Roble 99',
        fechaServicio: now,
        montoCobrado: 45000.0,
        estado: Servicio.estadoCompletado,
        minutosAnticipacion: 1440,
        observacion: 'Tocar timbre del portón negro.',
      );

      final map = servicioOriginal.toMap();
      expect(map['id'], 1);
      expect(map['clienteNombre'], 'Valeria Rossi');
      expect(map['telefono'], '+56912345678');
      expect(map['direccion'], 'Pasaje Roble 99');
      expect(map['fechaServicio'], now.toIso8601String());
      expect(map['montoCobrado'], 45000.0);
      expect(map['estado'], Servicio.estadoCompletado);
      expect(map['minutosAnticipacion'], 1440);
      expect(map['observacion'], 'Tocar timbre del portón negro.');

      final servicioReconstruido = Servicio.fromMap(map);
      expect(servicioReconstruido, equals(servicioOriginal));
      expect(servicioReconstruido.tieneTelefono, isTrue);
      expect(servicioReconstruido.tieneObservacion, isTrue);
      expect(servicioReconstruido.isCompletado, isTrue);
      expect(servicioReconstruido.isPendiente, isFalse);
    });

    test('Inmutabilidad y copyWith() con cambio de fecha, hora y observación', () {
      final servicioOriginal = Servicio(
        id: 2,
        clienteNombre: 'Esteban Paz',
        direccion: 'Calle 10 Nro 20',
        fechaServicio: DateTime(2026, 11, 15, 16, 41),
      );

      final nuevaFechaHora = DateTime(2026, 11, 18, 09, 15);
      final servicioModificado = servicioOriginal.copyWith(
        fechaServicio: nuevaFechaHora,
        minutosAnticipacion: 300,
        observacion: 'Llevar orilladora y tijeras de podar.',
      );

      expect(servicioOriginal.fechaServicio, DateTime(2026, 11, 15, 16, 41));
      expect(servicioOriginal.observacion, isNull);
      expect(servicioModificado.fechaServicio, nuevaFechaHora);
      expect(servicioModificado.minutosAnticipacion, 300);
      expect(servicioModificado.id, 2);
      expect(servicioModificado.observacion, 'Llevar orilladora y tijeras de podar.');
      expect(servicioModificado.tieneObservacion, isTrue);
      expect(servicioModificado.fechaAlarma, nuevaFechaHora.subtract(const Duration(minutes: 300)));
    });
  });
}
