import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:moblie/Account/login_screen.dart';
import 'package:moblie/ui/discovery/discovery.dart';
import 'package:moblie/ui/home/home.dart';
import 'package:firebase_storage/firebase_storage.dart';
void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
