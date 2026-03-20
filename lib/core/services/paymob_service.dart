import 'package:dio/dio.dart';

class PaymobService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://accept.paymob.com/api',
      headers: {'Content-Type': 'application/json'},
    ),
  );

  final String _apiKey = "ZXlKaGJHY2lPaUpJVXpVeE1pSXNJblI1Y0NJNklrcFhWQ0o5LmV5SmpiR0Z6Y3lJNklrMWxjbU5vWVc1MElpd2ljSEp2Wm1sc1pWOXdheUk2TVRFME1ESTFOeXdpYm1GdFpTSTZJbWx1YVhScFlXd2lmUS5LR2R5VFlpX0JNeWFFNmRmdzFCazRhWWFXeXZCQzg5TVpkU2JKVXpqLWZJQzRhMjB5cWk5bXlKNzJENVgtYUl4SVM4MjJhQ2NUVFUyWkZZYTVBdkljZw==";

  /// Step 1: Get Authentication Token
  Future<String> getAuthToken() async {
    try {
      final response = await _dio.post(
        '/auth/tokens',
        data: {'api_key': _apiKey},
      );
      final token = response.data['token'] as String;
      print('DEBUG: Auth Token received: ${token.substring(0, 10)}...${token.substring(token.length - 10)}');
      return token;
    } catch (e) {
      throw Exception('Failed to get Paymob auth token: $e');
    }
  }

  /// Step 2: Register Order
  Future<int> registerOrder({
    required String authToken,
    required double amount,
  }) async {
    try {
      final response = await _dio.post(
        '/ecommerce/orders',
        options: Options(
          headers: {'Authorization': 'Bearer $authToken'},
        ),
        data: {
          'auth_token': authToken,
          'delivery_needed': 'false',
          'amount_cents': (amount * 100).round(),
          'currency': 'EGP',
          'items': [],
        },
      );
      print('DEBUG: Register Order Response: ${response.data}');
      return response.data['id'];
    } catch (e) {
      throw Exception('Failed to register Paymob order: $e');
    }
  }

  /// Step 3: Get Payment Key
  Future<String> getPaymentKey({
    required String authToken,
    required int orderId,
    required double amount,
    required int integrationId,
    required Map<String, String> billingData,
  }) async {
    try {
      final int amountCents = (amount * 100).round();
      
      final response = await _dio.post(
        '/acceptance/payment_keys',
        options: Options(
          headers: {'Authorization': 'Bearer $authToken'},
        ),
        data: {
          'auth_token': authToken,
          'amount_cents': amountCents,
          'expiration': 3600,
          'order_id': orderId,
          'billing_data': {
            'apartment': (billingData['apartment']?.isNotEmpty == true) ? billingData['apartment']! : 'NA',
            'email': (billingData['email']?.isNotEmpty == true) ? billingData['email']! : 'NA',
            'floor': (billingData['floor']?.isNotEmpty == true) ? billingData['floor']! : 'NA',
            'first_name': (billingData['first_name']?.isNotEmpty == true) ? billingData['first_name']! : 'NA',
            'street': (billingData['street']?.isNotEmpty == true) ? billingData['street']! : 'NA',
            'building': (billingData['building']?.isNotEmpty == true) ? billingData['building']! : 'NA',
            'phone_number': (billingData['phone_number']?.isNotEmpty == true) ? billingData['phone_number']! : 'NA',
            'shipping_method': 'NA',
            'postal_code': 'NA',
            'city': 'NA',
            'country': 'NA',
            'last_name': (billingData['last_name']?.isNotEmpty == true) ? billingData['last_name']! : 'NA',
            'state': 'NA',
          },
          'currency': 'EGP',
          'integration_id': integrationId,
        },
      );
      print('DEBUG: Get Payment Key Response Success!');
      return response.data['token'];
    } catch (e) {
      throw Exception('Failed to get Paymob payment key: $e');
    }
  }
  /// Step 4: Initiate Payment (Mandatory for Wallets via POST)
  Future<String> initiatePayment({
    required String paymentToken,
    String? phone,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'payment_token': paymentToken,
        'source': {
          'identifier': '01010101010', // Forced Test Number for Wallet integration
          'subtype': 'WALLET',
        },
      };
      
      print('DEBUG: Sending Initiate Payment Request Body: $data');

      final response = await _dio.post(
        '/acceptance/payments/pay',
        // Some accounts require authorization even for this step
        options: Options(
          validateStatus: (status) => true, // Log everything even errors
        ),
        data: data,
      );

      print('DEBUG: Initiate Payment Full Response: ${response.data}');

      // Return the redirection URL (common keys in Paymob response)
      return response.data['redirect_url'] ??
          response.data['iframe_redirection_url'] ??
          response.data['url'] ??
          (response.data['data'] != null ? response.data['data']['url'] : null) ??
          '';
    } catch (e) {
      throw Exception('Failed to initiate payment: $e');
    }
  }
}
