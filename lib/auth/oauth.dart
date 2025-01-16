import 'dart:math';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class OAuthButtons extends StatelessWidget {
  final Future<void> Function(UserCredential userCredential) signInCallback;

  const OAuthButtons({
    super.key,
    required this.signInCallback,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildGoogleButton(),
        const SizedBox(height: 12),
        if (defaultTargetPlatform == TargetPlatform.iOS) ...[
          _buildAppleButton(),
          const SizedBox(height: 12),
        ],
        _buildFacebookButton(),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SocialAuthButton(
      text: 'Continue with Google',
      icon: '../../assets/icons/google.png',
      onPressed: () => _signInWithGoogle(),
    );
  }

  Widget _buildAppleButton() {
    return SocialAuthButton(
      text: 'Continue with Apple',
      icon: '../../assets/icons/apple.png',
      onPressed: () => _signInWithApple(),
    );
  }

  Widget _buildFacebookButton() {
    return SocialAuthButton(
      text: 'Continue with Facebook',
      icon: '../../assets/icons/facebook.png',
      onPressed: () => _signInWithFacebook(),
    );
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      await FirebaseAuth.instance.signInWithCredential(credential).then(
          (onValue) => {onValue.user!.updatePhotoURL(googleUser.photoUrl)});

      await signInCallback.call(userCredential);
    } catch (e) {
      debugPrint('Google sign in error: $e');
    }
  }

  String generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _signInWithApple() async {
    try {
      final rawNonce = generateNonce();
      final nonce = sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        accessToken: appleCredential.authorizationCode,
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      await signInCallback.call(userCredential);
    } catch (e) {
      debugPrint('Apple sign in error: $e');
    }
  }

  Future<void> _signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status != LoginStatus.success) return;

      final OAuthCredential credential =
          FacebookAuthProvider.credential(result.accessToken!.tokenString);

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      await signInCallback.call(userCredential);
    } catch (e) {
      debugPrint('Facebook sign in error: $e');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Sign in failed.'))
      // );
    }
  }
}

class SocialAuthButton extends StatelessWidget {
  final String text;
  final String icon;
  final VoidCallback onPressed;

  const SocialAuthButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            icon,
            height: 24,
            width: 24,
          ),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }
}
