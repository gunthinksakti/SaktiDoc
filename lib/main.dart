import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';

void main() => runApp(const SaktiDocApp());

class SaktiDocApp extends StatelessWidget {
  const SaktiDocApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SaktiDoc',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DashboardScreen(),
    );
  }
}
