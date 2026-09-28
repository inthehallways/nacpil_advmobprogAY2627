import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../models/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';

ValueNotifier<UserService> userService = ValueNotifier(UserService());

class UserService {
  Map<String, dynamic> data = {};

  final fb.FirebaseAuth firebaseAuth = fb.FirebaseAuth.instance;
  // lab act 6: firestore instance for user data management
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  fb.User? get currentUser => firebaseAuth.currentUser;

  Stream<fb.User?> get authStateChanges => firebaseAuth.authStateChanges();

  /// login via dummyjson api
  Future<Map<String, dynamic>> loginUser(String username, String password) async {
    final response = await post(
      Uri.parse('$host/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username, 
        'password': password,
        'expiresInMins': 60
      }),
    );

    if (response.statusCode == 200) {
      data = jsonDecode(response.body);
      data['loginType'] = 'dummyjson';
      await saveUserData(data);
      return data;
    } else {
      throw Exception(response.body);
    }
  }

  /// sign in via firebase auth
  Future<fb.UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final fbUser = credential.user;
    if (fbUser != null) {
      // lab act 6: fetch existing user document from cloud_firestore Users collection
      Map<String, dynamic> firestoreData = {};
      try {
        final userDoc = await _firestore.collection('Users').doc(fbUser.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          firestoreData = userDoc.data()!;
        }
      } catch (_) {}

      final String resolvedUsername = firestoreData['username'] ??
          (fbUser.displayName?.isNotEmpty == true
              ? fbUser.displayName!
              : email.split('@').first);

      final String resolvedFirstName = firestoreData['firstName'] ??
          (fbUser.displayName?.split(' ').first ?? '');

      final String resolvedLastName = firestoreData['lastName'] ??
          (fbUser.displayName?.contains(' ') == true
              ? fbUser.displayName!.split(' ').sublist(1).join(' ')
              : '');

      final userData = {
        'id': fbUser.uid.hashCode.abs(),
        'uid': fbUser.uid,
        'username': resolvedUsername,
        'email': fbUser.email ?? email,
        'firstName': resolvedFirstName,
        'lastName': resolvedLastName,
        'age': firestoreData['age'] ?? '',
        'contactNo': firestoreData['contactNo'] ?? '',
        'gender': firestoreData['gender'] ?? 'N/A',
        'image': fbUser.photoURL ?? '',
        'token': await fbUser.getIdToken() ?? '',
        'accessToken': await fbUser.getIdToken() ?? '',
        'loginType': 'firebase',
      };
      await saveUserData(userData);

      // lab act 6: ensure user document is populated in Users collection
      try {
        await _firestore.collection('Users').doc(fbUser.uid).set({
          'uid': fbUser.uid,
          'username': resolvedUsername,
          'email': fbUser.email ?? email,
          'firstName': resolvedFirstName,
          'lastName': resolvedLastName,
          'age': firestoreData['age'] ?? '',
          'contactNo': firestoreData['contactNo'] ?? '',
        }, SetOptions(merge: true));
      } catch (_) {}
    }
    return credential;
  }

  /// create account via firebase auth
  Future<fb.UserCredential> createAccount({
    required String email,
    required String password,
    String? username,
    String? fName,
    String? lName,
    String? age,
    String? contactNo,
  }) async {
    final credential = await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final fbUser = credential.user;
    if (fbUser != null) {
      final displayName = (fName != null || lName != null)
          ? '${fName ?? ''} ${lName ?? ''}'.trim()
          : (username ?? email.split('@').first);

      if (displayName.isNotEmpty) {
        await fbUser.updateDisplayName(displayName);
      }

      final resolvedUsername = username ?? email.split('@').first;
      final resolvedFirstName = fName ?? '';
      final resolvedLastName = lName ?? '';

      final userData = {
        'id': fbUser.uid.hashCode.abs(),
        'uid': fbUser.uid,
        'username': resolvedUsername,
        'email': email,
        'firstName': resolvedFirstName,
        'lastName': resolvedLastName,
        'age': age ?? '',
        'contactNo': contactNo ?? '',
        'gender': 'N/A',
        'image': fbUser.photoURL ?? '',
        'token': await fbUser.getIdToken() ?? '',
        'accessToken': await fbUser.getIdToken() ?? '',
        'loginType': 'firebase',
      };
      await saveUserData(userData);

      // lab act 6: store newly created user in cloud_firestore Users collection
      try {
        await _firestore.collection('Users').doc(fbUser.uid).set({
          'uid': fbUser.uid,
          'username': resolvedUsername,
          'email': email,
          'firstName': resolvedFirstName,
          'lastName': resolvedLastName,
          'age': age ?? '',
          'contactNo': contactNo ?? '',
        }, SetOptions(merge: true));
      } catch (_) {}
    }

    return credential;
  }

  /// sign out from firebase auth
  Future<void> signOut() async {
    await firebaseAuth.signOut();
    await logout();
  }

  /// update username
  Future<void> updateUsername({required String username}) async {
    if (currentUser != null) {
      await currentUser!.updateDisplayName(username);
      // lab act 6: update username in cloud_firestore Users collection
      try {
        await _firestore.collection('Users').doc(currentUser!.uid).set({
          'username': username,
        }, SetOptions(merge: true));
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
  }

  /// delete account
  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    if (currentUser != null) {
      fb.AuthCredential credential = fb.EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      await currentUser!.reauthenticateWithCredential(credential);
      await currentUser!.delete();
      await firebaseAuth.signOut();
    }
    await logout();
  }

  /// reset password from current password
  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    if (currentUser != null) {
      fb.AuthCredential credential = fb.EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      await currentUser!.reauthenticateWithCredential(credential);
      await currentUser!.updatePassword(newPassword);
    } else {
      throw Exception('No active Firebase user found to update password.');
    }
  }

  /// save user data to shared preferences
  Future<void> saveUserData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final user = User.fromJson(data);

    await prefs.setInt('id', user.id);
    await prefs.setString('username', user.username);
    await prefs.setString('email', user.email);
    await prefs.setString('firstName', user.firstName);
    await prefs.setString('lastName', user.lastName);
    await prefs.setString('age', user.age);
    await prefs.setString('contactNo', user.contactNo);
    await prefs.setString('gender', user.gender);
    await prefs.setString('image', user.image);
    await prefs.setString('accessToken', user.accessToken);
    await prefs.setString('refreshToken', user.refreshToken);
    await prefs.setString('loginType', user.loginType);

    // lab act 6: persist firebase uid for chat identification
    final resolvedUid = data['uid']?.toString() ?? firebaseAuth.currentUser?.uid ?? '';
    await prefs.setString('uid', resolvedUid);

    if (data.containsKey('token')) {
      await prefs.setString('token', data['token'] ?? '');
    } else if (user.accessToken.isNotEmpty) {
      await prefs.setString('token', user.accessToken);
    }
  }

  /// retrieve user data from shared preferences
  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'id': prefs.getInt('id') ?? 0,
      'uid': prefs.getString('uid') ?? (firebaseAuth.currentUser?.uid ?? ''),
      'username': prefs.getString('username') ?? '',
      'email': prefs.getString('email') ?? (firebaseAuth.currentUser?.email ?? ''),
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'age': prefs.getString('age') ?? '',
      'contactNo': prefs.getString('contactNo') ?? '',
      'gender': prefs.getString('gender') ?? '',
      'image': prefs.getString('image') ?? '',
      'accessToken': prefs.getString('accessToken') ?? '',
      'refreshToken': prefs.getString('refreshToken') ?? '',
      'token': prefs.getString('token') ?? '',
      'loginType': prefs.getString('loginType') ?? 'dummyjson',
    };
  }

  /// retrieve user model from shared preferences
  Future<User> getUser() async {
    final userData = await getUserData();
    return User.fromJson(userData);
  }

  /// check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken') ?? prefs.getString('token');
    return (token != null && token.isNotEmpty) || firebaseAuth.currentUser != null;
  }

  /// logout and clear user data
  Future<void> logout() async {
    try {
      if (firebaseAuth.currentUser != null) {
        await firebaseAuth.signOut();
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      throw Exception('Failed to logout: $e');
    }
  }
}