/// Modelo inmutable que representa un cliente de jardinería.
class Cliente {
  static const String tipoOcasional = 'OCASIONAL';
  static const String tipoAbono = 'ABONO';

  static const String frec1VezMes = '1 vez/mes'; // 1 visita al mes (cada 30 días)
  static const String frec2VecesMes = '2 veces/mes'; // 2 visitas al mes (cada 15 días)
  static const String frec3VecesMes = '3 veces/mes'; // 3 visitas al mes (cada 10 días)
  static const String frecSemanal = 'Semanal'; // 4 visitas al mes (cada 7 días)
  static const String frecNinguna = 'NINGUNA';

  // Alias de compatibilidad para registros previos
  static const String frecQuincenal = frec2VecesMes;
  static const String frecMensual = frec1VezMes;

  final int? id;
  final String nombre;
  final String? telefono;
  final String direccion;
  final String tipoCliente; // OCASIONAL o ABONO
  final String frecuenciaAbono; // '1 vez/mes', '2 veces/mes', '3 veces/mes', 'Semanal', 'NINGUNA'
  final double precioSugerido;
  final String? observacion;

  const Cliente({
    this.id,
    required this.nombre,
    this.telefono,
    required this.direccion,
    this.tipoCliente = tipoOcasional,
    this.frecuenciaAbono = frecNinguna,
    this.precioSugerido = 0.0,
    this.observacion,
  });

  /// Indica si el cliente tiene un plan de mantención recurrente (Abono).
  bool get isAbono => tipoCliente == tipoAbono;

  /// Retorna si el cliente cuenta con un número de teléfono registrado.
  bool get tieneTelefono => telefono != null && telefono!.trim().isNotEmpty;

  /// Retorna si el cliente cuenta con observaciones registradas.
  bool get tieneObservacion =>
      observacion != null && observacion!.trim().isNotEmpty;

  /// Retorna el intervalo en días sugerido según la frecuencia de abono.
  int get diasIntervaloAbono {
    switch (frecuenciaAbono) {
      case frecSemanal:
      case 'SEMANAL':
        return 7;
      case frec3VecesMes:
      case '3 VECES/MES':
        return 10;
      case frec2VecesMes:
      case '2 VECES/MES':
      case 'QUINCENAL':
        return 15;
      case frec1VezMes:
      case '1 VEZ/MES':
      case 'MENSUAL':
        return 30;
      default:
        return 0;
    }
  }

  /// Retorna la cantidad sugerida de visitas a generar para un mes completo.
  int get visitasSugeridasAlMes {
    switch (frecuenciaAbono) {
      case frecSemanal:
      case 'SEMANAL':
        return 4;
      case frec3VecesMes:
      case '3 VECES/MES':
        return 3;
      case frec2VecesMes:
      case '2 VECES/MES':
      case 'QUINCENAL':
        return 2;
      case frec1VezMes:
      case '1 VEZ/MES':
      case 'MENSUAL':
        return 1;
      default:
        return 1;
    }
  }

  /// Convierte la instancia a un Map para SQLite.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'nombre': nombre,
      'telefono': telefono,
      'direccion': direccion,
      'tipoCliente': tipoCliente,
      'frecuenciaAbono': frecuenciaAbono,
      'precioSugerido': precioSugerido,
      'observacion': observacion,
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  /// Construye una instancia a partir de un registro de SQLite.
  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id'] as int?,
      nombre: map['nombre'] as String? ?? '',
      telefono: map['telefono'] as String?,
      direccion: map['direccion'] as String? ?? '',
      tipoCliente: map['tipoCliente'] as String? ?? tipoOcasional,
      frecuenciaAbono: map['frecuenciaAbono'] as String? ?? frecNinguna,
      precioSugerido: (map['precioSugerido'] is num)
          ? (map['precioSugerido'] as num).toDouble()
          : 0.0,
      observacion: map['observacion'] as String?,
    );
  }

  /// Copia inmutable con modificaciones.
  Cliente copyWith({
    int? id,
    String? nombre,
    String? telefono,
    String? direccion,
    String? tipoCliente,
    String? frecuenciaAbono,
    double? precioSugerido,
    String? observacion,
  }) {
    return Cliente(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      tipoCliente: tipoCliente ?? this.tipoCliente,
      frecuenciaAbono: frecuenciaAbono ?? this.frecuenciaAbono,
      precioSugerido: precioSugerido ?? this.precioSugerido,
      observacion: observacion ?? this.observacion,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cliente &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nombre == other.nombre &&
          telefono == other.telefono &&
          direccion == other.direccion &&
          tipoCliente == other.tipoCliente &&
          frecuenciaAbono == other.frecuenciaAbono &&
          precioSugerido == other.precioSugerido &&
          observacion == other.observacion;

  @override
  int get hashCode =>
      id.hashCode ^
      nombre.hashCode ^
      telefono.hashCode ^
      direccion.hashCode ^
      tipoCliente.hashCode ^
      frecuenciaAbono.hashCode ^
      precioSugerido.hashCode ^
      (observacion?.hashCode ?? 0);
}
