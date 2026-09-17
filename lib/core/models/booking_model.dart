class BookingModel {
  final String id;
  final String propertyId;
  final String guestId;
  final String ownerId;
  final DateTime checkIn;
  final DateTime checkOut;
  final double totalPrice;
  final double khoznaFee;
  final String? paymentType;
  final String? paymentProofUrl;
  final String? paymentReference;
  final String status; // Legacy status field for backward compatibility
  final String bookingStatus; // 'pending', 'accepted', 'declined', 'confirmed', 'cancelled', 'completed'
  final String paymentStatus; // 'not_required', 'payment_pending', 'payment_submitted', 'payment_confirmed', 'payment_issue'
  final int guestCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? propertyTitle;
  final String? rejectionReason;
  final bool? visitConfirmed;
  final bool? visitLiked;
  final String? feedbackReason;

  BookingModel({
    required this.id,
    required this.propertyId,
    required this.guestId,
    required this.ownerId,
    required this.checkIn,
    required this.checkOut,
    required this.totalPrice,
    required this.khoznaFee,
    this.paymentType,
    this.paymentProofUrl,
    this.paymentReference,
    required this.status,
    String? bookingStatus,
    String? paymentStatus,
    this.guestCount = 1,
    required this.createdAt,
    required this.updatedAt,
    this.propertyTitle,
    this.rejectionReason,
    this.visitConfirmed,
    this.visitLiked,
    this.feedbackReason,
  })  : bookingStatus = bookingStatus ?? _deriveBookingStatus(status),
        paymentStatus = paymentStatus ?? _derivePaymentStatus(status);

  /// Helper getter for formatted Booking ID (e.g. KZ-102914)
  String get formattedBookingId {
    final cleanId = id.replaceAll('-', '').toUpperCase();
    if (cleanId.length >= 6) {
      return 'KZ-${cleanId.substring(0, 6)}';
    }
    return 'KZ-${cleanId.padRight(6, '0')}';
  }

  /// Calculates the number of nights
  int get nights {
    final diff = checkOut.difference(checkIn).inDays;
    return diff > 0 ? diff : 1;
  }

  /// Map raw/legacy status string to normalized booking_status
  static String _deriveBookingStatus(String rawStatus) {
    switch (rawStatus.toLowerCase()) {
      case 'pending':
      case 'pending_approval':
      case 'suggested_time':
        return 'pending';
      case 'accepted':
      case 'visit_accepted':
      case 'awaiting_payment':
      case 'paid':
      case 'payment_submitted':
        return 'accepted';
      case 'confirmed':
        return 'confirmed';
      case 'declined':
      case 'rejected':
      case 'visit_rejected':
        return 'declined';
      case 'cancelled':
      case 'canceled':
      case 'visit_cancelled':
        return 'cancelled';
      case 'completed':
      case 'visit_completed':
        return 'completed';
      default:
        return 'pending';
    }
  }

  /// Map raw/legacy status string to normalized payment_status
  static String _derivePaymentStatus(String rawStatus) {
    switch (rawStatus.toLowerCase()) {
      case 'pending':
      case 'pending_approval':
      case 'suggested_time':
        return 'not_required';
      case 'accepted':
      case 'visit_accepted':
      case 'awaiting_payment':
        return 'payment_pending';
      case 'paid':
      case 'payment_submitted':
        return 'payment_submitted';
      case 'confirmed':
        return 'payment_confirmed';
      case 'payment_issue':
      case 'payment_rejected':
        return 'payment_issue';
      default:
        return 'payment_pending';
    }
  }

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    final rawStatus = map['status'] ?? map['booking_status'] ?? 'pending_approval';
    return BookingModel(
      id: map['id']?.toString() ?? '',
      propertyId: map['property_id']?.toString() ?? '',
      guestId: map['guest_id']?.toString() ?? '',
      ownerId: map['owner_id']?.toString() ?? '',
      checkIn: DateTime.tryParse(map['check_in']?.toString() ?? '') ?? DateTime.now(),
      checkOut: DateTime.tryParse(map['check_out']?.toString() ?? '') ?? DateTime.now().add(const Duration(days: 1)),
      totalPrice: double.tryParse(map['total_price']?.toString() ?? '0') ?? 0,
      khoznaFee: double.tryParse(map['khozna_fee']?.toString() ?? '0') ?? 0,
      paymentType: map['payment_type'],
      paymentProofUrl: map['payment_proof_url'],
      paymentReference: map['payment_reference'] ?? map['reference_id'],
      status: rawStatus,
      bookingStatus: map['booking_status'] ?? _deriveBookingStatus(rawStatus),
      paymentStatus: map['payment_status'] ?? _derivePaymentStatus(rawStatus),
      guestCount: int.tryParse(map['guests']?.toString() ?? map['guest_count']?.toString() ?? '1') ?? 1,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
      propertyTitle: map['property_title'],
      rejectionReason: map['rejection_reason'],
      visitConfirmed: map['visit_confirmed'],
      visitLiked: map['visit_liked'],
      feedbackReason: map['feedback_reason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'property_id': propertyId,
      'guest_id': guestId,
      'owner_id': ownerId,
      'check_in': checkIn.toIso8601String(),
      'check_out': checkOut.toIso8601String(),
      'total_price': totalPrice,
      'khozna_fee': khoznaFee,
      'payment_type': paymentType,
      'payment_proof_url': paymentProofUrl,
      'payment_reference': paymentReference,
      'status': status,
      'booking_status': bookingStatus,
      'payment_status': paymentStatus,
      'guests': guestCount,
    };
  }

  BookingModel copyWith({
    String? id,
    String? propertyId,
    String? guestId,
    String? ownerId,
    DateTime? checkIn,
    DateTime? checkOut,
    double? totalPrice,
    double? khoznaFee,
    String? paymentType,
    String? paymentProofUrl,
    String? paymentReference,
    String? status,
    String? bookingStatus,
    String? paymentStatus,
    int? guestCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? propertyTitle,
    String? rejectionReason,
    bool? visitConfirmed,
    bool? visitLiked,
    String? feedbackReason,
  }) {
    return BookingModel(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      guestId: guestId ?? this.guestId,
      ownerId: ownerId ?? this.ownerId,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      totalPrice: totalPrice ?? this.totalPrice,
      khoznaFee: khoznaFee ?? this.khoznaFee,
      paymentType: paymentType ?? this.paymentType,
      paymentProofUrl: paymentProofUrl ?? this.paymentProofUrl,
      paymentReference: paymentReference ?? this.paymentReference,
      status: status ?? this.status,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      guestCount: guestCount ?? this.guestCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      propertyTitle: propertyTitle ?? this.propertyTitle,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      visitConfirmed: visitConfirmed ?? this.visitConfirmed,
      visitLiked: visitLiked ?? this.visitLiked,
      feedbackReason: feedbackReason ?? this.feedbackReason,
    );
  }
}

