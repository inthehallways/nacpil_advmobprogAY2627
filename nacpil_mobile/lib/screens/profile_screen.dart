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

  late Future<_ProfileData> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfileData();
  }

  // enhancement 3: profile renders the saved user model and loads cart by user id.
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

  void _showUpdateUsernameDialog(User user) {
    final controller = TextEditingController(text: user.username);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: CustomText(
          text: 'Update Username',
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'New Username',
              border: OutlineInputBorder(),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Username cannot be empty';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final newUsername = controller.text.trim();
              Navigator.pop(dialogCtx);

              final messenger = ScaffoldMessenger.of(context);

              try {
                await _userService.updateUsername(username: newUsername);
                if (!mounted) return;
                setState(() {
                  _profileFuture = _loadProfileData();
                });
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Username updated successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed to update username: $e'),
                    backgroundColor: const Color(0xFFE64B3C),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(User user) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureCurrent = true;
    bool obscureNew = true;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: CustomText(
            text: 'Change Password',
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentPasswordController,
                    obscureText: obscureCurrent,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureCurrent
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setDialogState(
                          () => obscureCurrent = !obscureCurrent,
                        ),
                      ),
                    ),
                    validator: (val) => (val == null || val.isEmpty)
                        ? 'Enter current password'
                        : null,
                  ),
                  SizedBox(height: 12.h),
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNew
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setDialogState(
                          () => obscureNew = !obscureNew,
                        ),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 12.h),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: obscureNew,
                    decoration: const InputDecoration(
                      labelText: 'Confirm New Password',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val != newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final currentPass = currentPasswordController.text;
                final newPass = newPasswordController.text;
                Navigator.pop(dialogCtx);

                final messenger = ScaffoldMessenger.of(context);

                try {
                  await _userService.resetPasswordFromCurrentPassword(
                    currentPassword: currentPass,
                    newPassword: newPass,
                    email: user.email,
                  );
                  if (!mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Password changed successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to change password: $e'),
                      backgroundColor: const Color(0xFFE64B3C),
                    ),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(User user) {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscure = true;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: CustomText(
            text: 'Delete Account',
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFF5B4D),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text:
                      'This action is permanent and cannot be undone. Please enter your password to confirm.',
                  fontSize: 12.sp,
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: passwordController,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setDialogState(() => obscure = !obscure),
                    ),
                  ),
                  validator: (val) => (val == null || val.isEmpty)
                      ? 'Enter your password to confirm'
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF5B4D),
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final password = passwordController.text;
                Navigator.pop(dialogCtx);

                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);

                try {
                  await _userService.deleteAccount(
                    email: user.email,
                    password: password,
                  );
                  if (!mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Account deleted successfully.'),
                      backgroundColor: Colors.black87,
                    ),
                  );
                  navigator.pushNamedAndRemoveUntil(
                    '/signin',
                    (route) => false,
                  );
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete account: $e'),
                      backgroundColor: const Color(0xFFE64B3C),
                    ),
                  );
                }
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
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
                    if (user.loginType == 'firebase') ...[
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFECE5),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomText(
                              text: 'Firebase Auth',
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFE65100),
                            ),
                          ],
                        ),
                      ),
                    ],
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
              if (user.loginType == 'firebase') ...[
                SizedBox(height: 16.h),
                _ActionPanel(
                  children: [
                    _ActionRow(
                      icon: Icons.edit_outlined,
                      label: 'Update Username',
                      iconColor: colorScheme.primary,
                      onTap: () => _showUpdateUsernameDialog(user),
                    ),
                    const Divider(height: 1, indent: 14, endIndent: 14),
                    _ActionRow(
                      icon: Icons.restore,
                      label: 'Change Password',
                      iconColor: colorScheme.primary,
                      onTap: () => _showChangePasswordDialog(user),
                    ),
                    const Divider(height: 1, indent: 14, endIndent: 14),
                    _ActionRow(
                      icon: Icons.delete_outline,
                      label: 'Delete Account',
                      textColor: const Color(0xFFFF5B4D),
                      iconColor: const Color(0xFFFF5B4D),
                      showChevron: false,
                      onTap: () => _showDeleteAccountDialog(user),
                    ),
                  ],
                ),
              ],
              if (user.loginType != 'firebase') ...[
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

class _ActionPanel extends StatelessWidget {
  final List<Widget> children;

  const _ActionPanel({required this.children});

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

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;
  final bool showChevron;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.textColor,
    this.iconColor,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20.sp,
              color: effectiveIconColor,
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: CustomText(
                text: label,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            if (showChevron)
              Icon(
                Icons.arrow_forward_ios,
                size: 14.sp,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
          ],
        ),
      ),
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
