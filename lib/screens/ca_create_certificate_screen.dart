import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'dart:io';
import 'dart:math';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CaCreateCertificateScreen extends StatefulWidget {
  const CaCreateCertificateScreen({super.key});

  @override
  State<CaCreateCertificateScreen> createState() => _CaCreateCertificateScreenState();
}

class _CaCreateCertificateScreenState extends State<CaCreateCertificateScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _recipientName;
  String? _organization;
  String? _purpose;
  DateTime? _issueDate;
  DateTime? _expiryDate;
  PlatformFile? _pdfFile;
  bool _autoGenerate = false;
  bool _isUploading = false;
  String? _recipientEmail;

  Future<void> _pickDate(BuildContext context, bool isIssue) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isIssue) {
          _issueDate = picked;
        } else {
          _expiryDate = picked;
        }
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
    if (_issueDate == null || _expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both issue and expiry dates.')),
      );
      return;
    }
    setState(() => _isUploading = true);
    String? pdfUrl;
    String signature = '';
    try {
      if (_autoGenerate) {
        // Generate PDF with watermark/signature
        final pdf = pw.Document();
        final randomSignature = 'SIG-${Random().nextInt(1000000)}';
        pdf.addPage(
          pw.Page(
            build: (pw.Context context) => pw.Stack(
              children: [
                pw.Center(
                  child: pw.Text(
                    _recipientName ?? '',
                    style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: pw.Center(
                    child: pw.Text(
                      'Digitally Signed: $randomSignature',
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
                      'Organization: ${_organization ?? ''}\nPurpose: ${_purpose ?? ''}\nIssue: ${_issueDate!.toLocal().toString().split(' ')[0]}\nExpiry: ${_expiryDate!.toLocal().toString().split(' ')[0]}',
                      style: pw.TextStyle(fontSize: 16),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        
        final ref = FirebaseStorage.instance
            .ref()
            .child('certificates')
            .child('${DateTime.now().millisecondsSinceEpoch}_${_recipientName}.pdf');
        
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
        signature = randomSignature;
      } else if (_pdfFile != null) {
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
        setState(() => _isUploading = false);
        return;
      }
      // Save metadata to Firestore
      await FirebaseFirestore.instance.collection('certificates').add({
        'title': 'Certificate for ${_recipientName ?? ''}',
        'recipientName': _recipientName,
        'recipientEmail': _recipientEmail,
        'organization': _organization,
        'purpose': _purpose,
        'issueDate': _issueDate,
        'expiryDate': _expiryDate,
        'pdfUrl': pdfUrl,
        'issuer': 'CA',
        'signature': signature,
        'status': 'Valid',
        'createdAt': FieldValue.serverTimestamp(),
      });
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Certificate issued and saved!')),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create/Issue Certificate'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Recipient Name'),
                validator: (v) => v == null || v.isEmpty ? 'Enter recipient name' : null,
                onSaved: (v) => _recipientName = v,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Recipient Email'),
                validator: (v) => v == null || v.isEmpty ? 'Enter recipient email' : null,
                onSaved: (v) => _recipientEmail = v,
                keyboardType: TextInputType.emailAddress,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Organization'),
                validator: (v) => v == null || v.isEmpty ? 'Enter organization' : null,
                onSaved: (v) => _organization = v,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Purpose'),
                validator: (v) => v == null || v.isEmpty ? 'Enter purpose' : null,
                onSaved: (v) => _purpose = v,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_issueDate == null ? 'Select Issue Date' : 'Issue Date: ${_issueDate!.toLocal().toString().split(' ')[0]}'),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _pickDate(context, true),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_expiryDate == null ? 'Select Expiry Date' : 'Expiry Date: ${_expiryDate!.toLocal().toString().split(' ')[0]}'),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _pickDate(context, false),
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
                onPressed: _isUploading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: _isUploading ? const CircularProgressIndicator() : const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 