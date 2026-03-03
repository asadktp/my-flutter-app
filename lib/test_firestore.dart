import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final snapshot = await FirebaseFirestore.instance
      .collection('organizations')
      .get();
  for (var doc in snapshot.docs) {
    print('ORG ID: ${doc.id}');
    print('NAME: ${doc['name']}');
    print('ADDRESS: ${doc['address']}');
    print('---');
  }
}
