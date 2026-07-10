class CouponResponse {
  final bool success;
  final CouponData? data;
  final String? message;

  CouponResponse({required this.success, this.data, this.message});

  factory CouponResponse.fromJson(Map<String, dynamic> json) {
    return CouponResponse(
      success: json['success'] ?? false,
      data: json['data'] != null ? CouponData.fromJson(json['data']) : null,
      message: json['message'],
    );
  }
}

class CouponData {
  final PlanDiscount plan;
  final String couponCode;
  final bool applied;

  CouponData({
    required this.plan,
    required this.couponCode,
    required this.applied,
  });

  factory CouponData.fromJson(Map<String, dynamic> json) {
    return CouponData(
      plan: PlanDiscount.fromJson(json['plan']),
      couponCode: json['coupon_code'] ?? '',
      applied: json['applied'] ?? false,
    );
  }
}

class PlanDiscount {
  final int id;
  final String name;
  final String description;
  final double originalPrice;
  final double discountPercentage;
  final double discountAmount;
  final double finalPrice;
  final String periodType;
  final int periodValue;

  PlanDiscount({
    required this.id,
    required this.name,
    required this.description,
    required this.originalPrice,
    required this.discountPercentage,
    required this.discountAmount,
    required this.finalPrice,
    required this.periodType,
    required this.periodValue,
  });

  factory PlanDiscount.fromJson(Map<String, dynamic> json) {
    return PlanDiscount(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      originalPrice: (json['original_price'] ?? 0).toDouble(),
      discountPercentage: (json['discount_percentage'] ?? 0).toDouble(),
      discountAmount: (json['discount_amount'] ?? 0).toDouble(),
      finalPrice: (json['final_price'] ?? 0).toDouble(),
      periodType: json['period_type'] ?? '',
      periodValue: json['period_value'] ?? 0,
    );
  }
}
