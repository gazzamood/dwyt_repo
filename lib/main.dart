import 'package:dwyt_test/pages/home_page.dart';
import 'package:dwyt_test/pages/login_page.dart';
import 'package:dwyt_test/services/auth.dart';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    useMaterial3: true,
    ),
    home: StreamBuilder(
      stream: Auth().authStateChanges,
      builder: (context, snapshot){
        if(snapshot.hasData){
          return HomePage();
        }else{
          return LoginPage();
        }
      }
    )
    );
    }
}