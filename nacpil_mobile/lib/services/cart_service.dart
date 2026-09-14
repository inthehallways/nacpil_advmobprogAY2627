import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/cart.dart';

class CartService {
  Future<List<Cart>> getAllCarts() async {
    try {
      final response = await http.get(Uri.parse('$host/carts'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List cartsJson = data['carts'] ?? [];
        return cartsJson.map((json) => Cart.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (_) {
      return [];
    }
  }

  Future<Cart?> getCartByUserId(int userId) async {
    try {
      // 1. Try to fetch cart for the specific user ID
      if (userId > 0) {
        final response = await http.get(Uri.parse('$host/carts/user/$userId'));

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          final List cartsJson = data['carts'] ?? [];

          if (cartsJson.isNotEmpty) {
            return Cart.fromJson(cartsJson.first);
          }
        }
      }

      // 2. Fallback: If user has no pre-existing cart on DummyJSON (e.g. Firebase Auth user), load default cart #1
      final fallbackResponse = await http.get(Uri.parse('$host/carts/1'));
      if (fallbackResponse.statusCode == 200) {
        final Map<String, dynamic> fallbackData = jsonDecode(fallbackResponse.body);
        return Cart.fromJson(fallbackData);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Cart> addToCart({
    required int userId,
    required int productId,
    int quantity = 1,
  }) async {
    final response = await http.post(
      Uri.parse('$host/carts/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'products': [
          {
            'id': productId,
            'quantity': quantity,
          },
        ],
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return Cart.fromJson(data);
    } else {
      throw Exception('Failed to add product to cart');
    }
  }
}
