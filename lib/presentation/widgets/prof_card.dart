import 'package:edu/data/models/professeur.dart';
import 'package:flutter/material.dart';

class ProfCard extends StatelessWidget {
  final Professeur prof;
  final VoidCallback? onTap;
  const ProfCard({super.key, required this.prof, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: prof.photoUrl != null ? NetworkImage(prof.photoUrl!) : null,
                    child: prof.photoUrl == null ? const Icon(Icons.person) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      prof.nom,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (prof.specialites?.isNotEmpty == true)
                Text(prof.specialites!, maxLines: 1, overflow: TextOverflow.ellipsis),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(label: Text(prof.modeLabel)),
                  Text(
                    prof.tarifHoraire != null ? '${prof.tarifHoraire!.toStringAsFixed(0)} XOF/H' : '—',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
