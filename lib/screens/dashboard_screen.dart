import 'package:flutter/material.dart';
import '../models/grupo.dart';
import '../services/aula_service.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int> onCambiarTab;
  final ValueChanged<Grupo> onAbrirGrupo;

  const DashboardScreen({
    super.key,
    required this.onCambiarTab,
    required this.onAbrirGrupo,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AulaService _service = AulaService();
  List<Grupo> _grupos = [];
  int _pendientesSync = 0;
  int _totalSesiones = 0;
  bool _modoOnline = true;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarResumen();
  }

  Future<void> _cargarResumen() async {
    final grupos = await _service.obtenerGrupos();
    final pendientes = await _service.contarPendientesSincronizacion();
    int sesionesCount = 0;
    for (final g in grupos) {
      final s = await _service.obtenerSesionesPorGrupo(g.id);
      sesionesCount += s.length;
    }

    if (!mounted) return;
    setState(() {
      _grupos = grupos;
      _pendientesSync = pendientes;
      _totalSesiones = sesionesCount;
      _cargando = false;
    });
  }

  Future<void> _sincronizar() async {
    if (!_modoOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activa el modo Online para sincronizar.')),
      );
      return;
    }
    await _service.sincronizarTodo();
    await _cargarResumen();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos sincronizados correctamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        title: const Text('Aula Puntos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF004B93),
        foregroundColor: Colors.white,
        actions: [
          GestureDetector(
            onTap: () => setState(() => _modoOnline = !_modoOnline),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: _modoOnline ? Colors.green.withValues(alpha: 0.25) : Colors.orange.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _modoOnline ? Colors.lightGreenAccent : Colors.orangeAccent,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(_modoOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    _modoOnline ? 'Online' : 'Offline',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: RefreshIndicator(
                  onRefresh: _cargarResumen,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // 1. Estado de sincronización compacto
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _pendientesSync > 0 ? const Color(0xFFFFFBEB) : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _pendientesSync > 0 ? const Color(0xFFFDE68A) : const Color(0xFFBBF7D0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _pendientesSync > 0 ? Icons.sync_problem_rounded : Icons.cloud_done_rounded,
                              color: _pendientesSync > 0 ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                              size: 26,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _pendientesSync > 0
                                        ? '$_pendientesSync cambios sin subir'
                                        : 'Todo sincronizado',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                  Text(
                                    _modoOnline ? 'Conectado al servidor' : 'Guardando en dispositivo',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            if (_pendientesSync > 0)
                              ElevatedButton(
                                onPressed: _sincronizar,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD97706),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Subir', style: TextStyle(fontSize: 13)),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 2. Indicadores rápidos en dos columnas
                      Row(
                        children: [
                          Expanded(
                            child: _tarjetaResumen(
                              titulo: 'Grupos Activos',
                              valor: '${_grupos.length}',
                              icono: Icons.groups_rounded,
                              onTap: () => widget.onCambiarTab(1),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _tarjetaResumen(
                              titulo: 'Sesiones Creadas',
                              valor: '$_totalSesiones',
                              icono: Icons.event_note_rounded,
                              onTap: () => widget.onCambiarTab(2),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // 3. Acceso directo a los cursos
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Acceso Rápido a Grupos',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                          TextButton(
                            onPressed: () => widget.onCambiarTab(1),
                            child: const Text('Ver todos'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      ..._grupos.map((g) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              onTap: () => widget.onAbrirGrupo(g),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF004B93),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        g.codigo,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        g.nombre,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _tarjetaResumen({
    required String titulo,
    required String valor,
    required IconData icono,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: const Color(0xFF004B93), size: 24),
            const SizedBox(height: 10),
            Text(
              valor,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 2),
            Text(
              titulo,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}