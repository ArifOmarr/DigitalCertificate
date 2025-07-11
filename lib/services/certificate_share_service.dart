import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CertificateShareService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Generates a secure shareable link token for a certificate.
  /// [certificateId]: The Firestore document ID of the certificate.
  /// [expireDays]: Number of days before the link expires (default 3).
  /// [oneTime]: If true, link is one-time use only.
  /// [requireOtp]: If true, requires OTP for access.
  Future<String> createShareableLink(
    String certificateId, {
    int expireDays = 3,
    bool oneTime = false,
    bool requireOtp = false,
  }) async {
    // Generate a random 32-character token
    final token = List.generate(32, (i) => Random().nextInt(36).toRadixString(36)).join();
    final expiresAt = DateTime.now().add(Duration(days: expireDays));
    
    // Generate OTP if required
    String? otp;
    if (requireOtp) {
      otp = _generateOTP();
    }

    final user = _auth.currentUser;
    
    await FirebaseFirestore.instance.collection('shared_links').doc(token).set({
      'certificateId': certificateId,
      'expiresAt': expiresAt,
      'used': false,
      'oneTime': oneTime,
      'requireOtp': requireOtp,
      'otp': otp,
      'createdBy': user?.uid,
      'createdByEmail': user?.email,
      'createdAt': FieldValue.serverTimestamp(),
      'accessCount': 0,
      'lastAccessedAt': null,
    });
    
    return token;
  }

  /// Generate a 6-digit OTP
  String _generateOTP() {
    final random = Random();
    return List.generate(6, (index) => random.nextInt(10)).join();
  }

  /// Validate a shareable link token
  Future<Map<String, dynamic>?> validateShareableLink(String token) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('shared_links').doc(token).get();
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      final now = DateTime.now();
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      
      // Check if expired
      if (expiresAt.isBefore(now)) {
        return {'valid': false, 'reason': 'Link expired'};
      }
      
      // Check if one-time use and already used
      if (data['oneTime'] == true && data['used'] == true) {
        return {'valid': false, 'reason': 'Link already used'};
      }
      
      return {
        'valid': true,
        'data': data,
        'requireOtp': data['requireOtp'] ?? false,
        'otp': data['otp'],
      };
    } catch (e) {
      return {'valid': false, 'reason': 'Invalid link'};
    }
  }

  /// Verify OTP for shared link
  Future<bool> verifyOTP(String token, String otp) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('shared_links').doc(token).get();
      if (!doc.exists) return false;
      
      final data = doc.data()!;
      final storedOtp = data['otp'] as String?;
      
      return storedOtp == otp;
    } catch (e) {
      return false;
    }
  }

  /// Log access to shared link
  Future<void> logAccess(String token, String certificateId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      // Update access count and last accessed time
      final linkRef = FirebaseFirestore.instance.collection('shared_links').doc(token);
      batch.update(linkRef, {
        'accessCount': FieldValue.increment(1),
        'lastAccessedAt': FieldValue.serverTimestamp(),
        'used': true, // Mark as used if one-time
      });
      
      // Log access in separate collection
      final accessLogRef = FirebaseFirestore.instance.collection('shared_links').doc(token).collection('access_logs').doc();
      batch.set(accessLogRef, {
        'certificateId': certificateId,
        'token': token,
        'accessedAt': FieldValue.serverTimestamp(),
        'userAgent': 'Flutter App',
        'ipAddress': 'N/A', // Could be enhanced with IP tracking
      });
      
      await batch.commit();
    } catch (e) {
      print('Error logging access: $e');
    }
  }

  /// Get access statistics for a shared link
  Future<Map<String, dynamic>> getAccessStatistics(String token) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('shared_links').doc(token).get();
      if (!doc.exists) return {};
      
      final data = doc.data()!;
      final accessLogs = await FirebaseFirestore.instance
          .collection('shared_links')
          .doc(token)
          .collection('access_logs')
          .orderBy('accessedAt', descending: true)
          .limit(10)
          .get();
      
      return {
        'accessCount': data['accessCount'] ?? 0,
        'lastAccessedAt': data['lastAccessedAt'],
        'createdAt': data['createdAt'],
        'expiresAt': data['expiresAt'],
        'oneTime': data['oneTime'] ?? false,
        'used': data['used'] ?? false,
        'requireOtp': data['requireOtp'] ?? false,
        'recentAccesses': accessLogs.docs.map((doc) => doc.data()).toList(),
      };
    } catch (e) {
      return {};
    }
  }

  /// Revoke a shared link
  Future<void> revokeSharedLink(String token) async {
    try {
      await FirebaseFirestore.instance.collection('shared_links').doc(token).update({
        'revokedAt': FieldValue.serverTimestamp(),
        'revokedBy': _auth.currentUser?.uid,
        'revokedByEmail': _auth.currentUser?.email,
      });
    } catch (e) {
      print('Error revoking shared link: $e');
    }
  }

  /// Get all shared links for a certificate
  Future<List<Map<String, dynamic>>> getSharedLinksForCertificate(String certificateId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('shared_links')
          .where('certificateId', isEqualTo: certificateId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'token': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Clean up expired shared links
  Future<void> cleanupExpiredLinks() async {
    try {
      final now = DateTime.now();
      final querySnapshot = await FirebaseFirestore.instance
          .collection('shared_links')
          .where('expiresAt', isLessThan: now)
          .get();
      
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      print('Error cleaning up expired links: $e');
    }
  }

  /// Generate share link URL
  String generateShareUrl(String token, {String? baseUrl}) {
    final base = baseUrl ?? 'https://your-domain.com';
    return '$base/shared/$token';
  }

  /// Check if user has permission to share certificate
  Future<bool> canShareCertificate(String certificateId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      final doc = await FirebaseFirestore.instance.collection('certificates').doc(certificateId).get();
      if (!doc.exists) return false;
      
      final data = doc.data()!;
      final recipientEmail = data['recipientEmail'] as String?;
      final issuer = data['issuer'] as String?;
      
      // Allow sharing if user is the recipient or issuer
      return user.email == recipientEmail || issuer == 'CA';
    } catch (e) {
      return false;
    }
  }
} 