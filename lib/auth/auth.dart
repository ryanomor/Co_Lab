import 'package:flutter/material.dart';
import 'package:co_lab/dashboard.dart';
import 'package:co_lab/auth/oauth.dart';
import 'package:co_lab/auth/signup_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:co_lab/firestore/models/user.dart';
import 'package:co_lab/helpers/is_valid_email.dart';
import 'package:co_lab/firebase/firebase_service.dart';

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
    //   return StreamBuilder<User?>(
    //       stream: FirebaseAuth.instance.authStateChanges(),
    //       builder: (context, snapshot) {
    //         if (snapshot.connectionState == ConnectionState.waiting) {
    //           return const Scaffold(
    //             body: Center(child: CircularProgressIndicator()),
    //           );
    //         }

    //         if (snapshot.connectionState == ConnectionState.active) {
    //           User? user = snapshot.data;
    //           if (user == null) {
    //             return LoginScreen();
    //           }
    //           print('Got User object. Checking if user is in database...');
    //           return FutureBuilder<UserModel?>(
    //               future: FirebaseService().getUser(email: user.email),
    //               builder: (context, futureSnapshot) {
    //                 if (futureSnapshot.connectionState ==
    //                     ConnectionState.waiting) {
    //                   return LinearProgressIndicator();
    //                 }

    //                 UserModel? firestoreUser = futureSnapshot.data;

    //                 if (firestoreUser == null) {
    //                   print('No user found');
    //                   if (mounted && context.widget.runtimeType == LoginScreen) {
    //                     print('context from Login screen');
    //                     // popup modal to let user know the account is not signed up
    //                     showDialog(
    //                       context: context,
    //                       builder: (context) => AlertDialog(
    //                         title: const Text('Account Not Registered'),
    //                         content: const Text(
    //                             'Would you like to sign up with this account?'),
    //                         actions: [
    //                           TextButton(
    //                             onPressed: () {
    //                               _navigateToProfileSetup(user);
    //                             },
    //                             child: const Text('Yes'),
    //                           ),
    //                           TextButton(
    //                             onPressed: () {
    //                               Navigator.pop(context);
    //                             },
    //                             child: const Text('Cancel'),
    //                           ),
    //                         ],
    //                       ),
    //                     );
    //                   }
    //                   print('context from SignUp screen');
    //                   return _navigateToProfileSetup(user);
    //                 }
    //                 return DashboardScreen(uid: firestoreUser.uid);
    //               });
    //         }
    //         throw Exception('Unexpected authentication state');
    //       });
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

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileSetupScreen(
          uid: user.uid,
        ),
      ),
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
                Navigator.pushReplacementNamed(
                  context,
                  '/login',
                );
              },
              child: const Text('Login'),
            ),
            TextButton(
              onPressed: () {
                FirebaseAuth.instance.signOut();
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
      final UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await firestore.getUser(email: userCredential.user!.email).then((onValue) {
        if (onValue != null) {
          print('Email already in use');
          throw Exception('Account can\'t be created');
        }
      });

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
            OAuthButtons(
              signInCallback: _signUpOAuth,
            ),
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
  final firestore = FirebaseService();

  void _navigateToProfileSetup(User user) {
    firestore.createUser(UserModel(
      uid: user.uid,
      email: user.email!,
      username: user.email!.split('@').first, // email as username placeholder
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
  }

  Future<void> _loginOAuth(
    UserCredential userCredential,
  ) async {
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
                  FirebaseAuth.instance.signOut().then((onValue) {
                    userCredential.user!.delete();
                  });
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      } else {
        print('User found');
        Navigator.pushReplacementNamed(context, '/dashboard',
            arguments: firestoreUser.uid);
      }
    } catch (e) {
      print('Firestore Error: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Authentication error: $e')));
    }
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

      print('Navigating to dashboard...');

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
            OAuthButtons(
              signInCallback: _loginOAuth,
            ),
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
