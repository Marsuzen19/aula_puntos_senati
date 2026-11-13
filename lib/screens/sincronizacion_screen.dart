import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../services/aula_service.dart';

class SincronizacionScreen extends StatefulWidget {
  const SincronizacionScreen({super.key});

  @override
  State<SincronizacionScreen> createState() => _SincronizacionScreenState();
}

class _SincronizacionScreenState extends State<SincronizacionScreen> {
  final AulaService _service = AulaService();
  int _pendientes = 0;
  bool _sincronizando = false;
  bool _tieneInternet = true;

  @override
  void initState() {
    super.initState();
    _actualizarEstado();
  }

  Future<bool> _verificarConexionInternet() async {
    if (kIsWeb) return true;
    try {
      final resultado = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      return resultado.isNotEmpty && resultado.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _actualizarEstado() async {
    final total = await _service.contarPendientesSincronizacion();
    final online = await _verificarConexionInternet();
    if (!mounted) return;
    setState(() {
      _pendientes = total;
      _tieneInternet = online;
    });
  }

  Future<void> _ejecutarSincronizacion() async {
    setState(() => _sincronizando = true);

    final online = await _verificarConexionInternet();
    if (!mounted) return;

    if (!online) {
      setState(() {
        _tieneInternet = false;
        _sincronizando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFD93025),
          content: Text('Sin conexión a internet. Tus cambios siguen guardados y pendientes de sincronizar.'),
        ),
      );
      return;
    }

    await _service.sincronizarTodo();
    await _actualizarEstado();

    if (!mounted) return;
    setState(() => _sincronizando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF1E8E3E),
        content: Text('Sincronización completada. Todos tus cambios están al día.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        title: const Text('Sincronización', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF004B93),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _sincronizando ? null : _actualizarEstado,
            tooltip: 'Comprobar conexión y pendientes',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indicador de estado de red
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _tieneInternet ? const Color(0xFFE6F4EA) : const Color(0xFFFCE8E6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _tieneInternet ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                          size: 16,
                          color: _tieneInternet ? const Color(0xFF1E8E3E) : const Color(0xFFD93025),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _tieneInternet ? 'Conectado a internet' : 'Modo sin conexión',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _tieneInternet ? const Color(0xFF1E8E3E) : const Color(0xFFD93025),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Icon(
                    _pendientes == 0 ? Icons.cloud_done_rounded : Icons.cloud_upload_rounded,
                    size: 52,
                    color: _pendientes == 0 ? const Color(0xFF1E8E3E) : const Color(0xFFE37400),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _pendientes == 0
                        ? 'Todo está al día'
                        : '$_pendientes registros pendientes',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _pendientes == 0
                        ? 'Todos tus grupos, asistencias y notas están guardados y sincronizados.'
                        : 'Tus cambios están seguros en el teléfono. Sincroniza cuando tengas internet.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _sincronizando ? null : _ejecutarSincronizacion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF004B93),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.sync_rounded),
                      label: Text(_sincronizando ? 'Verificando y sincronizando...' : 'Sincronizar ahora'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}