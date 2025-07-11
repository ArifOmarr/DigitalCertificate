import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'audit_service.dart';

class SignatureService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuditService _auditService = AuditService();

  /// Generate a unique digital signature for a certificate
  Future<String> generateDigitalSignature({
    required String recipientName,
    required String organization,
    required String purpose,
    required DateTime issueDate,
    required DateTime expiryDate,
    String? issuerId,
  }) async {
    final user = _auth.currentUser;
    final issuer = issuerId ?? user?.uid ?? 'unknown';
    
    // Create a unique signature based on certificate data and issuer
    final signatureData = {
      'recipientName': recipientName,
      'organization': organization,
      'purpose': purpose,
      'issueDate': issueDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'issuer': issuer,
      'timestamp': DateTime.now().toIso8601String(),
      'nonce': Random().nextInt(1000000).toString(),
    };

    // Create SHA-256 hash of the signature data
    final signatureString = json.encode(signatureData);
    final bytes = utf8.encode(signatureString);
    final digest = sha256.convert(bytes);
    
    // Create a human-readable signature format
    final signature = 'SIG-${digest.toString().substring(0, 16).toUpperCase()}-${DateTime.now().millisecondsSinceEpoch}';
    
    return signature;
  }

  /// Generate a certificate template based on type
  Map<String, dynamic> generateCertificateTemplate({
    required String templateType,
    required String recipientName,
    required String organization,
    required String purpose,
    required DateTime issueDate,
    required DateTime expiryDate,
  }) {
    final templates = {
      'academic': {
        'title': 'Academic Certificate',
        'template': 'academic_template',
        'watermark': 'ACADEMIC CERTIFICATE',
        'signatureRequired': true,
        'qrCodeRequired': true,
      },
      'professional': {
        'title': 'Professional Certificate',
        'template': 'professional_template',
        'watermark': 'PROFESSIONAL CERTIFICATE',
        'signatureRequired': true,
        'qrCodeRequired': true,
      },
      'achievement': {
        'title': 'Achievement Certificate',
        'template': 'achievement_template',
        'watermark': 'ACHIEVEMENT CERTIFICATE',
        'signatureRequired': true,
        'qrCodeRequired': false,
      },
      'participation': {
        'title': 'Participation Certificate',
        'template': 'participation_template',
        'watermark': 'PARTICIPATION CERTIFICATE',
        'signatureRequired': false,
        'qrCodeRequired': false,
      },
    };

    final template = templates[templateType] ?? templates['academic']!;
    
    return {
      'templateType': templateType,
      'title': template['title'],
      'template': template['template'],
      'watermark': template['watermark'],
      'signatureRequired': template['signatureRequired'],
      'qrCodeRequired': template['qrCodeRequired'],
      'recipientName': recipientName,
      'organization': organization,
      'purpose': purpose,
      'issueDate': issueDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Verify a digital signature
  Future<bool> verifyDigitalSignature({
    required String signature,
    required String certificateId,
  }) async {
    try {
      // Get certificate data from Firestore
      final doc = await _firestore.collection('certificates').doc(certificateId).get();
      if (!doc.exists) return false;
      
      final data = doc.data()!;
      final storedSignature = data['signature'] as String?;
      
      if (storedSignature == null) return false;
      
      // Check if signature matches
      return signature == storedSignature;
    } catch (e) {
      print('Error verifying signature: $e');
      return false;
    }
  }

  /// Generate a watermark text for certificates
  String generateWatermark({
    required String recipientName,
    required String organization,
    DateTime? issueDate,
  }) {
    final date = issueDate ?? DateTime.now();
    final dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    
    return 'DIGITAL CERTIFICATE\n$organization\nIssued: $dateStr\nRecipient: $recipientName';
  }

  /// Create a QR code data for certificate verification
  String generateQRCodeData({
    required String certificateId,
    required String signature,
    required String verificationUrl,
  }) {
    final qrData = {
      'certificateId': certificateId,
      'signature': signature,
      'verificationUrl': verificationUrl,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    return json.encode(qrData);
  }

  /// Add digital signature to certificate metadata
  Future<void> addSignatureToCertificate({
    required String certificateId,
    required String signature,
    String? signatureType = 'SHA-256',
  }) async {
    try {
      await _firestore.collection('certificates').doc(certificateId).update({
        'signature': signature,
        'signatureType': signatureType,
        'signedAt': FieldValue.serverTimestamp(),
        'signedBy': _auth.currentUser?.uid,
      });

      // Log the signature addition
      await _auditService.logSignatureAdded(
        certificateId: certificateId,
        signature: signature,
        signatureType: signatureType ?? 'SHA-256',
      );
    } catch (e) {
      print('Error adding signature to certificate: $e');
      rethrow;
    }
  }

  /// Add watermark to certificate metadata
  Future<void> addWatermarkToCertificate({
    required String certificateId,
    required String watermarkText,
    String? watermarkType = 'text',
  }) async {
    try {
      await _firestore.collection('certificates').doc(certificateId).update({
        'watermark': watermarkText,
        'watermarkType': watermarkType,
        'watermarkedAt': FieldValue.serverTimestamp(),
      });

      // Log the watermark application
      await _auditService.logWatermarkApplied(
        certificateId: certificateId,
        watermarkText: watermarkText,
        watermarkType: watermarkType ?? 'text',
      );
    } catch (e) {
      print('Error adding watermark to certificate: $e');
      rethrow;
    }
  }

  /// Get certificate verification data
  Future<Map<String, dynamic>?> getCertificateVerificationData(String certificateId) async {
    try {
      final doc = await _firestore.collection('certificates').doc(certificateId).get();
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      return {
        'certificateId': certificateId,
        'signature': data['signature'],
        'signatureType': data['signatureType'],
        'signedAt': data['signedAt'],
        'signedBy': data['signedBy'],
        'watermark': data['watermark'],
        'watermarkType': data['watermarkType'],
        'recipientName': data['recipientName'],
        'organization': data['organization'],
        'issueDate': data['issueDate'],
        'expiryDate': data['expiryDate'],
        'status': data['status'],
      };
    } catch (e) {
      print('Error getting certificate verification data: $e');
      return null;
    }
  }

  /// Create a certificate hash for tamper detection
  String createCertificateHash({
    required String recipientName,
    required String organization,
    required String purpose,
    required DateTime issueDate,
    required DateTime expiryDate,
    required String signature,
  }) {
    final certificateData = {
      'recipientName': recipientName,
      'organization': organization,
      'purpose': purpose,
      'issueDate': issueDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'signature': signature,
    };
    
    final dataString = json.encode(certificateData);
    final bytes = utf8.encode(dataString);
    final digest = sha256.convert(bytes);
    
    return digest.toString();
  }

  /// Validate certificate data integrity
  Future<bool> validateCertificateIntegrity(String certificateId) async {
    try {
      final doc = await _firestore.collection('certificates').doc(certificateId).get();
      if (!doc.exists) return false;
      
      final data = doc.data()!;
      final storedHash = data['certificateHash'] as String?;
      
      if (storedHash == null) return false;
      
      // Recalculate hash and compare
      final calculatedHash = createCertificateHash(
        recipientName: data['recipientName'] ?? '',
        organization: data['organization'] ?? '',
        purpose: data['purpose'] ?? '',
        issueDate: (data['issueDate'] as Timestamp).toDate(),
        expiryDate: (data['expiryDate'] as Timestamp).toDate(),
        signature: data['signature'] ?? '',
      );
      
      return storedHash == calculatedHash;
    } catch (e) {
      print('Error validating certificate integrity: $e');
      return false;
    }
  }

  /// Generate certificate serial number
  String generateCertificateSerialNumber({
    required String organization,
    required String certificateType,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(1000);
    final orgCode = organization.substring(0, 3).toUpperCase();
    final typeCode = certificateType.substring(0, 3).toUpperCase();
    
    return '$orgCode-$typeCode-$timestamp-$random';
  }

  /// Check if certificate is expired
  bool isCertificateExpired(DateTime expiryDate) {
    return DateTime.now().isAfter(expiryDate);
  }

  /// Get certificate status
  String getCertificateStatus({
    required DateTime issueDate,
    required DateTime expiryDate,
    required String currentStatus,
  }) {
    if (currentStatus == 'Revoked') return 'Revoked';
    if (isCertificateExpired(expiryDate)) return 'Expired';
    if (DateTime.now().isBefore(issueDate)) return 'Pending';
    return 'Valid';
  }
} 