import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

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

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png']);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _file = result.files.first;
      });
    }
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
      final file = File(_file!.path!);
      final ref = FirebaseStorage.instance
          .ref()
          .child('physical_certificate_uploads')
          .child('${DateTime.now().millisecondsSinceEpoch}_${_file!.name}');
      await ref.putFile(file);
      final fileUrl = await ref.getDownloadURL();
      await FirebaseFirestore.instance.collection('physical_certificate_uploads').add({
        'name': _name,
        'purpose': _purpose,
        'fileUrl': fileUrl,
        'uploadedBy': user.email,
        'status': 'Pending Verification',
        'uploadedAt': FieldValue.serverTimestamp(),
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
        title: const Text('Upload Physical Certificate'),
        backgroundColor: Colors.teal,
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
                decoration: const InputDecoration(labelText: 'Purpose'),
                validator: (v) => v == null || v.isEmpty ? 'Enter purpose' : null,
                onSaved: (v) => _purpose = v,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_file == null ? 'No file selected' : _file!.name),
                trailing: ElevatedButton(
                  onPressed: _pickFile,
                  child: const Text('Select File'),
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
                child: _isUploading ? const CircularProgressIndicator() : const Text('Upload for Verification'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 