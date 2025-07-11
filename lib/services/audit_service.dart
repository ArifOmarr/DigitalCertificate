import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum AuditAction {
  certificateCreated,
  certificateIssued,
  certificateApproved,
  certificateRejected,
  certificateViewed,
  certificateDownloaded,
  certificateShared,
  certificateExpired,
  certificateRevoked,
  userLogin,
  userLogout,
  roleChanged,
  documentUploaded,
  documentVerified,
  signatureAdded,
  watermarkApplied,
  systemAccess,
  dataExport,
  configurationChanged,
  securityEvent,
  backupCreated,
  maintenancePerformed,
}

class AuditService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Log an audit event with detailed information
  Future<void> logAction({
    required AuditAction action,
    required String description,
    Map<String, dynamic>? metadata,
    String? targetId,
    String? targetType,
  }) async {
    try {
      final user = _auth.currentUser;
      await _firestore.collection('audit_logs').add({
        'action': action.toString().split('.').last,
        'description': description,
        'userId': user?.uid,
        'userEmail': user?.email,
        'userRole': await _getUserRole(user?.uid),
        'targetId': targetId,
        'targetType': targetType,
        'metadata': metadata ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'ipAddress': 'N/A', // Could be enhanced with IP tracking
        'userAgent': 'Flutter App',
        'sessionId': _generateSessionId(),
        'severity': _getActionSeverity(action),
      });
    } catch (e) {
      print('Error logging audit event: $e');
      // Don't throw error to avoid breaking main functionality
    }
  }

  /// Get user role for audit logging
  Future<String?> _getUserRole(String? uid) async {
    if (uid == null) return null;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['role'];
    } catch (e) {
      return null;
    }
  }

  /// Generate a session ID for tracking user sessions
  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}_${_auth.currentUser?.uid ?? 'anonymous'}';
  }

  /// Get severity level for audit action
  String _getActionSeverity(AuditAction action) {
    switch (action) {
      case AuditAction.securityEvent:
      case AuditAction.certificateRevoked:
      case AuditAction.systemAccess:
        return 'high';
      case AuditAction.certificateApproved:
      case AuditAction.certificateRejected:
      case AuditAction.roleChanged:
      case AuditAction.configurationChanged:
        return 'medium';
      default:
        return 'low';
    }
  }

  /// Log certificate creation
  Future<void> logCertificateCreated({
    required String certificateId,
    required String recipientName,
    required String recipientEmail,
    required String organization,
    required String purpose,
  }) async {
    await logAction(
      action: AuditAction.certificateCreated,
      description: 'Certificate created for $recipientName',
      targetId: certificateId,
      targetType: 'certificate',
      metadata: {
        'recipientName': recipientName,
        'recipientEmail': recipientEmail,
        'organization': organization,
        'purpose': purpose,
      },
    );
  }

  /// Log certificate issuance
  Future<void> logCertificateIssued({
    required String certificateId,
    required String recipientName,
    required String signature,
  }) async {
    await logAction(
      action: AuditAction.certificateIssued,
      description: 'Certificate issued to $recipientName with signature: $signature',
      targetId: certificateId,
      targetType: 'certificate',
      metadata: {
        'recipientName': recipientName,
        'signature': signature,
      },
    );
  }

  /// Log certificate approval
  Future<void> logCertificateApproved({
    required String certificateId,
    required String recipientName,
    String? approverNotes,
  }) async {
    await logAction(
      action: AuditAction.certificateApproved,
      description: 'Certificate approved for $recipientName',
      targetId: certificateId,
      targetType: 'certificate',
      metadata: {
        'recipientName': recipientName,
        'approverNotes': approverNotes,
      },
    );
  }

  /// Log certificate rejection
  Future<void> logCertificateRejected({
    required String certificateId,
    required String recipientName,
    required String rejectionReason,
  }) async {
    await logAction(
      action: AuditAction.certificateRejected,
      description: 'Certificate rejected for $recipientName',
      targetId: certificateId,
      targetType: 'certificate',
      metadata: {
        'recipientName': recipientName,
        'rejectionReason': rejectionReason,
      },
    );
  }

  /// Log certificate viewing
  Future<void> logCertificateViewed({
    required String certificateId,
    required String viewerEmail,
  }) async {
    await logAction(
      action: AuditAction.certificateViewed,
      description: 'Certificate viewed by $viewerEmail',
      targetId: certificateId,
      targetType: 'certificate',
      metadata: {
        'viewerEmail': viewerEmail,
      },
    );
  }

  /// Log certificate download
  Future<void> logCertificateDownloaded({
    required String certificateId,
    required String downloaderEmail,
  }) async {
    await logAction(
      action: AuditAction.certificateDownloaded,
      description: 'Certificate downloaded by $downloaderEmail',
      targetId: certificateId,
      targetType: 'certificate',
      metadata: {
        'downloaderEmail': downloaderEmail,
      },
    );
  }

  /// Log certificate sharing
  Future<void> logCertificateShared({
    required String certificateId,
    required String sharedBy,
    required String shareMethod,
  }) async {
    await logAction(
      action: AuditAction.certificateShared,
      description: 'Certificate shared by $sharedBy via $shareMethod',
      targetId: certificateId,
      targetType: 'certificate',
      metadata: {
        'sharedBy': sharedBy,
        'shareMethod': shareMethod,
      },
    );
  }

  /// Log user login
  Future<void> logUserLogin({
    required String userEmail,
    required String userRole,
  }) async {
    await logAction(
      action: AuditAction.userLogin,
      description: 'User login: $userEmail',
      metadata: {
        'userEmail': userEmail,
        'userRole': userRole,
        'loginMethod': 'Google Sign-In',
      },
    );
  }

  /// Log user logout
  Future<void> logUserLogout({
    required String userEmail,
  }) async {
    await logAction(
      action: AuditAction.userLogout,
      description: 'User logout: $userEmail',
      metadata: {
        'userEmail': userEmail,
      },
    );
  }

  /// Log role change
  Future<void> logRoleChanged({
    required String userEmail,
    required String oldRole,
    required String newRole,
    required String changedBy,
  }) async {
    await logAction(
      action: AuditAction.roleChanged,
      description: 'Role changed for $userEmail from $oldRole to $newRole',
      metadata: {
        'userEmail': userEmail,
        'oldRole': oldRole,
        'newRole': newRole,
        'changedBy': changedBy,
      },
    );
  }

  /// Log document upload
  Future<void> logDocumentUploaded({
    required String documentId,
    required String uploaderEmail,
    required String documentType,
    required int fileSize,
  }) async {
    await logAction(
      action: AuditAction.documentUploaded,
      description: 'Document uploaded by $uploaderEmail',
      targetId: documentId,
      targetType: 'document',
      metadata: {
        'uploaderEmail': uploaderEmail,
        'documentType': documentType,
        'fileSize': fileSize,
      },
    );
  }

  /// Log document verification
  Future<void> logDocumentVerified({
    required String documentId,
    required String verifierEmail,
    required String verificationResult,
    String? verificationNotes,
  }) async {
    await logAction(
      action: AuditAction.documentVerified,
      description: 'Document verified by $verifierEmail',
      targetId: documentId,
      targetType: 'document',
      metadata: {
        'verifierEmail': verifierEmail,
        'verificationResult': verificationResult,
        'verificationNotes': verificationNotes,
      },
    );
  }

  /// Log signature addition
  Future<void> logSignatureAdded({
    required String certificateId,
    required String signature,
    required String signatureType,
  }) async {
    await logAction(
      action: AuditAction.signatureAdded,
      description: 'Digital signature added to certificate',
      targetId: certificateId,
      targetType: 'certificate',
      metadata: {
        'signature': signature,
        'signatureType': signatureType,
      },
    );
  }

  /// Log watermark application
  Future<void> logWatermarkApplied({
    required String certificateId,
    required String watermarkText,
    required String watermarkType,
  }) async {
    await logAction(
      action: AuditAction.watermarkApplied,
      description: 'Watermark applied to certificate',
      targetId: certificateId,
      targetType: 'certificate',
      metadata: {
        'watermarkText': watermarkText,
        'watermarkType': watermarkType,
      },
    );
  }

  /// Log system access
  Future<void> logSystemAccess({
    required String accessType,
    required String accessedBy,
    Map<String, dynamic>? accessDetails,
  }) async {
    await logAction(
      action: AuditAction.systemAccess,
      description: 'System access: $accessType by $accessedBy',
      metadata: {
        'accessType': accessType,
        'accessedBy': accessedBy,
        'accessDetails': accessDetails,
      },
    );
  }

  /// Log data export
  Future<void> logDataExport({
    required String exportType,
    required String exportedBy,
    required int recordCount,
  }) async {
    await logAction(
      action: AuditAction.dataExport,
      description: 'Data export: $exportType by $exportedBy',
      metadata: {
        'exportType': exportType,
        'exportedBy': exportedBy,
        'recordCount': recordCount,
      },
    );
  }

  /// Log configuration change
  Future<void> logConfigurationChanged({
    required String configKey,
    required String oldValue,
    required String newValue,
    required String changedBy,
  }) async {
    await logAction(
      action: AuditAction.configurationChanged,
      description: 'Configuration changed: $configKey',
      metadata: {
        'configKey': configKey,
        'oldValue': oldValue,
        'newValue': newValue,
        'changedBy': changedBy,
      },
    );
  }

  /// Log security event
  Future<void> logSecurityEvent({
    required String eventType,
    required String description,
    required String severity,
    Map<String, dynamic>? eventDetails,
  }) async {
    await logAction(
      action: AuditAction.securityEvent,
      description: 'Security event: $description',
      metadata: {
        'eventType': eventType,
        'severity': severity,
        'eventDetails': eventDetails,
      },
    );
  }

  /// Get audit statistics
  Future<Map<String, dynamic>> getAuditStatistics({
    DateTime? startDate,
    DateTime? endDate,
    String? userRole,
  }) async {
    try {
      Query query = _firestore.collection('audit_logs');
      
      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }
      if (userRole != null) {
        query = query.where('userRole', isEqualTo: userRole);
      }
      
      final querySnapshot = await query.get();
      final logs = querySnapshot.docs;
      
      // Calculate statistics
      Map<String, int> actionCounts = {};
      Map<String, int> severityCounts = {};
      Map<String, int> userActivity = {};
      
      for (final doc in logs) {
        final data = doc.data() as Map<String, dynamic>;
        final action = data['action'] as String? ?? 'unknown';
        final severity = data['severity'] as String? ?? 'low';
        final userEmail = data['userEmail'] as String? ?? 'anonymous';
        
        actionCounts[action] = (actionCounts[action] ?? 0) + 1;
        severityCounts[severity] = (severityCounts[severity] ?? 0) + 1;
        userActivity[userEmail] = (userActivity[userEmail] ?? 0) + 1;
      }
      
      return {
        'totalLogs': logs.length,
        'actionCounts': actionCounts,
        'severityCounts': severityCounts,
        'userActivity': userActivity,
        'period': {
          'startDate': startDate?.toIso8601String(),
          'endDate': endDate?.toIso8601String(),
        },
      };
    } catch (e) {
      print('Error getting audit statistics: $e');
      return {};
    }
  }

  /// Get recent audit logs
  Future<List<Map<String, dynamic>>> getRecentAuditLogs({
    int limit = 50,
    String? action,
    String? severity,
  }) async {
    try {
      Query query = _firestore.collection('audit_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit);
      
      if (action != null) {
        query = query.where('action', isEqualTo: action);
      }
      if (severity != null) {
        query = query.where('severity', isEqualTo: severity);
      }
      
      final querySnapshot = await query.get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error getting recent audit logs: $e');
      return [];
    }
  }

  /// Get audit logs for a specific certificate
  Future<List<Map<String, dynamic>>> getCertificateAuditLogs(String certificateId) async {
    try {
      final querySnapshot = await _firestore.collection('audit_logs')
          .where('targetId', isEqualTo: certificateId)
          .where('targetType', isEqualTo: 'certificate')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error getting certificate audit logs: $e');
      return [];
    }
  }

  /// Get audit logs for a specific user
  Future<List<Map<String, dynamic>>> getUserAuditLogs(String userId) async {
    try {
      final querySnapshot = await _firestore.collection('audit_logs')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error getting user audit logs: $e');
      return [];
    }
  }

  /// Get all audit logs with optional filtering
  Future<List<Map<String, dynamic>>> getAllAuditLogs({
    int limit = 200,
    String? action,
    String? severity,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection('audit_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit);
      
      if (action != null) {
        query = query.where('action', isEqualTo: action);
      }
      if (severity != null) {
        query = query.where('severity', isEqualTo: severity);
      }
      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }
      
      final querySnapshot = await query.get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error getting all audit logs: $e');
      return [];
    }
  }

  /// Get audit logs by action type
  Future<List<Map<String, dynamic>>> getAuditLogsByAction(String action, {int limit = 50}) async {
    try {
      final querySnapshot = await _firestore.collection('audit_logs')
          .where('action', isEqualTo: action)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error getting audit logs by action: $e');
      return [];
    }
  }

  /// Get high severity audit logs
  Future<List<Map<String, dynamic>>> getHighSeverityLogs({int limit = 50}) async {
    try {
      final querySnapshot = await _firestore.collection('audit_logs')
          .where('severity', isEqualTo: 'high')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error getting high severity logs: $e');
      return [];
    }
  }
} 