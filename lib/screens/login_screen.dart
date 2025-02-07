import 'package:flutter/material.dart';
import 'package:the_mind_game/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final AuthService authService; // iniettiamo il servizio

  const LoginScreen({Key? key, required this.authService}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();

  Future<void> _login() async {
    try {
      await widget.authService.login(
        _emailController.text,
        _passwordController.text,
      );
      // Il StreamBuilder in main.dart farà il resto (mostrando la Home se utente loggato).
    } catch (e) {
      print("Errore di login: $e");
      // show a dialog/snackbar
    }
  }

  Future<void> _signup() async {
    try {
      await widget.authService.signup(
        _emailController.text,
        _passwordController.text,
        _nicknameController.text,
      );
      // Se va a buon fine, l'utente è loggato e il doc Firestore è creato
    } catch (e) {
      print("Errore di signup: $e");
      // show a dialog/snackbar
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login / Signup"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Email
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            // Password
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            // Nickname
            TextField(
              controller: _nicknameController,
              decoration:
              const InputDecoration(labelText: "Nickname (solo in signup)"),
            ),
            const SizedBox(height: 20),
            // Pulsanti
            ElevatedButton(
              onPressed: _login,
              child: const Text("Login"),
            ),
            ElevatedButton(
              onPressed: _signup,
              child: const Text("Sign Up"),
            ),
          ],
        ),
      ),
    );
  }
}
