import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Champs
  String role = 'Professeur'; // Professeur | Parent | Élève
  String _modeTravail = 'presentiel'; // en_ligne | presentiel | groupe
  String _formatCours = 'individuel'; // individu el | groupe | les_deux

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _matiereCtrl = TextEditingController();
  final _tarifCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  //Parent
  final _telephoneCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();

  // Fichiers (mobile) / Bytes (web)
  File? _avatarFile;
  File? _diplomeFile;
  Uint8List? _avatarBytesWeb;
  Uint8List? _diplomeBytesWeb;
  String? _avatarNameWeb;
  String? _diplomeNameWeb;

  bool isLoading = false;

  // ──────────────────────────────────────────────────────────────────────────
  String _safeFileName(String pathOrName) =>
      pathOrName.split('/').last.replaceAll(RegExp(r'[^a-zA-Z0-9\.\-_]'), '_');

  void _showSnack(String msg, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  ImageProvider? _avatarPreview() {
    if (!kIsWeb && _avatarFile != null) return FileImage(_avatarFile!);
    if (kIsWeb && _avatarBytesWeb != null) return MemoryImage(_avatarBytesWeb!);
    return null;
  }

  Future<void> _pickAvatar() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      withData: kIsWeb, // important sur Web
    );
    if (res == null) return;
    if (kIsWeb) {
      setState(() {
        _avatarBytesWeb = res.files.single.bytes;
        _avatarNameWeb = res.files.single.name;
        _avatarFile = null;
      });
    } else {
      final path = res.files.single.path;
      if (path != null) {
        setState(() {
          _avatarFile = File(path);
          _avatarBytesWeb = null;
          _avatarNameWeb = null;
        });
      }
    }
  }

  Future<void> _pickDiplome() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      withData: kIsWeb,
    );
    if (res == null) return;
    if (kIsWeb) {
      setState(() {
        _diplomeBytesWeb = res.files.single.bytes;
        _diplomeNameWeb = res.files.single.name;
        _diplomeFile = null;
      });
    } else {
      final path = res.files.single.path;
      if (path != null) {
        setState(() {
          _diplomeFile = File(path);
          _diplomeBytesWeb = null;
          _diplomeNameWeb = null;
        });
      }
    }
  }

  Future<String?> _uploadPublic({
    required String bucket,
    required String storagePath, // ex: 'avatars/<uid>.png' ou 'diplomes/<uid>-fichier.pdf'
    File? fileMobile,
    Uint8List? bytesWeb,
  }) async {
    final supa = Supabase.instance.client;
    try {
      if (kIsWeb) {
        if (bytesWeb == null) throw Exception('Aucun bytes pour upload web');
        await supa.storage.from(bucket).uploadBinary(
          storagePath,
          bytesWeb,
          fileOptions: const FileOptions(upsert: true),
        );
      } else {
        if (fileMobile == null) throw Exception('Aucun fichier pour upload mobile');
        await supa.storage.from(bucket).upload(
          storagePath,
          fileMobile,
          fileOptions: const FileOptions(upsert: true),
        );
      }
      return supa.storage.from(bucket).getPublicUrl(storagePath);
    } on StorageException catch (e) {
      _showSnack("Storage $bucket: ${e.message}", color: Colors.orange);
      return null;
    } catch (e) {
      _showSnack("Upload $bucket: $e", color: Colors.orange);
      return null;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    final supa = Supabase.instance.client;

    try {
      // 1) Auth
      final auth = await supa.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      final user = auth.user;
      if (user == null) {
        throw Exception("Impossible de créer le compte (Auth).");
      }
      final uid = user.id;

      // 2) Upload avatar (optionnel) — bucket: avatars (public conseillé)
      String? avatarUrl;
      if ((_avatarFile != null) || (_avatarBytesWeb != null)) {
        try {
          // nommage
          String fileName;
          if (kIsWeb) {
            fileName = _avatarNameWeb ?? 'avatar.png';
          } else {
            final ext = _avatarFile!.path.split('.').last.toLowerCase();
            fileName = '$uid.$ext';
          }
          final path = 'avatars/$fileName'; // sous-dossier dans le bucket avatars

          avatarUrl = await _uploadPublic(
            bucket: 'avatars',
            storagePath: path,
            fileMobile: _avatarFile,
            bytesWeb: _avatarBytesWeb,
          );
        } catch (e) {
          _showSnack("Erreur inconnue upload avatar: $e", color: Colors.orange);
        }
      }

      // 3) Table utilisateurs
      final roleDb = role.toLowerCase() == 'élève' ? 'eleve' : role.toLowerCase();
      await supa.from('utilisateurs').insert({
        'id': uid,
        'nom': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'role': roleDb,
        'photo_profil_url': avatarUrl, // <- champ de ta table
        'created_at': DateTime.now().toIso8601String(),
      });

      // 4) Rôle spécifique
      if (roleDb == 'professeur') {
        await _createProf(supa, uid);
      } else if (roleDb == 'parent') {
        await _createParent(supa, uid);
      } else if (roleDb == 'eleve') {
        await _createEleve(supa, uid);
      }

      _showSnack('Compte créé avec succès !', color: Colors.green);
      if (!mounted) return;
      Navigator.pop(context); // retour login
    } on AuthException catch (e) {
      _showSnack("Auth: ${e.message}", color: Colors.red);
    } on PostgrestException catch (e) {
      _showSnack("DB (${e.code ?? ''}): ${e.message.isNotEmpty ? e.message : 'Erreur DB'}", color: Colors.red);
    } catch (e) {
      _showSnack("Erreur: $e", color: Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ─── Professeur: professeurs(id=uid) + tarifs_professeurs ────────────────
  Future<void> _createProf(SupabaseClient supa, String uid) async {
    // 1) Upload diplôme (optionnel) — bucket: diplomes (privé conseillé)
    String? diplomeUrl;
    if ((_diplomeFile != null) || (_diplomeBytesWeb != null)) {
      try {
        String fileName;
        if (kIsWeb) {
          fileName = _diplomeNameWeb ?? 'diplome.pdf';
        } else {
          fileName = _safeFileName(_diplomeFile!.path);
        }
        final path = 'diplomes/$uid-$fileName'; // sous-dossier dans bucket diplomes

        diplomeUrl = await _uploadPublic(
          bucket: 'diplomes',
          storagePath: path,
          fileMobile: _diplomeFile,
          bytesWeb: _diplomeBytesWeb,
        );
      } catch (e) {
        _showSnack("Erreur inconnue upload diplôme: $e", color: Colors.orange);
      }
    }

    // 2) professeurs
    await supa.from('professeurs').insert({
      'id': uid,
      'utilisateur_id': uid, // ton schéma
      'specialites': _matiereCtrl.text.trim(),
      'bio': _bioCtrl.text.trim(),
      'diplome_url': diplomeUrl,
      'created_at': DateTime.now().toIso8601String(),
    });

    // 3) tarifs_professeurs (facultatif)
    final t = double.tryParse(_tarifCtrl.text.trim());
    if (t != null) {
      await supa.from('tarifs_professeurs').insert({
        'professeur_id': uid,
        'tarif_horaire': t,
        'mode': 'presentiel', // en_ligne | presentiel | les_deux
        'format': _formatCours,
        'devise': 'XOF',
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // ─── Parent ───────────
  Future<void> _createParent(SupabaseClient supa, String uid) async {
    await supa.from('parents').insert({
      'utilisateur_id': uid,
      'telephone': _telephoneCtrl.text.trim(),
      'adresse': _adresseCtrl.text.trim(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ─── Élève ────────────
  Future<void> _createEleve(SupabaseClient supa, String uid) async {
    await supa.from('eleves').insert({
      'utilisateur_id': uid,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _matiereCtrl.dispose();
    _tarifCtrl.dispose();
    _bioCtrl.dispose();
    _telephoneCtrl.dispose();
    _adresseCtrl.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, [IconData? icon]) => InputDecoration(
    labelText: label,
    prefixIcon: icon != null ? Icon(icon) : null,
    filled: true,
    fillColor: Colors.grey.shade100,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
  );

  @override
  Widget build(BuildContext context) {
    final isProf = role == 'Professeur';
    final isParent = role == 'Parent';
    final isEleve = role == 'Élève';

    return Scaffold(
      appBar: AppBar(title: const Text("Créer un compte")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar picker + aperçu
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundImage: _avatarPreview(),
                      child: _avatarPreview() == null ? const Icon(Icons.person, size: 40) : null,
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _pickAvatar,
                      icon: const Icon(Icons.photo_camera),
                      label: const Text("Ajouter une photo"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: role,
                decoration: _dec("Rôle"),
                items: const [
                  DropdownMenuItem(value: 'Professeur', child: Text('Professeur')),
                  DropdownMenuItem(value: 'Parent', child: Text('Parent')),
                  DropdownMenuItem(value: 'Élève', child: Text('Élève')),
                ],
                onChanged: (val) => setState(() => role = val ?? 'Professeur'),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nameCtrl,
                decoration: _dec("Nom complet", Icons.person),
                validator: (v) => (v == null || v.isEmpty) ? 'Entrez votre nom' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _emailCtrl,
                decoration: _dec("Email", Icons.email),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || !v.contains('@')) ? 'Email invalide' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _passCtrl,
                decoration: _dec("Mot de passe", Icons.lock),
                obscureText: true,
                validator: (v) => (v != null && v.length < 6) ? 'Min. 6 caractères' : null,
              ),
              const SizedBox(height: 12),

              if (isProf) ...[
                TextFormField(
                  controller: _matiereCtrl,
                  decoration: _dec("Matière principale", Icons.school),
                  validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 12),

                // Mode de travail
                DropdownButtonFormField<String>(
                value: _modeTravail,
                decoration: _dec("Mode de travail", Icons.work_outline),
                items:const[
                  DropdownMenuItem(value: 'en_ligne', child: Text('En ligne')),
                  DropdownMenuItem(value: 'presentiel', child: Text('Presentiel')),
                ],
                onChanged: (val) => setState(() => _modeTravail = val ?? 'presentiel'),
              ),
                const SizedBox(height: 12),



                // Format cours
                DropdownButtonFormField<String>(
                  value: _formatCours,
                  decoration: _dec("Format de cours", Icons.people_outline),
                  items: const [
                    DropdownMenuItem(value: 'individuel', child: Text('Individuel')),
                    DropdownMenuItem(value: 'groupe', child: Text('Groupe')),
                    DropdownMenuItem(value: 'les_deux', child: Text('Mixte (les deux)')),
                  ],
                  onChanged: (val) => setState(() => _formatCours = val ?? 'individuel'),
                ),
                const SizedBox(height: 12),


                TextFormField(
                  controller: _tarifCtrl,
                  decoration: _dec("Tarif horaire (ex: 8000)", Icons.monetization_on),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _bioCtrl,
                  decoration: _dec("Bio / Description", Icons.description),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),

                ElevatedButton.icon(
                  onPressed: _pickDiplome,
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Téléverser diplôme"),
                ),
                if (_diplomeBytesWeb != null || _diplomeFile != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      "Fichier : ${_diplomeNameWeb ?? _diplomeFile?.path.split('/').last ?? ''}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                const SizedBox(height: 12),
              ],

              // Parent
              if (isParent) ...[
                TextFormField(
                  controller: _telephoneCtrl,
                  decoration: _dec("Saisir votre numéro de téléphone avec le code pays" , Icons.phone),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _adresseCtrl,
                  decoration: _dec("Adresse", Icons.home),
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
    );
  }
}
