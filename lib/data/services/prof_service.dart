import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/professeur.dart';

class ProfService {
  final _supa = Supabase.instance.client;

  // util: dédupliquer par id
  List<Professeur> _dedupeById(List<Professeur> items) {
    final map = <String, Professeur>{};
    for (final p in items) {
      map[p.id] = p; // le dernier remplace (peu importe ici)
    }
    return map.values.toList();
  }

  Future<List<Professeur>> byMode(String mode, {int limit = 50}) async {
    final rows = await _supa
        .from('professeurs')
        .select('''
          id,
          specialites,
          bio,
          utilisateurs:utilisateurs!fk_prof_user ( nom, photo_profil_url ),
          tarifs_professeurs:tarifs_professeurs!inner!fk_tarif_prof ( tarif_horaire, mode, format )
        ''')
        .eq('tarifs_professeurs.mode', mode)
        .limit(limit);

    final list = (rows as List).cast<Map<String, dynamic>>();
    final items = list.map((r) => Professeur.fromRow(r)).toList();
    return _dedupeById(items);
  }

  Future<List<Professeur>> byFormat(String format, {int limit = 50}) async {
    final rows = await _supa
        .from('professeurs')
        .select('''
          id,
          specialites,
          bio,
          utilisateurs:utilisateurs!fk_prof_user ( nom, photo_profil_url ),
          tarifs_professeurs:tarifs_professeurs!inner!fk_tarif_prof ( tarif_horaire, mode, format )
        ''')
        .eq('tarifs_professeurs.format', format)
        .limit(limit);

    final list = (rows as List).cast<Map<String, dynamic>>();
    final items = list.map((r) => Professeur.fromRow(r)).toList();
    return _dedupeById(items);
  }
}
