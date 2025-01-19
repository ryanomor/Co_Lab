import 'package:flutter/material.dart';
import 'package:co_lab/auth/auth.dart';
import 'package:co_lab/dashboard.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:co_lab/firebase/firebase_options.dart';

void main() async {
  // Firestore.instance.settings(timestampsInSnapshotsEnabled: true).then((_) {
  //   print("Timestamps enabled in snapshots\n");
  // }, onError: (_) {
  //   print("Error enabling timestamps in snapshots\n");
  // });
  await dotenv.load(fileName: '../.env');
  // WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: await DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const CoLab());
}

class CoLab extends StatelessWidget {
  const CoLab({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Co-Lab',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        // primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/dashboard': (context) =>
            DashboardScreen(uid: FirebaseAuth.instance.currentUser!.uid),
      },
      home: const AuthenticationWrapper(),
    );
  }
}
