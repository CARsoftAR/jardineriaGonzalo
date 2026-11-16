/// Modelo inmutable que representa un servicio de jardinería.
class Servicio {
  static const String estadoPendiente = 'PENDIENTE';
  static const String estadoCompletado = 'COMPLETADO';

  final int? id;
  final int? clienteId;
  final String clienteNombre;
  final String? telefono;
  final String direccion;
  final DateTime fechaServicio;
  final double montoCobrado;
  final String estado;
  final int minutosAnticipacion;
  final String? observacion;

  const Servicio({
    this.id,
    this.clienteId,
    required this.clienteNombre,
    this.telefono,
    required this.direccion,
    required this.fechaServicio,
    this.montoCobrado = 0.0,
    this.estado = estadoPendiente,
    this.minutosAnticipacion = 60,
    this.observacion,
  });

  /// Indica si el servicio aún se encuentra en estado pendiente.
  bool get isPendiente => estado == estadoPendiente;

  /// Indica si el servicio ya ha sido completado.
  bool get isCompletado => estado == estadoCompletado;

  /// Retorna si el servicio cuenta con un número de teléfono registrado.
  bool get tieneTelefono => telefono != null && telefono!.trim().isNotEmpty;

  /// Retorna si el servicio cuenta con observaciones/instrucciones especiales.
  bool get tieneObservacion =>
      observacion != null && observacion!.trim().isNotEmpty;

  /// Retorna la fecha exacta programada para disparar la alarma/notificación previa.
  DateTime get fechaAlarma =>
      fechaServicio.subtract(Duration(minutes: minutosAnticipacion));

  /// Convierte la instancia a un [Map] adecuado para inserción/actualización en SQLite.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'clienteId': clienteId,
      'clienteNombre': clienteNombre,
      'telefono': telefono,
      'direccion': direccion,
      'fechaServicio': fechaServicio.toIso8601String(),
      'montoCobrado': montoCobrado,
      'estado': estado,
      'minutosAnticipacion': minutosAnticipacion,
      'observacion': observacion,
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  /// Construye una instancia de [Servicio] a partir de un registro de SQLite.
  factory Servicio.fromMap(Map<String, dynamic> map) {
    return Servicio(
      id: map['id'] as int?,
      clienteId: map['clienteId'] as int?,
      clienteNombre: map['clienteNombre'] as String? ?? '',
      telefono: map['telefono'] as String?,
      direccion: map['direccion'] as String? ?? '',
      fechaServicio: DateTime.tryParse(map['fechaServicio'] as String? ?? '') ??
          DateTime.now(),
      montoCobrado: (map['montoCobrado'] is num)
          ? (map['montoCobrado'] as num).toDouble()
          : 0.0,
      estado: map['estado'] as String? ?? estadoPendiente,
      minutosAnticipacion: (map['minutosAnticipacion'] is num)
          ? (map['minutosAnticipacion'] as num).toInt()
          : 60,
      observacion: map['observacion'] as String?,
    );
  }

  /// Genera una copia inmutable con los campos modificados especificados.
  Servicio copyWith({
    int? id,
    int? clienteId,
    String? clienteNombre,
    String? telefono,
    String? direccion,
    DateTime? fechaServicio,
    double? montoCobrado,
    String? estado,
    int? minutosAnticipacion,
    String? observacion,
  }) {
    return Servicio(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      fechaServicio: fechaServicio ?? this.fechaServicio,
      montoCobrado: montoCobrado ?? this.montoCobrado,
      estado: estado ?? this.estado,
      minutosAnticipacion: minutosAnticipacion ?? this.minutosAnticipacion,
      observacion: observacion ?? this.observacion,
    );
  }

  @override
  String toString() {
    return 'Servicio(id: $id, clienteId: $clienteId, clienteNombre: $clienteNombre, telefono: $telefono, '
        'direccion: $direccion, fechaServicio: $fechaServicio, '
        'montoCobrado: $montoCobrado, estado: $estado, '
        'minutosAnticipacion: $minutosAnticipacion, observacion: $observacion)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Servicio &&
        other.id == id &&
        other.clienteId == clienteId &&
        other.clienteNombre == clienteNombre &&
        other.telefono == telefono &&
        other.direccion == direccion &&
        other.fechaServicio == fechaServicio &&
        other.montoCobrado == montoCobrado &&
        other.estado == estado &&
        other.minutosAnticipacion == minutosAnticipacion &&
        other.observacion == observacion;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      clienteId,
      clienteNombre,
      telefono,
      direccion,
      fechaServicio,
      montoCobrado,
      estado,
      minutosAnticipacion,
      observacion,
    );
  }
}
