import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/movement.dart';

class PdfEditPreview extends StatefulWidget {
  final List<Movement> movements;
  final double totalBalance;

  const PdfEditPreview({
    super.key,
    required this.movements,
    required this.totalBalance,
  });

  @override
  State<PdfEditPreview> createState() => _PdfEditPreviewState();
}

class _PdfEditPreviewState extends State<PdfEditPreview> {
  String _title = 'Reporte de Movimientos';
  String _notes = '';
  final _formatoNumero = NumberFormat.decimalPattern('es_ES');
  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vista Previa y Edición'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Título del Reporte',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _title = value;
                    });
                  },
                  controller: TextEditingController(text: _title),
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Notas / Observaciones',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _notes = value;
                    });
                  },
                  maxLines: 2,
                ),
              ],
            ),
          ),
          Expanded(
            child: PdfPreview(
              build: (format) => _generatePdf(format, _title, _notes),
              canChangeOrientation: false,
              canChangePageFormat: false,
              allowPrinting: true,
              allowSharing: true,
              // We can hide the default actions if we want to implement our own "Save" logic
              // but PdfPreview's actions are quite good (Print, Share, Save).
            ),
          ),
        ],
      ),
    );
  }

  Future<Uint8List> _generatePdf(
      PdfPageFormat format, String title, String notes) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(title,
                      style: pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())),
                ],
              ),
            ),
            if (notes.isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 20),
                child: pw.Text(notes,
                    style: pw.TextStyle(
                        fontSize: 14, fontStyle: pw.FontStyle.italic)),
              ),
            pw.TableHelper.fromTextArray(
              context: context,
              headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
              headerHeight: 25,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.center,
              },
              headers: ['Fecha', 'Concepto', 'Monto', 'Tipo'],
              data: widget.movements.map((m) {
                return [
                  _dateFormat.format(m.date),
                  m.concept,
                  '\$${_formatoNumero.format(m.amount)}',
                  m.isDigital ? 'Digital' : 'Efectivo',
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  'Total: \$${_formatoNumero.format(widget.totalBalance)}',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}
