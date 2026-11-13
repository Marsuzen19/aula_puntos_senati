class Asistencia {
  final String id;
  final String sesionId;
  final String estudianteId;
  final String estado; // Presente, Tardanza, Falta, Justificado
  final String fechaRegistro;
  final String observacion;
  final String syncStatus;

  Asistencia({
    required this.id,
    required this.sesionId,
    required this.estudianteId,
    required this.estado,
    required this.fechaRegistro,
    this.observacion = '',
    this.syncStatus = 'pendiente',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'sesion_id': sesionId,
        'estudiante_id': estudianteId,
        'estado': estado,
        'fecha_registro': fechaRegistro,
        'observacion': observacion,
        'sync_status': syncStatus,
      };

  factory Asistencia.fromMap(Map<String, dynamic> map) => Asistencia(
        id: map['id'],
        sesionId: map['sesion_id'],
        estudianteId: map['estudiante_id'],
        estado: map['estado'],
        fechaRegistro: map['fecha_registro'],
        observacion: map['observacion'] ?? '',
        syncStatus: map['sync_status'] ?? 'pendiente',
      );
}