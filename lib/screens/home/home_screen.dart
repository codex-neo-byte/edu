
import 'package:flutter/material.dart';
import 'package:edu/data/models/professeur.dart';
import 'package:edu/data/services/prof_service.dart';
import 'package:edu/presentation/widgets/h_carousel_paged.dart'; //
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _svc = ProfService();
  late Future<List<Professeur>> _individuel;
  late Future<List<Professeur>> _enLigne;
  late Future<List<Professeur>> _groupe;

  @override
  void initState() {
    super.initState();
    _individuel = _svc.byFormat('individuel');
    _enLigne    = _svc.byMode('en_ligne');
    _groupe     = _svc.byFormat('les_deux');
  }

  Widget _section(String title, Future<List<Professeur>> future) {
    final width = MediaQuery.of(context).size.width;
    // 1 carte si très étroit, sinon 2
    final pageSize = width < 360 ? 1 : 2;
    // marge horizontale ~32 + gap 12 entre cartes
    final horizontalPadding = 32.0;
    final gap = 12.0;
    final totalGap = (pageSize - 1) * gap;
    final usable = width - horizontalPadding - totalGap;
    final cardWidth = (usable / pageSize).clamp(160, 260);

    return FutureBuilder<List<Professeur>>(
      future: future,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 190, child: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Erreur: ${snap.error}', style: const TextStyle(color: Colors.red)),
          );
        }
        final items = snap.data ?? [];

        // DEBUG rapide pour vérifier la data
        // ignore: avoid_print
        print('SECTION "$title" -> ${items.length} profs');

        return HorizontalProfCarouselPaged(
          title: title,
          items: items,
          pageSize: pageSize,
          cardWidth: cardWidth.toDouble(),
          autoplay: true,
          autoPlayInterval: const Duration(seconds: 3),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EduSphere'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.person)),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _section('Encadrement individuel', _individuel),
          _section('Travail de groupe', _groupe),
          _section('Travail en ligne', _enLigne),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
