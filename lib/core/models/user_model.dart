class UserModel {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final String? phoneNumber;
  final String kycStatus;
  final bool isVerified;
  final bool isOwner;
  final String? esewaNumber;
  final String? khaltiNumber;
  final String? accountHolderName;
  final String? qrCodeUrl;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.phoneNumber,
    this.kycStatus = 'unverified',
    this.isVerified = false,
    this.isOwner = false,
    this.esewaNumber,
    this.khaltiNumber,
    this.accountHolderName,
    this.qrCodeUrl,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      fullName: map['full_name'] ?? 'Khozna User',
      avatarUrl: map['avatar_url'],
      phoneNumber: map['phone_number'],
      kycStatus: map['kyc_status'] ?? 'unverified',
      isVerified: map['kyc_status'] == 'verified',
      isOwner: map['is_owner'] ?? false,
      esewaNumber: map['esewa_number'],
      khaltiNumber: map['khalti_number'],
      accountHolderName: map['account_holder_name'],
      qrCodeUrl: map['qr_code_url'],
      createdAt: DateTime.parse(
        map['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class UserReportModel {
  final String id;
  final String reportedUserId;
  final String reportedUserName;
  final String? reportedUserAvatar;
  final String reporterId;
  final String reporterName;
  final String reason;
  final DateTime createdAt;

  UserReportModel({
    required this.id,
    required this.reportedUserId,
    required this.reportedUserName,
    this.reportedUserAvatar,
    required this.reporterId,
    required this.reporterName,
    required this.reason,
    required this.createdAt,
  });

  factory UserReportModel.fromMap(Map<String, dynamic> map) {
    final reported = map['reported'] as Map<String, dynamic>?;
    final reporter = map['reporter'] as Map<String, dynamic>?;

    return UserReportModel(
      id: map['id'].toString(),
      reportedUserId: map['reported_user_id'],
      reportedUserName: reported?['full_name'] ?? 'Unknown User',
      reportedUserAvatar: reported?['avatar_url'],
      reporterId: map['reporter_id'],
      reporterName: reporter?['full_name'] ?? 'Anonymous',
      reason: map['reason'] ?? 'No reason provided',
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
