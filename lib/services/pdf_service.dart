import 'dart:io';
import 'dart:math';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class PdfService {
  /// Generate a certificate PDF with the given data
  static Future<File> generateCertificate({
    required String recipientName,
    required String organization,
    required String purpose,
    required DateTime issueDate,
    required DateTime expiryDate,
    String? template = 'standard',
  }) async {
    final pdf = pw.Document();
    final signature = 'SIG-${Random().nextInt(1000000)}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return _buildCertificateContent(
            recipientName: recipientName,
            organization: organization,
            purpose: purpose,
            issueDate: issueDate,
            expiryDate: expiryDate,
            signature: signature,
            template: template,
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/certificate_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _buildCertificateContent({
    required String recipientName,
    required String organization,
    required String purpose,
    required DateTime issueDate,
    required DateTime expiryDate,
    required String signature,
    String? template,
  }) {
    switch (template) {
      case 'academic':
        return _buildAcademicTemplate(
          recipientName: recipientName,
          organization: organization,
          purpose: purpose,
          issueDate: issueDate,
          expiryDate: expiryDate,
          signature: signature,
        );
      case 'professional':
        return _buildProfessionalTemplate(
          recipientName: recipientName,
          organization: organization,
          purpose: purpose,
          issueDate: issueDate,
          expiryDate: expiryDate,
          signature: signature,
        );
      case 'achievement':
        return _buildAchievementTemplate(
          recipientName: recipientName,
          organization: organization,
          purpose: purpose,
          issueDate: issueDate,
          expiryDate: expiryDate,
          signature: signature,
        );
      default:
        return _buildStandardTemplate(
          recipientName: recipientName,
          organization: organization,
          purpose: purpose,
          issueDate: issueDate,
          expiryDate: expiryDate,
          signature: signature,
        );
    }
  }

  static pw.Widget _buildStandardTemplate({
    required String recipientName,
    required String organization,
    required String purpose,
    required DateTime issueDate,
    required DateTime expiryDate,
    required String signature,
  }) {
    return pw.Container(
      padding: pw.EdgeInsets.all(40),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey, width: 2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'CERTIFICATE',
            style: pw.TextStyle(
              fontSize: 32,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.teal,
            ),
          ),
          pw.SizedBox(height: 40),
          pw.Text('This is to certify that', style: pw.TextStyle(fontSize: 16)),
          pw.SizedBox(height: 20),
          pw.Text(
            recipientName,
            style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'has successfully completed the requirements for',
            style: pw.TextStyle(fontSize: 16),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            purpose,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 40),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Issue Date: ${_formatDate(issueDate)}'),
                  pw.Text('Expiry Date: ${_formatDate(expiryDate)}'),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Digital Signature:'),
                  pw.Text(signature, style: pw.TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildAcademicTemplate({
    required String recipientName,
    required String organization,
    required String purpose,
    required DateTime issueDate,
    required DateTime expiryDate,
    required String signature,
  }) {
    return pw.Container(
      padding: pw.EdgeInsets.all(40),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue, width: 3),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: 80,
            height: 80,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              color: PdfColors.blue,
            ),
            child: pw.Center(
              child: pw.Text(
                'SEAL',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
          pw.SizedBox(height: 30),
          pw.Text(
            'ACADEMIC CERTIFICATE',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue,
            ),
          ),
          pw.SizedBox(height: 40),
          pw.Text(
            'This academic certificate is hereby awarded to',
            style: pw.TextStyle(fontSize: 16),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            recipientName,
            style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'for successful completion of',
            style: pw.TextStyle(fontSize: 16),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            purpose,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 40),
          pw.Text(
            'Issued on ${_formatDate(issueDate)}',
            style: pw.TextStyle(fontSize: 14),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Certificate ID: $signature',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildProfessionalTemplate({
    required String recipientName,
    required String organization,
    required String purpose,
    required DateTime issueDate,
    required DateTime expiryDate,
    required String signature,
  }) {
    return pw.Container(
      padding: pw.EdgeInsets.all(40),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [PdfColors.grey300, PdfColors.white],
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'PROFESSIONAL CERTIFICATION',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 30),
          pw.Text(
            'This professional certification is awarded to',
            style: pw.TextStyle(fontSize: 14),
          ),
          pw.SizedBox(height: 15),
          pw.Text(
            recipientName,
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 15),
          pw.Text(
            'for demonstrating proficiency in',
            style: pw.TextStyle(fontSize: 14),
          ),
          pw.SizedBox(height: 15),
          pw.Text(
            purpose,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 30),
          pw.Container(
            padding: pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Column(
              children: [
                pw.Text('Issue Date: ${_formatDate(issueDate)}'),
                pw.Text('Valid Until: ${_formatDate(expiryDate)}'),
                pw.Text('Certification ID: $signature'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildAchievementTemplate({
    required String recipientName,
    required String organization,
    required String purpose,
    required DateTime issueDate,
    required DateTime expiryDate,
    required String signature,
  }) {
    return pw.Container(
      padding: pw.EdgeInsets.all(40),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [PdfColors.yellow, PdfColors.orange],
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text('🏆', style: pw.TextStyle(fontSize: 60)),
          pw.SizedBox(height: 20),
          pw.Text(
            'ACHIEVEMENT CERTIFICATE',
            style: pw.TextStyle(
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 40),
          pw.Text(
            'Congratulations to',
            style: pw.TextStyle(fontSize: 18, color: PdfColors.white),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            recipientName,
            style: pw.TextStyle(
              fontSize: 32,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'for outstanding achievement in',
            style: pw.TextStyle(fontSize: 18, color: PdfColors.white),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            purpose,
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 40),
          pw.Text(
            'Awarded on ${_formatDate(issueDate)}',
            style: pw.TextStyle(fontSize: 16, color: PdfColors.white),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Achievement ID: $signature',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.white),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Get available certificate templates
  static List<Map<String, String>> getAvailableTemplates() {
    return [
      {
        'id': 'standard',
        'name': 'Standard Certificate',
        'description': 'Professional certificate with clean design',
      },
      {
        'id': 'academic',
        'name': 'Academic Certificate',
        'description': 'Formal academic certificate with seal',
      },
      {
        'id': 'professional',
        'name': 'Professional Certification',
        'description': 'Professional certification with logo',
      },
      {
        'id': 'achievement',
        'name': 'Achievement Certificate',
        'description': 'Celebratory achievement certificate',
      },
    ];
  }
}
