class Grupo {
  final String id;
  final String codigo; // Código de sección (ej. 2026-20-202601)
  final String nombre; // Asignatura / curso (ej. Desarrollo Web)
  final String nombreGrupo; // Ej. 202601
  final String programaAcademico; // Ej. 2026-20
  final String asignatura; // Ej. Desarrollo Web
  final String periodo; // Ej. 2026-20
  final String syncStatus;

  Grupo({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.nombreGrupo = '',
    this.programaAcademico = '',
    this.asignatura = '',
    required this.periodo,
    this.syncStatus = 'sincronizado',
  });

  factory Grupo.fromMap(Map<String, dynamic> map) {
    final nombreBase = (map['nombre'] as String?) ?? '';
    final asig = (map['asignatura'] as String?) ?? '';
    return Grupo(
      id: map['id'] as String,
      codigo: map['codigo'] as String,
      nombre: asig.isNotEmpty ? asig : nombreBase,
      nombreGrupo: (map['nombre_grupo'] as String?) ?? '',
      programaAcademico: (map['programa_academico'] as String?) ?? '',
      asignatura: asig.isNotEmpty ? asig : nombreBase,
      periodo: map['periodo'] as String,
      syncStatus: (map['sync_status'] as String?) ?? 'sincronizado',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigo': codigo,
      'nombre': asignatura.isNotEmpty ? asignatura : nombre,
      'nombre_grupo': nombreGrupo,
      'programa_academico': programaAcademico,
      'asignatura': asignatura.isNotEmpty ? asignatura : nombre,
      'periodo': periodo,
      'sync_status': syncStatus,
    };
  }
}