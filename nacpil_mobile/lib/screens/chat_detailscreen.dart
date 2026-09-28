import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nacpil_mobile/widgets/custom_text.dart';

import '../services/chat_service.dart';
import '../services/user_service.dart';

final ChatService chatService = ChatService();

class ChatDetailScreen extends StatefulWidget {
  final String currentUserEmail;
  final Map<String, dynamic> tappedUser;

  const ChatDetailScreen({
    super.key,
    required this.currentUserEmail,
    required this.tappedUser,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final FocusNode _msgFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();

  late Future<String> _currentUserIdFuture;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _currentUserIdFuture = _getCurrentUserId();
  }

  Future<String> _getCurrentUserId() async {
    final userData = await userService.value.getUserData();
    return (userData['uid'] ?? userService.value.currentUser?.uid ?? '').toString();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _msgFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // lab act 6 enhancement 3: handle message sending cleanly without duplicating bubbles
  Future<void> _send(String currentUserId, String receiverId) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    _msgCtrl.clear();

    try {
      await chatService.sendMessage(receiverId, text);

      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          0.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  // helper to format firestore timestamp to readable time string
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return _formatDateTime(DateTime.now());
    DateTime dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dt = timestamp;
    } else {
      return '';
    }
    return _formatDateTime(dt);
  }

  String _formatDateTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final tappedUserId = (widget.tappedUser['uid'] ?? '').toString();
    final fName = (widget.tappedUser['firstName'] ?? '').toString().trim();
    final lName = (widget.tappedUser['lastName'] ?? '').toString().trim();
    final fullName = '$fName $lName'.trim();
    final tappedUserName = fullName.isNotEmpty
        ? fullName
        : ((widget.tappedUser['username'] ?? widget.tappedUser['email'] ?? 'Chat').toString());
    final userEmail = (widget.tappedUser['email'] ?? '').toString();
    final initial = fName.isNotEmpty
        ? fName[0].toUpperCase()
        : (tappedUserName.isNotEmpty ? tappedUserName[0].toUpperCase() : '?');

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<String>(
      future: _currentUserIdFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError || !snap.hasData || snap.data!.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('Error loading user data')),
          );
        }

        final currentUserId = snap.data!;

        return Scaffold(
          // lab act 6 enhancement 3: updated app bar with user avatar and detail info
          appBar: AppBar(
            elevation: 1,
            titleSpacing: 0,
            title: Row(
              children: [
                CircleAvatar(
                  radius: 19.r,
                  backgroundColor: Colors.white24,
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tappedUserName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        userEmail.isNotEmpty ? userEmail : 'Online',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11.sp,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // messages list
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: chatService.getMessage(currentUserId, tappedUserId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !_isSending) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error loading messages: ${snapshot.error}'),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 48.sp,
                              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                            ),
                            SizedBox(height: 12.h),
                            CustomText(
                              text: 'Say hello to $tappedUserName!',
                              fontSize: 15.sp,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollCtrl,
                      reverse: true,
                      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final msgTxt = (data['message'] ?? '').toString();
                        final senderId = (data['senderId'] ?? '').toString();
                        final isMe = senderId == currentUserId;
                        final timestamp = data['timestamp'];
                        final timeString = _formatTimestamp(timestamp);

                        // lab act 6 enhancement 3: check if firestore document is still uploading (hasPendingWrites)
                        final isPending = doc.metadata.hasPendingWrites;
                        final status = isPending ? 'sending' : (data['status'] ?? 'delivered').toString();

                        return _buildAnimatedBubble(
                          key: ValueKey(doc.id),
                          context: context,
                          message: msgTxt,
                          isMe: isMe,
                          timeString: timeString,
                          status: status,
                          isDark: isDark,
                        );
                      },
                    );
                  },
                ),
              ),

              // lab act 6 enhancement 3: composer with pill shape and send states
              _buildComposer(context, currentUserId, tappedUserId, isDark),
            ],
          ),
        );
      },
    );
  }

  // lab act 6 enhancement 3: animated message bubble with fade and slide transition
  Widget _buildAnimatedBubble({
    required Key key,
    required BuildContext context,
    required String message,
    required bool isMe,
    required String timeString,
    required String status,
    required bool isDark,
  }) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return TweenAnimationBuilder<double>(
      key: key,
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return Opacity(
          opacity: animValue,
          child: Transform.translate(
            offset: Offset(0, 14 * (1.0 - animValue)),
            child: child,
          ),
        );
      },
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(
            top: 4.h,
            bottom: 4.h,
            left: isMe ? 50.w : 6.w,
            right: isMe ? 6.w : 50.w,
          ),
          padding: EdgeInsets.symmetric(vertical: 9.h, horizontal: 13.w),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          // lab act 6 enhancement 3: improved bubble design for clear sender/receiver distinction
          decoration: BoxDecoration(
            color: isMe
                ? primaryColor
                : (isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
              bottomLeft: isMe ? Radius.circular(16.r) : Radius.circular(3.r),
              bottomRight: isMe ? Radius.circular(3.r) : Radius.circular(16.r),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // message body
              Text(
                message.isNotEmpty ? message : '[empty]',
                style: TextStyle(
                  fontSize: 14.5.sp,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.normal,
                  color: isMe
                      ? Colors.white
                      : (isDark ? Colors.white : Colors.black87),
                  height: 1.25,
                ),
              ),
              SizedBox(height: 4.h),

              // timestamp and sending states
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeString,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontFamily: 'Poppins',
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.75)
                          : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                  ),
                  if (isMe) ...[
                    SizedBox(width: 4.w),
                    // lab act 6 enhancement 3: sending states ("sending...", checkmarks for delivered/seen)
                    if (status == 'sending') ...[
                      SizedBox(
                        width: 10.r,
                        height: 10.r,
                        child: const CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Text(
                        'sending...',
                        style: TextStyle(
                          fontSize: 9.5.sp,
                          fontStyle: FontStyle.italic,
                          fontFamily: 'Poppins',
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ] else ...[
                      Icon(
                        Icons.done_all_rounded,
                        size: 14.sp,
                        color: Colors.white,
                      ),
                    ],
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // lab act 6 enhancement 3: pill-shaped composer
  Widget _buildComposer(
    BuildContext context,
    String currentUserId,
    String tappedUserId,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, -2),
            blurRadius: 6,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    width: 0.8,
                  ),
                ),
                child: TextField(
                  controller: _msgCtrl,
                  focusNode: _msgFocus,
                  enabled: !_isSending,
                  textInputAction: TextInputAction.send,
                  minLines: 1,
                  maxLines: 4,
                  onSubmitted: (_) =>
                      !_isSending ? _send(currentUserId, tappedUserId) : null,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13.5.sp,
                      color: Colors.grey.shade500,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Material(
              color: Theme.of(context).colorScheme.primary,
              shape: const CircleBorder(),
              elevation: 2,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _isSending ? null : () => _send(currentUserId, tappedUserId),
                child: Padding(
                  padding: EdgeInsets.all(10.r),
                  child: _isSending
                      ? SizedBox(
                          height: 20.r,
                          width: 20.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}