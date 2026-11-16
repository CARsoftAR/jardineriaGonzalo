import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/servicio_model.dart';
import '../../services/db_service.dart';
import '../../theme/app_theme.dart';
import '../formularios/nuevo_servicio_view.dart';

/// Vista principal de la Agenda de servicios pendientes con edición reactiva y selector granular.
class AgendaView extends StatefulWidget {
  const AgendaView({super.key});

  @override
  State<AgendaView> createState() => _AgendaViewState();
}

class _AgendaViewState extends State<AgendaView> {
  final DbService _dbService = DbService();
  late Future<List<Servicio>> _serviciosFuture;
  final DateFormat _dateFormat = DateFormat('EEE, d MMM • HH:mm', 'es');

  @override
  void initState() {
    super.initState();
    _cargarServicios();
  }

  void _cargarServicios() {
    setState(() {
      _serviciosFuture = _dbService.getServiciosPendientes();
    });
  }

  /// Abre la dirección del servicio directamente en Google Maps de forma explícita.
  Future<void> _abrirEnGoogleMaps(String direccion) async {
    final query = Uri.encodeComponent(direccion);
    final mapUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');

    try {
      final launched = await launchUrl(mapUri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        _mostrarMensajeSutil('No se pudo abrir la aplicación de mapas.');
      }
    } catch (e) {
      if (mounted) {
        _mostrarMensajeSutil('Error al intentar abrir el mapa: $e');
      }
    }
  }

  /// Inicia una llamada telefónica directa al cliente o solicita el número si no existe.
  Future<void> _iniciarLlamadaCliente(Servicio servicio) async {
    if (servicio.tieneTelefono) {
      final phoneUri = Uri(scheme: 'tel', path: servicio.telefono!.trim());
      try {
        final launched = await launchUrl(phoneUri);
        if (!launched && mounted) {
          _mostrarMensajeSutil('No se pudo iniciar la llamada.');
        }
      } catch (e) {
        if (mounted) {
          _mostrarMensajeSutil('Error al marcar teléfono: $e');
        }
      }
    } else {
      final phoneController = TextEditingController();
      final formKey = GlobalKey<FormState>();

      final telefonoIngresado = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Llamar a ${servicio.clienteNombre}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Este servicio no tiene teléfono guardado. Ingresa el número para llamar:',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  autofocus: true,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Número de Teléfono',
                    hintText: 'Ej. +56 9 1234 5678',
                    prefixIcon: Icon(Icons.phone, color: AppColors.sageGreen),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Por favor ingresa un número';
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
              child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.call, size: 18),
              label: const Text('Llamar'),
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(ctx).pop(phoneController.text.trim());
                }
              },
            ),
          ],
        ),
      );

      if (telefonoIngresado != null && telefonoIngresado.isNotEmpty) {
        if (servicio.id != null) {
          final actualizado = servicio.copyWith(telefono: telefonoIngresado);
          await _dbService.updateServicio(actualizado);
          _cargarServicios();
        }

        final phoneUri = Uri(scheme: 'tel', path: telefonoIngresado);
        await launchUrl(phoneUri);
      }
    }
  }

  /// Abre la vista de formulario completa para editar todos los campos del servicio.
  Future<void> _abrirFormularioEditar(Servicio servicio) async {
    final bool? actualizado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => NuevoServicioView(servicioAEditar: servicio),
      ),
    );

    if (actualizado == true && mounted) {
      _cargarServicios();
    }
  }

  /// Diálogo minimalista para asentar el cobro final y completar la orden.
  Future<void> _abrirDialogoCompletar(Servicio servicio) async {
    final controller = TextEditingController(
      text: servicio.montoCobrado > 0 ? servicio.montoCobrado.toStringAsFixed(0) : '',
    );
    final formKey = GlobalKey<FormState>();

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Completar y Cobrar', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cliente: ${servicio.clienteNombre}',
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.forestGreen),
              ),
              const SizedBox(height: 4),
              Text(
                servicio.direccion,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monto final cobrado (\$)',
                  prefixText: '\$ ',
                  hintText: '0',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Ingresa el monto cobrado';
                  }
                  final parsed = double.tryParse(val.replaceAll(',', '.'));
                  if (parsed == null || parsed < 0) {
                    return 'Monto inválido';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: const Text('Confirmar Cobro'),
          ),
        ],
      ),
    );

    if (confirmado == true && servicio.id != null) {
      final monto = double.parse(controller.text.replaceAll(',', '.'));
      await _dbService.completarServicio(servicio.id!, monto);
      if (mounted) {
        _mostrarMensajeSutil('Servicio de ${servicio.clienteNombre} completado.');
        _cargarServicios();
      }
    }
  }

  void _mostrarMensajeSutil(String texto) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto, style: const TextStyle(fontSize: 14)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: AppColors.forestGreen,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String _describirAnticipacion(int minutosTotales) {
    if (minutosTotales <= 0) return 'en punto';
    final dias = minutosTotales ~/ 1440;
    final horas = (minutosTotales % 1440) ~/ 60;
    final mins = minutosTotales % 60;

    final partes = <String>[];
    if (dias > 0) partes.add('${dias}d');
    if (horas > 0) partes.add('${horas}h');
    if (mins > 0) partes.add('${mins}m');

    return '${partes.join(" ")} antes';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Agenda de Servicios',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: FutureBuilder<List<Servicio>>(
        future: _serviciosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.forestGreen),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar agenda: ${snapshot.error}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          final servicios = snapshot.data ?? [];
          if (servicios.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.eco_outlined,
                        size: 56,
                        color: AppColors.forestGreen,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No hay servicios pendientes',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.forestGreen,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tu agenda de jardinería está al día. Puedes registrar un nuevo servicio desde el botón inferior.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
            );
          }

                return RefreshIndicator(
                  color: AppColors.forestGreen,
                  onRefresh: () async => _cargarServicios(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 90),
                    itemCount: servicios.length,
                    itemBuilder: (context, index) {
                      final item = servicios[index];
                      final fechaFormateada = _dateFormat.format(item.fechaServicio);

                      return Card(
                        child: InkWell(
                          // Al tocar el cuerpo de la tarjeta se abre la edición reactiva
                          onTap: () => _abrirFormularioEditar(item),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Cabecera: Cliente y Alarma
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.clienteNombre,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                          if (item.tieneTelefono) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              item.telefono!,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: AppColors.mintPastel,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.alarm, size: 14, color: AppColors.forestGreenDark),
                                          const SizedBox(width: 4),
                                          Text(
                                            _describirAnticipacion(item.minutosAnticipacion),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.forestGreenDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // Dirección informativa
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 16,
                                      color: AppColors.sageGreen,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item.direccion,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 6),

                                // Fecha y hora
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 16,
                                      color: AppColors.sageGreen,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      fechaFormateada,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.forestGreen,
                                      ),
                                    ),
                                  ],
                                ),

                                // Observaciones del Servicio
                                if (item.tieneObservacion) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.notes_outlined,
                                        size: 16,
                                        color: AppColors.sageGreen,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item.observacion!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

                                const SizedBox(height: 14),
                                const Divider(height: 1, color: AppColors.border),
                                const SizedBox(height: 10),

                                // Barra de Acciones Móviles Separadas y Explícitas
                                Row(
                                  children: [
                                    // Acción 1: Abrir en Google Maps ÚNICAMENTE desde este botón
                                    IconButton.filledTonal(
                                      tooltip: 'Abrir ubicación en Google Maps',
                                      style: IconButton.styleFrom(
                                        backgroundColor: AppColors.surfaceSubtle,
                                        foregroundColor: AppColors.forestGreen,
                                      ),
                                      icon: const Icon(Icons.map_outlined, size: 20),
                                      onPressed: () => _abrirEnGoogleMaps(item.direccion),
                                    ),
                                    const SizedBox(width: 8),

                                    // Acción 2: Llamada telefónica directa
                                    IconButton.filledTonal(
                                      tooltip: 'Llamar al cliente',
                                      style: IconButton.styleFrom(
                                        backgroundColor: AppColors.surfaceSubtle,
                                        foregroundColor: AppColors.forestGreen,
                                      ),
                                      icon: const Icon(Icons.phone_outlined, size: 20),
                                      onPressed: () => _iniciarLlamadaCliente(item),
                                    ),
                                    const SizedBox(width: 8),

                                    // Acción 3: Editar servicio pendiente
                                    IconButton.filledTonal(
                                      tooltip: 'Editar servicio',
                                      style: IconButton.styleFrom(
                                        backgroundColor: AppColors.surfaceSubtle,
                                        foregroundColor: AppColors.forestGreen,
                                      ),
                                      icon: const Icon(Icons.edit_outlined, size: 20),
                                      onPressed: () => _abrirFormularioEditar(item),
                                    ),

                                    const Spacer(),

                                    // Acción 4: Completar y Cobrar
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.forestGreen,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      icon: const Icon(Icons.check_circle_outline, size: 18),
                                      label: const Text(
                                        'Completar',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                      onPressed: () => _abrirDialogoCompletar(item),
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
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add),
        label: const Text(
          'Nuevo Servicio',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const NuevoServicioView()),
          );
          if (result == true) {
            _cargarServicios();
          }
        },
      ),
    );
  }
}
