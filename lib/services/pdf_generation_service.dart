import 'dart:io';
import 'dart:math';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PdfGenerationService {
  static const String _watermarkText = 'Digital Certificate Repository';

  /// Generate a professional certificate PDF
  static Future<Map<String, dynamic>> generateCertificate({
    required String recipientName,
    required String organization,
    required String purpose,
    required DateTime issueDate,
    required DateTime expiryDate,
    String? recipientEmail,
    String? issuerName,
    String? certificateType,
    String? template,
  }) async {
    try {
      // Generate unique signature
      final signature = _generateSignature();

      // Create PDF document
      final pdf = pw.Document();

      // Add certificate page based on template
      switch (template?.toLowerCase() ?? 'standard') {
        case 'academic':
          pdf.addPage(
            _createAcademicCertificate(
              recipientName: recipientName,
              organization: organization,
              purpose: purpose,
              issueDate: issueDate,
              expiryDate: expiryDate,
              signature: signature,
              issuerName: issuerName ?? 'Certificate Authority',
            ),
          );
          break;
        case 'professional':
          pdf.addPage(
            _createProfessionalCertificate(
              recipientName: recipientName,
              organization: organization,
              purpose: purpose,
              issueDate: issueDate,
              expiryDate: expiryDate,
              signature: signature,
              issuerName: issuerName ?? 'Certificate Authority',
            ),
          );
          break;
        case 'achievement':
          pdf.addPage(
            _createAchievementCertificate(
              recipientName: recipientName,
              organization: organization,
              purpose: purpose,
              issueDate: issueDate,
              expiryDate: expiryDate,
              signature: signature,
              issuerName: issuerName ?? 'Certificate Authority',
            ),
          );
          break;
        default:
          pdf.addPage(
            _createStandardCertificate(
              recipientName: recipientName,
              organization: organization,
              purpose: purpose,
              issueDate: issueDate,
              expiryDate: expiryDate,
              signature: signature,
              issuerName: issuerName ?? 'Certificate Authority',
            ),
          );
      }

      // Save PDF to temporary file
      final output = await getTemporaryDirectory();
      final fileName =
          'certificate_${DateTime.now().millisecondsSinceEpoch}_$signature.pdf';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Upload to Firebase Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('certificates')
          .child(fileName);
      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();

      return {
        'pdfUrl': downloadUrl,
        'signature': signature,
        'fileName': fileName,
        'filePath': file.path,
      };
    } catch (e) {
      throw Exception('Failed to generate certificate: $e');
    }
  }

  /// Generate unique signature for certificate
  static String _generateSignature() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomNum = random.nextInt(1000000);
    return 'DCR-${timestamp.toString().substring(timestamp.toString().length - 6)}-$randomNum';
  }

  /// Create standard certificate template
  static pw.Page _createStandardCertificate({
    required String recipientName,
    required String organization,
    required String purpose,
    required DateTime issueDate,
    required DateTime expiryDate,
    required String signature,
    required String issuerName,
  }) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey, width: 3),
          ),
          child: pw.Stack(
            children: [
              // Background watermark
              pw.Positioned.fill(
                child: pw.Center(
                  child: pw.Transform.rotate(
                    angle: -0.5,
                    child: pw.Text(
                      _watermarkText,
                      style: pw.TextStyle(
                        fontSize: 48,
                        color: PdfColors.grey300,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              // Main content
              pw.Padding(
                padding: const pw.EdgeInsets.all(40),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // Header
                    pw.Text(
                      'CERTIFICATE',
                      style: pw.TextStyle(
                        fontSize: 36,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal,
                      ),
                    ),
                    pw.SizedBox(height: 20),

                    // Certificate text
                    pw.Text(
                      'This is to certify that',
                      style: pw.TextStyle(fontSize: 18),
                    ),
                    pw.SizedBox(height: 10),

                    // Recipient name
                    pw.Text(
                      recipientName,
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                    pw.SizedBox(height: 20),

                    // Certificate details
                    pw.Text(
                      'has successfully completed the requirements for',
                      style: pw.TextStyle(fontSize: 16),
                    ),
                    pw.SizedBox(height: 10),

                    pw.Text(
                      purpose,
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal,
                      ),
                    ),
                    pw.SizedBox(height: 10),

                    pw.Text(
                      'at $organization',
                      style: pw.TextStyle(fontSize: 16),
                    ),
                    pw.SizedBox(height: 30),

                    // Dates
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                      children: [
                        pw.Column(
                          children: [
                            pw.Text(
                              'Issue Date',
                              style: pw.TextStyle(
                                fontSize: 12,
                                color: PdfColors.grey,
                              ),
                            ),
                            pw.Text(
                              _formatDate(issueDate),
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        pw.Column(
                          children: [
                            pw.Text(
                              'Expiry Date',
                              style: pw.TextStyle(
                                fontSize: 12,
                                color: PdfColors.grey,
                              ),
                            ),
                            pw.Text(
                              _formatDate(expiryDate),
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 40),

                    // Signature section
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Issued by:',
                              style: pw.TextStyle(
                                fontSize: 12,
                                color: PdfColors.grey,
                              ),
                            ),
                            pw.Text(
                              issuerName,
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              'Digital Signature:',
                              style: pw.TextStyle(
                                fontSize: 12,
                                color: PdfColors.grey,
                              ),
                            ),
                            pw.Text(
                              signature,
                              style: pw.TextStyle(
                                fontSize: 10,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Create academic certificate template
  static pw.Page _createAcademicCertificate({
    required String recipientName,
    required String organization,
    required String purpose,
    required DateTime issueDate,
    required DateTime expiryDate,
    required String signature,
    required String issuerName,
  }) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.blue, width: 4),
          ),
          child: pw.Stack(
            children: [
              // Academic seal watermark
              pw.Positioned(
                top: 50,
                right: 50,
                child: pw.Container(
                  width: 100,
                  height: 100,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    border: pw.Border.all(color: PdfColors.blue, width: 2),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'ACADEMIC\nSEAL',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue,
                      ),
                    ),
                  ),
                ),
              ),

              pw.Padding(
                padding: const pw.EdgeInsets.all(50),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'ACADEMIC CERTIFICATE',
                      style: pw.TextStyle(
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue,
                      ),
                    ),
                    pw.SizedBox(height: 30),

                    pw.Text(
                      'This academic certificate is hereby awarded to',
                      style: pw.TextStyle(fontSize: 16),
                    ),
                    pw.SizedBox(height: 15),

                    pw.Text(
                      recipientName,
                      style: pw.TextStyle(
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                    pw.SizedBox(height: 20),

                    pw.Text(
                      'for successful completion of',
                      style: pw.TextStyle(fontSize: 16),
                    ),
                    pw.SizedBox(height: 15),

                    pw.Text(
                      purpose,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue,
                      ),
                    ),
                    pw.SizedBox(height: 15),

                    pw.Text(
                      'at $organization',
                      style: pw.TextStyle(fontSize: 18),
                    ),
                    pw.SizedBox(height: 40),

                    pw.Text(
                      'Certificate ID: $signature',
                      style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
                    ),
                    pw.SizedBox(height: 20),

                    pw.Text(
                      'Valid from ${_formatDate(issueDate)} to ${_formatDate(expiryDate)}',
                      style: pw.TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Create professional certificate template
  static pw.Page _createProfessionalCertificate({
    required String recipientName,
    required String organization,
    required String purpose,
    required DateTime issueDate,
    required DateTime expiryDate,
    required String signature,
    required String issuerName,
  }) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.green, width: 3),
          ),
          child: pw.Stack(
            children: [
              // Professional logo watermark
              pw.Positioned(
                top: 30,
                left: 30,
                child: pw.Container(
                  width: 80,
                  height: 80,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green,
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'PRO',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ),
              ),

              pw.Padding(
                padding: const pw.EdgeInsets.all(40),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'PROFESSIONAL CERTIFICATION',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green,
                      ),
                    ),
                    pw.SizedBox(height: 30),

                    pw.Text(
                      'This professional certification is awarded to',
                      style: pw.TextStyle(fontSize: 16),
                    ),
                    pw.SizedBox(height: 15),

                    pw.Text(
                      recipientName,
                      style: pw.TextStyle(
                        fontSize: 30,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                    pw.SizedBox(height: 20),

                    pw.Text(
                      'for demonstrating excellence in',
                      style: pw.TextStyle(fontSize: 16),
                    ),
                    pw.SizedBox(height: 15),

                    pw.Text(
                      purpose,
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green,
                      ),
                    ),
                    pw.SizedBox(height: 15),

                    pw.Text(
                      'Organization: $organization',
                      style: pw.TextStyle(fontSize: 16),
                    ),
                    pw.SizedBox(height: 40),

                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Issue Date: ${_formatDate(issueDate)}',
                              style: pw.TextStyle(fontSize: 14),
                            ),
                            pw.Text(
                              'Expiry Date: ${_formatDate(expiryDate)}',
                              style: pw.TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              'Certification ID:',
                              style: pw.TextStyle(
                                fontSize: 12,
                                color: PdfColors.grey,
                              ),
                            ),
                            pw.Text(
                              signature,
                              style: pw.TextStyle(
                                fontSize: 10,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Create achievement certificate template
  static pw.Page _createAchievementCertificate({
    required String recipientName,
    required String organization,
    required String purpose,
    required DateTime issueDate,
    required DateTime expiryDate,
    required String signature,
    required String issuerName,
  }) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.orange, width: 4),
          ),
          child: pw.Stack(
            children: [
              // Achievement star watermark
              pw.Positioned(
                top: 50,
                left: 50,
                child: pw.Text(
                  '★',
                  style: pw.TextStyle(fontSize: 60, color: PdfColors.orange300),
                ),
              ),

              pw.Padding(
                padding: const pw.EdgeInsets.all(50),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'ACHIEVEMENT CERTIFICATE',
                      style: pw.TextStyle(
                        fontSize: 30,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.orange,
                      ),
                    ),
                    pw.SizedBox(height: 30),

                    pw.Text(
                      'Congratulations!',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.orange,
                      ),
                    ),
                    pw.SizedBox(height: 20),

                    pw.Text(
                      recipientName,
                      style: pw.TextStyle(
                        fontSize: 34,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                    pw.SizedBox(height: 20),

                    pw.Text(
                      'You have successfully achieved',
                      style: pw.TextStyle(fontSize: 16),
                    ),
                    pw.SizedBox(height: 15),

                    pw.Text(
                      purpose,
                      style: pw.TextStyle(
                        fontSize: 26,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.orange,
                      ),
                    ),
                    pw.SizedBox(height: 15),

                    pw.Text(
                      'at $organization',
                      style: pw.TextStyle(fontSize: 18),
                    ),
                    pw.SizedBox(height: 40),

                    pw.Text(
                      'Achievement ID: $signature',
                      style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
                    ),
                    pw.SizedBox(height: 20),

                    pw.Text(
                      'Awarded on ${_formatDate(issueDate)}',
                      style: pw.TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Format date for display
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
