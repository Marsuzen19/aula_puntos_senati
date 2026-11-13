import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/grupo.dart';
import '../models/estudiante.dart';
import '../models/sesion.dart';
import '../models/participacion.dart';

typedef MapaAsistencia = Map<String, String>;
typedef MapaPuntos = Map<String, int>;
typedef MapaPuntosPorActividad = Map<String, MapaPuntos>;
typedef MapaObservacionesPorActividad = Map<String, MapaAsistencia>;
typedef FilaReporte = Map<String, dynamic>;

class AulaService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  // 1. Grupos
  Future<List<Grupo>> obtenerGrupos() async {
    final db = await _dbHelper.database;
    final maps = await db.query('grupos', orderBy: 'codigo ASC');
    return maps.map((m) => Grupo.fromMap(m)).toList();
  }

  Future<Grupo> crearGrupo({
    required String nombreGrupo,
    required String programaAcademico,
    required String asignatura,
    required String periodo,
    required String codigoSeccion,
  }) async {
    final db = await _dbHelper.database;
    final nuevo = Grupo(
      id: _uuid.v4(),
      codigo: codigoSeccion,
      nombre: asignatura,
      nombreGrupo: nombreGrupo,
      programaAcademico: programaAcademico,
      asignatura: asignatura,
      periodo: periodo,
      syncStatus: 'pendiente',
    );
    await db.insert('grupos', nuevo.toMap());
    return nuevo;
  }

  // 2. Estudiantes
  Future<List<Estudiante>> obtenerEstudiantesPorGrupo(String grupoId) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT e.* FROM estudiantes e
      INNER JOIN grupo_estudiante ge ON e.id = ge.estudiante_id
      WHERE ge.grupo_id = ? AND ge.estado = 'Activo'
      ORDER BY e.apellidos ASC
    ''', [grupoId]);
    return maps.map((m) => Estudiante.fromMap(m)).toList();
  }

  Future<void> agregarEstudianteAGrupo({
    required String grupoId,
    required String codigoInstitucional,
    required String nombres,
    required String apellidos,
  }) async {
    final db = await _dbHelper.database;

    final existente = await db.query(
      'estudiantes',
      where: 'codigo_institucional = ?',
      whereArgs: [codigoInstitucional],
    );

    String estudianteId;
    if (existente.isNotEmpty) {
      estudianteId = existente.first['id'] as String;
    } else {
      estudianteId = _uuid.v4();
      await db.insert('estudiantes', {
        'id': estudianteId,
        'codigo_institucional': codigoInstitucional,
        'nombres': nombres,
        'apellidos': apellidos,
        'estado': 'Activo',
      });
    }

    await db.insert(
      'grupo_estudiante',
      {
        'grupo_id': grupoId,
        'estudiante_id': estudianteId,
        'fecha_incorporacion': DateTime.now().toIso8601String().split('T').first,
        'estado': 'Activo',
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // 3. Sesiones
  Future<List<Sesion>> obtenerSesionesPorGrupo(String grupoId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'sesiones',
      where: 'grupo_id = ?',
      whereArgs: [grupoId],
      orderBy: 'numero_sesion DESC, fecha DESC',
    );
    return maps.map((m) => Sesion.fromMap(m)).toList();
  }

  Future<Sesion> crearSesion({
    required String grupoId,
    required int numeroSesion,
    required String tema,
    required String tipoSesion,
    required String duracion,
    String observaciones = '',
  }) async {
    final db = await _dbHelper.database;
    final nuevaSesion = Sesion(
      id: _uuid.v4(),
      grupoId: grupoId,
      numeroSesion: numeroSesion,
      fecha: DateTime.now().toIso8601String(),
      tema: tema,
      tipoSesion: tipoSesion,
      duracion: duracion,
      observaciones: observaciones,
      syncStatus: 'pendiente',
    );
    await db.insert('sesiones', nuevaSesion.toMap());
    return nuevaSesion;
  }

  // 4. Asistencia por fecha dentro de la sesión
  Future<void> registrarAsistencia({
    required String sesionId,
    required String estudianteId,
    required String fechaAsistencia, // Formato YYYY-MM-DD
    required String estado,
    String observacion = '',
  }) async {
    final db = await _dbHelper.database;
    final existente = await db.query(
      'asistencia',
      where: 'sesion_id = ? AND estudiante_id = ? AND fecha_asistencia = ?',
      whereArgs: [sesionId, estudianteId, fechaAsistencia],
    );

    final ahora = DateTime.now().toIso8601String();

    if (existente.isNotEmpty) {
      await db.update(
        'asistencia',
        {
          'estado': estado,
          'fecha_registro': ahora,
          'observacion': observacion,
          'sync_status': 'pendiente',
        },
        where: 'id = ?',
        whereArgs: [existente.first['id']],
      );
    } else {
      await db.insert('asistencia', {
        'id': _uuid.v4(),
        'sesion_id': sesionId,
        'estudiante_id': estudianteId,
        'fecha_asistencia': fechaAsistencia,
        'estado': estado,
        'fecha_registro': ahora,
        'observacion': observacion,
        'sync_status': 'pendiente',
      });
    }
  }

  Future<MapaAsistencia> obtenerAsistenciasDeSesionPorFecha(
    String sesionId,
    String fechaAsistencia,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'asistencia',
      where: 'sesion_id = ? AND fecha_asistencia = ?',
      whereArgs: [sesionId, fechaAsistencia],
    );
    final MapaAsistencia resultado = {};
    for (var m in maps) {
      resultado[m['estudiante_id'] as String] = m['estado'] as String;
    }
    return resultado;
  }

  Future<Set<String>> obtenerFechasConAsistenciaEnSesion(String sesionId) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT DISTINCT fecha_asistencia
      FROM asistencia
      WHERE sesion_id = ?
    ''', [sesionId]);

    return maps.map((m) => m['fecha_asistencia'] as String).toSet();
  }

  // 5. Participaciones y notas
  Future<void> registrarParticipacion({
    required String sesionId,
    required String estudianteId,
    required String actividadId,
    required int puntos,
    String observacion = '',
  }) async {
    final db = await _dbHelper.database;
    final nueva = Participacion(
      id: _uuid.v4(),
      sesionId: sesionId,
      estudianteId: estudianteId,
      actividadId: actividadId,
      puntos: puntos,
      fecha: DateTime.now().toIso8601String(),
      observacion: observacion,
      syncStatus: 'pendiente',
    );
    await db.insert('participaciones', nueva.toMap());
  }

  Future<MapaPuntosPorActividad> obtenerPuntosPorActividadEnSesion(String sesionId) async {
    final db = await _dbHelper.database;
    final maps = await db.rawQuery('''
      SELECT actividad_id, estudiante_id, SUM(puntos) as total
      FROM participaciones
      WHERE sesion_id = ?
      GROUP BY actividad_id, estudiante_id
    ''', [sesionId]);

    final MapaPuntosPorActividad resultado = {};
    for (var m in maps) {
      final actId = m['actividad_id'] as String;
      final estId = m['estudiante_id'] as String;
      final total = (m['total'] as int?) ?? 0;

      resultado.putIfAbsent(actId, () => {});
      resultado[actId]![estId] = total;
    }
    return resultado;
  }

  // 6. Sincronización
  Future<int> contarPendientesSincronizacion() async {
    final db = await _dbHelper.database;
    final g = Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM grupos WHERE sync_status = 'pendiente'")) ?? 0;
    final s = Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM sesiones WHERE sync_status = 'pendiente'")) ?? 0;
    final a = Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM asistencia WHERE sync_status = 'pendiente'")) ?? 0;
    final p = Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM participaciones WHERE sync_status = 'pendiente'")) ?? 0;
    return g + s + a + p;
  }

  Future<void> sincronizarTodo() async {
    final db = await _dbHelper.database;
    await db.update('grupos', {'sync_status': 'sincronizado'}, where: "sync_status = 'pendiente'");
    await db.update('sesiones', {'sync_status': 'sincronizado'}, where: "sync_status = 'pendiente'");
    await db.update('asistencia', {'sync_status': 'sincronizado'}, where: "sync_status = 'pendiente'");
    await db.update('participaciones', {'sync_status': 'sincronizado'}, where: "sync_status = 'pendiente'");
  }

  // 7. Reportes
  Future<List<FilaReporte>> obtenerReporteConsolidadoGrupo(String grupoId) async {
    final db = await _dbHelper.database;
    final estudiantes = await obtenerEstudiantesPorGrupo(grupoId);
    final sesiones = await obtenerSesionesPorGrupo(grupoId);

    final diasDistintos = Sqflite.firstIntValue(await db.rawQuery('''
          SELECT COUNT(DISTINCT a.fecha_asistencia)
          FROM asistencia a
          INNER JOIN sesiones s ON a.sesion_id = s.id
          WHERE s.grupo_id = ?
        ''', [grupoId])) ??
        0;

    final int totalSesiones = sesiones.length;
    final int baseAsistencia = diasDistintos > totalSesiones ? diasDistintos : totalSesiones;

    final asistenciasRows = await db.rawQuery('''
      SELECT a.estudiante_id, a.estado, COUNT(*) as cantidad
      FROM asistencia a
      INNER JOIN sesiones s ON a.sesion_id = s.id
      WHERE s.grupo_id = ?
      GROUP BY a.estudiante_id, a.estado
    ''', [grupoId]);

    final Map<String, MapaPuntos> conteoAsistencia = {};
    for (var row in asistenciasRows) {
      final estId = row['estudiante_id'] as String;
      final estado = row['estado'] as String;
      final cant = (row['cantidad'] as int?) ?? 0;
      conteoAsistencia.putIfAbsent(estId, () => {});
      conteoAsistencia[estId]![estado] = cant;
    }

    final puntosRows = await db.rawQuery('''
      SELECT p.estudiante_id, p.actividad_id, SUM(p.puntos) as total
      FROM participaciones p
      INNER JOIN sesiones s ON p.sesion_id = s.id
      WHERE s.grupo_id = ?
      GROUP BY p.estudiante_id, p.actividad_id
    ''', [grupoId]);

    final Map<String, MapaPuntos> conteoPuntos = {};
    for (var row in puntosRows) {
      final estId = row['estudiante_id'] as String;
      final actId = row['actividad_id'] as String;
      final total = (row['total'] as int?) ?? 0;
      conteoPuntos.putIfAbsent(estId, () => {});
      conteoPuntos[estId]![actId] = total;
    }

    final List<FilaReporte> reporte = [];

    for (final est in estudiantes) {
      final asist = conteoAsistencia[est.id] ?? {};
      final int p = asist['Presente'] ?? 0;
      final int t = asist['Tardanza'] ?? 0;
      final int f = asist['Falta'] ?? 0;
      final int j = asist['Justificado'] ?? 0;

      final double porcentajeAsist = baseAsistencia == 0
          ? 0.0
          : ((p + t + j) / baseAsistencia) * 100;

      final pts = conteoPuntos[est.id] ?? {};
      final int part = pts['act-01'] ?? 0;
      final int ejer = pts['act-02'] ?? 0;
      final int sust = pts['act-03'] ?? 0;
      final int sumaTotal = part + ejer + sust;
      final double promedio = sumaTotal / 3.0;

      reporte.add({
        'codigo': est.codigoInstitucional,
        'nombre': est.nombreCompleto,
        'totalSesiones': baseAsistencia,
        'presentes': p,
        'tardanzas': t,
        'faltas': f,
        'justificados': j,
        'porcentajeAsistencia': porcentajeAsist,
        'participacion': part,
        'ejercicios': ejer,
        'sustentacion': sust,
        'totalPuntos': sumaTotal,
        'promedio': promedio,
      });
    }

    return reporte;
  }
}