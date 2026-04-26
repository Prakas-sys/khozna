class BookingModel {
  final String id;
  final String propertyId;
  final String guestId;
  final String ownerId;
  final String propertyTitle;
  final DateTime moveInDate;
  final int durationMonths;
  final int guestsCount;
  final String purpose;
  final String message;
  final String status;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final String? rejectReason;

  BookingModel({
    required this.id,
    required this.propertyId,
    required this.guestId,
    required this.ownerId,
    required this.propertyTitle,
    required this.moveInDate,
    required this.durationMonths,
    required this.guestsCount,
    required this.purpose,
    required this.message,
    required this.status,
    required this.createdAt,
    this.confirmedAt,
    this.rejectReason,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id'],
      propertyId: map['property_id'],
      guestId: map['guest_id'],
      ownerId: map['owner_id'],
      propertyTitle: map['property_title'] ?? '',
      moveInDate: DateTime.parse(map['move_in_date']),
      durationMonths: map['duration_months'] ?? 1,
      guestsCount: map['guests_count'] ?? 1,
      purpose: map['purpose'] ?? 'other',
      message: map['message'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: DateTime.parse(map['created_at']),
      confirmedAt: map['confirmed_at'] != null ? DateTime.parse(map['confirmed_at']) : null,
      rejectReason: map['reject_reason'],
    );
  }
}
