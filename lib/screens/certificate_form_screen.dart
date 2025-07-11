import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

class CertificateFormScreen extends StatefulWidget {
  const CertificateFormScreen({super.key});

  @override
  State<CertificateFormScreen> createState() => _CertificateFormScreenState();
}

class _CertificateFormScreenState extends State<CertificateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _name;
  String? _recipient;
  String? _purpose;
  DateTime? _date;
  PlatformFile? _pdfFile;
  bool _autoGenerate = false;

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
      });
    }
  }

  Future<void> _pickPDF() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pdfFile = result.files.first;
        _autoGenerate = false;
      });
    }
  }

  void _toggleAutoGenerate(bool? value) {
    setState(() {
      _autoGenerate = value ?? false;
      if (_autoGenerate) _pdfFile = null;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _formKey.currentState?.save();

    if (_date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an issue date.')),
      );
      return;
    }

    String? pdfUrl;

    try {
      // 1. Handle PDF upload or auto-generate
      if (_autoGenerate) {
        // Generate PDF with watermark
        final pdf = pw.Document();
        pdf.addPage(
          pw.Page(
            build: (pw.Context context) => pw.Stack(
              children: [
                pw.Center(
                  child: pw.Text(
                    _name ?? '',
                    style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: pw.Center(
                    child: pw.Text(
                      'Signed by CA',
                      style: pw.TextStyle(
                        fontSize: 18,
                        color: PdfColor.fromInt(0xFFAAAAAA),
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                pw.Positioned(
                  top: 80,
                  left: 0,
                  right: 0,
                  child: pw.Center(
                    child: pw.Text(
                      'Recipient: ${_recipient ?? ''}\nPurpose: ${_purpose ?? ''}\nDate: ${_date!.toLocal().toString().split(' ')[0]}',
                      style: pw.TextStyle(fontSize: 16),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        // Upload to Firebase Storage
        final ref = FirebaseStorage.instance
            .ref()
            .child('certificates')
            .child('${DateTime.now().millisecondsSinceEpoch}_${_recipient}.pdf');
        
        // Handle PDF upload differently for web vs mobile
        if (kIsWeb) {
          // Web: Use putData with Uint8List
          final pdfBytes = await pdf.save();
          await ref.putData(pdfBytes);
        } else {
          // Mobile: Use putFile with File
          final output = await getTemporaryDirectory();
          final file = File('${output.path}/certificate_${DateTime.now().millisecondsSinceEpoch}.pdf');
          await file.writeAsBytes(await pdf.save());
          await ref.putFile(file);
        }
        
        pdfUrl = await ref.getDownloadURL();
      } else if (_pdfFile != null) {
        // Upload selected PDF
        final ref = FirebaseStorage.instance
            .ref()
            .child('certificates')
            .child('${DateTime.now().millisecondsSinceEpoch}_${_pdfFile!.name}');
        
        // Handle file upload differently for web vs mobile
        if (kIsWeb) {
          // Web: Use putData with Uint8List
          if (_pdfFile!.bytes != null) {
            await ref.putData(_pdfFile!.bytes!);
          } else {
            throw Exception('File bytes not available');
          }
        } else {
          // Mobile: Use putFile with File
          if (_pdfFile!.path != null) {
            final file = File(_pdfFile!.path!);
            await ref.putFile(file);
          } else {
            throw Exception('File path not available');
          }
        }
        
        pdfUrl = await ref.getDownloadURL();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload or auto-generate a PDF.')),
        );
        return;
      }

      // 2. Save metadata in Firestore
      await FirebaseFirestore.instance.collection('certificates').add({
        'title': _name,
        'recipientEmail': _recipient,
        'purpose': _purpose,
        'issueDate': _date,
        'status': 'Valid',
        'pdfUrl': pdfUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Certificate submitted!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Issue Certificate'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Certificate Name'),
                validator: (v) => v == null || v.isEmpty ? 'Enter certificate name' : null,
                onSaved: (v) => _name = v,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Recipient Email'),
                validator: (v) => v == null || v.isEmpty ? 'Enter recipient email' : null,
                onSaved: (v) => _recipient = v,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Purpose'),
                validator: (v) => v == null || v.isEmpty ? 'Enter purpose' : null,
                onSaved: (v) => _purpose = v,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_date == null ? 'Select Issue Date' : 'Issue Date: ${_date!.toLocal().toString().split(' ')[0]}'),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _pickDate(context),
                ),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: _autoGenerate,
                onChanged: _toggleAutoGenerate,
                title: const Text('Auto-generate certificate PDF'),
              ),
              if (!_autoGenerate)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_pdfFile == null ? 'No PDF selected' : _pdfFile!.name),
                  trailing: ElevatedButton(
                    onPressed: _pickPDF,
                    child: const Text('Upload PDF'),
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 