class Sesion {
  final String id;
  final String grupoId;
  final int numeroSesion;
  final String fecha;
  final String tema;
  final String tipoSesion;
  final String duracion;
  final String observaciones;
  final String estado;
  final String syncStatus;

  Sesion({
    required this.id,
    required this.grupoId,
    this.numeroSesion = 1,
    required this.fecha,
    required this.tema,
    this.tipoSesion = 'Teoría (Tecnología)',
    this.duracion = '4 horas',
    this.observaciones = '',
    this.estado = 'Activa',
    this.syncStatus = 'pendiente',
  });

  factory Sesion.fromMap(Map<String, dynamic> map) {
    return Sesion(
      id: map['id'] as String,
      grupoId: map['grupo_id'] as String,
      numeroSesion: (map['numero_sesion'] as int?) ?? 1,
      fecha: map['fecha'] as String,
      tema: map['tema'] as String,
      tipoSesion: (map['tipo_sesion'] as String?) ?? 'Teoría (Tecnología)',
      duracion: (map['duracion'] as String?) ?? '4 horas',
      observaciones: (map['observaciones'] as String?) ?? '',
      estado: (map['estado'] as String?) ?? 'Activa',
      syncStatus: (map['sync_status'] as String?) ?? 'pendiente',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'grupo_id': grupoId,
      'numero_sesion': numeroSesion,
      'fecha': fecha,
      'tema': tema,
      'tipo_sesion': tipoSesion,
      'duracion': duracion,
      'observaciones': observaciones,
      'estado': estado,
      'sync_status': syncStatus,
    };
  }
}