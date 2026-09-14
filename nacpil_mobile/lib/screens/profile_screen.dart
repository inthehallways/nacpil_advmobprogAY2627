import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/cart.dart';
import '../models/user.dart';
import '../services/cart_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final CartService _cartService = CartService();

  late final Future<_ProfileData> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfileData();
  }

  // enhancement 3: profile renders the saved User model and loads cart by user id.
  Future<_ProfileData> _loadProfileData() async {
    final user = await _userService.getUser();
    Cart? cart;
    try {
      cart = user.id == 0 ? null : await _cartService.getCartByUserId(user.id);
    } catch (_) {
      cart = null;
    }

    return _ProfileData(user: user, cart: cart);
  }

  Future<void> _logout() async {
    await _userService.logout();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: FutureBuilder<_ProfileData>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(20.r),
                child: CustomText(
                  text: 'Unable to load profile: ${snapshot.error}',
                  fontSize: 14.sp,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data = snapshot.data;
          final user = data?.user;

          if (user == null || user.id == 0) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(20.r),
                child: CustomText(
                  text: 'No saved user data found.',
                  fontSize: 14.sp,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final fullName = '${user.firstName} ${user.lastName}'.trim();
          final displayName = fullName.isEmpty ? user.username : fullName;

          return ListView(
            padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 24.h),
            children: [
              Container(
                padding: EdgeInsets.all(22.r),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(8.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 46.r,
                      backgroundColor: colorScheme.primaryContainer,
                      backgroundImage:
                          user.image.isEmpty ? null : NetworkImage(user.image),
                      child: user.image.isEmpty
                          ? Icon(
                              Icons.person,
                              size: 46.sp,
                              color: colorScheme.primary,
                            )
                          : null,
                    ),
                    SizedBox(height: 16.h),
                    CustomText(
                      text: displayName,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4.h),
                    CustomText(
                      text: '@${user.username}',
                      fontSize: 12.sp,
                      color: colorScheme.primary,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              _InfoPanel(
                children: [
                  _InfoRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: user.email,
                  ),
                  _InfoRow(
                    icon: Icons.person_outline,
                    label: 'Gender',
                    value: user.gender,
                  ),
                  _InfoRow(
                    icon: Icons.badge_outlined,
                    label: 'User ID',
                    value: '#${user.id}',
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              _CartSummary(cart: data?.cart),
              SizedBox(height: 20.h),
              SizedBox(
                height: 52.h,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5B4D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  onPressed: _logout,
                  icon: Icon(Icons.logout, size: 18.sp),
                  label: CustomText(
                    text: 'Log Out',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileData {
  final User user;
  final Cart? cart;

  const _ProfileData({
    required this.user,
    required this.cart,
  });
}

class _InfoPanel extends StatelessWidget {
  final List<Widget> children;

  const _InfoPanel({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20.sp,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: CustomText(
              text: label,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          Flexible(
            child: CustomText(
              text: value.isEmpty ? 'Not available' : value,
              fontSize: 11.sp,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final Cart? cart;

  const _CartSummary({required this.cart});

  @override
  Widget build(BuildContext context) {
    final currentCart = cart;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46.r,
            height: 46.r,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 24.sp,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: 'My Cart',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
                SizedBox(height: 4.h),
                CustomText(
                  text: currentCart == null
                      ? 'No cart found for this user'
                      : '${currentCart.totalProducts} products | ${currentCart.totalQuantity} items',
                  fontSize: 11.sp,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          CustomText(
            text: currentCart == null
                ? '\$0.00'
                : '\$${currentCart.discountedTotal.toStringAsFixed(2)}',
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
