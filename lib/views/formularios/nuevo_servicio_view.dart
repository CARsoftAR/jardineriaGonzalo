import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/cliente_model.dart';
import '../../models/servicio_model.dart';
import '../../services/db_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/selector_anticipacion_widget.dart';

/// Formulario ergonómico y de alta legibilidad para programar y editar servicios de jardinería.
class NuevoServicioView extends StatefulWidget {
  final Servicio? servicioAEditar;
  final Cliente? clientePreseleccionado;

  const NuevoServicioView({
    super.key,
    this.servicioAEditar,
    this.clientePreseleccionado,
  });

  bool get esEdicion => servicioAEditar != null;

  @override
  State<NuevoServicioView> createState() => _NuevoServicioViewState();
}

class _NuevoServicioViewState extends State<NuevoServicioView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _clienteController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _direccionController;
  late final TextEditingController _presupuestoController;
  late final TextEditingController _observacionController;

  late DateTime _fechaSeleccionada;
  late TimeOfDay _horaSeleccionada;

  // Anticipación granular (Días, Horas, Minutos)
  late int _diasAnticipacion;
  late int _horasAnticipacion;
  late int _minutosAnticipacion;

  // Libreta de Clientes y Abonos
  List<Cliente> _clientesDisponibles = [];
  Cliente? _clienteSeleccionado;
  bool _autoprogramarAbono = false;
  int _visitasAbonoAGenerar = 1;
  int _intervaloDiasAbono = 7;

  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final editando = widget.servicioAEditar;
    if (editando != null) {
      _clienteController = TextEditingController(text: editando.clienteNombre);
      _telefonoController = TextEditingController(text: editando.telefono ?? '');
      _direccionController = TextEditingController(text: editando.direccion);
      _presupuestoController = TextEditingController(
        text: editando.montoCobrado > 0 ? editando.montoCobrado.toStringAsFixed(0) : '',
      );
      _observacionController = TextEditingController(text: editando.observacion ?? '');

      _fechaSeleccionada = editando.fechaServicio;
      _horaSeleccionada = TimeOfDay.fromDateTime(editando.fechaServicio);

      final total = editando.minutosAnticipacion;
      _diasAnticipacion = total ~/ 1440;
      _horasAnticipacion = (total % 1440) ~/ 60;
      _minutosAnticipacion = total % 60;
    } else {
      _clienteController = TextEditingController();
      _telefonoController = TextEditingController();
      _direccionController = TextEditingController();
      _presupuestoController = TextEditingController();
      _observacionController = TextEditingController(
        text: widget.clientePreseleccionado?.observacion ?? '',
      );

      _fechaSeleccionada = DateTime.now().add(const Duration(hours: 2));
      _horaSeleccionada = TimeOfDay.fromDateTime(
        DateTime.now().add(const Duration(hours: 2)),
      );

      _diasAnticipacion = 0;
      _horasAnticipacion = 1;
      _minutosAnticipacion = 0;
    }

    _cargarClientesDisponibles();
  }

  Future<void> _cargarClientesDisponibles() async {
    final clientes = await DbService().getClientes();
    if (mounted) {
      setState(() {
        _clientesDisponibles = clientes;
        if (widget.clientePreseleccionado != null) {
          final coincidente = _clientesDisponibles.firstWhere(
            (c) => c.id == widget.clientePreseleccionado!.id,
            orElse: () => widget.clientePreseleccionado!,
          );
          _aplicarClienteSeleccionado(coincidente);
        } else if (widget.servicioAEditar?.clienteId != null) {
          try {
            _clienteSeleccionado = _clientesDisponibles.firstWhere(
              (c) => c.id == widget.servicioAEditar!.clienteId,
            );
          } catch (_) {}
        }
      });
    }
  }

  void _aplicarClienteSeleccionado(Cliente? cliente) {
    setState(() {
      _clienteSeleccionado = cliente;
      if (cliente != null) {
        _clienteController.text = cliente.nombre;
        _telefonoController.text = cliente.telefono ?? '';
        _direccionController.text = cliente.direccion;
        if (cliente.precioSugerido > 0) {
          _presupuestoController.text = cliente.precioSugerido.toStringAsFixed(0);
        }
        // Autocompletado inteligente de observaciones guardadas del cliente
        if (cliente.tieneObservacion && _observacionController.text.trim().isEmpty) {
          _observacionController.text = cliente.observacion!;
        }
        if (cliente.isAbono && !widget.esEdicion) {
          _autoprogramarAbono = true;
          _visitasAbonoAGenerar = cliente.visitasSugeridasAlMes;
          _intervaloDiasAbono = cliente.diasIntervaloAbono;
        } else {
          _autoprogramarAbono = false;
        }
      }
    });
  }

  @override
  void dispose() {
    _clienteController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _presupuestoController.dispose();
    _observacionController.dispose();
    super.dispose();
  }

  /// Atajos de 1 toque para programar con una sola mano
  void _aplicarAtajoFecha(int diasDiferencia) {
    final base = DateTime.now().add(Duration(days: diasDiferencia));
    setState(() {
      _fechaSeleccionada = DateTime(
        base.year,
        base.month,
        base.day,
        _horaSeleccionada.hour,
        _horaSeleccionada.minute,
      );
    });
  }

  /// Selector nativo de fecha optimizado
  Future<void> _seleccionarFecha() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'SELECCIONA EL DÍA',
      cancelText: 'CANCELAR',
      confirmText: 'CONFIRMAR',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.forestGreen,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _fechaSeleccionada = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _horaSeleccionada.hour,
          _horaSeleccionada.minute,
        );
      });
    }
  }

  /// Selector nativo de hora
  Future<void> _seleccionarHora() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _horaSeleccionada,
      helpText: 'SELECCIONA LA HORA',
      cancelText: 'CANCELAR',
      confirmText: 'CONFIRMAR',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.forestGreen,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      setState(() {
        _horaSeleccionada = pickedTime;
        _fechaSeleccionada = DateTime(
          _fechaSeleccionada.year,
          _fechaSeleccionada.month,
          _fechaSeleccionada.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  Future<void> _guardarServicio() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {
      final montoTexto = _presupuestoController.text.trim();
      final double montoEstimado = montoTexto.isNotEmpty
          ? double.tryParse(montoTexto.replaceAll(',', '.')) ?? 0.0
          : 0.0;

      final int totalMinutosAnticipacion =
          (_diasAnticipacion * 1440) + (_horasAnticipacion * 60) + _minutosAnticipacion;

      final obsTexto = _observacionController.text.trim();
      final String? observacionFinal = obsTexto.isNotEmpty ? obsTexto : null;

      final dbService = DbService();
      final notifService = NotificationService();

      if (widget.esEdicion) {
        final original = widget.servicioAEditar!;
        final servicioActualizado = original.copyWith(
          clienteId: _clienteSeleccionado?.id ?? original.clienteId,
          clienteNombre: _clienteController.text.trim(),
          telefono: _telefonoController.text.trim().isNotEmpty
              ? _telefonoController.text.trim()
              : null,
          direccion: _direccionController.text.trim(),
          fechaServicio: _fechaSeleccionada,
          montoCobrado: montoEstimado,
          minutosAnticipacion: totalMinutosAnticipacion,
          observacion: observacionFinal,
        );

        final filas = await dbService.updateServicio(servicioActualizado);
        print('Servicio editado en DB con id ${servicioActualizado.id}, filas afectadas: $filas');

        // Reprogramar alarma de forma segura
        bool alarmaAgendada = false;
        if (servicioActualizado.id != null) {
          try {
            await notifService.cancelServicioAlarma(servicioActualizado.id!);
            alarmaAgendada =
                await notifService.scheduleServicioAlarma(servicioActualizado);
          } catch (notifErr) {
            print('Advertencia en notificación al editar: $notifErr');
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    alarmaAgendada ? Icons.alarm_on : Icons.check_circle_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Servicio de ${servicioActualizado.clienteNombre} actualizado.',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              backgroundColor: AppColors.forestGreen,
              duration: const Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        // Lógica de Abonos: Autoprogramar múltiples visitas recurrentes
        if (_autoprogramarAbono && _visitasAbonoAGenerar > 1) {
          int agendadosConAlarma = 0;

          for (int i = 0; i < _visitasAbonoAGenerar; i++) {
            final fechaVisita = _fechaSeleccionada.add(Duration(days: i * _intervaloDiasAbono));

            final nuevoServicio = Servicio(
              clienteId: _clienteSeleccionado?.id,
              clienteNombre: _clienteController.text.trim(),
              telefono: _telefonoController.text.trim().isNotEmpty
                  ? _telefonoController.text.trim()
                  : null,
              direccion: _direccionController.text.trim(),
              fechaServicio: fechaVisita,
              montoCobrado: montoEstimado,
              minutosAnticipacion: totalMinutosAnticipacion,
              estado: Servicio.estadoPendiente,
              observacion: observacionFinal,
            );

            final idGenerado = await dbService.insertServicio(nuevoServicio);
            final servicioConId = nuevoServicio.copyWith(id: idGenerado);
            final alarmaAgendada =
                await notifService.scheduleServicioAlarma(servicioConId);
            if (alarmaAgendada) agendadosConAlarma++;
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.repeat, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '¡Se programaron $_visitasAbonoAGenerar visitas de abono ($agendadosConAlarma con alarma) para ${_clienteController.text.trim()}!',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                backgroundColor: AppColors.forestGreen,
                duration: const Duration(seconds: 4),
              ),
            );
            Navigator.of(context).pop(true);
          }
        } else {
          // Servicio individual único
          final nuevoServicio = Servicio(
            clienteId: _clienteSeleccionado?.id,
            clienteNombre: _clienteController.text.trim(),
            telefono: _telefonoController.text.trim().isNotEmpty
                ? _telefonoController.text.trim()
                : null,
            direccion: _direccionController.text.trim(),
            fechaServicio: _fechaSeleccionada,
            montoCobrado: montoEstimado,
            minutosAnticipacion: totalMinutosAnticipacion,
            estado: Servicio.estadoPendiente,
            observacion: observacionFinal,
          );

          final idGenerado = await dbService.insertServicio(nuevoServicio);
          final servicioConId = nuevoServicio.copyWith(id: idGenerado);
          final alarmaAgendada =
              await notifService.scheduleServicioAlarma(servicioConId);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(
                      alarmaAgendada ? Icons.alarm_on : Icons.check_circle_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        alarmaAgendada
                            ? 'Servicio agendado con alarma activa.'
                            : 'Servicio agendado (alarma no requerida por fecha pasada).',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                backgroundColor: AppColors.forestGreen,
                duration: const Duration(seconds: 3),
              ),
            );
            Navigator.of(context).pop(true);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, d MMM yyyy', 'es');
    final timeFormat = DateFormat('HH:mm');

    final bool esHoy = DateUtils.isSameDay(_fechaSeleccionada, DateTime.now());
    final bool esManana = DateUtils.isSameDay(
      _fechaSeleccionada,
      DateTime.now().add(const Duration(days: 1)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.esEdicion ? 'Editar Servicio' : 'Nuevo Servicio'),
        actions: [
          IconButton(
            tooltip: 'Probar Alarma en 10 seg',
            icon: const Icon(Icons.alarm, color: AppColors.forestGreen),
            onPressed: () async {
              final ok = await NotificationService().scheduleAlarmaDePrueba();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? '🔔 Alarma de prueba programada para dentro de 10 segundos.'
                          : 'No se pudo programar la alarma de prueba.',
                    ),
                    backgroundColor: AppColors.forestGreen,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selector inteligente de Cliente Habitual
              if (_clientesDisponibles.isNotEmpty) ...[
                DropdownButtonFormField<Cliente?>(
                  value: _clienteSeleccionado,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Cargar desde Libreta de Clientes',
                    prefixIcon: const Icon(Icons.people_outline, color: AppColors.sageGreen),
                    suffixIcon: _clienteSeleccionado != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => _aplicarClienteSeleccionado(null),
                          )
                        : null,
                  ),
                  items: [
                    const DropdownMenuItem<Cliente?>(
                      value: null,
                      child: Text(
                        '-- Ingreso manual / Nuevo cliente --',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ),
                    ..._clientesDisponibles.map(
                      (c) => DropdownMenuItem<Cliente?>(
                        value: c,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                c.nombre,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (c.isAbono)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.mintPastel,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Abono ${c.frecuenciaAbono}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.mintPastelText,
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.salmonPastel,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Ocasional',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.salmonPastelText,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  onChanged: _aplicarClienteSeleccionado,
                ),
                const SizedBox(height: 16),
              ],

              // Tarjeta especial si es Cliente con Abono (Recurrencia)
              if (_clienteSeleccionado != null &&
                  _clienteSeleccionado!.isAbono &&
                  !widget.esEdicion) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.cardBorder, width: 1.2),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowColor,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.repeat, color: AppColors.forestGreen, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Cliente con Abono (${_clienteSeleccionado!.frecuenciaAbono})',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.forestGreen,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Switch(
                            value: _autoprogramarAbono,
                            activeColor: AppColors.forestGreen,
                            onChanged: (val) {
                              setState(() => _autoprogramarAbono = val);
                            },
                          ),
                        ],
                      ),
                      if (_autoprogramarAbono) ...[
                        const SizedBox(height: 10),
                        const Text(
                          'Autoprogramar turnos en la agenda:',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 10),
                        // Grilla 2x2 simétrica para evitar desbordamiento horizontal en pantallas angostas
                        Row(
                          children: [
                            Expanded(child: _buildBotonVisita(1)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildBotonVisita(2)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: _buildBotonVisita(3)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildBotonVisita(4)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Frecuencia: Cada $_intervaloDiasAbono días. Se agendarán automáticamente los próximos turnos con sus alarmas.',
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppColors.forestGreen,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // Sección 1: Datos del Cliente
              const Text(
                'Datos del Servicio',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.forestGreen,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _clienteController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Cliente *',
                  hintText: 'Ej. Gonzalo Martínez',
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.sageGreen),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Ingresa el nombre del cliente';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telefonoController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono de Contacto (Opcional)',
                  hintText: 'Ej. +56 9 8765 4321',
                  prefixIcon: Icon(Icons.phone_outlined, color: AppColors.sageGreen),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _direccionController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Dirección o Ubicación *',
                  hintText: 'Ej. Av. Los Robles 1234, El Bosque',
                  prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.sageGreen),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Ingresa la dirección para el mapa';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Sección 2: Fecha y Hora con atajos de una sola mano
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Programación',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.forestGreen,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Row(
                    children: [
                      ActionChip(
                        label: const Text('Hoy'),
                        backgroundColor: esHoy ? AppColors.mintPastel : AppColors.surface,
                        side: BorderSide(
                          color: esHoy ? AppColors.forestGreen : AppColors.cardBorder,
                          width: esHoy ? 1.4 : 1.0,
                        ),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: esHoy ? FontWeight.w800 : FontWeight.w500,
                          color: esHoy ? AppColors.forestGreenDark : AppColors.chipInactiveText,
                        ),
                        onPressed: () => _aplicarAtajoFecha(0),
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        label: const Text('Mañana'),
                        backgroundColor: esManana ? AppColors.mintPastel : AppColors.surface,
                        side: BorderSide(
                          color: esManana ? AppColors.forestGreen : AppColors.cardBorder,
                          width: esManana ? 1.4 : 1.0,
                        ),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: esManana ? FontWeight.w800 : FontWeight.w500,
                          color: esManana ? AppColors.forestGreenDark : AppColors.chipInactiveText,
                        ),
                        onPressed: () => _aplicarAtajoFecha(1),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: InkWell(
                      onTap: _seleccionarFecha,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.border, width: 1.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 18, color: AppColors.forestGreen),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                dateFormat.format(_fechaSeleccionada),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: InkWell(
                      onTap: _seleccionarHora,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.border, width: 1.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.access_time, size: 18, color: AppColors.forestGreen),
                            const SizedBox(width: 6),
                            Text(
                              timeFormat.format(_fechaSeleccionada),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Sección 3: Presupuesto estimado inicial
              const Text(
                'Presupuesto / Cobro Estimado',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.forestGreen,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _presupuestoController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monto Estimado (Opcional)',
                  hintText: '0',
                  prefixText: '\$ ',
                  prefixIcon: Icon(Icons.payments_outlined, color: AppColors.sageGreen),
                ),
                validator: (val) {
                  if (val != null && val.trim().isNotEmpty) {
                    final parsed = double.tryParse(val.replaceAll(',', '.'));
                    if (parsed == null || parsed < 0) {
                      return 'Ingresa un valor numérico válido';
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Observaciones del Servicio
              const Text(
                'Observaciones del Servicio',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.forestGreen,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _observacionController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Observaciones / Notas (Opcional)',
                  hintText: 'Ej: Portón con candado, perro suelto en el patio, llevar bordeadora...',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 36.0),
                    child: Icon(Icons.notes_outlined, color: AppColors.sageGreen),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Sección 4: Selector Granular de Anticipación (Días, Horas, Minutos)
              SelectorAnticipacionWidget(
                dias: _diasAnticipacion,
                horas: _horasAnticipacion,
                minutos: _minutosAnticipacion,
                fechaServicio: _fechaSeleccionada,
                onChanged: (nuevosDias, nuevasHoras, nuevosMinutos) {
                  setState(() {
                    _diasAnticipacion = nuevosDias;
                    _horasAnticipacion = nuevasHoras;
                    _minutosAnticipacion = nuevosMinutos;
                  });
                },
              ),

              const SizedBox(height: 36),

              // Botón de acción principal
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _guardando ? null : _guardarServicio,
                  child: _guardando
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          widget.esEdicion
                              ? 'Guardar Cambios'
                              : (_autoprogramarAbono && _visitasAbonoAGenerar > 1)
                                  ? 'Programar $_visitasAbonoAGenerar Visitas de Abono'
                                  : 'Programar Servicio',
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBotonVisita(int n) {
    final bool seleccionado = _visitasAbonoAGenerar == n;
    return InkWell(
      onTap: () => setState(() => _visitasAbonoAGenerar = n),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
        decoration: BoxDecoration(
          color: seleccionado ? AppColors.forestGreen : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: seleccionado ? AppColors.forestGreen : AppColors.cardBorder,
            width: seleccionado ? 1.6 : 1.0,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            '$n ${n == 1 ? "visita" : "visitas"}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: seleccionado ? FontWeight.w800 : FontWeight.w600,
              color: seleccionado ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
