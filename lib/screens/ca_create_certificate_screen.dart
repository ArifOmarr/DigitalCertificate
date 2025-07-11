import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../services/pdf_service.dart';

class CaCreateCertificateScreen extends StatefulWidget {
  const CaCreateCertificateScreen({super.key});

  @override
  State<CaCreateCertificateScreen> createState() =>
      _CaCreateCertificateScreenState();
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
  String _selectedTemplate = 'standard';
  bool? _pdfOption; // null = not picked, true = auto-generate, false = upload

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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pdfFile = result.files.first;
        _autoGenerate = false;
      });
    }
  }

  void _pickPdfOption(bool? value) {
    setState(() {
      _pdfOption = value;
      if (_pdfOption == true) _pdfFile = null;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _formKey.currentState?.save();
    if (_issueDate == null || _expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both issue and expiry dates.'),
        ),
      );
      return;
    }
    setState(() => _isUploading = true);
    String? pdfUrl;
    String signature = '';
    try {
      File? generatedPdfFile;
      if (_pdfFile != null) {
        final file = File(_pdfFile!.path!);
        final ref = FirebaseStorage.instance
            .ref()
            .child('certificates')
            .child(
              '${DateTime.now().millisecondsSinceEpoch}_${_pdfFile!.name}',
            );
        await ref.putFile(file);
        pdfUrl = await ref.getDownloadURL();
      } else {
        generatedPdfFile = await PdfService.generateCertificate(
          recipientName: _recipientName!,
          organization: _organization!,
          purpose: _purpose!,
          issueDate: _issueDate!,
          expiryDate: _expiryDate!,
          template: _selectedTemplate,
        );
        final ref = FirebaseStorage.instance
            .ref()
            .child('certificates')
            .child(
              '${DateTime.now().millisecondsSinceEpoch}_${_recipientName}.pdf',
            );
        await ref.putFile(generatedPdfFile);
        pdfUrl = await ref.getDownloadURL();
        signature = 'Auto-generated';
      }
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
        'template': _selectedTemplate,
      });
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Certificate issued and saved!')),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _sectionHeader(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12.0),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.teal,
      ),
    ),
  );

  Widget _summaryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.teal, width: 1.5),
      ),
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Certificate Preview',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Divider(),
            Text('Recipient: ${_recipientName ?? '-'}'),
            Text('Email: ${_recipientEmail ?? '-'}'),
            Text('Organization: ${_organization ?? '-'}'),
            Text('Purpose: ${_purpose ?? '-'}'),
            Text(
              'Issue Date: ${_issueDate != null ? _issueDate!.toLocal().toString().split(' ')[0] : '-'}',
            ),
            Text(
              'Expiry Date: ${_expiryDate != null ? _expiryDate!.toLocal().toString().split(' ')[0] : '-'}',
            ),
            Text(
              'Template: ${_selectedTemplate[0].toUpperCase()}${_selectedTemplate.substring(1)}',
            ),
            if (_pdfFile != null && !_autoGenerate)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'PDF: ${_pdfFile!.name}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final templates = PdfService.getAvailableTemplates();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create/Issue Certificate'),
        backgroundColor: Colors.teal,
      ),
      backgroundColor: Colors.teal[50],
      body: SingleChildScrollView(
        child: Card(
          elevation: 6,
          margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Colors.teal, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionHeader('Recipient Details'),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Recipient Name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        (v) =>
                            v == null || v.isEmpty
                                ? 'Enter recipient name'
                                : null,
                    onSaved: (v) => _recipientName = v,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Recipient Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        (v) =>
                            v == null || v.isEmpty
                                ? 'Enter recipient email'
                                : null,
                    onSaved: (v) => _recipientEmail = v,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  _sectionHeader('Certificate Details'),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Organization',
                      prefixIcon: Icon(Icons.business),
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        (v) =>
                            v == null || v.isEmpty
                                ? 'Enter organization'
                                : null,
                    onSaved: (v) => _organization = v,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Purpose',
                      prefixIcon: Icon(Icons.assignment_turned_in),
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        (v) => v == null || v.isEmpty ? 'Enter purpose' : null,
                    onSaved: (v) => _purpose = v,
                  ),
                  const SizedBox(height: 12),
                  _sectionHeader('Certificate Dates'),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Issue Date',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      _issueDate == null
                                          ? 'Not selected'
                                          : _issueDate!
                                              .toLocal()
                                              .toString()
                                              .split(' ')[0],
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _pickDate(context, true),
                                icon: const Icon(
                                  Icons.calendar_today,
                                  size: 18,
                                ),
                                label: const Text('Select'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Expiry Date',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      _expiryDate == null
                                          ? 'Not selected'
                                          : _expiryDate!
                                              .toLocal()
                                              .toString()
                                              .split(' ')[0],
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _pickDate(context, false),
                                icon: const Icon(
                                  Icons.calendar_today,
                                  size: 18,
                                ),
                                label: const Text('Select'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionHeader('PDF Options'),
                  if (_pdfOption == null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickPdfOption(true),
                            child: Card(
                              elevation: 2,
                              color: Colors.teal[50],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.auto_awesome,
                                      color: Colors.orange,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Auto-generate PDF',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Let the system create a professional certificate for you.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickPdfOption(false),
                            child: Card(
                              elevation: 2,
                              color: Colors.blue[50],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.upload_file,
                                      color: Colors.blue,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Upload PDF',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Upload your own certificate PDF file.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (_pdfOption == true) ...[
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.auto_awesome, color: Colors.orange),
                                const SizedBox(width: 8),
                                const Text(
                                  'Auto-generate PDF',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                  ),
                                  tooltip: 'Cancel',
                                  onPressed: () => _pickPdfOption(null),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.teal[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.teal[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.style,
                                        color: Colors.teal,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Template Selection',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      return ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxHeight: 300,
                                          minWidth: constraints.maxWidth,
                                        ),
                                        child: DropdownButtonFormField<String>(
                                          value: _selectedTemplate,
                                          items:
                                              templates
                                                  .map(
                                                    (tpl) => DropdownMenuItem(
                                                      value: tpl['id'],
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(tpl['name']!),
                                                          Text(
                                                            tpl['description']!,
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 12,
                                                                  color:
                                                                      Colors
                                                                          .grey,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                          selectedItemBuilder:
                                              (context) =>
                                                  templates
                                                      .map(
                                                        (tpl) =>
                                                            Text(tpl['name']!),
                                                      )
                                                      .toList(),
                                          onChanged: (val) {
                                            setState(() {
                                              _selectedTemplate =
                                                  val ?? 'standard';
                                            });
                                          },
                                          menuMaxHeight: 300,
                                          decoration: const InputDecoration(
                                            labelText: 'Choose Template',
                                            border: OutlineInputBorder(),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 15,
                                                  vertical: 10,
                                                ),
                                            isDense: true,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (_pdfOption == false) ...[
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.upload_file, color: Colors.blue),
                                const SizedBox(width: 8),
                                const Text(
                                  'Upload PDF',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                  ),
                                  tooltip: 'Cancel',
                                  onPressed: () => _pickPdfOption(null),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Upload an existing PDF certificate',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 2,
                                  style: BorderStyle.solid,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey[50],
                              ),
                              child: Column(
                                children: [
                                  if (_pdfFile == null) ...[
                                    Icon(
                                      Icons.cloud_upload,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'No file selected',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton.icon(
                                      onPressed: _pickPDF,
                                      icon: const Icon(Icons.file_upload),
                                      label: const Text('Choose PDF File'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    Icon(
                                      Icons.file_present,
                                      size: 48,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _pdfFile!.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Size: ${(_pdfFile!.size / 1024).toStringAsFixed(1)} KB',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: _pickPDF,
                                          icon: const Icon(Icons.edit),
                                          label: const Text('Change'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              _pdfFile = null;
                                            });
                                          },
                                          icon: const Icon(Icons.delete),
                                          label: const Text('Remove'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  _summaryCard(),
                  const SizedBox(height: 16),
                  _isUploading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Issue Certificate'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
