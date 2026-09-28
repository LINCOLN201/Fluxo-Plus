import 'package:flutter/material.dart';

/// Catálogo de serviços de assinatura mais comuns no Brasil, pra montar a
/// lista rápido em vez de digitar tudo na mão. Usa só ícones do Material
/// (sem baixar logo de ninguém) — cada um com uma cor própria só pra
/// diferenciar visualmente, sem pretensão de imitar a marca.
class StreamingService {
  const StreamingService(this.name, this.icon, this.color);

  final String name;
  final IconData icon;
  final Color color;
}

abstract final class StreamingCatalog {
  static const services = <StreamingService>[
    StreamingService('Netflix', Icons.movie_rounded, Color(0xFFB3261E)),
    StreamingService(
      'Amazon Prime Video',
      Icons.local_movies_rounded,
      Color(0xFF2A6DB0),
    ),
    StreamingService('Disney+', Icons.star_rounded, Color(0xFF1E3A8A)),
    StreamingService('Max (HBO)', Icons.theaters_rounded, Color(0xFF6D28D9)),
    StreamingService('Globoplay', Icons.live_tv_rounded, Color(0xFFB3261E)),
    StreamingService(
      'Paramount+',
      Icons.movie_filter_rounded,
      Color(0xFF2A6DB0),
    ),
    StreamingService(
      'Apple TV+',
      Icons.tv_rounded,
      Color(0xFF3F3F46),
    ),
    StreamingService(
      'Crunchyroll',
      Icons.animation_rounded,
      Color(0xFFD9661F),
    ),
    StreamingService(
        'YouTube Premium', Icons.smart_display_rounded, Color(0xFFB3261E)),
    StreamingService('Spotify', Icons.music_note_rounded, Color(0xFF1DB954)),
    StreamingService(
      'Deezer',
      Icons.headphones_rounded,
      Color(0xFFD9661F),
    ),
    StreamingService(
      'Amazon Music',
      Icons.queue_music_rounded,
      Color(0xFF2A6DB0),
    ),
    StreamingService(
      'Google One',
      Icons.cloud_rounded,
      Color(0xFF2A6DB0),
    ),
    StreamingService('iCloud+', Icons.cloud_queue_rounded, Color(0xFF3F3F46)),
    StreamingService(
      'Xbox Game Pass',
      Icons.sports_esports_rounded,
      Color(0xFF2E7D32),
    ),
    StreamingService(
      'PlayStation Plus',
      Icons.sports_esports_rounded,
      Color(0xFF2A6DB0),
    ),
    StreamingService(
      'Outro',
      Icons.subscriptions_rounded,
      Color(0xFF6A4FA0),
    ),
  ];

  /// Serviço pelo nome salvo na transação, ou o ícone genérico ("Outro") se
  /// a pessoa digitou um nome que não está no catálogo.
  static StreamingService match(String name) {
    for (final service in services) {
      if (service.name.toLowerCase() == name.toLowerCase()) return service;
    }
    return services.last;
  }
}
