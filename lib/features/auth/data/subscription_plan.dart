class SubscriptionPlan {
  final int id;
  final String name;
  final String description;
  final double price;
  final double? originalPrice;
  final String periodType;
  final int periodValue;
  final String? badge;
  final String? badgeColor;
  final bool isFeatured;
  final bool hasDiscount;
  final List<PlanFeature> features;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.periodType,
    required this.periodValue,
    this.badge,
    this.badgeColor,
    required this.isFeatured,
    required this.hasDiscount,
    required this.features,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    final featuresList = json['features'] as List?;
    final features =
        featuresList?.map((e) => PlanFeature.fromJson(e)).toList() ?? [];

    return SubscriptionPlan(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      originalPrice: json['original_price'] != null
          ? (json['original_price'] as num).toDouble()
          : null,
      periodType: json['period_type'] ?? '',
      periodValue: json['period_value'] ?? 0,
      badge: json['badge'],
      badgeColor: json['badge_color'],
      isFeatured: json['is_featured'] ?? false,
      hasDiscount: json['has_discount'] ?? false,
      features: features,
    );
  }

  String getDisplayPrice() {
    if (originalPrice != null && originalPrice! > price) {
      return '${price.toInt()} ج.م بدلاً من ${originalPrice!.toInt()} ج.م';
    }
    return '${price.toInt()} ج.م';
  }

  String getDurationText() {
    if (periodType == 'month') {
      return periodValue == 1 ? 'شهر واحد' : '$periodValue أشهر';
    }
    return '';
  }
}

class PlanFeature {
  final int id;
  final String featureText;
  final bool isIncluded;

  PlanFeature({
    required this.id,
    required this.featureText,
    required this.isIncluded,
  });

  factory PlanFeature.fromJson(Map<String, dynamic> json) {
    return PlanFeature(
      id: json['id'] ?? 0,
      featureText: json['feature_text'] ?? '',
      isIncluded: json['is_included'] ?? false,
    );
  }
}
