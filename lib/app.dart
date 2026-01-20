import 'package:flutter/material.dart';

class PsClipsApp extends StatelessWidget {
  const PsClipsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PS Clips',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const Scaffold(body: Center(child: Text('PS Clips - Coming Soon'))),
    );
  }
}
