import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import 'chat_detailscreen.dart';

class ChatScreen extends StatefulWidget {
    const ChatScreen({super.key});

    @override
    State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
    final TextEditingController _searchChatController = TextEditingController();
    final ChatService _chatService = ChatService();
    String? _currentUserEmail;
    String? _currentUserId;
    String _searchText = '';

    @override
    void initState() {
        super.initState();
        _loadCurrentUser();
    }

    Future<void> _loadCurrentUser() async {
        final userData = await userService.value.getUserData();
        if (mounted) {
            setState(() {
                _currentUserEmail = userData['email']?.toString() ?? userService.value.currentUser?.email;
                _currentUserId = userData['uid']?.toString() ?? userService.value.currentUser?.uid;
            });
        }
    }

    @override
    void dispose() {
        _searchChatController.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text('Messages'),
                centerTitle: true,
            ),
            body: SingleChildScrollView(
                child: Column(
                    children: [
                        SizedBox(height: 20.h),
                        Padding(
                            padding: EdgeInsets.symmetric(horizontal: 23.w),
                            child: TextField(
                                controller: _searchChatController,
                                textInputAction: TextInputAction.search,
                                // lab act 6 enhancement 2: update search filter on input change
                                onChanged: (value) {
                                    setState(() {
                                        _searchText = value.trim().toLowerCase();
                                    });
                                },
                                decoration: InputDecoration(
                                    hintText: 'Search chat...',
                                    prefixIcon: const Icon(Icons.search),
                                    suffixIcon: (_searchChatController.text.isNotEmpty)
                                        ? IconButton(
                                            tooltip: 'Clear',
                                            icon: const Icon(Icons.cancel),
                                            onPressed: () {
                                                setState(() {
                                                    _searchChatController.clear();
                                                    _searchText = '';
                                                });
                                            },
                                        )
                                        : null,
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                    ),
                                ),
                            ),
                        ),
                        SizedBox(height: 10.h),

                        // users stream
                        StreamBuilder<List<Map<String, dynamic>>>(
                            stream: _chatService.getUsersStream(),
                            builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Container(
                                        height: ScreenUtil().screenHeight * 0.6,
                                        padding: EdgeInsets.all(16.sp),
                                        child: const Center(
                                            child: CircularProgressIndicator.adaptive(),
                                        ),
                                    );
                                }
                                if (snapshot.hasError) {
                                    return Container(
                                        height: ScreenUtil().screenHeight * 0.6,
                                        padding: EdgeInsets.all(16.sp),
                                        child: Center(
                                            child: CustomText(
                                                text: 'Error loading users',
                                                fontSize: 16.sp,
                                            ),
                                        ),
                                    );
                                }
                                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                    return Container(
                                        height: ScreenUtil().screenHeight * 0.6,
                                        padding: EdgeInsets.all(16.sp),
                                        child: Center(
                                            child: CustomText(
                                                text: 'No users found',
                                                fontSize: 16.sp,
                                            ),
                                        ),
                                    );
                                }

                                // lab act 6 enhancement 1: display all registered users while excluding the current logged-in user
                                final currentEmail = (_currentUserEmail ?? userService.value.currentUser?.email ?? '').trim().toLowerCase();
                                final currentUid = (_currentUserId ?? userService.value.currentUser?.uid ?? '').trim();

                                final users = snapshot.data!.where((user) {
                                    final userEmail = (user['email'] ?? '').toString().trim().toLowerCase();
                                    final userUid = (user['uid'] ?? '').toString().trim();

                                    final isCurrentUser = (currentEmail.isNotEmpty && userEmail == currentEmail) ||
                                        (currentUid.isNotEmpty && userUid == currentUid);

                                    return !isCurrentUser;
                                }).toList();

                                if (users.isEmpty) {
                                    return Container(
                                        height: ScreenUtil().screenHeight * 0.6,
                                        padding: EdgeInsets.all(16.sp),
                                        child: Center(
                                            child: CustomText(
                                                text: 'No other users found',
                                                fontSize: 16.sp,
                                            ),
                                        ),
                                    );
                                }

                                // lab act 6 enhancement 2: filter users by typing their name or email
                                final filteredUsers = users.where((user) {
                                    if (_searchText.isEmpty) return true;

                                    final firstName = (user['firstName'] ?? '').toString().toLowerCase();
                                    final lastName = (user['lastName'] ?? '').toString().toLowerCase();
                                    final fullName = '$firstName $lastName'.trim();
                                    final username = (user['username'] ?? '').toString().toLowerCase();
                                    final email = (user['email'] ?? '').toString().toLowerCase();

                                    return firstName.contains(_searchText) ||
                                        lastName.contains(_searchText) ||
                                        fullName.contains(_searchText) ||
                                        username.contains(_searchText) ||
                                        email.contains(_searchText);
                                }).toList();

                                if (filteredUsers.isEmpty) {
                                    return Container(
                                        height: ScreenUtil().screenHeight * 0.6,
                                        padding: EdgeInsets.all(16.sp),
                                        child: Center(
                                            child: CustomText(
                                                text: 'No users found matching "$_searchText"',
                                                fontSize: 16.sp,
                                            ),
                                        ),
                                    );
                                }

                                return ListView.builder(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: filteredUsers.length,
                                    itemBuilder: (context, index) {
                                        final user = filteredUsers[index];
                                        return GestureDetector(
                                            onTap: () {
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) => ChatDetailScreen(
                                                            currentUserEmail: _currentUserEmail ?? userService.value.currentUser?.email ?? '',
                                                            tappedUser: user,
                                                        ),
                                                    ),
                                                );
                                            },
                                            child: Builder(
                                                builder: (context) {
                                                    final fName = (user['firstName'] ?? '').toString().trim();
                                                    final lName = (user['lastName'] ?? '').toString().trim();
                                                    final fullName = '$fName $lName'.trim();
                                                    final displayName = fullName.isNotEmpty
                                                        ? fullName
                                                        : ((user['username'] ?? user['email'] ?? 'Unknown').toString());
                                                    final initial = fName.isNotEmpty
                                                        ? fName[0].toUpperCase()
                                                        : (displayName.isNotEmpty ? displayName[0].toUpperCase() : '?');

                                                    return Card(
                                                        child: ListTile(
                                                            leading: CircleAvatar(
                                                                child: CustomText(
                                                                    text: initial,
                                                                    fontSize: 16,
                                                                    fontWeight: FontWeight.bold,
                                                                ),
                                                            ),
                                                            title: CustomText(
                                                                text: displayName,
                                                                fontSize: 18.sp,
                                                                fontWeight: FontWeight.bold,    
                                                            ),
                                                            subtitle: CustomText(
                                                                text: user['email'] ?? 'No email',
                                                                fontSize: 12.sp,
                                                                fontWeight: FontWeight.w300,
                                                            ),
                                                        ),
                                                    );
                                                },
                                            ),
                                        );
                                    },
                                );
                            },
                        ),
                    ],
                ),
            ),
        );
    }
}