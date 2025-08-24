class Professeur {
  final String id;
  final String nom;
  final String? photoUrl;
  final String? specialites;
  final String? bio;
  final double? tarifHoraire;
  final String? mode;   // en_ligne | presentiel | les_deux (depuis tarifs_professeurs)
  final String? format; // individuel | groupe | les_deux (depuis tarifs_professeurs)

  Professeur({
    required this.id,
    required this.nom,
    this.photoUrl,
    this.specialites,
    this.bio,
    this.tarifHoraire,
    this.mode,
    this.format,
  });

  // util: si la jointure renvoie une liste, on prend le 1er élément
  static Map<String, dynamic>? _firstJoin(dynamic v) {
    if (v == null) return null;
    if (v is List && v.isNotEmpty) return v.first as Map<String, dynamic>;
    if (v is Map<String, dynamic>) return v;
    return null;
  }

  factory Professeur.fromRow(Map<String, dynamic> row) {
    final utilisateur = row['utilisateurs'] as Map<String, dynamic>?;
    final tarifsRaw = row['tarifs_professeurs'];
    final tarifObj = _firstJoin(tarifsRaw); // <- clé pour éviter les erreurs

    return Professeur(
      id: row['id'] as String,
      nom: utilisateur?['nom'] as String? ?? '—',
      photoUrl: utilisateur?['photo_profil_url'] as String?,
      specialites: row['specialites'] as String?,
      bio: row['bio'] as String?,
      tarifHoraire: (tarifObj?['tarif_horaire'] as num?)?.toDouble(),
      mode: tarifObj?['mode'] as String?,
      format: tarifObj?['format'] as String?,
    );
  }

  String get modeLabel => switch (mode) {
    'presentiel' => 'Présentiel',
    'les_deux'   => 'Hybride',
    'en_ligne'   => 'En ligne',
    _            => '—',
  };

  String get formatLabel => switch (format) {
    'groupe'     => 'Groupe',
    'les_deux'   => 'Mixte',
    'individuel' => 'Individuel',
    _            => '—',
  };
}
