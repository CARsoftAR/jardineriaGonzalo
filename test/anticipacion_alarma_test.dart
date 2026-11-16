import 'package:test/test.dart';
import 'package:jardineria_gonzalo/models/servicio_model.dart';

void main() {
  group('Cálculo de Anticipación y Fecha de Alarma', () {
    test('Servicio con 5 minutos de anticipación calcula fecha exacta', () {
      final base = DateTime(2026, 11, 20, 15, 30);
      final servicio = Servicio(
        id: 1,
        clienteNombre: 'Gonzalo Jardin',
        direccion: 'Calle Verde 123',
        fechaServicio: base,
        minutosAnticipacion: 5,
      );

      final fechaAlarmaCalculada =
          servicio.fechaServicio.subtract(Duration(minutes: servicio.minutosAnticipacion));

      expect(fechaAlarmaCalculada, DateTime(2026, 11, 20, 15, 25));
      expect(servicio.fechaAlarma, DateTime(2026, 11, 20, 15, 25));
    });

    test('Servicio con 2 días y 4 horas (3120 min) calcula fecha exacta', () {
      final base = DateTime(2026, 11, 20, 15, 30);
      const minutosTotales = (2 * 1440) + (4 * 60); // 2880 + 240 = 3120
      final servicio = Servicio(
        id: 2,
        clienteNombre: 'Maria Bosque',
        direccion: 'Av. Siempre Viva 742',
        fechaServicio: base,
        minutosAnticipacion: minutosTotales,
      );

      final fechaAlarma = servicio.fechaAlarma;
      expect(fechaAlarma, DateTime(2026, 11, 18, 11, 30));
    });

    test('Anticipación cero hace sonar la alarma al momento del servicio', () {
      final base = DateTime(2026, 11, 20, 15, 30);
      final servicio = Servicio(
        id: 3,
        clienteNombre: 'Pedro Huerta',
        direccion: 'Pasaje Florido 44',
        fechaServicio: base,
        minutosAnticipacion: 0,
      );

      expect(servicio.fechaAlarma, base);
    });

    test('Lógica de contingencia: si la fechaAlarma ya pasó pero el servicio es futuro', () {
      final now = DateTime.now();
      // Servicio en 15 minutos, con anticipación de 60 minutos
      final fechaServicio = now.add(const Duration(minutes: 15));
      const minutosAnticipacion = 60;
      final fechaAlarma = fechaServicio.subtract(const Duration(minutes: minutosAnticipacion));

      // La fecha calculada está en el pasado
      expect(fechaAlarma.isBefore(now), isTrue);
      // Pero el servicio es en el futuro
      expect(fechaServicio.isAfter(now), isTrue);

      // Simulación del algoritmo implementado en NotificationService:
      DateTime fechaEfectivaAlarma;
      if (!fechaAlarma.isAfter(now.add(const Duration(seconds: 10)))) {
        fechaEfectivaAlarma = now.add(const Duration(seconds: 30));
      } else {
        fechaEfectivaAlarma = fechaAlarma;
      }

      // La fecha efectiva forzada debe ser estrictamente en el futuro (30 seg)
      expect(fechaEfectivaAlarma.isAfter(now), isTrue);
      expect(fechaEfectivaAlarma.difference(now).inSeconds, closeTo(30, 2));
    });
  });
}
