import 'package:rawasi_app_n/core/network/api_error.dart';
import 'package:rawasi_app_n/core/network/api_services.dart';
import 'package:rawasi_app_n/features/auth/data/coupon_response.dart';
import 'package:rawasi_app_n/features/auth/data/subscription_plan.dart';

class SubscriptionRepo {
  final ApiServices _api = ApiServices();

  Future<List<SubscriptionPlan>> fetchPlans() async {
    final response = await _api.get('/subscription-plans');

    if (response is ApiError) {
      throw response;
    }

    if (response is Map<String, dynamic>) {
      final data = response['data'] as List?;
      if (data == null) throw Exception('No data in response');

      return data.map((e) => SubscriptionPlan.fromJson(e)).toList();
    }

    throw Exception('Invalid response format');
  }

  Future<CouponResponse> applyCoupon(int planId, String couponCode) async {
    final response = await _api.post('/apply-copoun/$planId', {
      'coupon': couponCode,
    });

    if (response is ApiError) {
      throw response;
    }

    if (response is Map<String, dynamic>) {
      return CouponResponse.fromJson(response);
    }

    throw Exception('Invalid response format');
  }
}
