import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/servicio_model.dart';
import '../../services/db_service.dart';
import '../../services/seeder_service.dart';
import '../../theme/app_theme.dart';

/// Vista para el historial de servicios realizados, auditoría contable y corrección de cobros.
class HistorialView extends StatefulWidget {
  const HistorialView({super.key});

  @override
  State<HistorialView> createState() => _HistorialViewState();
}

class _HistorialViewState extends State<HistorialView> {
  final DbService _dbService = DbService();
  late Future<List<Servicio>> _historialFuture;

  // Mes seleccionado para la auditoría financiera (por defecto, el mes actual)
  late DateTime _mesSeleccionado;

  final DateFormat _dateFormat = DateFormat('EEE, d MMM • HH:mm', 'es');
  final DateFormat _mesNombreFormat = DateFormat('MMMM yyyy', 'es');
  final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 0,
    locale: 'es',
  );

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _mesSeleccionado = DateTime(now.year, now.month, 1);
    _cargarHistorial();
  }

  void _cargarHistorial() {
    setState(() {
      _historialFuture = _dbService.getServiciosCompletados();
    });
  }

  /// Navega al mes anterior
  void _mesAnterior() {
    setState(() {
      _mesSeleccionado =
          DateTime(_mesSeleccionado.year, _mesSeleccionado.month - 1, 1);
    });
  }

  /// Navega al mes siguiente
  void _mesSiguiente() {
    setState(() {
      _mesSeleccionado =
          DateTime(_mesSeleccionado.year, _mesSeleccionado.month + 1, 1);
    });
  }

  /// Restablece la vista al mes en curso
  void _volverAlMesActual() {
    final now = DateTime.now();
    setState(() {
      _mesSeleccionado = DateTime(now.year, now.month, 1);
    });
  }

  /// Abre diálogo modal para corregir o ajustar el monto cobrado de un trabajo
  Future<void> _abrirCorreccionMonto(Servicio servicio) async {
    final controller = TextEditingController(
      text: servicio.montoCobrado.toStringAsFixed(0),
    );
    final formKey = GlobalKey<FormState>();

    final nuevoMonto = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit_note, color: AppColors.forestGreen, size: 24),
            SizedBox(width: 8),
            Text(
              'Ajustar Cobro',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cliente: ${servicio.clienteNombre}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.forestGreen,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Fecha: ${_dateFormat.format(servicio.fechaServicio)}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 3),
              Text(
                'Dirección: ${servicio.direccion}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: controller,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monto Corregido (\$)',
                  prefixText: '\$ ',
                  hintText: '0',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Ingresa el nuevo monto';
                  }
                  final parsed = double.tryParse(val.replaceAll(',', '.'));
                  if (parsed == null || parsed < 0) {
                    return 'Monto numérico no válido';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                final valor =
                    double.parse(controller.text.replaceAll(',', '.'));
                Navigator.of(ctx).pop(valor);
              }
            },
            child: const Text('Guardar Corrección'),
          ),
        ],
      ),
    );

    if (nuevoMonto != null && servicio.id != null) {
      await _dbService.actualizarMontoCobrado(servicio.id!, nuevoMonto);
      if (mounted) {
        _mostrarMensajeSutil(
            'Cobro actualizado para ${servicio.clienteNombre}.');
        _cargarHistorial();
      }
    }
  }

  void _mostrarMensajeSutil(String texto) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(texto, style: const TextStyle(fontWeight: FontWeight.w500)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: AppColors.forestGreen,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _abrirMapa(String direccion) async {
    final query = Uri.encodeComponent(direccion);
    final mapUri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    await launchUrl(mapUri, mode: LaunchMode.externalApplication);
  }

  Future<void> _llamarCliente(String telefono) async {
    final phoneUri = Uri(scheme: 'tel', path: telefono.trim());
    await launchUrl(phoneUri);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final esMesActual = _mesSeleccionado.year == now.year &&
        _mesSeleccionado.month == now.month;

    // Capitalizar primera letra del mes ("Noviembre 2026")
    final mesNombreRaw = _mesNombreFormat.format(_mesSeleccionado);
    final mesNombre = mesNombreRaw.isNotEmpty
        ? mesNombreRaw[0].toUpperCase() + mesNombreRaw.substring(1)
        : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Historial y Cobros',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Cargar Trabajos de Prueba (Demo)',
            icon: const Icon(Icons.dataset_outlined),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await SeederService()
                  .ejecutarSeederCompleto(forzarServicios: true);
              _cargarHistorial();
              messenger.showSnackBar(
                const SnackBar(
                  content:
                      Text('¡Historial y agenda de prueba cargados con éxito!'),
                  backgroundColor: AppColors.forestGreen,
                ),
              );
            },
          ),
          if (!esMesActual)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton.filledTonal(
                tooltip: 'Volver al Mes Actual',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.mintPastel,
                  foregroundColor: AppColors.forestGreenDark,
                  minimumSize: const Size(36, 36),
                  padding: EdgeInsets.zero,
                ),
                icon: const Icon(Icons.today, size: 18),
                onPressed: _volverAlMesActual,
              ),
            ),
        ],
      ),
      body: FutureBuilder<List<Servicio>>(
        future: _historialFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.forestGreen),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar historial: ${snapshot.error}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          final todosLosServicios = snapshot.data ?? [];

          // Filtrar servicios pertenecientes al mes seleccionado
          final serviciosDelMes = todosLosServicios.where((s) {
            return s.fechaServicio.year == _mesSeleccionado.year &&
                s.fechaServicio.month == _mesSeleccionado.month;
          }).toList();

          final totalMesActual = serviciosDelMes.fold<double>(
            0.0,
            (sum, item) => sum + item.montoCobrado,
          );

          return Column(
            children: [
              // 1. Tarjeta Resumen Financiero Superior con Selector Rápido de Mes
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.forestGreen,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.forestGreen.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selector rápido de mes (< Noviembre 2026 >)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          tooltip: 'Mes anterior',
                          icon: const Icon(Icons.chevron_left,
                              color: Colors.white, size: 24),
                          onPressed: _mesAnterior,
                          style: IconButton.styleFrom(
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.15),
                            padding: const EdgeInsets.all(6),
                            minimumSize: const Size(36, 36),
                          ),
                        ),
                        Flexible(
                          child: InkWell(
                            onTap: esMesActual ? null : _volverAlMesActual,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                mesNombre,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Mes siguiente',
                          icon: const Icon(Icons.chevron_right,
                              color: Colors.white, size: 24),
                          onPressed: _mesSiguiente,
                          style: IconButton.styleFrom(
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.15),
                            padding: const EdgeInsets.all(6),
                            minimumSize: const Size(36, 36),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 14),

                    // Monto destacado del mes y chip contador de servicios (distribución segura contra overflow)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                esMesActual
                                    ? 'Total Cobrado del Mes'
                                    : 'Total Cobrado ($mesNombre)',
                                style: const TextStyle(
                                  color: AppColors.mintPastel,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _currencyFormat.format(totalMesActual),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${serviciosDelMes.length} ${serviciosDelMes.length == 1 ? 'servicio' : 'servicios'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Encabezado de la lista con indicador de edición (protegido con Expanded)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Servicios Realizados ($mesNombre)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.forestGreen,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // const SizedBox(width: 8),
                    // const Text(
                    //   'Toca para ajustar',
                    //   style: TextStyle(
                    //     fontSize: 11,
                    //     color: AppColors.textSecondary,
                    //     fontWeight: FontWeight.w500,
                    //   ),
                    // ),
                  ],
                ),
              ),

              // 3. Listado de Servicios Realizados
              Expanded(
                child: serviciosDelMes.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: const BoxDecoration(
                                  color: AppColors.surfaceSubtle,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.receipt_long_outlined,
                                  size: 48,
                                  color: AppColors.forestGreen,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Sin cobros en $mesNombre',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.forestGreen,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Usa las flechas superiores para auditar otros meses o completa servicios en la Agenda.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.forestGreen,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.dataset_outlined,
                                    size: 18),
                                label: const Text(
                                    'Cargar Trabajos de Prueba (Demo)'),
                                onPressed: () async {
                                  final messenger =
                                      ScaffoldMessenger.of(context);
                                  await SeederService().ejecutarSeederCompleto(
                                      forzarServicios: true);
                                  _cargarHistorial();
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          '¡Historial y agenda cargados con éxito!'),
                                      backgroundColor: AppColors.forestGreen,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.forestGreen,
                        onRefresh: () async => _cargarHistorial(),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24, top: 4),
                          itemCount: serviciosDelMes.length,
                          itemBuilder: (context, index) {
                            final item = serviciosDelMes[index];
                            final fechaFormateada =
                                _dateFormat.format(item.fechaServicio);

                            return Card(
                              child: InkWell(
                                onTap: () => _abrirCorreccionMonto(item),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Fila Principal: Cliente y Chip Verde Salvia de Cobro
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.clienteNombre,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        AppColors.textPrimary,
                                                    letterSpacing: -0.3,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons
                                                          .location_on_outlined,
                                                      size: 14,
                                                      color:
                                                          AppColors.sageGreen,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        item.direccion,
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          color: AppColors
                                                              .textSecondary,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (item.tieneObservacion) ...[
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    item.observacion!,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors
                                                          .textSecondary,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),

                                          // Insignia (Chip) con monto cobrado en Verde Menta Pastel
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.mintPastel,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: AppColors.mintPastelText
                                                    .withValues(alpha: 0.25),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              _currencyFormat
                                                  .format(item.montoCobrado),
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.mintPastelText,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 10),
                                      const Divider(
                                          height: 1, color: AppColors.border),
                                      const SizedBox(height: 8),

                                      // Fila Inferior: Fecha/Hora y Acciones directas
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.check_circle_outline,
                                                size: 15,
                                                color: AppColors.success,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                fechaFormateada,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.forestGreen,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              if (item.tieneTelefono) ...[
                                                IconButton(
                                                  tooltip: 'Llamar cliente',
                                                  icon: const Icon(
                                                    Icons.phone_outlined,
                                                    size: 18,
                                                    color:
                                                        AppColors.forestGreen,
                                                  ),
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                  onPressed: () =>
                                                      _llamarCliente(
                                                          item.telefono!),
                                                ),
                                              ],
                                              IconButton(
                                                tooltip: 'Ver ubicación',
                                                icon: const Icon(
                                                  Icons.map_outlined,
                                                  size: 18,
                                                  color: AppColors.forestGreen,
                                                ),
                                                visualDensity:
                                                    VisualDensity.compact,
                                                onPressed: () =>
                                                    _abrirMapa(item.direccion),
                                              ),
                                              IconButton(
                                                tooltip: 'Editar monto cobrado',
                                                icon: const Icon(
                                                  Icons.edit_outlined,
                                                  size: 18,
                                                  color: AppColors.forestGreen,
                                                ),
                                                visualDensity:
                                                    VisualDensity.compact,
                                                onPressed: () =>
                                                    _abrirCorreccionMonto(item),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
