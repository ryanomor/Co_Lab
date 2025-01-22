import 'dart:math';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:co_lab/auth/signup_profile.dart';
import 'package:co_lab/auth/phone_auth.dart';
import 'package:co_lab/firebase/auth_service.dart';

class OAuthButtons extends StatelessWidget {
  const OAuthButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildGoogleButton(context),
        const SizedBox(height: 8),
        if (defaultTargetPlatform == TargetPlatform.iOS) ...[
          _buildAppleButton(context),
          const SizedBox(height: 8),
        ],
        _buildFacebookButton(context),
        const SizedBox(height: 8),
        _buildPhoneButton(context),
      ],
    );
  }

  Widget _buildGoogleButton(BuildContext context) {
    return SocialAuthButton(
      text: 'Continue with Google',
      icon: '../../icons/google.png',
      onPressed: () => _signInWithGoogle(context),
    );
  }

  Widget _buildAppleButton(BuildContext context) {
    return SocialAuthButton(
      text: 'Continue with Apple',
      icon: '../../icons/apple.png',
      onPressed: () => _signInWithApple(context),
    );
  }

  Widget _buildFacebookButton(BuildContext context) {
    return SocialAuthButton(
      text: 'Continue with Facebook',
      icon: '../../icons/facebook.png',
      onPressed: () => _signInWithFacebook(context),
    );
  }

  Widget _buildPhoneButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PhoneAuthScreen(),
          ),
        );
      },
      icon: const Icon(Icons.phone),
      label: const Text('Continue with Phone'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      await FirebaseAuth.instance.currentUser?.updatePhotoURL(googleUser.photoUrl);

      await AuthService.handleSignIn(
        context,
        userCredential.user!,
        email: googleUser.email,
        photoUrl: googleUser.photoUrl,
      );
    } catch (e) {
      AuthService.handleError(context, e);
    }
  }

  Future<void> _signInWithApple(BuildContext context) async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      await AuthService.handleSignIn(
        context,
        userCredential.user!,
        email: userCredential.user?.email,
        photoUrl: userCredential.user?.photoURL,
      );
    } catch (e) {
      AuthService.handleError(context, e);
    }
  }

  Future<void> _signInWithFacebook(BuildContext context) async {
    try {
      final LoginResult loginResult = await FacebookAuth.instance.login();

      if (loginResult.status == LoginStatus.success) {
        final AccessToken accessToken = loginResult.accessToken!;
        final OAuthCredential credential = FacebookAuthProvider.credential(accessToken.token);
        
        final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        final userData = await FacebookAuth.instance.getUserData();

        await AuthService.handleSignIn(
          context,
          userCredential.user!,
          email: userData['email'],
          photoUrl: userData['picture']['data']['url'],
        );
      }
    } catch (e) {
      AuthService.handleError(context, e);
    }
  }

  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
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
