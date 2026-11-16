import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/cliente_model.dart';
import '../../services/db_service.dart';
import '../../services/seeder_service.dart';
import '../../theme/app_theme.dart';
import '../formularios/nuevo_servicio_view.dart';

/// Vista para gestión integral de la libreta de clientes y servicios recurrentes (abonos).
class ClientesView extends StatefulWidget {
  const ClientesView({super.key});

  @override
  State<ClientesView> createState() => _ClientesViewState();
}

class _ClientesViewState extends State<ClientesView> {
  final DbService _dbService = DbService();
  late Future<List<Cliente>> _clientesFuture;

  String _filtroTipo = 'TODOS'; // 'TODOS', 'ABONO', 'OCASIONAL'
  String _busqueda = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _cargarClientes() {
    setState(() {
      _clientesFuture = _dbService.getClientes();
    });
  }

  Future<void> _abrirFormularioCliente([Cliente? clienteAEditar]) async {
    final resultado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ClienteFormModal(clienteAEditar: clienteAEditar),
    );

    if (resultado == true && mounted) {
      _cargarClientes();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            clienteAEditar == null
                ? 'Cliente registrado en la libreta.'
                : 'Cliente actualizado exitosamente.',
          ),
          backgroundColor: AppColors.forestGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _eliminarCliente(Cliente cliente) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar Cliente', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('¿Deseas eliminar a "${cliente.nombre}" de tu libreta de clientes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true && cliente.id != null) {
      await _dbService.deleteCliente(cliente.id!);
      _cargarClientes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cliente "${cliente.nombre}" eliminado.'),
            backgroundColor: AppColors.forestGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _llamarCliente(Cliente cliente) async {
    if (!cliente.tieneTelefono) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este cliente no tiene teléfono registrado.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final phoneUri = Uri(scheme: 'tel', path: cliente.telefono!.trim());
    try {
      final launched = await launchUrl(phoneUri);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo iniciar la llamada.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al marcar teléfono: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _agendarServicioParaCliente(Cliente cliente) async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => NuevoServicioView(clientePreseleccionado: cliente),
      ),
    );

    if (resultado == true && mounted) {
      _cargarClientes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Libreta de Clientes',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Cargar Datos de Prueba',
            icon: const Icon(Icons.dataset_outlined, color: AppColors.forestGreen),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await SeederService().ejecutarSeederCompleto(
                sembrarClientes: true,
                forzarServicios: true,
              );
              _cargarClientes();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('¡Datos de prueba cargados con éxito!'),
                  backgroundColor: AppColors.forestGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de Búsqueda y Filtros
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre, dirección o teléfono...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.sageGreen),
                    suffixIcon: _busqueda.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _busqueda = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (val) {
                    setState(() => _busqueda = val.trim().toLowerCase());
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildFilterChip('TODOS', 'Todos'),
                    const SizedBox(width: 8),
                    _buildFilterChip('ABONO', 'Con Abono', icon: Icons.repeat),
                    const SizedBox(width: 8),
                    _buildFilterChip('OCASIONAL', 'Ocasionales', icon: Icons.person_outline),
                  ],
                ),
              ],
            ),
          ),

          // Listado de Clientes
          Expanded(
            child: FutureBuilder<List<Cliente>>(
              future: _clientesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.forestGreen),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error al cargar clientes: ${snapshot.error}'),
                  );
                }

                final todos = snapshot.data ?? [];
                final filtrados = todos.where((c) {
                  if (_filtroTipo == 'ABONO' && !c.isAbono) return false;
                  if (_filtroTipo == 'OCASIONAL' && c.isAbono) return false;

                  if (_busqueda.isNotEmpty) {
                    final nombreMatch = c.nombre.toLowerCase().contains(_busqueda);
                    final dirMatch = c.direccion.toLowerCase().contains(_busqueda);
                    final telMatch = (c.telefono ?? '').toLowerCase().contains(_busqueda);
                    return nombreMatch || dirMatch || telMatch;
                  }
                  return true;
                }).toList();

                if (filtrados.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
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
                              Icons.people_outline,
                              size: 50,
                              color: AppColors.sageGreen,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            todos.isEmpty
                                ? 'Aún no tienes clientes registrados'
                                : 'No se encontraron clientes con ese criterio',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.forestGreen,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Registra a tus clientes habituales para programar servicios y abonos en un solo toque.',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          if (todos.isEmpty) ...[
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.forestGreen,
                                side: const BorderSide(color: AppColors.forestGreen),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.dataset_outlined),
                              label: const Text('Cargar 10 Clientes de Prueba', style: TextStyle(fontWeight: FontWeight.w700)),
                              onPressed: () async {
                                await SeederService().ejecutarSeederCompleto(
                                  sembrarClientes: true,
                                  forzarServicios: true,
                                );
                                _cargarClientes();
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.forestGreen,
                  onRefresh: () async => _cargarClientes(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 90, left: 16, right: 16),
                    itemCount: filtrados.length,
                    itemBuilder: (context, index) {
                      final cliente = filtrados[index];
                      return _buildClienteCard(cliente);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo Cliente', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: () => _abrirFormularioCliente(),
      ),
    );
  }

  Widget _buildFilterChip(String valor, String label, {IconData? icon}) {
    final seleccionado = _filtroTipo == valor;
    return ChoiceChip(
      selected: seleccionado,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: seleccionado ? AppColors.forestGreenDark : AppColors.chipInactiveText,
            ),
            const SizedBox(width: 4),
          ],
          Text(label),
        ],
      ),
      selectedColor: AppColors.mintPastel,
      backgroundColor: AppColors.surface,
      side: BorderSide(
        color: seleccionado ? AppColors.forestGreen : AppColors.cardBorder,
        width: seleccionado ? 1.4 : 1.0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: seleccionado ? FontWeight.w800 : FontWeight.w500,
        color: seleccionado ? AppColors.forestGreenDark : AppColors.chipInactiveText,
      ),
      onSelected: (val) {
        if (val) setState(() => _filtroTipo = valor);
      },
    );
  }

  Widget _buildClienteCard(Cliente cliente) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: Nombre y Badge de Tipo (Pastel funcional con contraste pleno)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cliente.nombre,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (cliente.tieneTelefono) ...[
                        const SizedBox(height: 2),
                        Text(
                          cliente.telefono!,
                          style: const TextStyle(
                            fontSize: 13,
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
                    color: cliente.isAbono ? AppColors.mintPastel : AppColors.salmonPastel,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        cliente.isAbono ? Icons.repeat : Icons.person_outline,
                        size: 13,
                        color: cliente.isAbono ? AppColors.mintPastelText : AppColors.salmonPastelText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        cliente.isAbono ? 'Abono ${cliente.frecuenciaAbono}' : 'Ocasional',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: cliente.isAbono ? AppColors.mintPastelText : AppColors.salmonPastelText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Dirección
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.sageGreen),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    cliente.direccion,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),

            // Precio Sugerido
            if (cliente.precioSugerido > 0) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.payments_outlined, size: 16, color: AppColors.sageGreen),
                  const SizedBox(width: 6),
                  Text(
                    'Cobro pactado: \$ ${cliente.precioSugerido.toStringAsFixed(0)} / visita',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.forestGreen,
                    ),
                  ),
                ],
              ),
            ],

            // Observaciones
            if (cliente.tieneObservacion) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes_outlined, size: 16, color: AppColors.sageGreen),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      cliente.observacion!,
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

            // Barra de Acciones
            Row(
              children: [
                // Llamar
                if (cliente.tieneTelefono)
                  IconButton.filledTonal(
                    tooltip: 'Llamar al cliente',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceSubtle,
                      foregroundColor: AppColors.forestGreen,
                    ),
                    icon: const Icon(Icons.phone_outlined, size: 18),
                    onPressed: () => _llamarCliente(cliente),
                  ),
                if (cliente.tieneTelefono) const SizedBox(width: 8),

                // Editar
                IconButton.filledTonal(
                  tooltip: 'Editar cliente',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceSubtle,
                    foregroundColor: AppColors.forestGreen,
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: () => _abrirFormularioCliente(cliente),
                ),
                const SizedBox(width: 8),

                // Eliminar
                IconButton.filledTonal(
                  tooltip: 'Eliminar cliente',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceSubtle,
                    foregroundColor: Colors.redAccent,
                  ),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => _eliminarCliente(cliente),
                ),

                const Spacer(),

                // Agendar Servicio
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forestGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.calendar_today_outlined, size: 16),
                  label: const Text('Agendar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  onPressed: () => _agendarServicioParaCliente(cliente),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal ergonómico para crear o editar un Cliente en la libreta.
class _ClienteFormModal extends StatefulWidget {
  final Cliente? clienteAEditar;

  const _ClienteFormModal({this.clienteAEditar});

  @override
  State<_ClienteFormModal> createState() => _ClienteFormModalState();
}

class _ClienteFormModalState extends State<_ClienteFormModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _direccionCtrl;
  late final TextEditingController _precioCtrl;
  late final TextEditingController _observacionCtrl;

  late String _tipoCliente;
  late String _frecuenciaAbono;

  bool get _esEdicion => widget.clienteAEditar != null;

  @override
  void initState() {
    super.initState();
    final c = widget.clienteAEditar;
    _nombreCtrl = TextEditingController(text: c?.nombre ?? '');
    _telefonoCtrl = TextEditingController(text: c?.telefono ?? '');
    _direccionCtrl = TextEditingController(text: c?.direccion ?? '');
    _precioCtrl = TextEditingController(
      text: (c?.precioSugerido != null && c!.precioSugerido > 0)
          ? c.precioSugerido.toStringAsFixed(0)
          : '',
    );
    _observacionCtrl = TextEditingController(text: c?.observacion ?? '');
    _tipoCliente = c?.tipoCliente ?? Cliente.tipoOcasional;
    _frecuenciaAbono = c?.frecuenciaAbono ?? Cliente.frecSemanal;
    if (_frecuenciaAbono == Cliente.frecNinguna) {
      _frecuenciaAbono = Cliente.frecSemanal;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _direccionCtrl.dispose();
    _precioCtrl.dispose();
    _observacionCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final precio = double.tryParse(_precioCtrl.text.replaceAll(',', '.')) ?? 0.0;
    final frecFinal = _tipoCliente == Cliente.tipoAbono ? _frecuenciaAbono : Cliente.frecNinguna;
    final obs = _observacionCtrl.text.trim().isNotEmpty ? _observacionCtrl.text.trim() : null;

    final dbService = DbService();

    if (_esEdicion) {
      final actualizado = widget.clienteAEditar!.copyWith(
        nombre: _nombreCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim().isNotEmpty ? _telefonoCtrl.text.trim() : null,
        direccion: _direccionCtrl.text.trim(),
        tipoCliente: _tipoCliente,
        frecuenciaAbono: frecFinal,
        precioSugerido: precio,
        observacion: obs,
      );
      await dbService.updateCliente(actualizado);
    } else {
      final nuevo = Cliente(
        nombre: _nombreCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim().isNotEmpty ? _telefonoCtrl.text.trim() : null,
        direccion: _direccionCtrl.text.trim(),
        tipoCliente: _tipoCliente,
        frecuenciaAbono: frecFinal,
        precioSugerido: precio,
        observacion: obs,
      );
      await dbService.insertCliente(nuevo);
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _esEdicion ? 'Editar Cliente' : 'Nuevo Cliente',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.forestGreen,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Nombre
              TextFormField(
                controller: _nombreCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre y Apellido *',
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

              // Teléfono
              TextFormField(
                controller: _telefonoCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono de Contacto (Opcional)',
                  prefixIcon: Icon(Icons.phone_outlined, color: AppColors.sageGreen),
                ),
              ),
              const SizedBox(height: 12),

              // Dirección
              TextFormField(
                controller: _direccionCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Dirección o Ubicación habitual *',
                  prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.sageGreen),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Ingresa la dirección';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tipo de Cliente: Ocasional vs Con Abono
              const Text(
                'Tipo de Servicio',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.forestGreen,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      selected: _tipoCliente == Cliente.tipoOcasional,
                      label: const Center(child: Text('Ocasional')),
                      selectedColor: AppColors.sageGreenLight,
                      labelStyle: TextStyle(
                        fontWeight: _tipoCliente == Cliente.tipoOcasional
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _tipoCliente == Cliente.tipoOcasional
                            ? AppColors.forestGreen
                            : AppColors.textSecondary,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _tipoCliente = Cliente.tipoOcasional);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      selected: _tipoCliente == Cliente.tipoAbono,
                      label: const Center(child: Text('Con Abono')),
                      selectedColor: AppColors.sageGreenLight,
                      labelStyle: TextStyle(
                        fontWeight: _tipoCliente == Cliente.tipoAbono
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: _tipoCliente == Cliente.tipoAbono
                            ? AppColors.forestGreen
                            : AppColors.textSecondary,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _tipoCliente = Cliente.tipoAbono);
                      },
                    ),
                  ),
                ],
              ),

              // Frecuencia si es Abono
              if (_tipoCliente == Cliente.tipoAbono) ...[
                const SizedBox(height: 14),
                const Text(
                  'Frecuencia de Mantenimiento',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.forestGreen,
                  ),
                ),
                const SizedBox(height: 8),
                // Grilla 2x2 con contraste solar optimizado
                Row(
                  children: [
                    Expanded(
                      child: _buildFrecuenciaBoton(
                        Cliente.frec1VezMes,
                        '1 vez/mes',
                        'cada 30 días',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFrecuenciaBoton(
                        Cliente.frec2VecesMes,
                        '2 veces/mes',
                        'Quincenal • 15 días',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildFrecuenciaBoton(
                        Cliente.frec3VecesMes,
                        '3 veces/mes',
                        'cada 10 días',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFrecuenciaBoton(
                        Cliente.frecSemanal,
                        'Semanal',
                        '4 veces/mes • 7 días',
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 14),

              // Precio Pactado / Sugerido
              TextFormField(
                controller: _precioCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Precio Pactado por Visita (\$) (Opcional)',
                  prefixText: '\$ ',
                  prefixIcon: Icon(Icons.payments_outlined, color: AppColors.sageGreen),
                ),
              ),

              const SizedBox(height: 14),

              // Observaciones (Opcional)
              TextFormField(
                controller: _observacionCtrl,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Observaciones (Opcional)',
                  hintText: 'Ej: Perro suelto en el patio, tocar timbre del portón negro, llevar bordeadora...',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 36.0),
                    child: Icon(Icons.notes_outlined, color: AppColors.sageGreen),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _guardar,
                  child: Text(_esEdicion ? 'Guardar Cambios' : 'Registrar Cliente'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrecuenciaBoton(String valor, String titulo, String subtitulo) {
    final bool seleccionado = _frecuenciaAbono == valor;
    return InkWell(
      onTap: () => setState(() => _frecuenciaAbono = valor),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: seleccionado ? AppColors.forestGreen : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: seleccionado ? AppColors.forestGreen : Colors.grey.shade300,
            width: seleccionado ? 1.6 : 1.0,
          ),
          boxShadow: seleccionado
              ? [
                  BoxShadow(
                    color: AppColors.forestGreen.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: seleccionado ? Colors.white : AppColors.forestGreen,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: seleccionado ? FontWeight.w600 : FontWeight.w500,
                color: seleccionado ? AppColors.sageGreenLight : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
