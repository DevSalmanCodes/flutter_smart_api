import 'package:flutter/material.dart';
import 'package:flutter_smart_api/flutter_smart_api.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize API config and built-in persistent caching
  await ApiConfig.init(
    baseUrl: 'https://jsonplaceholder.typicode.com',
    enableLogging: true,
  );

  // 2. Register JSON parsing constructors centrally
  ModelFactory.register<Post>((json) => Post.fromJson(json));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Smart API Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 3. Fetch data efficiently using Safe Result wrappers
  Future<Result<List<Post>>> _fetchPosts() {
    return Api.getSafe<List<Post>>(
      '/posts',
      // The framework will first use its blazing fast memory cache,
      // fallback to persistent disk parsing if missing from memory,
      // and only hit network if data is entirely absent or expired.
      cache: true,
      persistent: true,
      cacheTtl: const Duration(hours: 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart API Showcase')),
      body: FutureBuilder<Result<List<Post>>>(
        future: _fetchPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            final result = snapshot.data!;

            // 4. Clean `.when()` pattern enforces exhaustive UI states
            return result.when(
              success: (posts) {
                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return ListTile(
                      title: Text(post.title, maxLines: 1),
                      subtitle: Text(post.body, maxLines: 2),
                      leading: CircleAvatar(child: Text('${post.id}')),
                    );
                  },
                );
              },
              failure: (error) {
                return Center(
                  child: Text(
                    'Error: ${error.message}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Triggers a UI refresh but instant because cache hits locally
          setState(() {});
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

// Simple Dart data model
class Post {
  final int id;
  final String title;
  final String body;

  Post({required this.id, required this.title, required this.body});

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'body': body};
  }
}
