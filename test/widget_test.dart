import 'package:test/test.dart';
import 'package:jardineria_gonzalo/models/servicio_model.dart';

void main() {
  test('Smoke Test inicial de modelo Servicio', () {
    final servicio = Servicio(
      clienteNombre: 'Gonzalo',
      direccion: 'Av. Jardines 100',
      fechaServicio: DateTime(2026, 11, 15, 14, 0),
    );
    expect(servicio.clienteNombre, 'Gonzalo');
    expect(servicio.isPendiente, isTrue);
  });
}
