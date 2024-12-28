import 'package:flutter/material.dart';
import 'package:co_lab/dashboard.dart';
import 'package:co_lab/auth/oauth.dart';
import 'package:co_lab/firebase/firebase_service.dart';
import 'package:co_lab/auth/signup_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:co_lab/firestore/models/user.dart';
import 'package:co_lab/helpers/is_valid_email.dart';

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            return LoginScreen();
          } else {
            return DashboardScreen(uid: user.uid);
          }
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

class SignUpScreen extends StatefulWidget {
  // final FirebaseService firestore = FirebaseService();

  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // listen for auth state changes
  // @override
  // void initState() {
  //   super.initState();
  //   FirebaseAuth.instance.authStateChanges().listen((User? user) {
  //     if (user != null) {
  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(
  //           builder: (context) => ProfileSetupScreen(
  //             uid: user!.uid,
  //           ),
  //         ),
  //       );
  //     }
  //   });
  // }

  Future<void> _signup() async {
    if (!isValidEmail(_emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid email')));
      return;
    }

    try {
      final UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // create user in Firestore
      // await widget.firestore.createUser(UserModel(
      //   uid: userCredential.user!.uid,
      //   email: userCredential.user!.email!,
      //   username: userCredential.user!.email!
      //       .split('@')
      //       .first, // email as username placeholder
      // ));

      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => ProfileSetupScreen(
      //       uid: userCredential.user!.uid,
      //     ),
      //   ),
      // );
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
            OAuthButtons(isSignUp: true,),
            ElevatedButton(
              onPressed: _signup,
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
  final FirebaseService firestore = FirebaseService();

  LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // listen for auth state changes
  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        FirebaseService().getUser(email: user.email).then((firestoreUser) {
          if (firestoreUser == null) {
            widget.firestore.createUser(UserModel(
              uid: user.uid,
              email: user.email!,
              username: user.email!
                  .split('@')
                  .first, // email as username placeholder
              photoUrl: user.photoURL ?? '',
            ));

            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(
                builder: (context) => ProfileSetupScreen(
                  uid: user.uid,
                ),
              ),
            );
          } else {
            Navigator.pushReplacementNamed(
              context, 
              '/dashboard',
              arguments: firestoreUser.uid);
          }
        });
      }
    });
  }

  Future<void> _login() async {
    if (!isValidEmail(_emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid email')));
      return;
    }

    try {
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      Navigator.pushNamed(context, '/dashboard',
          arguments: userCredential.user!.uid);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
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
              onPressed: _login,
              child: const Text('Login'),
            ),
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
      )),
    );
  }
}
