class ReviewModel {
  final String id;
  final String bookingId;
  final String reviewerId;
  final String targetId;
  final String propertyId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final String? reviewerName;
  final String? reviewerAvatar;
  final String? reviewerKycStatus;

  ReviewModel({
    required this.id,
    required this.bookingId,
    required this.reviewerId,
    required this.targetId,
    required this.propertyId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.reviewerName,
    this.reviewerAvatar,
    this.reviewerKycStatus,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      id: map['id'],
      bookingId: map['booking_id'],
      reviewerId: map['reviewer_id'],
      targetId: map['target_id'],
      propertyId: map['property_id'],
      rating: map['rating'] ?? 5,
      comment: map['comment'],
      createdAt: DateTime.parse(map['created_at']),
      reviewerName: map['reviewer_name'],
      reviewerAvatar: map['reviewer_avatar'],
      reviewerKycStatus: map['reviewer_kyc_status'],
    );
  }
}
