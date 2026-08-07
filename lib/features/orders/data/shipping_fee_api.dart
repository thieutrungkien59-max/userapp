import 'package:latlong2/latlong.dart';

import '../../../core/network/api_client.dart';
import 'shipping_quote_model.dart';

class ShippingFeeApi {
  const ShippingFeeApi();

  Future<ShippingQuote> calculate({
    required LatLng pickup,
    required LatLng delivery,
  }) async {
    final response = await apiClient.post(
      '/api/DonHang/tinh-phi-van-chuyen',
      data: {
        'viDoLay': pickup.latitude,
        'kinhDoLay': pickup.longitude,
        'viDoGiao': delivery.latitude,
        'kinhDoGiao': delivery.longitude,
      },
    );

    if (response is! Map) {
      throw const FormatException(
        'Backend trả dữ liệu tính phí không hợp lệ.',
      );
    }

    return ShippingQuote.fromJson(
      Map<String, dynamic>.from(response),
    );
  }
}

const shippingFeeApi = ShippingFeeApi();
