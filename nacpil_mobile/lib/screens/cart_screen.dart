import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// models
import '../models/cart.dart';

// screens
import 'product_detail_screen.dart';

// services
import '../services/cart_service.dart';
import '../services/product_service.dart';
import '../services/user_service.dart';

// widgets
import '../widgets/custom_text.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late final Future<Cart?> _cartFuture;
  final CartService _cartService = CartService();
  final ProductService _productService = ProductService();
  final UserService _userService = UserService();
  final Map<int, int> _quantities = {};

  @override
  void initState() {
    super.initState();
    // enhancement 3: cart is rendered from the saved authenticated user's id
    _cartFuture = _getSavedUserCart();
  }

  Future<Cart?> _getSavedUserCart() async {
    final userData = await _userService.getUserData();
    final userId = userData['id'] as int? ?? 0;

    if (userId == 0) {
      return null;
    }

    return _cartService.getCartByUserId(userId);
  }

  Future<void> _openProductDetail(CartProduct cartProduct) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final product = await _productService.getProductById(cartProduct.id);

      if (!mounted) {
        return;
      }

      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailScreen(product: product),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load product: $error')),
      );
    }
  }

  int _quantityFor(CartProduct product) {
    return _quantities[product.id] ?? product.quantity;
  }

  void _increaseQuantity(CartProduct product) {
    setState(() {
      _quantities[product.id] = _quantityFor(product) + 1;
    });
  }

  void _decreaseQuantity(CartProduct product) {
    final quantity = _quantityFor(product);

    if (quantity <= 1) {
      return;
    }

    setState(() {
      _quantities[product.id] = quantity - 1;
    });
  }

  double _cartSubtotal(List<CartProduct> products) {
    return products.fold(0.0, (total, product) {
      return total + (product.price * _quantityFor(product));
    });
  }

  double _cartDiscount(List<CartProduct> products) {
    return products.fold(0.0, (total, product) {
      final originalTotal = product.price * _quantityFor(product);
      final discountedTotal = _discountedTotalFor(product);
      return total + (originalTotal - discountedTotal);
    });
  }

  double _discountedUnitPriceFor(CartProduct product) {
    return product.price * (1 - (product.discountPercentage / 100));
  }

  double _discountedTotalFor(CartProduct product) {
    return _discountedUnitPriceFor(product) * _quantityFor(product);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final greenAccent = isDark ? Colors.green.shade300 : Colors.green.shade700;
    // final greenContainer = isDark ? Colors.green.shade900 : Colors.green.shade50;

    return SafeArea(
      child: FutureBuilder<Cart?>(
        future: _cartFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(32.r),
                child: const CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(16.r),
                child: CustomText(
                  text: 'Error: ${snapshot.error}',
                  fontSize: 14.sp,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final cart = snapshot.data;
          final products = cart?.products ?? [];

          if (products.isEmpty) {
            return Center(
              child: CustomText(
                text: 'No cart found.',
                fontSize: 14.sp,
              ),
            );
          }

          final subtotal = _cartSubtotal(products);
          final discount = _cartDiscount(products);
          final total = subtotal - discount;

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(12.w, 16.h, 12.w, 8.h),
                  itemCount: products.length,
                  separatorBuilder: (_, _) => SizedBox(height: 10.h),
                  itemBuilder: (context, index) {
                    final product = products[index];

                    return _CartProductTile(
                      product: product,
                      quantity: _quantityFor(product),
                      onTap: () => _openProductDetail(product),
                      onIncrease: () => _increaseQuantity(product),
                      onDecrease: () => _decreaseQuantity(product),
                    );
                  },
                ),
              ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _SummaryRow(
                      label: 'Subtotal:',
                      value: '\$${subtotal.toStringAsFixed(2)}',
                      valueColor: greenAccent,
                    ),
                    SizedBox(height: 8.h),
                    _SummaryRow(
                      label: 'Discount:',
                      value: '-\$${discount.toStringAsFixed(2)}',
                      valueColor: greenAccent,
                    ),
                    SizedBox(height: 8.h),
                    _SummaryRow(
                      label: 'Total:',
                      value: '\$${total.toStringAsFixed(2)}',
                      valueColor: greenAccent,
                      isBold: true,
                    ),
                    SizedBox(height: 12.h),
                    SizedBox(
                      width: double.infinity,
                      height: 48.h,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Order confirmed'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: greenAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                        child: CustomText(
                          text: 'Confirm Order',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CartProductTile extends StatelessWidget {
  final CartProduct product;
  final int quantity;
  final VoidCallback onTap;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const _CartProductTile({
    required this.product,
    required this.quantity,
    required this.onTap,
    required this.onIncrease,
    required this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final greenAccent = isDark ? Colors.green.shade300 : Colors.green.shade700;
    final greenContainer = isDark ? Colors.green.shade900 : Colors.green.shade50;
    final total = product.price * quantity;

    return Card(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        // enhancement 1: cart items are clickable and reuse the product detail screen.
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(10.r),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: Image.network(
                  product.thumbnail,
                  width: 72.r,
                  height: 72.r,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Container(
                    width: 72.r,
                    height: 72.r,
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(Icons.image, size: 28.sp),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: product.title,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    CustomText(
                      text: '\$${product.price.toStringAsFixed(2)}',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    CustomText(
                      text:
                          '${product.discountPercentage.toStringAsFixed(0)}% off | \$${total.toStringAsFixed(2)} total',
                      fontSize: 10.sp,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Column(
                children: [
                  _QuantityButton(
                    icon: Icons.add,
                    backgroundColor: greenAccent,
                    iconColor: greenContainer,
                    onTap: onIncrease,
                  ),
                  SizedBox(height: 6.h),
                  CustomText(
                    text: '$quantity',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 6.h),
                  _QuantityButton(
                    icon: Icons.remove,
                    backgroundColor: greenContainer,
                    iconColor: greenAccent,
                    onTap: onDecrease,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuantityButton({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        width: 28.r,
        height: 28.r,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(icon, size: 16.sp, color: iconColor),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(
          text: label,
          fontSize: 12.sp,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
        CustomText(
          text: value,
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          textAlign: TextAlign.right,
          color: valueColor,
        ),
      ],
    );
  }
}
