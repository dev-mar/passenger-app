class _CacheEntry<T> {
  const _CacheEntry(this.value, this.expiresAt);

  final T value;
  final DateTime expiresAt;
}

/// Cache en memoria con deduplicación de requests en vuelo.
///
/// Útil para consultas no-realtime de alto tráfico (autocomplete, geocoding,
/// rutas, catálogos), evitando ráfagas innecesarias al backend/terceros.
class RequestPolicyCache<T> {
  RequestPolicyCache({required this.defaultTtl});

  final Duration defaultTtl;
  final Map<String, _CacheEntry<T>> _cache = <String, _CacheEntry<T>>{};
  final Map<String, Future<T>> _inFlight = <String, Future<T>>{};

  Future<T> run({
    required String key,
    required Future<T> Function() fetcher,
    Duration? ttl,
    bool forceRefresh = false,
  }) {
    final now = DateTime.now();
    if (!forceRefresh) {
      final cached = _cache[key];
      if (cached != null && cached.expiresAt.isAfter(now)) {
        return Future<T>.value(cached.value);
      }
      final pending = _inFlight[key];
      if (pending != null) return pending;
    }

    final future = fetcher()
        .then((value) {
          _cache[key] = _CacheEntry<T>(value, now.add(ttl ?? defaultTtl));
          _trimExpired(now);
          return value;
        })
        .whenComplete(() {
          _inFlight.remove(key);
        });

    _inFlight[key] = future;
    return future;
  }

  void _trimExpired(DateTime now) {
    if (_cache.length < 250) return;
    final expiredKeys = _cache.entries
        .where((entry) => !entry.value.expiresAt.isAfter(now))
        .map((entry) => entry.key)
        .toList(growable: false);
    for (final key in expiredKeys) {
      _cache.remove(key);
    }
  }
}
