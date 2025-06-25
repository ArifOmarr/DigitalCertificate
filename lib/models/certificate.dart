class Certificate {
  final String name;
  final String organization;
  final String purpose;
  final DateTime issueDate;
  final DateTime expiryDate;

  Certificate({
    required this.name,
    required this.organization,
    required this.purpose,
    required this.issueDate,
    required this.expiryDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'organization': organization,
      'purpose': purpose,
      'issueDate': issueDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
    };
  }
}