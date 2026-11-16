import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'agenda/agenda_view.dart';
import 'clientes/clientes_view.dart';
import 'historial/historial_view.dart';

/// Contenedor de navegación principal con barra inferior moderna y minimalista.
class HomeNavigationView extends StatefulWidget {
  const HomeNavigationView({super.key});

  @override
  State<HomeNavigationView> createState() => _HomeNavigationViewState();
}

class _HomeNavigationViewState extends State<HomeNavigationView> {
  int _currentIndex = 0;

  final List<Widget> _views = const [
    AgendaView(),
    ClientesView(),
    HistorialView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _views,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.mintPastel,
          elevation: 0,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.calendar_month, color: AppColors.forestGreen),
              label: 'Agenda',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.people, color: AppColors.forestGreen),
              label: 'Clientes',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.receipt_long, color: AppColors.forestGreen),
              label: 'Historial',
            ),
          ],
        ),
      ),
    );
  }
}
