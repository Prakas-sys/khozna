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
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? propertyTitle;

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
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.propertyTitle,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id'],
      propertyId: map['property_id'],
      guestId: map['guest_id'],
      ownerId: map['owner_id'],
      checkIn: DateTime.parse(map['check_in']),
      checkOut: DateTime.parse(map['check_out']),
      totalPrice: double.tryParse(map['total_price']?.toString() ?? '0') ?? 0,
      khoznaFee: double.tryParse(map['khozna_fee']?.toString() ?? '0') ?? 0,
      paymentType: map['payment_type'],
      status: map['status'] ?? 'pending_approval',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      propertyTitle: map['property_title'],
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
      'status': status,
    };
  }
}
