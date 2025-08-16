import 'package:edu/presentation/auth/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:edu/presentation/auth/login_screen.dart';


const supabaseUrl = 'https://taqkokkgjwaaolwvzxde.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRhcWtva2tnandhYW9sd3Z6eGRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQzMjQ1ODEsImV4cCI6MjA2OTkwMDU4MX0.hpG2TlWobFnOgajrBsp2SqpJO4s0F3ARNM1DCwkn2WA';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduSphere',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/homeParent': (_) => const HomeParentScreen(),
        '/homeProf': (_) => const HomeProfScreen(),
      },
    );
  }
}

// Juste placeholders pour tester
class HomeParentScreen extends StatelessWidget {
  const HomeParentScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text("Accueil Parent")));
  }
}

class HomeProfScreen extends StatelessWidget {
  const HomeProfScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text("Accueil Professeur")));
  }
}
