import 'package:flutter/material.dart';
import '../models/grupo.dart';
import 'dashboard_screen.dart';
import 'grupos_screen.dart';
import 'sesiones_screen.dart';
import 'reportes_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _indiceActual = 0;
  Grupo? _grupoPreseleccionado;

  void _irASesionesDeGrupo(Grupo grupo) {
    setState(() {
      _grupoPreseleccionado = grupo;
      _indiceActual = 2; // Pestaña Sesiones
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pantallas = [
      DashboardScreen(
        onCambiarTab: (nuevoIndice) => setState(() => _indiceActual = nuevoIndice),
        onAbrirGrupo: _irASesionesDeGrupo,
      ),
      GruposScreen(
        onSeleccionarGrupo: _irASesionesDeGrupo,
      ),
      SesionesScreen(
        grupoInicial: _grupoPreseleccionado,
      ),
      const ReportesScreen(),
    ];

    return Scaffold(
      body: pantallas[_indiceActual],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indiceActual,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE8F0FE),
        elevation: 3,
        onDestinationSelected: (index) {
          setState(() => _indiceActual = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF004B93)),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded, color: Color(0xFF004B93)),
            label: 'Mis Grupos',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note_rounded, color: Color(0xFF004B93)),
            label: 'Sesiones',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded, color: Color(0xFF004B93)),
            label: 'Reportes',
          ),
        ],
      ),
    );
  }
}