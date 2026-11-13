import 'package:flutter/material.dart';
import '../models/grupo.dart';
import '../services/aula_service.dart';

class GruposScreen extends StatefulWidget {
  final ValueChanged<Grupo> onSeleccionarGrupo;

  const GruposScreen({super.key, required this.onSeleccionarGrupo});

  @override
  State<GruposScreen> createState() => _GruposScreenState();
}

class _GruposScreenState extends State<GruposScreen> {
  final AulaService _service = AulaService();
  List<Grupo> _grupos = [];
  Map<String, int> _conteoAlumnos = {};
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarGrupos();
  }

  Future<void> _cargarGrupos() async {
    final lista = await _service.obtenerGrupos();
    final Map<String, int> conteos = {};
    for (final g in lista) {
      final ests = await _service.obtenerEstudiantesPorGrupo(g.id);
      conteos[g.id] = ests.length;
    }
    if (!mounted) return;
    setState(() {
      _grupos = lista;
      _conteoAlumnos = conteos;
      _cargando = false;
    });
  }

  Future<void> _mostrarDialogoNuevoGrupo() async {
    final ctrlNombreGrupo = TextEditingController();
    final ctrlPrograma = TextEditingController(text: '2026-20');
    final ctrlAsignatura = TextEditingController();
    final ctrlPeriodo = TextEditingController(text: '2026-20');
    final ctrlCodigoSeccion = TextEditingController();

    void actualizarCodigoSugerido() {
      final prog = ctrlPrograma.text.trim();
      final nom = ctrlNombreGrupo.text.trim();
      if (prog.isNotEmpty && nom.isNotEmpty) {
        ctrlCodigoSeccion.text = '$prog-$nom';
      }
    }

    ctrlNombreGrupo.addListener(actualizarCodigoSugerido);
    ctrlPrograma.addListener(actualizarCodigoSugerido);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Nuevo Grupo Académico', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrlNombreGrupo,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nombre de grupo',
                  hintText: 'Ej. 202601',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ctrlPrograma,
                      decoration: const InputDecoration(
                        labelText: 'Programa académico',
                        hintText: 'Ej. 2026-20',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: ctrlPeriodo,
                      decoration: const InputDecoration(
                        labelText: 'Periodo',
                        hintText: 'Ej. 2026-20',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrlAsignatura,
                decoration: const InputDecoration(
                  labelText: 'Asignatura / Curso',
                  hintText: 'Ej. Desarrollo Web',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrlCodigoSeccion,
                decoration: const InputDecoration(
                  labelText: 'Código de sección',
                  hintText: 'Ej. 2026-20-202601',
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
              final nombreGrupo = ctrlNombreGrupo.text.trim();
              final programa = ctrlPrograma.text.trim();
              final asignatura = ctrlAsignatura.text.trim();
              final periodo = ctrlPeriodo.text.trim();
              final codigo = ctrlCodigoSeccion.text.trim();

              if (nombreGrupo.isEmpty || asignatura.isEmpty || codigo.isEmpty) return;

              await _service.crearGrupo(
                nombreGrupo: nombreGrupo,
                programaAcademico: programa,
                asignatura: asignatura,
                periodo: periodo,
                codigoSeccion: codigo,
              );
              if (ctx.mounted) Navigator.pop(ctx);
              await _cargarGrupos();
            },
            child: const Text('Crear Grupo'),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarDialogoGestionarAlumnos(Grupo grupo) async {
    final ctrlCodigo = TextEditingController();
    final ctrlNombres = TextEditingController();
    final ctrlApellidos = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estudiantes · ${grupo.codigo}',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    grupo.asignatura,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: ctrlCodigo,
                          decoration: const InputDecoration(
                            labelText: 'ID / Código',
                            hintText: '001458220',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: ctrlNombres,
                          decoration: const InputDecoration(
                            labelText: 'Nombres',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: ctrlApellidos,
                          decoration: const InputDecoration(
                            labelText: 'Apellidos',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF004B93),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        ),
                        onPressed: () async {
                          final cod = ctrlCodigo.text.trim();
                          final nom = ctrlNombres.text.trim();
                          final ape = ctrlApellidos.text.trim();
                          if (cod.isEmpty || nom.isEmpty || ape.isEmpty) return;

                          await _service.agregarEstudianteAGrupo(
                            grupoId: grupo.id,
                            codigoInstitucional: cod,
                            nombres: nom,
                            apellidos: ape,
                          );
                          ctrlCodigo.clear();
                          ctrlNombres.clear();
                          ctrlApellidos.clear();
                          await _cargarGrupos();
                          setModalState(() {});
                        },
                        icon: const Icon(Icons.person_add_rounded, size: 18),
                        label: const Text('Agregar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder(
                    future: _service.obtenerEstudiantesPorGrupo(grupo.id),
                    builder: (context, snapshot) {
                      final alumnos = snapshot.data ?? [];
                      if (alumnos.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: Text('Aún no hay estudiantes en este grupo.')),
                        );
                      }
                      return ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: alumnos.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final a = alumnos[i];
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                radius: 14,
                                backgroundColor: const Color(0xFFE8F0FE),
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF004B93), fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(a.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.w500)),
                              trailing: Text(a.codigoInstitucional, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        title: const Text('Mis Grupos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF004B93),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoNuevoGrupo,
        backgroundColor: const Color(0xFF004B93),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo Grupo'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 84),
                  itemCount: _grupos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final grupo = _grupos[index];
                    final cantAlumnos = _conteoAlumnos[grupo.id] ?? 0;

                    return InkWell(
                      onTap: () => widget.onSeleccionarGrupo(grupo),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F0FE),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    grupo.codigo,
                                    style: const TextStyle(
                                      color: Color(0xFF004B93),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Periodo ${grupo.periodo}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                                  ),
                                ),
                                const Spacer(),
                                TextButton.icon(
                                  onPressed: () => _mostrarDialogoGestionarAlumnos(grupo),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                                  label: Text('$cantAlumnos alumnos', style: const TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        grupo.asignatura,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      if (grupo.programaAcademico.isNotEmpty || grupo.nombreGrupo.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 3),
                                          child: Text(
                                            'Programa: ${grupo.programaAcademico}  ·  Grupo: ${grupo.nombreGrupo}',
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
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
    );
  }
}