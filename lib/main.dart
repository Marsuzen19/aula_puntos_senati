import 'package:flutter/material.dart';
import 'models/grupo.dart';
import 'screens/login_screen.dart';
import 'screens/grupos_screen.dart';
import 'screens/sesiones_screen.dart';
import 'screens/reportes_screen.dart';
import 'screens/sincronizacion_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AulaApp());
}

class AulaApp extends StatefulWidget {
  const AulaApp({super.key});

  @override
  State<AulaApp> createState() => _AulaAppState();
}

class _AulaAppState extends State<AulaApp> {
  String? _usuarioActivo;

  void _iniciarSesion(String usuario) {
    setState(() {
      _usuarioActivo = usuario;
    });
  }

  void _cerrarSesion() {
    setState(() {
      _usuarioActivo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Control de Aula SENATI',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF004B93),
      ),
      home: _usuarioActivo == null
          ? LoginScreen(onLoginExitoso: _iniciarSesion)
          : NavegacionPrincipal(
              usuario: _usuarioActivo!,
              onCerrarSesion: _cerrarSesion,
            ),
    );
  }
}

class NavegacionPrincipal extends StatefulWidget {
  final String usuario;
  final VoidCallback onCerrarSesion;

  const NavegacionPrincipal({
    super.key,
    required this.usuario,
    required this.onCerrarSesion,
  });

  @override
  State<NavegacionPrincipal> createState() => _NavegacionPrincipalState();
}

class _NavegacionPrincipalState extends State<NavegacionPrincipal> {
  int _indiceActual = 0;
  Grupo? _grupoSeleccionado;

  void _irASesionesDeGrupo(Grupo grupo) {
    setState(() {
      _grupoSeleccionado = grupo;
      _indiceActual = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pantallas = [
      GruposScreen(onSeleccionarGrupo: _irASesionesDeGrupo),
      SesionesScreen(grupoInicial: _grupoSeleccionado),
      const ReportesScreen(),
      const SincronizacionScreen(),
    ];

    return Scaffold(
      body: Column(
        children: [
          Container(
            color: const Color(0xFF003B75),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  const Icon(Icons.account_circle_rounded, color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Docente: ${widget.usuario}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: widget.onCerrarSesion,
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.logout_rounded, color: Colors.white, size: 15),
                          SizedBox(width: 4),
                          Text(
                            'Salir',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: pantallas[_indiceActual]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indiceActual,
        onDestinationSelected: (index) {
          setState(() {
            _indiceActual = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'Grupos',
          ),
          NavigationDestination(
            icon: Icon(Icons.class_outlined),
            selectedIcon: Icon(Icons.class_rounded),
            label: 'Sesiones',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Reportes',
          ),
          NavigationDestination(
            icon: Icon(Icons.sync_outlined),
            selectedIcon: Icon(Icons.sync_rounded),
            label: 'Sincronizar',
          ),
        ],
      ),
    );
  }
}