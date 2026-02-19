import 'package:flutter/material.dart';
import 'features/post/presentation/pages/post_list_page.dart';

void main() {
  runApp(const KnockApp());
}

class KnockApp extends StatelessWidget {
  const KnockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Knock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: const Color(0xFFF7F6FB),
      ),
      home: const PostListPage(),
    );
  }
}
