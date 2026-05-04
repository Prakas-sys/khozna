class PaymentModel {
  final String id;
  final String bookingId;
  final String payerId;
  final double amount;
  final String paymentMethod;
  final String? referenceId;
  final String? proofImageUrl;
  final String status;
  final DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.bookingId,
    required this.payerId,
    required this.amount,
    required this.paymentMethod,
    this.referenceId,
    this.proofImageUrl,
    required this.status,
    required this.createdAt,
  });

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'],
      bookingId: map['booking_id'],
      payerId: map['payer_id'],
      amount: double.tryParse(map['amount']?.toString() ?? '0') ?? 0,
      paymentMethod: map['payment_method'],
      referenceId: map['reference_id'],
      proofImageUrl: map['proof_image_url'],
      status: map['status'] ?? 'pending',
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
