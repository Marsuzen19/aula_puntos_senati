import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/grupo.dart';
import '../models/sesion.dart';
import '../services/aula_service.dart';
import 'control_sesion_screen.dart';

class SesionesScreen extends StatefulWidget {
  final Grupo? grupoInicial;

  const SesionesScreen({super.key, this.grupoInicial});

  @override
  State<SesionesScreen> createState() => _SesionesScreenState();
}

class _SesionesScreenState extends State<SesionesScreen> {
  final AulaService _service = AulaService();
  List<Grupo> _grupos = [];
  Grupo? _grupoActivo;
  List<Sesion> _sesiones = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  @override
  void didUpdateWidget(covariant SesionesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.grupoInicial != null && widget.grupoInicial?.id != _grupoActivo?.id) {
      _seleccionarGrupo(widget.grupoInicial!);
    }
  }

  Future<void> _inicializar() async {
    final grupos = await _service.obtenerGrupos();
    if (!mounted) return;
    if (grupos.isEmpty) {
      setState(() => _cargando = false);
      return;
    }

    final inicial = widget.grupoInicial ?? grupos.first;
    setState(() {
      _grupos = grupos;
      _grupoActivo = inicial;
    });
    await _cargarSesiones(inicial.id);
  }

  Future<void> _seleccionarGrupo(Grupo grupo) async {
    setState(() {
      _grupoActivo = grupo;
      _cargando = true;
    });
    await _cargarSesiones(grupo.id);
  }

  Future<void> _cargarSesiones(String grupoId) async {
    final lista = await _service.obtenerSesionesPorGrupo(grupoId);
    if (!mounted) return;
    setState(() {
      _sesiones = lista;
      _cargando = false;
    });
  }

  Future<void> _mostrarDialogoNuevaSesion() async {
    if (_grupoActivo == null) return;

    final siguienteNumero = _sesiones.isEmpty
        ? 1
        : _sesiones.map((s) => s.numeroSesion).reduce((a, b) => a > b ? a : b) + 1;

    final ctrlNumero = TextEditingController(text: siguienteNumero.toString());
    final ctrlTema = TextEditingController();
    final ctrlDuracion = TextEditingController(text: '4 horas');
    final ctrlObservaciones = TextEditingController();
    String tipoSeleccionado = 'Teoría (Tecnología)';

    final tiposSesion = [
      'Teoría (Tecnología)',
      'Taller / Laboratorio',
      'Formación Práctica',
      'Evaluación',
    ];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nueva Sesión Académica', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                Text(
                  '${_grupoActivo!.codigo} · ${_grupoActivo!.asignatura}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.normal),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 110,
                        child: TextField(
                          controller: ctrlNumero,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'N° Sesión',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: ctrlDuracion,
                          decoration: const InputDecoration(
                            labelText: 'Duración',
                            hintText: 'Ej. 4 horas',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ctrlTema,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Tema desarrollado',
                      hintText: 'Ej. Formación dual',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: tipoSeleccionado,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de sesión',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: tiposSesion.map((t) {
                      return DropdownMenuItem<String>(
                        value: t,
                        child: Text(t, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => tipoSeleccionado = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ctrlObservaciones,
                    decoration: const InputDecoration(
                      labelText: 'Observaciones',
                      hintText: 'Ej. Clase 01',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004B93),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final tema = ctrlTema.text.trim();
                  if (tema.isEmpty) return;

                  final numSesion = int.tryParse(ctrlNumero.text.trim()) ?? siguienteNumero;
                  final duracion = ctrlDuracion.text.trim().isEmpty ? '4 horas' : ctrlDuracion.text.trim();
                  final obs = ctrlObservaciones.text.trim();

                  await _service.crearSesion(
                    grupoId: _grupoActivo!.id,
                    numeroSesion: numSesion,
                    tema: tema,
                    tipoSesion: tipoSeleccionado,
                    duracion: duracion,
                    observaciones: obs,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  await _cargarSesiones(_grupoActivo!.id);
                },
                child: const Text('Crear Sesión'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatearFecha(String isoFecha) {
    try {
      return DateFormat('dd MMM yyyy · HH:mm').format(DateTime.parse(isoFecha));
    } catch (_) {
      return isoFecha;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        title: const Text('Sesiones de Clase', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF004B93),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _grupoActivo == null ? null : _mostrarDialogoNuevaSesion,
        backgroundColor: const Color(0xFF004B93),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva Sesión'),
      ),
      body: Column(
        children: [
          if (_grupos.isNotEmpty)
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _grupos.map((g) {
                        final seleccionado = g.id == _grupoActivo?.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('${g.codigo} · ${g.asignatura}'),
                            selected: seleccionado,
                            selectedColor: const Color(0xFF004B93),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: seleccionado ? Colors.white : const Color(0xFF334155),
                            ),
                            onSelected: (_) => _seleccionarGrupo(g),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),

          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: _sesiones.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'No hay sesiones registradas en este grupo.\nToca "+ Nueva Sesión" para comenzar.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 84),
                              itemCount: _sesiones.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final sesion = _sesiones[index];
                                final pendiente = sesion.syncStatus == 'pendiente';

                                return InkWell(
                                  onTap: () async {
                                    if (_grupoActivo == null) return;
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ControlSesionScreen(
                                          grupo: _grupoActivo!,
                                          sesion: sesion,
                                        ),
                                      ),
                                    );
                                    _cargarSesiones(_grupoActivo!.id);
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF004B93),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'Sesión #${sesion.numeroSesion}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                sesion.tipoSesion,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF004B93),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: pendiente ? Colors.orange : Colors.green,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                sesion.tema,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16,
                                                  color: Color(0xFF1E293B),
                                                ),
                                              ),
                                            ),
                                            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 12,
                                          runSpacing: 4,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF64748B)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  sesion.duracion,
                                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF64748B)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _formatearFecha(sesion.fecha),
                                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                                ),
                                              ],
                                            ),
                                            if (sesion.observaciones.isNotEmpty)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  sesion.observaciones,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF475569),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}