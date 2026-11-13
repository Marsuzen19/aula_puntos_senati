class Participacion {
  final String id;
  final String sesionId;
  final String estudianteId;
  final String actividadId;
  final int puntos;
  final String fecha;
  final String observacion;
  final String syncStatus;

  Participacion({
    required this.id,
    required this.sesionId,
    required this.estudianteId,
    required this.actividadId,
    required this.puntos,
    required this.fecha,
    this.observacion = '',
    this.syncStatus = 'pendiente',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'sesion_id': sesionId,
        'estudiante_id': estudianteId,
        'actividad_id': actividadId,
        'puntos': puntos,
        'fecha': fecha,
        'observacion': observacion,
        'sync_status': syncStatus,
      };

  factory Participacion.fromMap(Map<String, dynamic> map) => Participacion(
        id: map['id'],
        sesionId: map['sesion_id'],
        estudianteId: map['estudiante_id'],
        actividadId: map['actividad_id'],
        puntos: map['puntos'],
        fecha: map['fecha'],
        observacion: map['observacion'] ?? '',
        syncStatus: map['sync_status'] ?? 'pendiente',
      );
}