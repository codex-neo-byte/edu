import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final supa = Supabase.instance.client;

    try {
      // 1) Auth
      final res = await supa.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      final user = res.user;
      if (user == null) {
        setState(() => _error = "Identifiants invalides");
        return;
      }

      // 2) Rôle (nécessite policy SELECT)
      final row = await supa
          .from('utilisateurs')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      if (row == null || row['role'] == null) {
        setState(() => _error = "Rôle introuvable pour cet utilisateur (vérifie l'insertion dans 'utilisateurs').");
        return;
      }

      final role = (row['role'] as String).toLowerCase();

      // 3) Redirection
      if (!mounted) return;
      switch (role) {
        case 'professeur':
          Navigator.pushReplacementNamed(context, '/homeProf');
          break;
        case 'parent':
          Navigator.pushReplacementNamed(context, '/homeParent');
          break;
        case 'eleve':
          Navigator.pushReplacementNamed(context, '/homeEleve');
          break;
        default:
          setState(() => _error = "Rôle inconnu: $role");
      }
    } on AuthException catch (e) {
      setState(() => _error = "AUTH: ${e.message}");
    } on PostgrestException catch (e) {
      // Typiquement RLS → code 404/42501, message explicite
      setState(() => _error = "DB ${e.code ?? ''}: ${e.message} ${e.hint ?? ''}".trim());
    } catch (e) {
      setState(() => _error = "Erreur de connexion: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Connexion")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: emailController,
                decoration: _inputDecoration("Email", Icons.email),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || v.trim().isEmpty) ? "Champ requis" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: _inputDecoration("Mot de passe", Icons.lock),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Champ requis" : null,
              ),
              const SizedBox(height: 20),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),

              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                child: const Text("Se connecter"),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: const Text("Créer un compte"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
