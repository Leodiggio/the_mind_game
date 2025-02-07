import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> login(String email, String password) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<void> signup(String email, String password, String nickname) async {
    //final String finalNickname = nickname.trim().isEmpty ? 'Player' : nickname.trim();

    //Controllo se un nickname uguale esiste già su Firestore
    //Per eseguire questa query è necessario modificare le regole da Pirestore
    //final QuerySnapshot nicknameSnapshot = await _firestore
    //    .collection('users')
    //    .where('nickname', isEqualTo: finalNickname)
    //    .limit(1)
    //    .get();

    //if (nicknameSnapshot.docs.isNotEmpty) {
      // nickname già usato
    //  throw Exception("nickname-already-in-use");
    //}

    //Se arrivo qui, nickname non usato. Creo l'account con FirebaseAuth.
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final user = credential.user;
      if (user != null) {
        final String finalNickname = nickname.isEmpty ? 'Player' : nickname;
        await _firestore.collection('users').doc(user.uid).set({
          'nickname': finalNickname,
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseAuthException catch (e) {
      // Se l'email è duplicata, troverai "e.code == 'email-already-in-use'"
      rethrow;
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  User? get currentUser => _firebaseAuth.currentUser;
}
