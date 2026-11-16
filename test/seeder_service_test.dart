import 'package:test/test.dart';
import 'package:jardineria_gonzalo/models/cliente_model.dart';
import 'package:jardineria_gonzalo/models/servicio_model.dart';
import 'package:jardineria_gonzalo/services/seeder_service.dart';

void main() {
  group('SeederService Data Validation Tests', () {
    test('SeederService es un Singleton', () {
      final s1 = SeederService();
      final s2 = SeederService();
      expect(identical(s1, s2), isTrue);
    });

    test('Validación de estructura de clientes semilla', () {
      const c1 = Cliente(
        nombre: 'Carlos Gómez',
        telefono: '1145678912',
        direccion: 'Av. Mitre 1250',
        tipoCliente: Cliente.tipoAbono,
        frecuenciaAbono: Cliente.frec1VezMes,
        precioSugerido: 35000.0,
        observacion: 'Perro ovejero alemán en el fondo, llamar antes de entrar.',
      );

      expect(c1.isAbono, isTrue);
      expect(c1.precioSugerido, 35000.0);
      expect(c1.tieneObservacion, isTrue);
      expect(c1.observacion, contains('Perro ovejero alemán'));
    });

    test('Validación de estructura de servicios históricos de prueba (COMPLETADO)', () {
      final sHistorico = Servicio(
        clienteNombre: 'Carlos Gómez',
        telefono: '1145678912',
        direccion: 'Av. Mitre 1250',
        fechaServicio: DateTime(2026, 9, 5, 9, 0),
        montoCobrado: 35000.0,
        estado: Servicio.estadoCompletado,
        observacion: 'Corte mensual y perfilado de bordes.',
      );

      expect(sHistorico.isCompletado, isTrue);
      expect(sHistorico.isPendiente, isFalse);
      expect(sHistorico.montoCobrado, 35000.0);
      expect(sHistorico.fechaServicio.year, 2026);
      expect(sHistorico.fechaServicio.month, 9);
      expect(sHistorico.tieneObservacion, isTrue);
    });

    test('Validación de estructura de servicios futuros de prueba (PENDIENTE con alarma)', () {
      final sFuturo = Servicio(
        clienteNombre: 'Silvia Benítez',
        telefono: '1166778899',
        direccion: 'Los Pinos 340',
        fechaServicio: DateTime(2026, 11, 16, 9, 30),
        montoCobrado: 27000.0,
        minutosAnticipacion: 15,
        estado: Servicio.estadoPendiente,
        observacion: 'Cuidado con plantas de lavanda delicadas.',
      );

      expect(sFuturo.isPendiente, isTrue);
      expect(sFuturo.minutosAnticipacion, 15);
      expect(sFuturo.fechaAlarma, DateTime(2026, 11, 16, 9, 15));
      expect(sFuturo.tieneObservacion, isTrue);
    });
  });
}
