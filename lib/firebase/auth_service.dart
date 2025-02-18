import 'package:flutter/material.dart';
import 'package:co_lab/auth/signup_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:co_lab/firestore/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:co_lab/firebase/firebase_service.dart';

class AuthService {
  static final FirebaseService _firestore = FirebaseService();
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Handles the sign-in process for both OAuth and Phone authentication
  static Future<void> handleSignIn(
    BuildContext context,
    User user, {
    String? phoneNumber,
    String? email,
    String? photoUrl,
  }) async {
    assert(phoneNumber != null || email != null, 'Either phoneNumber or email must be provided');
    if (!context.mounted) return;

    try {
      // Check if user exists in Firestore with either email or phone
      UserModel? existingUserByEmail = email != null ? await _firestore.getUser(email: email) : null;
      UserModel? existingUserByPhone = phoneNumber != null ? await _firestore.getUser(phoneNumber: phoneNumber) : null;

      // If user exists with different auth method, show error
      if ((email != null && existingUserByPhone != null) || 
          (phoneNumber != null && existingUserByEmail != null)) {
        // Delete the Firebase Auth user since we can't use this credential
        await _auth.currentUser?.delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An account already exists with this email/phone number. Please sign in with the original method.'),
          ),
        );
        return;
      }

      // Check if user exists with same auth method
      UserModel? firestoreUser = existingUserByEmail ?? existingUserByPhone;

      if (firestoreUser != null) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/dashboard',
          (route) => false,
          arguments: firestoreUser.uid,
        );
      } else {
        // User doesn't exist, show prompt
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Account Not Registered'),
            content: const Text('Would you like to create a new account?'),
            actions: [
              TextButton(
                onPressed: () async {
                  try {
                    // Create new user
                    final userModel = UserModel(
                      uid: user.uid,
                      phoneNumber: phoneNumber,
                      email: email,
                      username: 'User${user.uid.substring(0, 6)}',
                      photoUrl: photoUrl,
                      lastLogin: (FieldValue.serverTimestamp() as Timestamp).toDate(),
                      lastActiveTime: (FieldValue.serverTimestamp() as Timestamp).toDate(),
                      createdTime: (FieldValue.serverTimestamp() as Timestamp).toDate(),
                    );

                    await _firestore.createUser(userModel);

                    Navigator.of(context).pop(); // Close dialog
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileSetupScreen(uid: user.uid),
                      ),
                      (route) => false,
                    );
                  } catch (e) {
                    // If user creation fails, clean up
                    await _auth.currentUser?.delete();
                    Navigator.of(context).pop(); // Close dialog
                    handleError(context, 'Failed to create account. Please try again.');
                  }
                },
                child: const Text('Yes'),
              ),
              TextButton(
                onPressed: () {
                  // Delete the Firebase Auth user since they don't want to create an account
                  _auth.currentUser?.delete();
                  Navigator.of(context).pop(); // Close dialog
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Clean up Firebase Auth user on any error
      await _auth.currentUser?.delete();
      handleError(context, e);
    }
  }

  /// Handles errors during authentication
  static void handleError(BuildContext context, dynamic error) {
    String message = error is String ? error : error.toString();
    // Clean up error message if it's from Firebase
    if (message.contains(']')) {
      message = message.split('] ').last;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
