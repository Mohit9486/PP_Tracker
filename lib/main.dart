import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pp_tracker/home.dart';
import 'package:pp_tracker/models/blog/app_user.dart';
import 'package:pp_tracker/models/user_model.dart';
import 'package:pp_tracker/repositories/blog_repository.dart';
import 'package:pp_tracker/repositories/mock_blog_repository.dart';
import 'package:pp_tracker/state/blog_controller.dart';
import 'package:pp_tracker/theme/app_theme.dart';

void main() {
  runApp(const PetalApp());
}

class PetalApp extends StatelessWidget {
  const PetalApp({super.key});

  @override
  Widget build(BuildContext context) {
    // The signed-in user. With Firebase this comes from auth; for now it's a
    // local demo identity shared across the app (blogs, comments, …).
    final currentUser = AppUser(
      id: 'me',
      displayName: 'You',
      joinedAt: DateTime(2025, 1, 1),
    );

    // Single repository instance — swap MockBlogRepository for a Firestore
    // implementation here and nothing else needs to change.
    final BlogRepository blogRepository = MockBlogRepository();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserModel()),
        ChangeNotifierProvider(
          create: (_) =>
              BlogController(blogRepository, currentUser: currentUser),
        ),
      ],
      child: MaterialApp(
        title: 'Petal — Cycle & Wellness',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const HomePage(),
      ),
    );
  }
}
