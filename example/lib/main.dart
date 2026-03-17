import 'package:flutter/material.dart';
import 'package:flutter_smart_api/flutter_smart_api.dart';

void main() {
  // 1. Initialize API Config
  ApiConfig.init(
    baseUrl: 'https://jsonplaceholder.typicode.com',
    enableLogging: true,
  );

  // 2. Register Models
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
      home: const ExampleScreen(),
    );
  }
}

class ExampleScreen extends StatefulWidget {
  const ExampleScreen({super.key});

  @override
  State<ExampleScreen> createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen> {
  Future<List<Post>>? _postsFuture;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    setState(() {
      // 3. Make safe typed requests
      _postsFuture = Api.get<List<Post>>('/posts');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart API Example')),
      body: FutureBuilder<List<Post>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            String message = 'Unknown error';
            if (error is ApiException) {
              message = error.message;
            }
            return Center(child: Text('Error: $message'));
          }

          final posts = snapshot.data ?? [];
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return ListTile(
                leading: CircleAvatar(child: Text('${post.id}')),
                title: Text(
                  post.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  post.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchData,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

// Simple Model
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
}
