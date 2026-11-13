import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/grupo.dart';
import '../models/sesion.dart';
import '../models/estudiante.dart';
import '../services/aula_service.dart';

typedef SeccionTab = Map<String, String>;

class ControlSesionScreen extends StatefulWidget {
  final Grupo grupo;
  final Sesion sesion;

  const ControlSesionScreen({
    super.key,
    required this.grupo,
    required this.sesion,
  });

  @override
  State<ControlSesionScreen> createState() => _ControlSesionScreenState();
}

class _ControlSesionScreenState extends State<ControlSesionScreen> {
  final AulaService _service = AulaService();
  final ScrollController _scrollDiasController = ScrollController();

  List<Estudiante> _estudiantes = [];
  MapaAsistencia _asistencias = {};
  Set<String> _fechasRegistradas = {};
  MapaPuntosPorActividad _puntosPorActividad = {};

  DateTime _fechaAsistencia = DateTime.now();
  String _tabActiva = 'asistencia'; // 'asistencia', 'act-01', 'act-02', 'act-03'
  String _ordenLista = 'alfabetico';
  bool _cargandoInicial = true;

  static const List<String> _nombresMeses = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  static const List<String> _inicialesDiasSemana = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  final List<SeccionTab> _tabs = [
    {'id': 'asistencia', 'nombre': 'Asistencia'},
    {'id': 'act-01', 'nombre': 'Participación'},
    {'id': 'act-02', 'nombre': 'Ejercicios'},
    {'id': 'act-03', 'nombre': 'Sustentación'},
  ];

  final List<String> _criteriosNota = ['act-01', 'act-02', 'act-03'];

  bool get _esModoAsistencia => _tabActiva == 'asistencia';

  SeccionTab get _tabActual {
    return _tabs.firstWhere((t) => t['id'] == _tabActiva);
  }

  String _claveFecha(DateTime fecha) {
    return DateFormat('yyyy-MM-dd').format(fecha);
  }

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  @override
  void dispose() {
    _scrollDiasController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosIniciales() async {
    final claveHoy = _claveFecha(_fechaAsistencia);
    final estudiantes = await _service.obtenerEstudiantesPorGrupo(widget.grupo.id);
    final asistencias = await _service.obtenerAsistenciasDeSesionPorFecha(widget.sesion.id, claveHoy);
    final fechasGuardadas = await _service.obtenerFechasConAsistenciaEnSesion(widget.sesion.id);
    final puntosAgrupados = await _service.obtenerPuntosPorActividadEnSesion(widget.sesion.id);

    if (!mounted) return;
    setState(() {
      _estudiantes = estudiantes;
      _asistencias = asistencias;
      _fechasRegistradas = fechasGuardadas;
      _puntosPorActividad = puntosAgrupados;
      _cargandoInicial = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _centrarDiaSeleccionado());
  }

  void _centrarDiaSeleccionado() {
    if (!_scrollDiasController.hasClients) return;
    final offset = ((_fechaAsistencia.day - 3) * 46.0).clamp(
      0.0,
      _scrollDiasController.position.maxScrollExtent,
    );
    _scrollDiasController.animateTo(
      offset,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Future<void> _seleccionarFechaAsistencia(DateTime nuevaFecha) async {
    final clave = _claveFecha(nuevaFecha);
    setState(() {
      _fechaAsistencia = nuevaFecha;
    });

    final asistencias = await _service.obtenerAsistenciasDeSesionPorFecha(widget.sesion.id, clave);
    if (!mounted) return;
    setState(() {
      _asistencias = asistencias;
    });
  }

  Future<void> _cambiarMesAsistencia(int deltaMes) async {
    final nuevoMes = DateTime(_fechaAsistencia.year, _fechaAsistencia.month + deltaMes, 1);
    await _seleccionarFechaAsistencia(nuevoMes);
    WidgetsBinding.instance.addPostFrameCallback((_) => _centrarDiaSeleccionado());
  }

  Future<void> _abrirSelectorFechaCalendario() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fechaAsistencia,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (elegida != null) {
      await _seleccionarFechaAsistencia(elegida);
      WidgetsBinding.instance.addPostFrameCallback((_) => _centrarDiaSeleccionado());
    }
  }

  Future<void> _mostrarDialogoAgregarEstudiante() async {
    final ctrlCodigo = TextEditingController();
    final ctrlNombres = TextEditingController();
    final ctrlApellidos = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Agregar Estudiante', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text(
              'Se matriculará en ${widget.grupo.codigo}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrlCodigo,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'ID / Código institucional',
                  hintText: 'Ej. 001458225',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrlNombres,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombres',
                  hintText: 'Ej. María Fernanda',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrlApellidos,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Apellidos',
                  hintText: 'Ej. Quispe Mamani',
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
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF004B93),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final codigo = ctrlCodigo.text.trim();
              final nombres = ctrlNombres.text.trim();
              final apellidos = ctrlApellidos.text.trim();

              if (codigo.isEmpty || nombres.isEmpty || apellidos.isEmpty) return;

              await _service.agregarEstudianteAGrupo(
                grupoId: widget.grupo.id,
                codigoInstitucional: codigo,
                nombres: nombres,
                apellidos: apellidos,
              );

              if (ctx.mounted) Navigator.pop(ctx);
              await _cargarDatosIniciales();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$nombres $apellidos agregado a la sesión'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            icon: const Icon(Icons.person_add_rounded, size: 18),
            label: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  int _puntosEnCriterioActual(String estudianteId) {
    return _puntosPorActividad[_tabActiva]?[estudianteId] ?? 0;
  }

  int _sumaTotalEstudiante(String estudianteId) {
    int suma = 0;
    for (final actId in _criteriosNota) {
      suma += _puntosPorActividad[actId]?[estudianteId] ?? 0;
    }
    return suma;
  }

  String _promedioEstudiante(String estudianteId) {
    final suma = _sumaTotalEstudiante(estudianteId);
    return (suma / _criteriosNota.length).toStringAsFixed(1);
  }

  List<Estudiante> get _estudiantesOrdenados {
    final lista = List<Estudiante>.from(_estudiantes);
    if (_ordenLista == 'mayor') {
      lista.sort((a, b) => _sumaTotalEstudiante(b.id).compareTo(_sumaTotalEstudiante(a.id)));
    } else if (_ordenLista == 'menor') {
      lista.sort((a, b) => _sumaTotalEstudiante(a.id).compareTo(_sumaTotalEstudiante(b.id)));
    }
    return lista;
  }

  String get _etiquetaOrden {
    switch (_ordenLista) {
      case 'mayor':
        return 'Mayor promedio';
      case 'menor':
        return 'Menor promedio';
      default:
        return 'Alfabético (A-Z)';
    }
  }

  Future<void> _marcarAsistencia(Estudiante estudiante, String estado) async {
    if (_asistencias[estudiante.id] == estado) return;
    final clave = _claveFecha(_fechaAsistencia);

    setState(() {
      _asistencias[estudiante.id] = estado;
      _fechasRegistradas.add(clave);
    });

    await _service.registrarAsistencia(
      sesionId: widget.sesion.id,
      estudianteId: estudiante.id,
      fechaAsistencia: clave,
      estado: estado,
    );
  }

  Future<void> _marcarTodosPresentes() async {
    final clave = _claveFecha(_fechaAsistencia);

    setState(() {
      for (final est in _estudiantes) {
        _asistencias[est.id] = 'Presente';
      }
      _fechasRegistradas.add(clave);
    });

    for (final est in _estudiantes) {
      await _service.registrarAsistencia(
        sesionId: widget.sesion.id,
        estudianteId: est.id,
        fechaAsistencia: clave,
        estado: 'Presente',
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Todos marcados como Presente (${DateFormat('dd/MM').format(_fechaAsistencia)})'),
          duration: const Duration(milliseconds: 900),
        ),
      );
    }
  }

  Future<void> _guardarPuntaje(Estudiante estudiante, int nuevoPuntaje) async {
    final int puntajeActual = _puntosEnCriterioActual(estudiante.id);
    final int delta = nuevoPuntaje - puntajeActual;

    if (delta == 0) return;

    setState(() {
      _puntosPorActividad.putIfAbsent(_tabActiva, () => {});
      _puntosPorActividad[_tabActiva]![estudiante.id] = nuevoPuntaje;
    });

    await _service.registrarParticipacion(
      sesionId: widget.sesion.id,
      estudianteId: estudiante.id,
      actividadId: _tabActiva,
      puntos: delta,
    );
  }

  Future<void> _mostrarDialogoEditarNota(Estudiante estudiante) async {
    final int puntajeActual = _puntosEnCriterioActual(estudiante.id);
    final controladorPuntaje = TextEditingController(text: puntajeActual.toString());

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(estudiante.nombreCompleto, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 2),
            Text(
              'Criterio: ${_tabActual['nombre']}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        content: TextField(
          controller: controladorPuntaje,
          autofocus: true,
          keyboardType: TextInputType.number,
          onSubmitted: (val) async {
            final nuevoPuntaje = int.tryParse(val.trim());
            if (nuevoPuntaje == null || nuevoPuntaje < 0) return;
            Navigator.pop(ctx);
            await _guardarPuntaje(estudiante, nuevoPuntaje);
          },
          decoration: const InputDecoration(
            labelText: 'Puntaje',
            border: OutlineInputBorder(),
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
              final nuevoPuntaje = int.tryParse(controladorPuntaje.text.trim());
              if (nuevoPuntaje == null || nuevoPuntaje < 0) return;
              Navigator.pop(ctx);
              await _guardarPuntaje(estudiante, nuevoPuntaje);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // Selector de días del mes dentro de la pestaña Asistencia
  Widget _selectorDiasDelMes() {
    final diasEnMes = DateUtils.getDaysInMonth(_fechaAsistencia.year, _fechaAsistencia.month);
    final tituloMes = '${_nombresMeses[_fechaAsistencia.month - 1]} ${_fechaAsistencia.year}';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 2),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // Cabecera de mes y botón de calendario
          Row(
            children: [
              IconButton(
                onPressed: () => _cambiarMesAsistencia(-1),
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: _abrirSelectorFechaCalendario,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 15, color: Color(0xFF004B93)),
                      const SizedBox(width: 6),
                      Text(
                        tituloMes,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _cambiarMesAsistencia(1),
                icon: const Icon(Icons.chevron_right_rounded, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Tira horizontal de días del mes (1 .. 30/31)
          SizedBox(
            height: 50,
            child: ListView.builder(
              controller: _scrollDiasController,
              scrollDirection: Axis.horizontal,
              itemCount: diasEnMes,
              itemBuilder: (context, index) {
                final dia = index + 1;
                final fechaDia = DateTime(_fechaAsistencia.year, _fechaAsistencia.month, dia);
                final clave = _claveFecha(fechaDia);
                final seleccionado = _fechaAsistencia.day == dia;
                final tieneRegistro = _fechasRegistradas.contains(clave);
                final letraSemana = _inicialesDiasSemana[fechaDia.weekday - 1];

                return GestureDetector(
                  onTap: () => _seleccionarFechaAsistencia(fechaDia),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    width: 40,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: seleccionado ? const Color(0xFF004B93) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: seleccionado
                            ? const Color(0xFF004B93)
                            : tieneRegistro
                                ? const Color(0xFF1E8E3E)
                                : Colors.grey.shade300,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          letraSemana,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: seleccionado ? Colors.white70 : Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '$dia',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: seleccionado ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: tieneRegistro
                                ? (seleccionado ? Colors.lightGreenAccent : const Color(0xFF1E8E3E))
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _botonLetraAsistencia({
    required Estudiante est,
    required String estadoCompleto,
    required String letra,
    required Color colorActivo,
    required String estadoActual,
  }) {
    final bool seleccionado = estadoActual == estadoCompleto;

    return GestureDetector(
      onTap: () => _marcarAsistencia(est, estadoCompleto),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: seleccionado ? colorActivo : const Color(0xFFF1F3F5),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          letra,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: seleccionado ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _divisorVertical({double alto = 28}) {
    return Container(
      width: 1,
      height: alto,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.grey.shade300,
    );
  }

  @override
  Widget build(BuildContext context) {
    final listaVisible = _estudiantesOrdenados;
    final bool filtroActivo = _ordenLista != 'alfabetico';
    final fechaFormateada = DateFormat('dd/MM/yyyy').format(_fechaAsistencia);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sesión #${widget.sesion.numeroSesion} · ${widget.sesion.tema}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            Text(
              widget.grupo.codigo,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF004B93),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _mostrarDialogoAgregarEstudiante,
            tooltip: 'Agregar estudiante al grupo',
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
          ),
          if (_esModoAsistencia)
            TextButton.icon(
              onPressed: _estudiantes.isEmpty ? null : _marcarTodosPresentes,
              icon: const Icon(Icons.done_all_rounded, color: Colors.lightGreenAccent, size: 18),
              label: const Text(
                'Todos P',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
      ),
      body: _cargandoInicial
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 1. Selector de sección: Asistencia | Participación | Ejercicios | Sustentación
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _tabs.map((tab) {
                            final bool activo = tab['id'] == _tabActiva;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: GestureDetector(
                                onTap: () => setState(() => _tabActiva = tab['id']!),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: activo ? const Color(0xFF004B93) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    tab['nombre']!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: activo ? FontWeight.w600 : FontWeight.w500,
                                      color: activo ? Colors.white : const Color(0xFF334155),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. Selector de días del mes (visible dentro de la pestaña Asistencia)
                if (_esModoAsistencia)
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: _selectorDiasDelMes(),
                    ),
                  ),

                // 3. Barra superior contextual
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Row(
                        children: [
                          Text(
                            _esModoAsistencia
                                ? 'Asistencia: $fechaFormateada'
                                : '${listaVisible.length} estudiantes',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                          ),
                          const Spacer(),
                          if (_esModoAsistencia)
                            Text(
                              'P · T · F · J',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
                            )
                          else
                            PopupMenuButton<String>(
                              initialValue: _ordenLista,
                              tooltip: 'Ordenar lista',
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              onSelected: (valor) => setState(() => _ordenLista = valor),
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'alfabetico', child: Text('Alfabético (A-Z)')),
                                const PopupMenuItem(value: 'mayor', child: Text('Mayor promedio primero')),
                                const PopupMenuItem(value: 'menor', child: Text('Menor promedio primero')),
                              ],
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: filtroActivo ? const Color(0xFFE8F0FE) : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: filtroActivo ? const Color(0xFF004B93) : Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.filter_list_rounded,
                                      size: 15,
                                      color: filtroActivo ? const Color(0xFF004B93) : Colors.black54,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _etiquetaOrden,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: filtroActivo ? const Color(0xFF004B93) : Colors.black87,
                                      ),
                                    ),
                                    const Icon(Icons.arrow_drop_down_rounded, size: 18),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 4. Planilla estructurada
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: listaVisible.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Aún no hay estudiantes matriculados en ${widget.grupo.codigo}.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF004B93),
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: _mostrarDialogoAgregarEstudiante,
                                      icon: const Icon(Icons.person_add_rounded, size: 18),
                                      label: const Text('Agregar Estudiante'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Container(
                              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8F9FA),
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                      border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'ESTUDIANTE',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ),
                                        _divisorVertical(alto: 18),
                                        if (_esModoAsistencia)
                                          SizedBox(
                                            width: 144,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: ['P', 'T', 'F', 'J'].map((letra) {
                                                return SizedBox(
                                                  width: 32,
                                                  child: Center(
                                                    child: Text(
                                                      letra,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.grey.shade600,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          )
                                        else
                                          SizedBox(
                                            width: 68,
                                            child: Center(
                                              child: Text(
                                                'NOTA',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                  Expanded(
                                    child: ListView.separated(
                                      itemCount: listaVisible.length,
                                      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                                      itemBuilder: (context, index) {
                                        final est = listaVisible[index];
                                        final estadoActual = _asistencias[est.id] ?? '';
                                        final puntosCriterio = _puntosEnCriterioActual(est.id);
                                        final promedio = _promedioEstudiante(est.id);

                                        return Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      est.nombreCompleto,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 14,
                                                        color: Color(0xFF1F2937),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      _esModoAsistencia
                                                          ? 'ID: ${est.codigoInstitucional}'
                                                          : 'Prom: $promedio',
                                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              _divisorVertical(),

                                              if (_esModoAsistencia)
                                                SizedBox(
                                                  width: 144,
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      _botonLetraAsistencia(
                                                        est: est,
                                                        estadoCompleto: 'Presente',
                                                        letra: 'P',
                                                        colorActivo: const Color(0xFF1E8E3E),
                                                        estadoActual: estadoActual,
                                                      ),
                                                      _botonLetraAsistencia(
                                                        est: est,
                                                        estadoCompleto: 'Tardanza',
                                                        letra: 'T',
                                                        colorActivo: const Color(0xFFE37400),
                                                        estadoActual: estadoActual,
                                                      ),
                                                      _botonLetraAsistencia(
                                                        est: est,
                                                        estadoCompleto: 'Falta',
                                                        letra: 'F',
                                                        colorActivo: const Color(0xFFD93025),
                                                        estadoActual: estadoActual,
                                                      ),
                                                      _botonLetraAsistencia(
                                                        est: est,
                                                        estadoCompleto: 'Justificado',
                                                        letra: 'J',
                                                        colorActivo: const Color(0xFF1A73E8),
                                                        estadoActual: estadoActual,
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              else
                                                InkWell(
                                                  onTap: () => _mostrarDialogoEditarNota(est),
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Container(
                                                    width: 68,
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                                    decoration: BoxDecoration(
                                                      color: puntosCriterio > 0
                                                          ? const Color(0xFFE8F0FE)
                                                          : const Color(0xFFF1F3F5),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Text(
                                                          '$puntosCriterio',
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 13,
                                                            color: puntosCriterio > 0
                                                                ? const Color(0xFF004B93)
                                                                : Colors.black87,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 5),
                                                        Icon(
                                                          Icons.edit_rounded,
                                                          size: 13,
                                                          color: puntosCriterio > 0
                                                              ? const Color(0xFF004B93)
                                                              : Colors.black45,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}