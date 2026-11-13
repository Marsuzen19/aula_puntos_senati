import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('aula_puntos_senati.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return await openDatabase(
        filePath,
        version: 3,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      );
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE grupos ADD COLUMN nombre_grupo TEXT NOT NULL DEFAULT ''");
      await db.execute("ALTER TABLE grupos ADD COLUMN programa_academico TEXT NOT NULL DEFAULT ''");
      await db.execute("ALTER TABLE grupos ADD COLUMN asignatura TEXT NOT NULL DEFAULT ''");

      await db.execute("ALTER TABLE sesiones ADD COLUMN numero_sesion INTEGER NOT NULL DEFAULT 1");
      await db.execute("ALTER TABLE sesiones ADD COLUMN tipo_sesion TEXT NOT NULL DEFAULT 'Teoría (Tecnología)'");
      await db.execute("ALTER TABLE sesiones ADD COLUMN duracion TEXT NOT NULL DEFAULT '4 horas'");
      await db.execute("ALTER TABLE sesiones ADD COLUMN observaciones TEXT NOT NULL DEFAULT ''");
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE asistencia_nueva (
          id TEXT PRIMARY KEY,
          sesion_id TEXT NOT NULL,
          estudiante_id TEXT NOT NULL,
          fecha_asistencia TEXT NOT NULL,
          estado TEXT NOT NULL CHECK (estado IN ('Presente', 'Tardanza', 'Falta', 'Justificado')),
          fecha_registro TEXT NOT NULL,
          observacion TEXT,
          sync_status TEXT NOT NULL DEFAULT 'pendiente',
          UNIQUE (sesion_id, estudiante_id, fecha_asistencia),
          FOREIGN KEY (sesion_id) REFERENCES sesiones (id),
          FOREIGN KEY (estudiante_id) REFERENCES estudiantes (id)
        )
      ''');

      await db.execute('''
        INSERT INTO asistencia_nueva (id, sesion_id, estudiante_id, fecha_asistencia, estado, fecha_registro, observacion, sync_status)
        SELECT id, sesion_id, estudiante_id, substr(fecha_registro, 1, 10), estado, fecha_registro, observacion, sync_status
        FROM asistencia
      ''');

      await db.execute('DROP TABLE asistencia');
      await db.execute('ALTER TABLE asistencia_nueva RENAME TO asistencia');
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE grupos (
        id TEXT PRIMARY KEY,
        codigo TEXT NOT NULL,
        nombre TEXT NOT NULL,
        nombre_grupo TEXT NOT NULL DEFAULT '',
        programa_academico TEXT NOT NULL DEFAULT '',
        asignatura TEXT NOT NULL DEFAULT '',
        periodo TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'sincronizado'
      )
    ''');

    await db.execute('''
      CREATE TABLE estudiantes (
        id TEXT PRIMARY KEY,
        codigo_institucional TEXT NOT NULL UNIQUE,
        nombres TEXT NOT NULL,
        apellidos TEXT NOT NULL,
        estado TEXT NOT NULL DEFAULT 'Activo'
      )
    ''');

    await db.execute('''
      CREATE TABLE grupo_estudiante (
        grupo_id TEXT NOT NULL,
        estudiante_id TEXT NOT NULL,
        fecha_incorporacion TEXT NOT NULL,
        estado TEXT NOT NULL DEFAULT 'Activo',
        PRIMARY KEY (grupo_id, estudiante_id),
        FOREIGN KEY (grupo_id) REFERENCES grupos (id),
        FOREIGN KEY (estudiante_id) REFERENCES estudiantes (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE sesiones (
        id TEXT PRIMARY KEY,
        grupo_id TEXT NOT NULL,
        numero_sesion INTEGER NOT NULL DEFAULT 1,
        fecha TEXT NOT NULL,
        tema TEXT NOT NULL,
        tipo_sesion TEXT NOT NULL DEFAULT 'Teoría (Tecnología)',
        duracion TEXT NOT NULL DEFAULT '4 horas',
        observaciones TEXT NOT NULL DEFAULT '',
        estado TEXT NOT NULL DEFAULT 'Activa',
        sync_status TEXT NOT NULL DEFAULT 'pendiente',
        FOREIGN KEY (grupo_id) REFERENCES grupos (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE asistencia (
        id TEXT PRIMARY KEY,
        sesion_id TEXT NOT NULL,
        estudiante_id TEXT NOT NULL,
        fecha_asistencia TEXT NOT NULL,
        estado TEXT NOT NULL CHECK (estado IN ('Presente', 'Tardanza', 'Falta', 'Justificado')),
        fecha_registro TEXT NOT NULL,
        observacion TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pendiente',
        UNIQUE (sesion_id, estudiante_id, fecha_asistencia),
        FOREIGN KEY (sesion_id) REFERENCES sesiones (id),
        FOREIGN KEY (estudiante_id) REFERENCES estudiantes (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE actividades (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        descripcion TEXT,
        puntos_base INTEGER NOT NULL DEFAULT 1,
        estado TEXT NOT NULL DEFAULT 'Activa'
      )
    ''');

    await db.execute('''
      CREATE TABLE participaciones (
        id TEXT PRIMARY KEY,
        sesion_id TEXT NOT NULL,
        estudiante_id TEXT NOT NULL,
        actividad_id TEXT NOT NULL,
        puntos INTEGER NOT NULL,
        fecha TEXT NOT NULL,
        observacion TEXT,
        sync_status TEXT NOT NULL DEFAULT 'pendiente',
        FOREIGN KEY (sesion_id) REFERENCES sesiones (id),
        FOREIGN KEY (estudiante_id) REFERENCES estudiantes (id),
        FOREIGN KEY (actividad_id) REFERENCES actividades (id)
      )
    ''');

    await _insertarDatosIniciales(db);
  }

  Future _insertarDatosIniciales(Database db) async {
    await db.insert('grupos', {
      'id': 'grp-001',
      'codigo': '2026-20-202601',
      'nombre': 'Desarrollo Web',
      'nombre_grupo': '202601',
      'programa_academico': '2026-20',
      'asignatura': 'Desarrollo Web',
      'periodo': '2026-20',
      'sync_status': 'sincronizado',
    });
    await db.insert('grupos', {
      'id': 'grp-002',
      'codigo': '2026-20-202602',
      'nombre': 'Desarrollo de Aplicaciones Móviles',
      'nombre_grupo': '202602',
      'programa_academico': '2026-20',
      'asignatura': 'Desarrollo de Aplicaciones Móviles',
      'periodo': '2026-20',
      'sync_status': 'sincronizado',
    });

    final estudiantes = [
      {'id': 'est-01', 'codigo_institucional': '001458210', 'nombres': 'Carlos', 'apellidos': 'Mendoza Quispe'},
      {'id': 'est-02', 'codigo_institucional': '001458211', 'nombres': 'Valeria', 'apellidos': 'Torres Huamán'},
      {'id': 'est-03', 'codigo_institucional': '001458212', 'nombres': 'Diego', 'apellidos': 'Rojas Salazar'},
      {'id': 'est-04', 'codigo_institucional': '001458213', 'nombres': 'Lucía', 'apellidos': 'Paredes Vega'},
      {'id': 'est-05', 'codigo_institucional': '001458214', 'nombres': 'Andrés', 'apellidos': 'Castillo Flores'},
    ];

    for (var est in estudiantes) {
      await db.insert('estudiantes', est);
      await db.insert('grupo_estudiante', {
        'grupo_id': 'grp-001',
        'estudiante_id': est['id'],
        'fecha_incorporacion': '2026-08-10',
        'estado': 'Activo',
      });
    }

    await db.insert('actividades', {
      'id': 'act-01',
      'nombre': 'Participación en clase',
      'descripcion': 'Intervención oral o respuesta acertada',
      'puntos_base': 1,
    });
    await db.insert('actividades', {
      'id': 'act-02',
      'nombre': 'Resolución de ejercicio',
      'descripcion': 'Solución práctica en laboratorio o pizarra',
      'puntos_base': 2,
    });
    await db.insert('actividades', {
      'id': 'act-03',
      'nombre': 'Sustentación técnica',
      'descripcion': 'Exposición de avance o código funcional',
      'puntos_base': 3,
    });
  }
}