import 'package:morpheme_cli/helper/recase.dart';

enum CacheStrategy {
  asyncOrCache('async_or_cache'),
  cacheOrAsync('cache_or_async'),
  justAsync('just_async'),
  justCache('just_cache');

  const CacheStrategy(this.value);

  final String value;

  static CacheStrategy fromString(String value) {
    return CacheStrategy.values.firstWhere((e) => e.value == value);
  }

  String toParamCacheStrategy({int? ttl, bool? keepExpiredCache}) {
    if (this == CacheStrategy.justAsync) {
      return 'cacheStrategy: ${value.pascalCase}Strategy()';
    }
    return 'cacheStrategy: ${value.pascalCase}Strategy(${ttl == null ? '' : 'ttlValue: const Duration(minutes: $ttl)'}${keepExpiredCache == null ? '' : ttl == null ? '' : ', keepExpiredCache: $keepExpiredCache'}${ttl != null || keepExpiredCache != null ? ',' : ''})';
  }
}
