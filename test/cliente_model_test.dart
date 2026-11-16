import 'package:test/test.dart';
import 'package:jardineria_gonzalo/models/cliente_model.dart';

void main() {
  group('Cliente Model Tests', () {
    test('Creación de cliente ocasional por defecto', () {
      const cliente = Cliente(
        nombre: 'Gonzalo Silva',
        direccion: 'Av. Primavera 123',
      );

      expect(cliente.id, isNull);
      expect(cliente.nombre, 'Gonzalo Silva');
      expect(cliente.direccion, 'Av. Primavera 123');
      expect(cliente.tipoCliente, Cliente.tipoOcasional);
      expect(cliente.frecuenciaAbono, Cliente.frecNinguna);
      expect(cliente.isAbono, isFalse);
      expect(cliente.tieneTelefono, isFalse);
      expect(cliente.tieneObservacion, isFalse);
      expect(cliente.precioSugerido, 0.0);
    });

    test('Creación de cliente con abono semanal y observaciones', () {
      const cliente = Cliente(
        id: 10,
        nombre: 'Marta Fernandez',
        telefono: '+56987654321',
        direccion: 'Condominio Los Cerezos Casa 4',
        tipoCliente: Cliente.tipoAbono,
        frecuenciaAbono: Cliente.frecSemanal,
        precioSugerido: 25000.0,
        observacion: 'Perro suelto en el patio, tocar timbre negro.',
      );

      expect(cliente.id, 10);
      expect(cliente.isAbono, isTrue);
      expect(cliente.tieneTelefono, isTrue);
      expect(cliente.tieneObservacion, isTrue);
      expect(cliente.observacion, 'Perro suelto en el patio, tocar timbre negro.');
      expect(cliente.diasIntervaloAbono, 7);
      expect(cliente.visitasSugeridasAlMes, 4);
    });

    test('Cálculo de intervalos para las 4 frecuencias de abono por mes', () {
      const mensual = Cliente(
        nombre: 'Lucia Hiriart',
        direccion: 'Los Álamos 9',
        tipoCliente: Cliente.tipoAbono,
        frecuenciaAbono: Cliente.frec1VezMes,
      );
      expect(mensual.diasIntervaloAbono, 30);
      expect(mensual.visitasSugeridasAlMes, 1);

      const quincenal = Cliente(
        nombre: 'Pedro Pascal',
        direccion: 'Calle Sol 44',
        tipoCliente: Cliente.tipoAbono,
        frecuenciaAbono: Cliente.frec2VecesMes,
      );
      expect(quincenal.diasIntervaloAbono, 15);
      expect(quincenal.visitasSugeridasAlMes, 2);

      const tresVeces = Cliente(
        nombre: 'Andres Bello',
        direccion: 'Calle Luna 100',
        tipoCliente: Cliente.tipoAbono,
        frecuenciaAbono: Cliente.frec3VecesMes,
      );
      expect(tresVeces.diasIntervaloAbono, 10);
      expect(tresVeces.visitasSugeridasAlMes, 3);

      const semanal = Cliente(
        nombre: 'Claudio Arrau',
        direccion: 'Av. Las Condes 500',
        tipoCliente: Cliente.tipoAbono,
        frecuenciaAbono: Cliente.frecSemanal,
      );
      expect(semanal.diasIntervaloAbono, 7);
      expect(semanal.visitasSugeridasAlMes, 4);
    });

    test('Serialización toMap() y deserialización fromMap() con observacion', () {
      const original = Cliente(
        id: 5,
        nombre: 'Roberto Gómez',
        telefono: '99887766',
        direccion: 'Pasaje Vecinal 88',
        tipoCliente: Cliente.tipoAbono,
        frecuenciaAbono: Cliente.frec2VecesMes,
        precioSugerido: 18000.0,
        observacion: 'Llevar orilladora.',
      );

      final map = original.toMap();
      expect(map['id'], 5);
      expect(map['nombre'], 'Roberto Gómez');
      expect(map['telefono'], '99887766');
      expect(map['direccion'], 'Pasaje Vecinal 88');
      expect(map['tipoCliente'], Cliente.tipoAbono);
      expect(map['frecuenciaAbono'], Cliente.frec2VecesMes);
      expect(map['precioSugerido'], 18000.0);
      expect(map['observacion'], 'Llevar orilladora.');

      final reconstruido = Cliente.fromMap(map);
      expect(reconstruido, equals(original));
      expect(reconstruido.tieneObservacion, isTrue);
    });

    test('Inmutabilidad y copyWith() con campo observacion', () {
      const original = Cliente(
        id: 1,
        nombre: 'Original Name',
        direccion: 'Dir 1',
        tipoCliente: Cliente.tipoOcasional,
      );

      final modificado = original.copyWith(
        tipoCliente: Cliente.tipoAbono,
        frecuenciaAbono: Cliente.frecSemanal,
        precioSugerido: 22000.0,
        observacion: 'Cuidado con el cerco vivo.',
      );

      expect(original.tipoCliente, Cliente.tipoOcasional);
      expect(original.observacion, isNull);
      expect(modificado.tipoCliente, Cliente.tipoAbono);
      expect(modificado.frecuenciaAbono, Cliente.frecSemanal);
      expect(modificado.precioSugerido, 22000.0);
      expect(modificado.observacion, 'Cuidado con el cerco vivo.');
    });
  });
}
