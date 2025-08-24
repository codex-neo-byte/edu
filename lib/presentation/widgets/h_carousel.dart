import 'package:edu/data/models/professeur.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'prof_card.dart';

class HorizontalProfCarouselPaged extends StatefulWidget {
  final String title;
  final List<Professeur> items;
  final int pageSize;   // 2 ou 3 cartes par page
  final double cardWidth;

  const HorizontalProfCarouselPaged({
    super.key,
    required this.title,
    required this.items,
    this.pageSize = 3,
    this.cardWidth = 220,
  });

  @override
  State<HorizontalProfCarouselPaged> createState() => _HorizontalProfCarouselPagedState();
}

class _HorizontalProfCarouselPagedState extends State<HorizontalProfCarouselPaged> {
  final _controller = PageController(viewportFraction: 0.92);
  int _page = 0;

  List<List<Professeur>> _chunk(List<Professeur> source, int size) {
    final out = <List<Professeur>>[];
    for (var i = 0; i < source.length; i += size) {
      out.add(source.sublist(i, i + size > source.length ? source.length : i + size));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final pages = _chunk(widget.items, widget.pageSize);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Expanded(child: Text(widget.title, style: Theme.of(context).textTheme.titleMedium)),
              if (pages.length > 1)
                Text('${_page + 1}/${pages.length}', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: pages.isEmpty
              ? Center(child: Text('Aucun professeur', style: TextStyle(color: Colors.grey[600])))
              : PageView.builder(
            controller: _controller,
            itemCount: pages.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) {
              final pageItems = pages[i];
              return Row(
                children: [
                  for (var j = 0; j < pageItems.length; j++) ...[
                    SizedBox(width: widget.cardWidth, child: ProfCard(prof: pageItems[j])),
                    if (j != pageItems.length - 1) const SizedBox(width: 12),
                  ]
                ],
              );
            },
          ),
        ),
        if (pages.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                    (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 10 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _page ? Colors.blue : Colors.grey[400],
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
