import 'dart:typed_data';
import 'package:excel/excel.dart' as xl;
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/grupo.dart';
import '../services/aula_service.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final AulaService _service = AulaService();
  List<Grupo> _grupos = [];
  Grupo? _grupoActivo;
  List<FilaReporte> _filas = [];
  bool _cargando = true;
  bool _exportando = false;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    final grupos = await _service.obtenerGrupos();
    if (!mounted) return;
    if (grupos.isEmpty) {
      setState(() => _cargando = false);
      return;
    }
    setState(() => _grupos = grupos);
    await _seleccionarGrupo(grupos.first);
  }

  Future<void> _seleccionarGrupo(Grupo grupo) async {
    setState(() {
      _grupoActivo = grupo;
      _cargando = true;
    });
    final datos = await _service.obtenerReporteConsolidadoGrupo(grupo.id);
    if (!mounted) return;
    setState(() {
      _filas = datos;
      _cargando = false;
    });
  }

  double get _promedioGeneralGrupo {
    if (_filas.isEmpty) return 0.0;
    double suma = 0;
    for (final f in _filas) {
      suma += (f['promedio'] as double);
    }
    return suma / _filas.length;
  }

  double get _asistenciaPromedioGrupo {
    if (_filas.isEmpty) return 0.0;
    double suma = 0;
    for (final f in _filas) {
      suma += (f['porcentajeAsistencia'] as double);
    }
    return suma / _filas.length;
  }

  Future<void> _descargarExcel() async {
    if (_exportando || _grupoActivo == null) return;
    setState(() => _exportando = true);

    try {
      final workbook = xl.Excel.createExcel();
      final sheetName = 'Reporte_${_grupoActivo!.codigo}';
      workbook.rename('Sheet1', sheetName);
      final sheet = workbook[sheetName];

      final headerStyle = xl.CellStyle(
        bold: true,
        fontColorHex: xl.ExcelColor.white,
        backgroundColorHex: xl.ExcelColor.fromHexString('#004B93'),
        horizontalAlign: xl.HorizontalAlign.Center,
      );

      sheet.appendRow([xl.TextCellValue('SENATI - REPORTE CONSOLIDADO DE ASISTENCIA Y NOTAS')]);
      sheet.appendRow([
        xl.TextCellValue('Grupo: ${_grupoActivo!.codigo} - ${_grupoActivo!.nombre}'),
        xl.TextCellValue('Periodo: ${_grupoActivo!.periodo}'),
        xl.TextCellValue('Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'),
      ]);
      sheet.appendRow([]);

      final encabezados = [
        'ID',
        'Estudiante',
        'Sesiones',
        'Presente',
        'Tardanza',
        'Falta',
        'Justificado',
        '% Asistencia',
        'Participación',
        'Ejercicios',
        'Sustentación',
        'Total Puntos',
        'Promedio',
      ];
      sheet.appendRow(encabezados.map((e) => xl.TextCellValue(e)).toList());

      for (int col = 0; col < encabezados.length; col++) {
        final cell = sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 3));
        cell.cellStyle = headerStyle;
      }

      for (final f in _filas) {
        final porc = double.parse((f['porcentajeAsistencia'] as double).toStringAsFixed(1));
        final prom = double.parse((f['promedio'] as double).toStringAsFixed(1));

        sheet.appendRow([
          xl.TextCellValue(f['codigo'] as String),
          xl.TextCellValue(f['nombre'] as String),
          xl.IntCellValue(f['totalSesiones'] as int),
          xl.IntCellValue(f['presentes'] as int),
          xl.IntCellValue(f['tardanzas'] as int),
          xl.IntCellValue(f['faltas'] as int),
          xl.IntCellValue(f['justificados'] as int),
          xl.DoubleCellValue(porc),
          xl.IntCellValue(f['participacion'] as int),
          xl.IntCellValue(f['ejercicios'] as int),
          xl.IntCellValue(f['sustentacion'] as int),
          xl.IntCellValue(f['totalPuntos'] as int),
          xl.DoubleCellValue(prom),
        ]);
      }

      final bytes = workbook.encode();
      if (bytes != null) {
        await FileSaver.instance.saveFile(
          name: 'Reporte_${_grupoActivo!.codigo}',
          bytes: Uint8List.fromList(bytes),
          fileExtension: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Descargado: Reporte_${_grupoActivo!.codigo}.xlsx'),
            backgroundColor: const Color(0xFF1E8E3E),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Future<void> _descargarPDF() async {
    if (_exportando || _grupoActivo == null) return;
    setState(() => _exportando = true);

    try {
      final pdf = pw.Document();
      final fechaActual = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
      final int totalSesiones = _filas.isNotEmpty ? (_filas.first['totalSesiones'] as int) : 0;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) {
            return [
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#004B93'),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'SENATI – REPORTE CONSOLIDADO DE AULA',
                          style: pw.TextStyle(color: PdfColors.white, fontSize: 15, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '${_grupoActivo!.codigo} - ${_grupoActivo!.nombre} (${_grupoActivo!.periodo})',
                          style: const pw.TextStyle(color: PdfColors.white, fontSize: 11),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Generado: $fechaActual', style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Sesiones: $totalSesiones  |  Asist. Media: ${_asistenciaPromedioGrupo.toStringAsFixed(0)}%  |  Prom. Grupo: ${_promedioGeneralGrupo.toStringAsFixed(1)}',
                          style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 9),
                headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#004B93')),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellAlignment: pw.Alignment.center,
                cellAlignments: {1: pw.Alignment.centerLeft},
                oddRowDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#F4F6F9')),
                headers: ['ID', 'Estudiante', 'P', 'T', 'F', 'J', '% Asist.', 'Particip.', 'Ejerc.', 'Sustent.', 'Total', 'Promedio'],
                data: _filas.map((f) {
                  final porc = (f['porcentajeAsistencia'] as double).toStringAsFixed(0);
                  final prom = (f['promedio'] as double).toStringAsFixed(1);
                  return [
                    f['codigo'].toString(),
                    f['nombre'].toString(),
                    f['presentes'].toString(),
                    f['tardanzas'].toString(),
                    f['faltas'].toString(),
                    f['justificados'].toString(),
                    '$porc%',
                    f['participacion'].toString(),
                    f['ejercicios'].toString(),
                    f['sustentacion'].toString(),
                    f['totalPuntos'].toString(),
                    prom,
                  ];
                }).toList(),
              ),
            ];
          },
        ),
      );

      final Uint8List pdfBytes = await pdf.save();

      await FileSaver.instance.saveFile(
        name: 'Reporte_${_grupoActivo!.codigo}',
        bytes: pdfBytes,
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Descargado: Reporte_${_grupoActivo!.codigo}.pdf'),
            backgroundColor: const Color(0xFF1E8E3E),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int totalSesiones = _filas.isNotEmpty ? (_filas.first['totalSesiones'] as int) : 0;
    final bool botonesActivos = _filas.isNotEmpty && !_exportando;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        title: const Text('Reportes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF004B93),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TextButton.icon(
              onPressed: botonesActivos ? _descargarExcel : null,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF1E8E3E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              icon: const Icon(Icons.table_view_rounded, size: 17),
              label: const Text('Excel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8, right: 12),
            child: TextButton.icon(
              onPressed: botonesActivos ? _descargarPDF : null,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFD93025),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 17),
              label: const Text('PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Selector horizontal de grupos
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
                            label: Text('${g.codigo} · ${g.nombre}'),
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
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Resumen numérico compacto en 3 bloques
                          Row(
                            children: [
                              _kpiCompacto('Sesiones', '$totalSesiones'),
                              const SizedBox(width: 8),
                              _kpiCompacto('Asistencia', '${_asistenciaPromedioGrupo.toStringAsFixed(0)}%'),
                              const SizedBox(width: 8),
                              _kpiCompacto('Promedio', _promedioGeneralGrupo.toStringAsFixed(1)),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Lista limpia por estudiante adaptada a móvil
                          ..._filas.map((f) {
                            final double porc = f['porcentajeAsistencia'] as double;
                            final double prom = f['promedio'] as double;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          f['nombre'] as String,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Asist: ${porc.toStringAsFixed(0)}% (${f['presentes']}P · ${f['tardanzas']}T · ${f['faltas']}F)',
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F0FE),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      children: [
                                        const Text(
                                          'PROM',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF004B93),
                                          ),
                                        ),
                                        Text(
                                          prom.toStringAsFixed(1),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF004B93),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _kpiCompacto(String etiqueta, String valor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Text(
              valor,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 2),
            Text(
              etiqueta,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}