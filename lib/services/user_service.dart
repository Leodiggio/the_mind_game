import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> getNickname(String uid) async {
    final docSnap = await _firestore.collection('users').doc(uid).get();
    if (docSnap.exists) {
      final data = docSnap.data()!;
      return data['nickname'] as String?;
    }
    return null;
  }
}
