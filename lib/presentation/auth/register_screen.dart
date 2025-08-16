import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Champs
  String role = 'Professeur'; // Professeur | Parent | Élève
  String fullName = '';
  String email = '';
  String password = '';
  String matiere = '';
  String tarif = '';
  String bio = '';
  File? diplomeFile;

  bool isLoading = false;

  // ─── Helpers ────────────────────────────────────────────────────────────────
  String _safeFileName(String path) {
    final base = path.split('/').last;
    return base.replaceAll(RegExp(r'[^a-zA-Z0-9\.\-_]'), '_');
  }

  Future<void> _pickDiplome() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => diplomeFile = File(result.files.single.path!));
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  // ─── Register main ─────────────────────────────────────────────────────────
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    final supa = Supabase.instance.client;

    try {
      // 1) Auth
      final auth = await supa.auth.signUp(
        email: email.trim(),
        password: password.trim(),
      );
      final user = auth.user;
      if (user == null) {
        throw Exception("Impossible de créer le compte (Auth).");
      }
      final userId = user.id;

      // 2) Table utilisateurs
      final roleDb = role.toLowerCase() == 'élève' ? 'eleve' : role.toLowerCase();
      await supa.from('utilisateurs').insert({
        'id': userId,
        'nom': fullName.trim(),
        'email': email.trim(),
        'role': roleDb,
        'created_at': DateTime.now().toIso8601String(),
      });

      // 3) Rôle spécifique
      if (roleDb == 'professeur') {
        await _createProf(supa, userId);
      } else if (roleDb == 'parent') {
        await _createParent(supa, userId);
      } else if (roleDb == 'eleve') {
        await _createEleve(supa, userId);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compte créé avec succès !')),
      );
      Navigator.pop(context); // retour login
    } on AuthException catch (e) {
      _showError("Auth: ${e.message}");
    } on PostgrestException catch (e) {
      _showError("DB (${e.code ?? ''}): ${e.message.isNotEmpty ? e.message : 'Erreur de base de données'}");
    } catch (e) {
      _showError("Erreur: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ─── Professeur: professeurs(id=userId) + tarifs_professeurs ───────────────
  Future<void> _createProf(SupabaseClient supa, String userId) async {
    String? diplomeUrl;
    if (diplomeFile != null) {
      try {
        final safe = _safeFileName(diplomeFile!.path);
        final path = 'diplomes/$userId-$safe';
        await supa.storage
            .from('diplomes')
            .upload(path, diplomeFile!, fileOptions: const FileOptions(upsert: true));
        diplomeUrl = supa.storage.from('diplomes').getPublicUrl(path);
      } catch (e) {
        debugPrint("⚠️ Upload diplôme échoué: $e");
      }
    }

    await supa.from('professeurs').insert({
      'id': userId,        // 👈 PK = userId
      'utilisateur_id': userId,   // si cette colonne existe
      'specialites': matiere.trim(),
      'diplome_url': diplomeUrl,
      'bio': bio.trim(),
      'created_at': DateTime.now().toIso8601String(),
    });

    if (tarif.trim().isNotEmpty) {
      final value = double.tryParse(tarif.trim());
      if (value != null) {
        await supa.from('tarifs_professeurs').insert({
          'professeur_id': userId,
          'tarif_horaire': value,
          'mode': 'les_deux',
          'devise': 'XOF',
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    }
  }

  // ─── Parent ────────────────────────────────────────────────────────────────
  Future<void> _createParent(SupabaseClient supa, String userId) async {
    await supa.from('parents').insert({
      'user_id': userId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ─── Élève ────────────────────────────────────────────────────────────────
  Future<void> _createEleve(SupabaseClient supa, String userId) async {
    await supa.from('eleves').insert({
      'user_id': userId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ─── UI ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isProf = role == 'Professeur';

    return Scaffold(
      appBar: AppBar(title: const Text("Créer un compte")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: "Rôle"),
                  items: const [
                    DropdownMenuItem(value: 'Professeur', child: Text('Professeur')),
                    DropdownMenuItem(value: 'Parent', child: Text('Parent')),
                    DropdownMenuItem(value: 'Élève', child: Text('Élève')),
                  ],
                  onChanged: (val) => setState(() => role = val ?? 'Professeur'),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  decoration: const InputDecoration(labelText: "Nom complet"),
                  onChanged: (val) => fullName = val,
                  validator: (val) => (val == null || val.isEmpty) ? 'Entrez votre nom' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  decoration: const InputDecoration(labelText: "Email"),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (val) => email = val,
                  validator: (val) => (val == null || !val.contains('@')) ? 'Email invalide' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  decoration: const InputDecoration(labelText: "Mot de passe"),
                  obscureText: true,
                  onChanged: (val) => password = val,
                  validator: (val) => (val != null && val.length < 6) ? 'Min. 6 caractères' : null,
                ),
                const SizedBox(height: 12),

                if (isProf) ...[
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Matière principale"),
                    onChanged: (val) => matiere = val,
                    validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    decoration: const InputDecoration(labelText: "Tarif horaire (ex: 8000)"),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => tarif = val,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    decoration: const InputDecoration(labelText: "Bio / Description"),
                    maxLines: 3,
                    onChanged: (val) => bio = val,
                  ),
                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    onPressed: _pickDiplome,
                    icon: const Icon(Icons.upload_file),
                    label: const Text("Téléverser diplôme"),
                  ),
                  if (diplomeFile != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        "Fichier : ${diplomeFile!.path.split('/').last}",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  const SizedBox(height: 12),
                ],

                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isLoading ? null : _register,
                  child: isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text("Créer mon compte"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
