import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/certificate.dart';


class CertificateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> uploadCertificate(Certificate cert) async {
    await _firestore.collection('certificates').add(cert.toJson());
  }
}