class KycVerificationModel {
  final String id;
  final String userId;
  final String fullName;
  final String citizenshipNumber;
  final String phoneNumber;
  final String frontImageUrl;
  final String backImageUrl;
  final String selfieImageUrl;
  final String status;
  final String? rejectionReason;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  KycVerificationModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.citizenshipNumber,
    required this.phoneNumber,
    required this.frontImageUrl,
    required this.backImageUrl,
    required this.selfieImageUrl,
    required this.status,
    this.rejectionReason,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  factory KycVerificationModel.fromMap(Map<String, dynamic> map) {
    return KycVerificationModel(
      id: map['id'].toString(),
      userId: map['user_id'],
      fullName: map['full_name'] ?? 'Unknown User',
      citizenshipNumber: map['citizenship_number'] ?? '',
      phoneNumber: map['phone_number'] ?? '',
      frontImageUrl: map['front_image_url'] ?? '',
      backImageUrl: map['back_image_url'] ?? '',
      selfieImageUrl: map['selfie_image_url'] ?? '',
      status: map['status'] ?? 'pending',
      rejectionReason: map['rejection_reason'],
      latitude: map['latitude'] != null ? double.tryParse(map['latitude'].toString()) : null,
      longitude: map['longitude'] != null ? double.tryParse(map['longitude'].toString()) : null,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class AdminStatsModel {
  final int totalUsers;
  final int totalProperties;
  final int pendingKyc;
  final int pendingReports;
  final int activeBookings;

  AdminStatsModel({
    required this.totalUsers,
    required this.totalProperties,
    required this.pendingKyc,
    required this.pendingReports,
    required this.activeBookings,
  });

  factory AdminStatsModel.fromMap(Map<String, int> map) {
    return AdminStatsModel(
      totalUsers: map['totalUsers'] ?? 0,
      totalProperties: map['totalProperties'] ?? 0,
      pendingKyc: map['pendingKyc'] ?? 0,
      pendingReports: map['pendingReports'] ?? 0,
      activeBookings: map['activeBookings'] ?? 0,
    );
  }
}
