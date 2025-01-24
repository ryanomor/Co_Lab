import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:co_lab/firebase/auth_service.dart';
import 'package:country_code_picker/country_code_picker.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  String _selectedCountryCode = '+1';
  String _verificationId = '';
  bool _codeSent = false;
  bool _isLoading = false;
  RecaptchaVerifier? _webRecaptchaVerifier;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _webRecaptchaVerifier = RecaptchaVerifier(
        container: 'recaptcha-container',
        size: RecaptchaVerifierSize.normal,
        auth: FirebaseAuth.instance,
      );
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _webRecaptchaVerifier?.clear();
    super.dispose();
  }

  Future<void> _verifyPhoneNumber() async {
    final phoneNumber = _selectedCountryCode + _phoneController.text.trim();

    setState(() => _isLoading = true);

    try {
      if (kIsWeb) {
        // For web, use the reCAPTCHA verifier
        await FirebaseAuth.instance.signInWithPhoneNumber(
          phoneNumber,
          _webRecaptchaVerifier!,
        ).then((verificationId) {
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _isLoading = false;
          });
        });
      } else {
        // For mobile, use the regular verification flow
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          verificationCompleted: (PhoneAuthCredential credential) async {
            await _signInWithPhoneCredential(credential);
          },
          verificationFailed: (FirebaseAuthException e) {
            setState(() => _isLoading = false);
            AuthService.handleError(context, e);
          },
          codeSent: (String verificationId, int? resendToken) {
            setState(() {
              _verificationId = verificationId;
              _codeSent = true;
              _isLoading = false;
            });
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            setState(() {
              _verificationId = verificationId;
              _isLoading = false;
            });
          },
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      AuthService.handleError(context, e);
    }
  }

  Future<void> _verifyOTP() async {
    setState(() => _isLoading = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpController.text,
      );

      await _signInWithPhoneCredential(credential);
    } catch (e) {
      setState(() => _isLoading = false);
      AuthService.handleError(context, e);
    }
  }

  Future<void> _signInWithPhoneCredential(PhoneAuthCredential credential) async {
    try {
      final userCredential = 
          await FirebaseAuth.instance.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        final phoneNumber = _selectedCountryCode + _phoneController.text.trim();
        
        if (!mounted) return;
        await AuthService.handleSignIn(
          context,
          userCredential.user!,
          phoneNumber: phoneNumber,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      AuthService.handleError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone Authentication'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_codeSent) ...[
              Row(
                children: [
                  CountryCodePicker(
                    onChanged: (CountryCode countryCode) {
                      setState(() {
                        _selectedCountryCode = countryCode.dialCode ?? '+1';
                      });
                    },
                    initialSelection: 'US',
                    favorite: const ['US', 'CA'],
                    showCountryOnly: false,
                    showOnlyCountryWhenClosed: false,
                    alignLeft: false,
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        hintText: 'Enter your phone number',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        final cleanPhone = value.replaceAll(RegExp(r'\D'), '');
                        if (cleanPhone.length < 10) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              if (kIsWeb) Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                height: 100,
                child: const Center(
                  child: HtmlElementView(viewType: 'recaptcha-container'),
                ),
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyPhoneNumber,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Send Verification Code'),
              ),
            ] else ...[
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Verification Code',
                  hintText: 'Enter the code sent to your phone',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyOTP,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Verify Code'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
