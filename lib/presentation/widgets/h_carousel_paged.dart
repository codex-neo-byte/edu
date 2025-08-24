import 'dart:async';
import 'package:flutter/material.dart';
import 'package:edu/data/models/professeur.dart';
import 'prof_card.dart';

class HorizontalProfCarouselPaged extends StatefulWidget {
  final String title;
  final List<Professeur> items;

  /// Nombre de cartes par page (2 conseillé mobile, 3 si large)
  final int pageSize;

  /// Largeur d’une carte (doit tenir dans l’écran * pageSize)
  final double cardWidth;

  /// Auto défilement
  final bool autoplay;
  final Duration autoPlayInterval;
  final Duration autoPlayAnimDuration;
  final Curve autoPlayCurve;

  const HorizontalProfCarouselPaged({
    super.key,
    required this.title,
    required this.items,
    this.pageSize = 2,
    this.cardWidth = 200,
    this.autoplay = true,
    this.autoPlayInterval = const Duration(seconds: 3),
    this.autoPlayAnimDuration = const Duration(milliseconds: 450),
    this.autoPlayCurve = Curves.easeOut,
  });

  @override
  State<HorizontalProfCarouselPaged> createState() => _HorizontalProfCarouselPagedState();
}

class _HorizontalProfCarouselPagedState extends State<HorizontalProfCarouselPaged> {
  final PageController _controller = PageController(viewportFraction: 0.95);
  int _page = 0;
  Timer? _timer;

  int get _pagesCount {
    final n = widget.items.length;
    final s = widget.pageSize <= 0 ? 1 : widget.pageSize;
    if (n == 0) return 0;
    return (n + s - 1) ~/ s; // ceil(n / s)
  }

  List<List<Professeur>> _chunk(List<Professeur> src, int size) {
    final out = <List<Professeur>>[];
    for (var i = 0; i < src.length; i += size) {
      out.add(src.sublist(i, i + size > src.length ? src.length : i + size));
    }
    return out;
  }

  void _startAutoplay() {
    _timer?.cancel();
    if (!widget.autoplay) return;
    if (_pagesCount <= 1) return;

    _timer = Timer.periodic(widget.autoPlayInterval, (_) {
      if (!mounted) return;
      final total = _pagesCount;
      if (total <= 1) return;
      final next = (_page + 1) % total;
      _controller.animateToPage(
        next,
        duration: widget.autoPlayAnimDuration,
        curve: widget.autoPlayCurve,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoplay());
  }

  @override
  void didUpdateWidget(covariant HorizontalProfCarouselPaged oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si la data ou les paramètres autoplay changent, on relance le timer
    if (oldWidget.items.length != widget.items.length ||
        oldWidget.pageSize != widget.pageSize ||
        oldWidget.autoplay != widget.autoplay) {
      _startAutoplay();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = _chunk(widget.items, widget.pageSize);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre + compteur page
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Expanded(child: Text(widget.title, style: Theme.of(context).textTheme.titleMedium)),
              if (_pagesCount > 1)
                Text('${_page + 1}/$_pagesCount', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),

        // Pages
        SizedBox(
          height: 190,
          child: pages.isEmpty
              ? Center(child: Text('Aucun professeur', style: TextStyle(color: Colors.grey[600])))
              : PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: pages.length,
            itemBuilder: (_, i) {
              final items = pages[i];
              return Row(
                children: [
                  for (var j = 0; j < items.length; j++) ...[
                    SizedBox(width: widget.cardWidth, child: ProfCard(prof: items[j])),
                    if (j != items.length - 1) const SizedBox(width: 12),
                  ],
                ],
              );
            },
          ),
        ),

        // Indicateurs
        if (_pagesCount > 1)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pagesCount,
                    (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 10 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _page ? Colors.blue : Colors.red[400],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
