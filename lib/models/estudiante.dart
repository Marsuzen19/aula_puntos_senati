class Estudiante {
  final String id;
  final String codigoInstitucional;
  final String nombres;
  final String apellidos;
  final String estado;

  Estudiante({
    required this.id,
    required this.codigoInstitucional,
    required this.nombres,
    required this.apellidos,
    this.estado = 'Activo',
  });

  String get nombreCompleto => '$apellidos, $nombres';

  Map<String, dynamic> toMap() => {
        'id': id,
        'codigo_institucional': codigoInstitucional,
        'nombres': nombres,
        'apellidos': apellidos,
        'estado': estado,
      };

  factory Estudiante.fromMap(Map<String, dynamic> map) => Estudiante(
        id: map['id'],
        codigoInstitucional: map['codigo_institucional'],
        nombres: map['nombres'],
        apellidos: map['apellidos'],
        estado: map['estado'] ?? 'Activo',
      );
}