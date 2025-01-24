import 'package:flutter/material.dart';
import 'package:co_lab/dashboard.dart';
import 'package:co_lab/auth/oauth.dart';
import 'package:co_lab/auth/signup_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:co_lab/firestore/models/user.dart';
import 'package:co_lab/firebase/auth_service.dart';
import 'package:co_lab/helpers/is_valid_email.dart';
import 'package:co_lab/firebase/firebase_service.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_auth_web/firebase_auth_web.dart';

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
        future: FirebaseService()
            .getUser(email: FirebaseAuth.instance.currentUser?.email),
        builder: (context, futureSnapshot) {
          switch (futureSnapshot.connectionState) {
            case ConnectionState.waiting:
            case ConnectionState.none:
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            default:
              UserModel? firestoreUser = futureSnapshot.data;

              if (firestoreUser == null) {
                print('No user found');
                return LoginScreen();
              } else {
                return DashboardScreen(uid: firestoreUser.uid);
              }
          }
        });
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseService firestore = FirebaseService();

  void _navigateToProfileSetup(User user) {
    firestore.createUser(UserModel(
      uid: user.uid,
      email: user.email!,
      username: user.email!.split('@').first, // email as username placeholder
      photoUrl: user.photoURL ?? '',
    ));

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileSetupScreen(
          uid: user.uid,
        ),
      ),
      (route) => false, // Removes all previous routes
    );
  }

  Future<void> _signUpOAuth(UserCredential userCredential) async {
    UserModel? firestoreUser =
        await firestore.getUser(email: userCredential.user!.email);

    if (firestoreUser != null) {
      print('User exists');
      // popup modal to let user know the account is signed up
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Already Signed Up'),
          content: const Text('Please Login Instead'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
              child: const Text('Login'),
            ),
            TextButton(
              onPressed: () {
                FirebaseAuth.instance.currentUser!.delete();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } else {
      print('New User SignUp!');
      _navigateToProfileSetup(userCredential.user!);
    }
  }

  Future<void> _signUp() async {
    if (!isValidEmail(_emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid email')));
      return;
    }

    try {
      await firestore
          .getUser(email: _emailController.text.trim())
          .then((onValue) {
        if (onValue != null) {
          throw Exception('Account can\'t be created');
        }
      });

      final UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      _navigateToProfileSetup(userCredential.user!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signup failed: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Signup')),
      body: SafeArea(
          child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const Divider(height: 32),
            OAuthButtons(),
            ElevatedButton(
              onPressed: _signUp,
              child: const Text('Signup'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('I Have an Account'),
            ),
          ],
        ),
      )),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final firestore = FirebaseService();
  bool _isLoading = false;
  bool _isPhoneLogin = false;
  bool _codeSent = false;
  String _verificationId = '';
  String _selectedCountryCode = '+1';
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
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _webRecaptchaVerifier?.clear();
    super.dispose();
  }

  Future<void> _loginOAuth(UserCredential userCredential) async {
    try {
      print('Checking if user exists in Firestore...');
      UserModel? firestoreUser =
          await firestore.getUser(email: userCredential.user!.email);

      if (firestoreUser == null) {
        print('No user found');
        // popup modal to let user know the account is not signed up
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Account Not Registered'),
            content: const Text('Would you like to sign up with this account?'),
            actions: [
              TextButton(
                onPressed: () {
                  _navigateToProfileSetup(userCredential.user!);
                },
                child: const Text('Yes'),
              ),
              TextButton(
                onPressed: () {
                  FirebaseAuth.instance.currentUser!.delete();
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      } else {
        print('User found');
        Navigator.pushNamedAndRemoveUntil(
            context, '/dashboard', (route) => false,
            arguments: firestoreUser.uid);
      }
    } catch (e) {
      print('Firestore Error: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Authentication error: $e')));
    }
  }

  void _navigateToProfileSetup(User user) {
    firestore.createUser(UserModel(
      uid: user.uid,
      email: user.email!,
      username: user.email!.split('@').first, // email as username placeholder
      photoUrl: user.photoURL ?? '',
    ));

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileSetupScreen(
          uid: user.uid,
        ),
      ),
      (route) => false, // Removes all previous routes
    );
  }

  Future<void> _verifyPhoneNumber() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final phoneNumber = _selectedCountryCode + _phoneController.text.trim();

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
    if (!_formKey.currentState!.validate()) return;

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

  Future<void> _signInWithPhoneCredential(
      PhoneAuthCredential credential) async {
    try {
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        final phoneNumber = _selectedCountryCode + _phoneController.text.trim();

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

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isPhoneLogin) {
        await _verifyPhoneNumber();
      } else {
        await firestore
            .getUser(email: _emailController.text.trim())
            .then((onValue) {
          if (onValue == null) {
            throw Exception('User not found');
          }
        });

        final UserCredential userCredential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        Navigator.pushNamedAndRemoveUntil(
            context, '/dashboard', (route) => false,
            arguments: userCredential.user!.uid);
      }
    } catch (e) {
      print('Login Error: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Login failed')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        actions: [
          TextButton.icon(
            onPressed: () {
              setState(() {
                _isPhoneLogin = !_isPhoneLogin;
                _codeSent = false;
                _verificationId = '';
              });
            },
            icon: Icon(_isPhoneLogin ? Icons.email : Icons.phone),
            label: Text(_isPhoneLogin ? 'Use Email' : 'Use Phone'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isPhoneLogin && !_codeSent) ...[
                  Row(
                    children: [
                      CountryCodePicker(
                        onChanged: (CountryCode countryCode) {
                          setState(() {
                            _selectedCountryCode = countryCode.dialCode ?? '+1';
                          });
                        },
                        initialSelection: 'US',
                        favorite: const ['US', 'CA', 'GB'],
                        showCountryOnly: false,
                        showOnlyCountryWhenClosed: false,
                        alignLeft: false,
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            hintText: 'Enter your phone number',
                          ),
                          keyboardType: TextInputType.phone,
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
                ] else if (_isPhoneLogin && _codeSent) ...[
                  TextFormField(
                    controller: _otpController,
                    decoration: const InputDecoration(
                      labelText: 'Verification Code',
                      hintText: 'Enter the code sent to your phone',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOTP,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Verify Code'),
                  ),
                  TextButton(
                    onPressed: _isLoading ? null : _verifyPhoneNumber,
                    child: const Text('Resend Code'),
                  ),
                ],
                if (!_isPhoneLogin) ...[
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!isValidEmail(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 24),
                if (!_isPhoneLogin) ...[
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Login'),
                  ),
                ],
                if (!_isPhoneLogin) ...[
                  const Divider(height: 32),
                  OAuthButtons(),
                ],
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/signup',
                    );
                  },
                  child: const Text('Don\'t Have an Account?'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
