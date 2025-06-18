import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class CertificateUploadScreen extends StatefulWidget {
  const CertificateUploadScreen({super.key});

  @override
  State<CertificateUploadScreen> createState() => _CertificateUploadScreenState();
}

class _CertificateUploadScreenState extends State<CertificateUploadScreen> {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  
  // Controllers for form fields
  final TextEditingController _recipientNameController = TextEditingController();
  final TextEditingController _certificateTypeController = TextEditingController();
  final TextEditingController _dateIssuedController = TextEditingController();
  final TextEditingController _issuerNameController = TextEditingController();
  
  // State variables
  File? _selectedFile;
  Uint8List? _imageBytes;
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _errorMessage;
  
  @override
  void dispose() {
    _textRecognizer.close();
    _recipientNameController.dispose();
    _certificateTypeController.dispose();
    _dateIssuedController.dispose();
    _issuerNameController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        setState(() {
          _selectedFile = file;
          _imageBytes = file.readAsBytesSync();
        });
        
        // Process the image for OCR
        await _processImageForOCR();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking file: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _processImageForOCR() async {
    if (_imageBytes == null) return;

    try {
      setState(() {
        _isProcessing = true;
      });

      final inputImage = InputImage.fromFilePath(_selectedFile!.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      // Extract metadata from OCR result
      _extractMetadata(recognizedText);
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Error processing image: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _extractMetadata(RecognizedText recognizedText) {
    String fullText = recognizedText.text;
    _extractRecipientName(fullText);
    _extractCertificateType(fullText);
    _extractDateIssued(fullText);
    _extractIssuerName(fullText);
  }

  void _extractRecipientName(String text) {
    final patterns = [
      RegExp(r'Name[:\s]+([A-Za-z\s]+)', caseSensitive: false),
      RegExp(r'Recipient[:\s]+([A-Za-z\s]+)', caseSensitive: false),
      RegExp(r'To[:\s]+([A-Za-z\s]+)', caseSensitive: false),
      RegExp(r'This is to certify that ([A-Za-z\s]+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        _recipientNameController.text = match.group(1)?.trim() ?? '';
        break;
      }
    }
  }

  void _extractCertificateType(String text) {
    final patterns = [
      RegExp(r'Certificate of ([A-Za-z\s]+)', caseSensitive: false),
      RegExp(r'([A-Za-z\s]+) Certificate', caseSensitive: false),
      RegExp(r'Type[:\s]+([A-Za-z\s]+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        _certificateTypeController.text = match.group(1)?.trim() ?? '';
        break;
      }
    }
  }

  void _extractDateIssued(String text) {
    final patterns = [
      RegExp(r'Date[:\s]+(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})', caseSensitive: false),
      RegExp(r'Issued[:\s]+(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})', caseSensitive: false),
      RegExp(r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})', caseSensitive: false),
      RegExp(r'(\d{4}[/-]\d{1,2}[/-]\d{1,2})', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        _dateIssuedController.text = match.group(1)?.trim() ?? '';
        break;
      }
    }
  }

  void _extractIssuerName(String text) {
    final patterns = [
      RegExp(r'Issued by[:\s]+([A-Za-z\s]+)', caseSensitive: false),
      RegExp(r'Issuer[:\s]+([A-Za-z\s]+)', caseSensitive: false),
      RegExp(r'Signature[:\s]+([A-Za-z\s]+)', caseSensitive: false),
      RegExp(r'Authorized by[:\s]+([A-Za-z\s]+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        _issuerNameController.text = match.group(1)?.trim() ?? '';
        break;
      }
    }
  }

  Future<void> _submitCertificate() async {
    if (_selectedFile == null) {
      setState(() {
        _errorMessage = 'Please select a file first';
      });
      return;
    }

    if (_recipientNameController.text.isEmpty ||
        _certificateTypeController.text.isEmpty ||
        _dateIssuedController.text.isEmpty ||
        _issuerNameController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all required fields';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Simulate upload delay
      await Future.delayed(const Duration(seconds: 2));

      // Show success message with extracted data
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Success!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Certificate processed successfully!'),
                  const SizedBox(height: 16),
                  const Text('Extracted Data:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Recipient: ${_recipientNameController.text}'),
                  Text('Type: ${_certificateTypeController.text}'),
                  Text('Date: ${_dateIssuedController.text}'),
                  Text('Issuer: ${_issuerNameController.text}'),
                  Text('File: ${_selectedFile!.path.split('/').last}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _resetForm();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }

    } catch (e) {
      setState(() {
        _errorMessage = 'Error processing certificate: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetForm() {
    setState(() {
      _selectedFile = null;
      _imageBytes = null;
      _recipientNameController.clear();
      _certificateTypeController.clear();
      _dateIssuedController.clear();
      _issuerNameController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Certificate Upload'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // File Upload Section
            _buildUploadSection(),
            const SizedBox(height: 24),

            // Image Preview
            if (_imageBytes != null) ...[
              _buildImagePreview(),
              const SizedBox(height: 24),
            ],

            // Form Section
            _buildFormSection(),
            const SizedBox(height: 24),

            // Error Message
            if (_errorMessage != null) ...[
              _buildErrorMessage(),
              const SizedBox(height: 24),
            ],

            // Submit Button
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Upload Certificate',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a JPEG or PNG image of your certificate',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Choose File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          if (_selectedFile != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedFile!.path.split('/').last,
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                _imageBytes!,
                fit: BoxFit.cover,
              ),
            ),
          ),
          if (_isProcessing) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                SpinKitFadingCircle(
                  color: Colors.blue[600],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Processing image...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Certificate Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          
          _buildTextField(
            controller: _recipientNameController,
            label: 'Recipient Name',
            icon: Icons.person,
            hint: 'Enter recipient name',
          ),
          
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _certificateTypeController,
            label: 'Certificate Type',
            icon: Icons.card_membership,
            hint: 'e.g., Participation, Achievement',
          ),
          
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _dateIssuedController,
            label: 'Date Issued',
            icon: Icons.calendar_today,
            hint: 'DD/MM/YYYY',
          ),
          
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _issuerNameController,
            label: 'Issuer Name',
            icon: Icons.business,
            hint: 'Enter issuer organization',
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey[600], size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue[400]!, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: (_isLoading || _selectedFile == null) ? null : _submitCertificate,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SpinKitFadingCircle(
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Text('Processing...'),
                ],
              )
            : const Text(
                'Process Certificate',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
} 