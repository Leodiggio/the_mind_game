import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:the_mind_game/screens/home_screen.dart';
import 'package:the_mind_game/screens/login_screen.dart';
import 'package:the_mind_game/services/auth_service.dart';
import 'package:the_mind_game/services/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final authService = AuthService();
  final userService = UserService();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            final user = snapshot.data;
            // Se user == null => non loggato => mostra LoginScreen
            if (user == null) {
              return LoginScreen(authService: authService,);
            } else {
              // se c'è un utente loggato => HomeScreen
              return HomeScreen(userService: userService,);
            }
          }
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        },
      ),
    );
  }
}
