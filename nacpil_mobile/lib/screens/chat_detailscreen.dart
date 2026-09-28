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
    Key? key,
    required this.currentUserEmail,
    required this.tappedUser,
  }) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final FocusNode _msgFocus = FocusNode();
  final ScrollController _scrollCtrl =ScrollController();

  late Future<String> _currentUserIdFuture;
  bool _isSending = false;
  Timestamp? _sendingStartedAt;

  static const _postSendDelay = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    _currentUserIdFuture = _getCurrentUserId();
  }

  Future<String> _getCurrentUserId() async {
    final userData = await userService.value.getUserData();
    return (userData['uid'] ?? '').toString();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _msgFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String currentUserId, String receiverId) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _sendingStartedAt = Timestamp.now();
    });

    try {
      await chatService.sendMessage(receiverId, text);
      _msgCtrl.clear();
      _msgFocus.requestFocus();

      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }

      await Future.delayed(_postSendDelay);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _sendingStartedAt = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tappedUserId = (widget.tappedUser['uid'] ?? '').toString();
    final tappedUserName = (widget.tappedUser['firstName'] ?? '').toString();

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
          appBar: AppBar(
            centerTitle: true,
            title: CustomText(text: tappedUserName, fontSize: 25.sp),
          ),
          body: Column(
            children: [
              // messages
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: chatService.getMessage(currentUserId, tappedUserId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error loading messages: ${snapshot.error}'),
                      );
                    }
                    List<QueryDocumentSnapshot> docs = snapshot.data?.docs ?? [];

                    // hide my just-sent messages until delay completes
                    if (_isSending && _sendingStartedAt != null) {
                      docs = docs.where ((d) {
                        final data = d.data() as Map<String, dynamic>;
                        final senderId = (data['senderId'] ?? '').toString();
                        final ts = data['timestamp'];
                        if (senderId != currentUserId) return true;
                        if (ts is Timestamp) {
                          return ts.compareTo(_sendingStartedAt!) < 0;
                        }
                        return true;
                      }).toList();
                    }

                    if (docs.isEmpty) {
                      return const Center(child: Text('No messages yet'));
                    }

                    return ListView.builder(
                      controller: _scrollCtrl,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data =
                            docs[index].data() as Map<String, dynamic>;
                        final msgTxt = (data['message'] ?? '').toString();
                        final senderId = (data['senderId'] ?? '').toString();
                        final isMe = senderId == currentUserId;

                        return Align(
                          alignment:
                              isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                            padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 12),
                            constraints: BoxConstraints(
                              maxWidth:
                                MediaQuery.of(context).size.width * 0.75),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.5)
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(12).copyWith(
                                bottomLeft: isMe
                                  ? const Radius.circular(12)
                                  : Radius.zero,
                                bottomRight: isMe
                                  ? Radius.zero
                                  : const Radius.circular(12),
                              ),                          
                            ),
                            child: CustomText(
                              text: msgTxt.isNotEmpty ? msgTxt : "[empty]",
                              fontSize: 15.sp,
                              fontWeight: FontWeight.normal,
                              textAlign: TextAlign.left,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // composer
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgCtrl,
                          focusNode: _msgFocus,
                          enabled: !_isSending,
                          textInputAction: TextInputAction.send,
                          minLines: 1,
                          maxLines: 4,
                          onSubmitted: (_) =>
                            !_isSending ? _send(currentUserId, tappedUserId) : null,
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(fontFamily: 'Poppins'),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                        _isSending
                          ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : IconButton (
                              icon: const Icon(Icons.send),
                              onPressed: () => _send(currentUserId, tappedUserId),
                          ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}