import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final auth.FirebaseAuth _firebaseAuth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  String? lastError;

  bool get isAdmin =>
      _currentUser?.role == 'org_admin' ||
      _currentUser?.role == 'admin' ||
      _currentUser?.role == 'super_admin' ||
      _currentUser?.role == 'superadmin';

  bool get isReadOnly => _isReadOnly;
  bool _isReadOnly = false;

  AuthProvider() {
    _firebaseAuth.authStateChanges().listen((user) async {
      if (user != null && _currentUser == null) {
        debugPrint('[Auth] Session restored for UID: ${user.uid}');
        await _fetchUserRole(user.uid);
      } else if (user == null) {
        _currentUser = null;
        _isReadOnly = false;
        notifyListeners();
      }
    });
  }

  Future<void> _fetchUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = UserModel.fromJson(doc.data()!, doc.id);

        // Auto-assign organizationId to admin if missing (Legacy support)
        final role = _currentUser!.role;
        if ((role == 'org_admin' ||
                role == 'admin' ||
                role == 'super_admin' ||
                role == 'superadmin') &&
            (_currentUser!.organizationId == null ||
                _currentUser!.organizationId!.isEmpty)) {
          final newOrgRef = _firestore.collection('organizations').doc();
          _currentUser!.organizationId = newOrgRef.id;

          await _firestore.collection('users').doc(uid).update({
            'organizationId': newOrgRef.id,
          });
        }

        // Real-time subscription check
        await _checkSubscription();

        debugPrint('[Auth] User fetched — role: ${_currentUser?.role}');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[Auth] Error fetching user data: $e');
    }
  }

  Future<void> _checkSubscription() async {
    if (_currentUser == null ||
        _currentUser!.role == 'super_admin' ||
        _currentUser!.role == 'superadmin') {
      _isReadOnly = false;
      return;
    }

    final orgId = _currentUser!.organizationId;
    if (orgId != null && orgId.isNotEmpty) {
      final orgDoc = await _firestore
          .collection('organizations')
          .doc(orgId)
          .get();
      if (orgDoc.exists) {
        final data = orgDoc.data()!;
        final status = data['status'] ?? 'active';
        final expiry =
            (data['subscriptionEndDate'] as Timestamp?)?.toDate() ??
            (data['subscriptionExpiry'] as Timestamp?)?.toDate();

        if (status == 'suspended') {
          // Handled during login, but for real-time:
          _isReadOnly = true;
        } else if (expiry != null && expiry.isBefore(DateTime.now())) {
          _isReadOnly = true;
        } else {
          _isReadOnly = false;
        }
      }
    }
  }

  /// Login with full inline checks: blocked, deleted, subscription.
  Future<UserModel?> login(
    String email,
    String password, {
    String? expectedRoleType,
  }) async {
    lastError = null;
    _isReadOnly = false;

    try {
      debugPrint('[Auth] Login started for: $email');

      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;
      debugPrint('[Auth] Firebase Auth success — UID: $uid');

      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        lastError =
            'User profile not found in Firestore. Contact your administrator.';
        debugPrint('[Auth] ERROR: No Firestore document for UID: $uid');
        await _firebaseAuth.signOut();
        return null;
      }

      _currentUser = UserModel.fromJson(userDoc.data()!, userDoc.id);

      // Check expected role if provided
      if (expectedRoleType != null) {
        bool userIsAdmin =
            _currentUser!.role == 'org_admin' ||
            _currentUser!.role == 'admin' ||
            _currentUser!.role == 'super_admin' ||
            _currentUser!.role == 'superadmin';

        if (expectedRoleType == 'admin' && !userIsAdmin) {
          lastError = 'Access denied. Please use the Collector Login.';
          await _firebaseAuth.signOut();
          _currentUser = null;
          return null;
        } else if (expectedRoleType == 'collector' && userIsAdmin) {
          lastError = 'Access denied. Please use the Admin Login.';
          await _firebaseAuth.signOut();
          _currentUser = null;
          return null;
        }
      }

      // Check if blocked
      if (_currentUser!.status != 'active') {
        lastError = 'User Blocked';
        await _firebaseAuth.signOut();
        _currentUser = null;
        return null;
      }

      // Auto-assign organizationId to admin if missing (Legacy support)
      final role = _currentUser!.role;
      if ((role == 'org_admin' ||
              role == 'admin' ||
              role == 'super_admin' ||
              role == 'superadmin') &&
          (_currentUser!.organizationId == null ||
              _currentUser!.organizationId!.isEmpty)) {
        final newOrgRef = _firestore.collection('organizations').doc();
        _currentUser!.organizationId = newOrgRef.id;

        await _firestore.collection('users').doc(uid).update({
          'organizationId': newOrgRef.id,
        });
      }

      debugPrint('[Auth] User role: ${_currentUser!.role}');

      // Subscription check (skip for superadmin)
      if (_currentUser!.role != 'super_admin' &&
          _currentUser!.role != 'superadmin') {
        final orgId = _currentUser!.organizationId;
        if (orgId != null && orgId.isNotEmpty) {
          final orgDoc = await _firestore
              .collection('organizations')
              .doc(orgId)
              .get();

          if (orgDoc.exists) {
            final data = orgDoc.data()!;
            final statusData = data['status'] ?? 'active';
            final expiry =
                (data['subscriptionEndDate'] as Timestamp?)?.toDate() ??
                (data['subscriptionExpiry'] as Timestamp?)?.toDate();

            if (statusData == 'suspended') {
              lastError = 'Organization Suspended';
              await _firebaseAuth.signOut();
              _currentUser = null;
              return null;
            }

            if (expiry != null && expiry.isBefore(DateTime.now())) {
              _isReadOnly = true;
              if (_currentUser!.role == 'collector') {
                lastError =
                    'Your subscription has expired. Please renew to continue.';
                await _firebaseAuth.signOut();
                _currentUser = null;
                return null;
              }
            }
          }
        }
      }

      notifyListeners();
      return _currentUser;
    } on auth.FirebaseAuthException catch (e) {
      debugPrint('[Auth] FirebaseAuthException: ${e.code} — ${e.message}');
      lastError = _friendlyAuthError(e.code);
      return null;
    } catch (e) {
      debugPrint('[Auth] Unexpected login error: $e');
      if (e.toString().contains('User Blocked') ||
          e.toString().contains('Organization Suspended')) {
        lastError = e.toString().contains('User Blocked')
            ? 'User Blocked'
            : 'Organization Suspended';
      } else {
        lastError = 'An unexpected error occurred. Please try again.';
      }
      return null;
    }
  }

  String _friendlyAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found for this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled. Contact your administrator.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      default:
        return 'Login failed ($code). Please try again.';
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    _currentUser = null;
    _isReadOnly = false;
    lastError = null;
    notifyListeners();
  }

  void updateProfile() {
    notifyListeners();
  }

  /// Creates a new collector using a secondary Firebase app (avoids logging out admin).
  Future<void> addUser(UserModel user, String plainPassword) async {
    try {
      FirebaseApp secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      auth.UserCredential credential =
          await auth.FirebaseAuth.instanceFor(
            app: secondaryApp,
          ).createUserWithEmailAndPassword(
            email: user.email ?? '${user.username}@donation.local',
            password: plainPassword,
          );

      // Save to Firestore using the real Auth UID as document ID
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(user.toJson());

      await secondaryApp.delete();
      notifyListeners();
    } catch (e) {
      debugPrint('[Auth] Add user error: $e');
      rethrow;
    }
  }

  /// Upload a profile image to Firebase Storage and save URL to Firestore.
  Future<String?> uploadProfileImage(String uid, Uint8List imageBytes) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('$uid.jpg');

      final uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Save URL to Firestore
      await _firestore.collection('users').doc(uid).update({
        'profileImageUrl': downloadUrl,
      });

      // Update in-memory user
      if (_currentUser != null) {
        _currentUser!.profileImageUrl = downloadUrl;
        notifyListeners();
      }

      return downloadUrl;
    } catch (e) {
      debugPrint('[Auth] Image upload error: $e');
      return null;
    }
  }

  /// Block a collector.
  Future<void> blockCollector(String uid) async {
    await _firestore.collection('users').doc(uid).update({'status': 'blocked'});
    notifyListeners();
  }

  /// Unblock a collector.
  Future<void> unblockCollector(String uid) async {
    await _firestore.collection('users').doc(uid).update({'status': 'active'});
    notifyListeners();
  }

  /// Deactivate a collector (Soft delete equivalent)
  Future<void> softDeleteCollector(String uid) async {
    await _firestore.collection('users').doc(uid).update({'status': 'blocked'});
    notifyListeners();
  }

  Future<void> toggleUserStatus(String id, String currentStatus) async {
    await _firestore.collection('users').doc(id).update({
      'status': currentStatus == 'active' ? 'blocked' : 'active',
    });
    notifyListeners();
  }

  // Hard delete removed as per request
  Future<void> deleteUser(String id) async {
    // Only block the user, do not delete
    await softDeleteCollector(id);
  }
}
