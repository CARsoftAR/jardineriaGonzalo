import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';

/// Widget ergonómico de selección granular de anticipación (Días, Horas, Minutos).
class SelectorAnticipacionWidget extends StatelessWidget {
  final int dias;
  final int horas;
  final int minutos;
  final DateTime fechaServicio;
  final void Function(int nuevosDias, int nuevasHoras, int nuevosMinutos) onChanged;

  const SelectorAnticipacionWidget({
    super.key,
    required this.dias,
    required this.horas,
    required this.minutos,
    required this.fechaServicio,
    required this.onChanged,
  });

  /// Calcula el total de minutos de anticipación
  int get minutosTotales => (dias * 1440) + (horas * 60) + minutos;

  /// Calcula la fecha y hora exacta en la que sonará la alarma
  DateTime get fechaAlarma => fechaServicio.subtract(Duration(minutes: minutosTotales));

  /// Retorna un texto descriptivo de la anticipación (ej: "2 días y 4 horas antes")
  String _generarTextoResumen() {
    if (minutosTotales == 0) {
      return 'Al momento exacto del servicio';
    }

    final partes = <String>[];
    if (dias > 0) partes.add('$dias ${dias == 1 ? "día" : "días"}');
    if (horas > 0) partes.add('$horas ${horas == 1 ? "hora" : "horas"}');
    if (minutos > 0) partes.add('$minutos ${minutos == 1 ? "minuto" : "minutos"}');

    return '${partes.join(" y ")} antes del servicio';
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, d MMM yyyy', 'es');
    final timeFormat = DateFormat('HH:mm');
    final now = DateTime.now();
    final bool servicioEsFuturo = fechaServicio.isAfter(now);
    final bool alarmaEsFutura = fechaAlarma.isAfter(now.add(const Duration(seconds: 10)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Alarma de Anticipación',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.forestGreen,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Configura con cuánto tiempo previo debe sonar la alarma en tu teléfono:',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),

        // Fila de 3 Selectores Compuestos (Días, Horas, Minutos)
        Row(
          children: [
            // Selector Días
            Expanded(
              child: _buildSelectorBox(
                context: context,
                label: 'DÍAS',
                value: dias,
                items: List.generate(31, (i) => i),
                itemLabel: (val) => '$val d',
                onChanged: (val) => onChanged(val, horas, minutos),
              ),
            ),
            const SizedBox(width: 8),

            // Selector Horas
            Expanded(
              child: _buildSelectorBox(
                context: context,
                label: 'HORAS',
                value: horas,
                items: List.generate(24, (i) => i),
                itemLabel: (val) => '$val h',
                onChanged: (val) => onChanged(dias, val, minutos),
              ),
            ),
            const SizedBox(width: 8),

            // Selector Minutos
            Expanded(
              child: _buildSelectorBox(
                context: context,
                label: 'MINUTOS',
                value: minutos,
                items: const [0, 5, 10, 15, 20, 30, 45],
                itemLabel: (val) => '$val m',
                onChanged: (val) => onChanged(dias, horas, val),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Tarjeta resumen en tiempo real
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: alarmaEsFutura
                ? AppColors.mintPastel
                : AppColors.salmonPastel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: alarmaEsFutura
                  ? AppColors.forestGreenLight.withValues(alpha: 0.4)
                  : AppColors.salmonPastelText.withValues(alpha: 0.4),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    servicioEsFuturo ? Icons.alarm_on : Icons.alarm_off,
                    color: !servicioEsFuturo
                        ? AppColors.danger
                        : (alarmaEsFutura ? AppColors.forestGreenDark : AppColors.salmonPastelText),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _generarTextoResumen(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: !servicioEsFuturo
                            ? AppColors.danger
                            : (alarmaEsFutura ? AppColors.forestGreenDark : AppColors.salmonPastelText),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 28.0),
                child: Text(
                  !servicioEsFuturo
                      ? 'El servicio ya pasó. No se activará alarma.'
                      : (alarmaEsFutura
                          ? 'Sonará el ${dateFormat.format(fechaAlarma)} a las ${timeFormat.format(fechaAlarma)}.'
                          : 'Anticipación ya transcurrida. Sonará en 30 segundos tras guardar.'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: !servicioEsFuturo
                        ? Colors.redAccent.shade700
                        : (alarmaEsFutura ? AppColors.textPrimary : Colors.amber.shade900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectorBox({
    required BuildContext context,
    required String label,
    required int value,
    required List<int> items,
    required String Function(int) itemLabel,
    required void Function(int) onChanged,
  }) {
    // Si el valor actual no está en la lista (ej: minutos custom), lo incluimos
    final fullItems = items.contains(value) ? items : ([value, ...items]..sort());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: AppColors.forestGreen, size: 20),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.forestGreen,
              ),
              items: fullItems.map((val) {
                return DropdownMenuItem<int>(
                  value: val,
                  child: Text(itemLabel(val)),
                );
              }).toList(),
              onChanged: (newVal) {
                if (newVal != null) {
                  onChanged(newVal);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
