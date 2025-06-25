import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/certificate.dart';
import '../services/certificate_service.dart';
import 'certificate_display_screen.dart';

class CertificateFormScreen extends StatefulWidget {
  const CertificateFormScreen({super.key});

  @override
  _CertificateFormScreenState createState() => _CertificateFormScreenState();
}

class _CertificateFormScreenState extends State<CertificateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _organizationController = TextEditingController();
  final _purposeController = TextEditingController();

  DateTime? _issueDate;
  DateTime? _expiryDate;

  void _selectDate(bool isIssueDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isIssueDate) {
          _issueDate = picked;
        } else {
          _expiryDate = picked;
        }
      });
    }
  }

  Future<void> _submitForm() async {
    print('Form submitted'); // Add this line

    if (_formKey.currentState!.validate() && _issueDate != null && _expiryDate != null) {
      final cert = Certificate(
        name: _nameController.text.trim(),
        organization: _organizationController.text.trim(),
        purpose: _purposeController.text.trim(),
        issueDate: _issueDate!,
        expiryDate: _expiryDate!,
      );

      await CertificateService().uploadCertificate(cert);


      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Certificate Generated and Saved to Firebase!')),
      );

      await Future.delayed(Duration(milliseconds: 500));

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CertificateDisplayScreen(certificate: cert),
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff0f0f0),
      appBar: AppBar(
        title: const Text('Certificate Generator'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (val) => val!.isEmpty ? 'Enter name' : null,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _organizationController,
                decoration: InputDecoration(labelText: 'Organization'),
                validator: (val) => val!.isEmpty ? 'Enter organization' : null,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _purposeController,
                decoration: InputDecoration(labelText: 'Purpose'),
                validator: (val) => val!.isEmpty ? 'Enter purpose' : null,
              ),
              SizedBox(height: 20),
              ListTile(
                title: Text(_issueDate == null
                    ? 'Select Issue Date'
                    : 'Issue Date: ${DateFormat.yMMMd().format(_issueDate!)}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(true),
              ),
              ListTile(
                title: Text(_expiryDate == null
                    ? 'Select Expiry Date'
                    : 'Expiry Date: ${DateFormat.yMMMd().format(_expiryDate!)}'),
                trailing: Icon(Icons.calendar_today),
                onTap: () => _selectDate(false),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _submitForm,
                child: const Text('Generate Certificate'),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
