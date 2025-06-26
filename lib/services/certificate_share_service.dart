import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class CertificateShareService {
  /// Generates a secure shareable link token for a certificate.
  /// [certificateId]: The Firestore document ID of the certificate.
  /// [expireDays]: Number of days before the link expires (default 3).
  /// [oneTime]: If true, link is one-time use only.
  Future<String> createShareableLink(String certificateId, {int expireDays = 3, bool oneTime = false}) async {
    // Generate a random 32-character token
    final token = List.generate(32, (i) => Random().nextInt(36).toRadixString(36)).join();
    final expiresAt = DateTime.now().add(Duration(days: expireDays));
    await FirebaseFirestore.instance.collection('shared_links').doc(token).set({
      'certificateId': certificateId,
      'expiresAt': expiresAt,
      'used': false,
      'oneTime': oneTime,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return token;
  }
} 