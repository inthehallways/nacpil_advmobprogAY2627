import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/product.dart';
import '../services/cart_service.dart';
import '../widgets/custom_text.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final CartService _cartService = CartService();
  bool _isAddingToCart = false;

  Future<void> _addToCart() async {
    setState(() {
      _isAddingToCart = true;
    });

    try {
      // enhancement 3: adds the current product to a user cart through the Cart API.
      await _cartService.addToCart(
        userId: 5,
        productId: widget.product.id,
        quantity: 1,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.product.title} added to cart')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to add to cart: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAddingToCart = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final greenAccent = isDark ? Colors.green.shade300 : Colors.green.shade700;
    final greenContainer =
        isDark ? Colors.green.shade900 : Colors.green.shade50;
    final greenBorder =
        isDark ? Colors.green.shade700 : Colors.green.shade100;
    final reviewCount = product.reviews.length;
    final originalPrice = product.discountPercentage > 0
        ? product.price / (1 - (product.discountPercentage / 100))
        : product.price;

    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: product.title,
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // enhancement 2: made a product details page design for when a specific product card is clicked
            Image.network(
              product.thumbnail,
              width: double.infinity,
              height: 250.h,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Icon(Icons.image, size: 60.sp),
            ),
            SizedBox(height: 16.h),
            CustomText(
              text: product.title,
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
            ),
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999.r),
              ),
              child: CustomText(
                text: product.category.toUpperCase(),
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: greenAccent,
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  '\$${originalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.sp,
                    decoration: TextDecoration.lineThrough,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(width: 10.w),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: greenContainer,
                    border: Border.all(color: greenBorder),
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                  child: CustomText(
                    text:
                        '${product.discountPercentage.toStringAsFixed(1)}% OFF',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 18.h),
            // product metrics with rating context, stock, and discount
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: greenContainer,
                border: Border.all(color: greenBorder),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.star, size: 18.sp, color: greenAccent),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: CustomText(
                      text: '${product.rating} ($reviewCount reviews)',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Container(
                    width: 1,
                    height: 22.h,
                    color: greenBorder,
                  ),
                  SizedBox(width: 10.w),
                  Icon(
                    Icons.inventory_2,
                    size: 18.sp,
                    color: greenAccent,
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: CustomText(
                      text: '${product.stock} available',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            _SectionTitle(text: 'Description'),
            SizedBox(height: 8.h),
            CustomText(
              text: product.description,
              fontSize: 14.sp,
            ),
            SizedBox(height: 24.h),
            _DetailTile(
              icon: Icons.verified,
              title: 'Warranty',
              value: product.warrantyInformation,
            ),
            _DetailTile(
              icon: Icons.local_shipping,
              title: 'Shipping',
              value: product.shippingInformation,
            ),
            _DetailTile(
              icon: Icons.assignment_return,
              title: 'Return Policy',
              value: product.returnPolicy,
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isAddingToCart ? null : _addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: greenAccent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: greenContainer,
                  disabledForegroundColor: greenAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                icon: _isAddingToCart
                    ? SizedBox(
                        width: 18.r,
                        height: 18.r,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: greenAccent,
                        ),
                      )
                    : Icon(Icons.add_shopping_cart, size: 20.sp),
                label: CustomText(
                  text: _isAddingToCart ? 'Adding...' : 'Add to Cart',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: _isAddingToCart ? greenAccent : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return CustomText(
      text: text,
      fontSize: 18.sp,
      fontWeight: FontWeight.bold,
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DetailTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final greenAccent = isDark ? Colors.green.shade300 : Colors.green.shade700;
    final greenContainer =
        isDark ? Colors.green.shade900 : Colors.green.shade50;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: greenContainer,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 20.sp, color: greenAccent),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: title,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                ),
                SizedBox(height: 2.h),
                CustomText(
                  text: value.isEmpty ? 'Not available' : value,
                  fontSize: 12.sp,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
