import 'package:flutter/material.dart';
import 'Home.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Share',
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
        accentColor: Colors.deepPurple,
      ),
      home: Home(),
    );
  }
}