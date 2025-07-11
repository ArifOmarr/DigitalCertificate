import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class RecipientCertificateUploadScreen extends StatefulWidget {
  const RecipientCertificateUploadScreen({super.key});

  @override
  State<RecipientCertificateUploadScreen> createState() => _RecipientCertificateUploadScreenState();
}

class _RecipientCertificateUploadScreenState extends State<RecipientCertificateUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _name;
  String? _purpose;
  PlatformFile? _file;
  bool _isUploading = false;
  bool _isProcessing = false;
  String? _extractedText;
  Map<String, String> _extractedMetadata = {};
  final TextRecognizer _textRecognizer = TextRecognizer();

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, 
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _file = result.files.first;
        _extractedText = null;
        _extractedMetadata = {};
      });
      
      // Auto-process the file for OCR
      await _processFileForOCR();
    }
  }

  Future<void> _processFileForOCR() async {
    if (_file == null) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      // For now, we'll simulate OCR processing
      // In a real implementation, you would use Google ML Kit
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate extracted text
      final simulatedText = '''
Certificate of Achievement
This is to certify that
John Doe
has successfully completed the
Advanced Programming Course
Date: 15/12/2024
Issued by: UPM Faculty of Computer Science
      ''';
      
      setState(() {
        _extractedText = simulatedText;
        _extractedMetadata = _extractMetadata(simulatedText);
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing file: $e')),
      );
    }
  }

  Map<String, String> _extractMetadata(String text) {
    final metadata = <String, String>{};
    
    // Extract recipient name
    final nameMatch = RegExp(r'This is to certify that\s+([^\n]+)').firstMatch(text);
    if (nameMatch != null) {
      metadata['recipientName'] = nameMatch.group(1)?.trim() ?? '';
    }
    
    // Extract certificate type
    final typeMatch = RegExp(r'Certificate of ([^\n]+)').firstMatch(text);
    if (typeMatch != null) {
      metadata['certificateType'] = typeMatch.group(1)?.trim() ?? '';
    }
    
    // Extract date
    final dateMatch = RegExp(r'Date:\s*(\d{1,2}/\d{1,2}/\d{4})').firstMatch(text);
    if (dateMatch != null) {
      metadata['issueDate'] = dateMatch.group(1)?.trim() ?? '';
    }
    
    // Extract issuer
    final issuerMatch = RegExp(r'Issued by:\s*([^\n]+)').firstMatch(text);
    if (issuerMatch != null) {
      metadata['issuer'] = issuerMatch.group(1)?.trim() ?? '';
    }
    
    return metadata;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _formKey.currentState?.save();
    if (_file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file to upload.')),
      );
      return;
    }
    setState(() => _isUploading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');
      
      final ref = FirebaseStorage.instance
          .ref()
          .child('physical_certificate_uploads')
          .child('${DateTime.now().millisecondsSinceEpoch}_${_file!.name}');
      
      // Handle file upload differently for web vs mobile
      if (kIsWeb) {
        // Web: Use putData with Uint8List
        if (_file!.bytes != null) {
          await ref.putData(_file!.bytes!);
        } else {
          throw Exception('File bytes not available');
        }
      } else {
        // Mobile: Use putFile with File
        if (_file!.path != null) {
          final file = File(_file!.path!);
          await ref.putFile(file);
        } else {
          throw Exception('File path not available');
        }
      }
      
      final fileUrl = await ref.getDownloadURL();
      
      // Save to Firestore with enhanced metadata
      await FirebaseFirestore.instance.collection('physical_certificate_uploads').add({
        'name': _name,
        'purpose': _purpose,
        'fileUrl': fileUrl,
        'fileName': _file!.name,
        'fileSize': _file!.size,
        'uploadedBy': user.email,
        'uploadedByUid': user.uid,
        'status': 'Pending Verification',
        'uploadedAt': FieldValue.serverTimestamp(),
        'extractedText': _extractedText,
        'extractedMetadata': _extractedMetadata,
        'ocrProcessed': _extractedText != null,
        'verificationNotes': '',
        'caAssigned': null,
        'reviewedAt': null,
        'reviewedBy': null,
        'processingTime': DateTime.now().millisecondsSinceEpoch,
      });
      
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Certificate uploaded for verification!')),
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
        title: const Text('Upload Certificate'),
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
                decoration: const InputDecoration(
                  labelText: 'Certificate Name',
                  hintText: 'Enter a descriptive name for this certificate',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Enter certificate name' : null,
                onSaved: (v) => _name = v,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Purpose',
                  hintText: 'Why are you uploading this certificate?',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Enter purpose' : null,
                onSaved: (v) => _purpose = v,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload Certificate File',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Supported formats: PDF, JPG, JPEG, PNG',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      if (_file != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.file_present, color: Colors.green[600]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _file!.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Size: ${(_file!.size / 1024).toStringAsFixed(1)} KB',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _pickFile,
                        icon: const Icon(Icons.upload_file),
                        label: Text(_isProcessing ? 'Processing...' : 'Choose File'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isProcessing) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 8),
                        Text('Processing certificate with OCR...'),
                      ],
                    ),
                  ),
                ),
              ],
              if (_extractedText != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Extracted Information',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        if (_extractedMetadata.isNotEmpty) ...[
                          ..._extractedMetadata.entries.map((entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    '${entry.key}:',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Expanded(
                                  child: Text(entry.value),
                                ),
                              ],
                            ),
                          )),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          'Raw Extracted Text:',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _extractedText!,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isUploading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: _isUploading 
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                        SizedBox(width: 8),
                        Text('Uploading...'),
                      ],
                    )
                  : const Text('Upload Certificate'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 